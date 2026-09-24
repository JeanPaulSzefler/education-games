extends Control

# Sciezka poziomow - kolka polaczone linia, od lewej do prawej, z osobnymi
# kolkami na odblokowywane rosliny miedzy poziomami. Ekran przewija sie w
# poziomie (jak mapa przygody w Plants vs. Zombies).

const VIEWPORT_WIDTH := 1280
const VIEWPORT_HEIGHT := 720

const NODE_Y := 380.0
const NODE_SPACING := 170.0
const MARGIN := 150.0
const LEVEL_NODE_SIZE := 96.0
const PLANT_NODE_SIZE := 72.0
const BOSS_BADGE_SIZE := 44.0
const LINE_HEIGHT := 8.0
const DRAG_THRESHOLD := 12.0

var path_layer: Control
var arrow_left: Button
var arrow_right: Button

# node_sequence[i] = {"kind": "level", "level_idx": int} albo {"kind": "plant", "plant_idx": int}
var node_sequence: Array = []
var node_x_positions: Array = []
var level_seq_index: Dictionary = {}

# Do testowania tapniecia: lista {"level_idx", "rect" (Rect2 w ukladzie path_layer), "unlocked"}
var level_hit_nodes: Array = []

var min_offset := 0.0
var max_offset := 0.0

var pointer_down := false
var drag_total := 0.0

func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.15, 0.25, 0.15)
	bg.position = Vector2(0, 0)
	bg.size = Vector2(VIEWPORT_WIDTH, VIEWPORT_HEIGHT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var title := Label.new()
	title.text = "Junk vs Plants"
	title.position = Vector2(40, 20)
	title.add_theme_font_size_override("font_size", 40)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(title)

	path_layer = Control.new()
	path_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	path_layer.position = Vector2(0, 0)
	add_child(path_layer)

	_build_node_sequence()
	_build_line_segments()
	_build_nodes()
	_build_arrows()

	var x_last: float = node_x_positions[node_x_positions.size() - 1]
	min_offset = (VIEWPORT_WIDTH - MARGIN) - x_last
	max_offset = 0.0

	var current_idx := _current_level_index()
	var x_current: float = node_x_positions[level_seq_index[current_idx]]
	var start_offset: float = VIEWPORT_WIDTH / 2.0 - x_current
	path_layer.position.x = clamp(start_offset, min_offset, max_offset)
	_update_arrow_visibility()

# --- Budowa sekwencji wezlow: P1, P2, [Lisc], P3, P4, [Mroz], ... ---
func _build_node_sequence() -> void:
	var plants_by_level := {}
	for p_idx in range(PlantData.TYPES.size()):
		var unlock_level: int = PlantData.TYPES[p_idx].get("unlock_level", 1)
		if unlock_level > 1:
			if not plants_by_level.has(unlock_level):
				plants_by_level[unlock_level] = []
			plants_by_level[unlock_level].append(p_idx)

	node_sequence.clear()
	for i in range(LevelData.LEVELS.size()):
		var level_num := i + 1
		if plants_by_level.has(level_num):
			for p_idx in plants_by_level[level_num]:
				node_sequence.append({"kind": "plant", "plant_idx": p_idx})
		level_seq_index[i] = node_sequence.size()
		node_sequence.append({"kind": "level", "level_idx": i})

	node_x_positions.clear()
	for i in range(node_sequence.size()):
		node_x_positions.append(MARGIN + i * NODE_SPACING)

func _is_node_locked(entry: Dictionary) -> bool:
	if entry["kind"] == "level":
		return not GameState.is_level_unlocked(entry["level_idx"])
	return not GameState.is_plant_unlocked(entry["plant_idx"])

func _build_line_segments() -> void:
	for i in range(node_sequence.size() - 1):
		var x_a: float = node_x_positions[i]
		var x_b: float = node_x_positions[i + 1]
		var target_locked := _is_node_locked(node_sequence[i + 1])
		var seg := ColorRect.new()
		seg.color = Color(0.4, 0.4, 0.4) if target_locked else Color(0.55, 0.4, 0.25)
		seg.position = Vector2(x_a, NODE_Y - LINE_HEIGHT / 2.0)
		seg.size = Vector2(x_b - x_a, LINE_HEIGHT)
		seg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		path_layer.add_child(seg)

func _build_nodes() -> void:
	level_hit_nodes.clear()
	for i in range(node_sequence.size()):
		var entry = node_sequence[i]
		var x: float = node_x_positions[i]
		if entry["kind"] == "level":
			_build_level_node(entry["level_idx"], x)
		else:
			_build_plant_node(entry["plant_idx"], x)

func _build_level_node(level_idx: int, x: float) -> void:
	var level: Dictionary = LevelData.LEVELS[level_idx]
	var completed := GameState.is_level_completed(level_idx)
	var unlocked := GameState.is_level_unlocked(level_idx)

	var btn := Button.new()
	btn.size = Vector2(LEVEL_NODE_SIZE, LEVEL_NODE_SIZE)
	btn.position = Vector2(x - LEVEL_NODE_SIZE / 2.0, NODE_Y - LEVEL_NODE_SIZE / 2.0)
	btn.pivot_offset = Vector2(LEVEL_NODE_SIZE / 2.0, LEVEL_NODE_SIZE / 2.0)
	btn.text = str(level_idx + 1)
	btn.add_theme_font_size_override("font_size", 36)
	btn.disabled = not unlocked
	btn.focus_mode = Control.FOCUS_NONE
	# Klikanie obslugujemy sami w _handle_tap() (zeby odroznic tap od
	# przesuwania sciezki), wiec przycisk ma nie reagowac na input.
	btn.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var color: Color
	if completed:
		color = Color(0.25, 0.7, 0.3)
	elif unlocked:
		color = Color(0.85, 0.75, 0.2)
	else:
		color = Color(0.4, 0.4, 0.4)

	for state in ["normal", "hover", "pressed", "disabled"]:
		var sb := StyleBoxFlat.new()
		sb.bg_color = color
		sb.corner_radius_top_left = int(LEVEL_NODE_SIZE / 2.0)
		sb.corner_radius_top_right = int(LEVEL_NODE_SIZE / 2.0)
		sb.corner_radius_bottom_left = int(LEVEL_NODE_SIZE / 2.0)
		sb.corner_radius_bottom_right = int(LEVEL_NODE_SIZE / 2.0)
		btn.add_theme_stylebox_override(state, sb)

	path_layer.add_child(btn)

	if unlocked and not completed:
		var tw := btn.create_tween()
		tw.set_loops()
		tw.tween_property(btn, "scale", Vector2(1.08, 1.08), 0.6).set_trans(Tween.TRANS_SINE)
		tw.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.6).set_trans(Tween.TRANS_SINE)

	var name_label := Label.new()
	var level_name: String = level["name"]
	var dash: int = level_name.find("-")
	name_label.text = level_name.substr(dash + 2) if dash >= 0 else level_name
	name_label.position = Vector2(x - 70, NODE_Y + LEVEL_NODE_SIZE / 2.0 + 4)
	name_label.size = Vector2(140, 30)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 13)
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	path_layer.add_child(name_label)

	var boss_idx: int = level.get("boss", -1)
	if boss_idx >= 0:
		_build_boss_badge(boss_idx, x, unlocked)

	level_hit_nodes.append({
		"level_idx": level_idx,
		"rect": Rect2(x - LEVEL_NODE_SIZE / 2.0, NODE_Y - LEVEL_NODE_SIZE / 2.0, LEVEL_NODE_SIZE, LEVEL_NODE_SIZE),
		"unlocked": unlocked,
	})

func _build_boss_badge(boss_idx: int, x: float, level_unlocked: bool) -> void:
	var badge := Panel.new()
	badge.size = Vector2(BOSS_BADGE_SIZE, BOSS_BADGE_SIZE)
	badge.position = Vector2(x + LEVEL_NODE_SIZE / 2.0 - BOSS_BADGE_SIZE * 0.7, NODE_Y - LEVEL_NODE_SIZE / 2.0 - BOSS_BADGE_SIZE * 0.3)
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.5, 0.05, 0.05, 1.0 if level_unlocked else 0.55)
	sb.corner_radius_top_left = int(BOSS_BADGE_SIZE / 2.0)
	sb.corner_radius_top_right = int(BOSS_BADGE_SIZE / 2.0)
	sb.corner_radius_bottom_left = int(BOSS_BADGE_SIZE / 2.0)
	sb.corner_radius_bottom_right = int(BOSS_BADGE_SIZE / 2.0)
	badge.add_theme_stylebox_override("panel", sb)
	path_layer.add_child(badge)

	var icon := TextureRect.new()
	icon.texture = load(BossData.TYPES[boss_idx]["texture"])
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size = Vector2(BOSS_BADGE_SIZE - 8, BOSS_BADGE_SIZE - 8)
	icon.position = Vector2(4, 4)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not level_unlocked:
		icon.modulate = Color(1, 1, 1, 0.6)
	badge.add_child(icon)

func _build_plant_node(plant_idx: int, x: float) -> void:
	var pt: Dictionary = PlantData.TYPES[plant_idx]
	var unlocked := GameState.is_plant_unlocked(plant_idx)

	var frame := Panel.new()
	frame.size = Vector2(PLANT_NODE_SIZE, PLANT_NODE_SIZE)
	frame.position = Vector2(x - PLANT_NODE_SIZE / 2.0, NODE_Y - PLANT_NODE_SIZE / 2.0)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.55, 0.8, 0.4) if unlocked else Color(0.35, 0.35, 0.35)
	sb.corner_radius_top_left = int(PLANT_NODE_SIZE / 2.0)
	sb.corner_radius_top_right = int(PLANT_NODE_SIZE / 2.0)
	sb.corner_radius_bottom_left = int(PLANT_NODE_SIZE / 2.0)
	sb.corner_radius_bottom_right = int(PLANT_NODE_SIZE / 2.0)
	frame.add_theme_stylebox_override("panel", sb)
	path_layer.add_child(frame)

	var icon := TextureRect.new()
	icon.texture = load(pt["texture"])
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size = Vector2(PLANT_NODE_SIZE - 14, PLANT_NODE_SIZE - 14)
	icon.position = Vector2(7, 7)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not unlocked:
		icon.modulate = Color(0.15, 0.15, 0.15)
	frame.add_child(icon)

	var name_label := Label.new()
	name_label.text = pt["name"]
	name_label.position = Vector2(x - 60, NODE_Y + PLANT_NODE_SIZE / 2.0 + 4)
	name_label.size = Vector2(120, 26)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 13)
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	path_layer.add_child(name_label)

# --- Strzalki na krawedziach: widoczne tylko gdy w dana strone jest jeszcze
# cos do zobaczenia; tap przesuwa sciezke o szerokosc ekranu. ---
func _build_arrows() -> void:
	arrow_left = Button.new()
	arrow_left.text = "<"
	arrow_left.size = Vector2(56, 70)
	arrow_left.position = Vector2(6, NODE_Y - 35)
	arrow_left.add_theme_font_size_override("font_size", 30)
	arrow_left.modulate = Color(1, 1, 1, 0.6)
	arrow_left.focus_mode = Control.FOCUS_NONE
	arrow_left.pressed.connect(func(): _shift_offset(VIEWPORT_WIDTH))
	add_child(arrow_left)

	arrow_right = Button.new()
	arrow_right.text = ">"
	arrow_right.size = Vector2(56, 70)
	arrow_right.position = Vector2(VIEWPORT_WIDTH - 62, NODE_Y - 35)
	arrow_right.add_theme_font_size_override("font_size", 30)
	arrow_right.modulate = Color(1, 1, 1, 0.6)
	arrow_right.focus_mode = Control.FOCUS_NONE
	arrow_right.pressed.connect(func(): _shift_offset(-VIEWPORT_WIDTH))
	add_child(arrow_right)

func _shift_offset(delta: float) -> void:
	var target: float = clamp(path_layer.position.x + delta, min_offset, max_offset)
	var tw := create_tween()
	tw.tween_property(path_layer, "position:x", target, 0.35).set_trans(Tween.TRANS_SINE)
	tw.finished.connect(_update_arrow_visibility)

func _update_arrow_visibility() -> void:
	if arrow_left:
		arrow_left.visible = path_layer.position.x < max_offset - 1.0
	if arrow_right:
		arrow_right.visible = path_layer.position.x > min_offset + 1.0

# --- Aktualny poziom: najwyzszy odblokowany, jeszcze nieukonczony. ---
func _current_level_index() -> int:
	var last_unlocked := 0
	for i in range(LevelData.LEVELS.size()):
		if GameState.is_level_unlocked(i):
			last_unlocked = i
			if not GameState.is_level_completed(i):
				return i
	return last_unlocked

# --- Przesuwanie sciezki palcem/mysza + tap-vs-drag. Obsluzone w _input(),
# nie w _gui_input() na przyciskach, zeby jeden spojny mechanizm dzialal i
# nad wezlami, i nad tlem, niezaleznie od tego, co akurat jest pod kursorem. ---
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_start_drag()
			else:
				_end_drag(event.position)
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			path_layer.position.x = clamp(path_layer.position.x + 80.0, min_offset, max_offset)
			_update_arrow_visibility()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			path_layer.position.x = clamp(path_layer.position.x - 80.0, min_offset, max_offset)
			_update_arrow_visibility()
	elif event is InputEventMouseMotion:
		if pointer_down:
			_drag_move(event.relative.x)
	elif event is InputEventScreenTouch:
		if event.pressed:
			_start_drag()
		else:
			_end_drag(event.position)
	elif event is InputEventScreenDrag:
		_drag_move(event.relative.x)

func _start_drag() -> void:
	pointer_down = true
	drag_total = 0.0

func _drag_move(dx: float) -> void:
	if not pointer_down:
		return
	path_layer.position.x = clamp(path_layer.position.x + dx, min_offset, max_offset)
	drag_total += abs(dx)
	_update_arrow_visibility()

func _end_drag(pos: Vector2) -> void:
	if not pointer_down:
		return
	pointer_down = false
	if drag_total <= DRAG_THRESHOLD:
		_handle_tap(pos)

func _handle_tap(pos: Vector2) -> void:
	var local_x: float = pos.x - path_layer.position.x
	for node in level_hit_nodes:
		var rect: Rect2 = node["rect"]
		if rect.has_point(Vector2(local_x, pos.y)):
			if node["unlocked"]:
				GameState.current_level_index = node["level_idx"]
				get_tree().change_scene_to_file("res://scenes/PlantSelect.tscn")
			return
