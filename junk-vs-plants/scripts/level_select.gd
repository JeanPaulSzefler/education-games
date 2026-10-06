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

# Ikonki w rogach ekranu (notatki 2026-10-06): opis gry (lewy gorny), sklep
# i rubiny (prawy gorny), moje roslinki (lewy dolny), gracz (prawy dolny).
const CORNER_BTN_SIZE := 80.0
const CORNER_MARGIN := 20.0
const CLAIMABLE_PLANT_COLOR := Color(0.95, 0.8, 0.2)
const POPUP_BG_COLOR := Color(0.95, 0.93, 0.85)
const POPUP_TEXT_COLOR := Color(0.15, 0.12, 0.1)
const CORNER_BTN_COLOR := Color(0.3, 0.45, 0.25)
const OK_BTN_COLOR := Color(0.25, 0.6, 0.25)
const SELECTED_ICON_BORDER := Color(0.95, 0.75, 0.1)
const DELETE_BTN_COLOR := Color(0.75, 0.18, 0.15)
# Ikonka "Moich roslinek" - Lisc Bananowca (indeks w PlantData.TYPES).
const MY_PLANTS_ICON_PLANT := 2
const GAME_RULES_TEXT := "Smieciostwory ida przez ogrod do domu - nie pozwol im dojsc! " + \
	"Wybierz roslinke z paska po lewej i tapnij pole ogrodu, zeby ja posadzic. " + \
	"Sadzenie kosztuje krople wody: daja je Kaktusy, a krople zbierasz tapnieciem. " + \
	"Za kazdy wygrany poziom dostajesz rubin (raz na poziom). " + \
	"Po niektorych poziomach na sciezce czeka nowa roslinka - wejdz w jej kolko, zeby ja odblokowac."
const SHOP_OFFERS := [
	{"rubies": 2, "price": "Reklama"},
	{"rubies": 10, "price": "5 zl"},
	{"rubies": 20, "price": "9 zl"},
	{"rubies": 50, "price": "20 zl"},
	{"rubies": 100, "price": "39 zl"},
]

var path_layer: Control
var arrow_left: Button
var arrow_right: Button
# Otwarte okienko (opis gry, sklep, ...) - dopoki jest, sciezka nie reaguje
# na przesuwanie i tapniecia.
var popup: Control

# node_sequence[i] = {"kind": "level", "level_idx": int} albo {"kind": "plant", "plant_idx": int}
var node_sequence: Array = []
var node_x_positions: Array = []
var level_seq_index: Dictionary = {}

# Do testowania tapniecia: lista {"level_idx", "rect" (Rect2 w ukladzie path_layer), "unlocked"}
var level_hit_nodes: Array = []
# Kolka roslin, w ktore mozna teraz "wejsc": lista {"plant_idx", "rect"}
var plant_hit_nodes: Array = []

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
	title.position = Vector2(0, 24)
	title.size = Vector2(VIEWPORT_WIDTH, 56)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
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
	_build_corner_buttons()

	var x_last: float = node_x_positions[node_x_positions.size() - 1]
	min_offset = (VIEWPORT_WIDTH - MARGIN) - x_last
	max_offset = 0.0

	var x_current: float = node_x_positions[_current_seq_index()]
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
	var p_idx: int = entry["plant_idx"]
	return not (GameState.is_plant_unlocked(p_idx) or GameState.is_plant_claimable(p_idx))

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
	plant_hit_nodes.clear()
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
	var endless := GameState.is_endless_level(level_idx)
	btn.text = "∞" if endless else str(level_idx + 1)
	btn.add_theme_font_size_override("font_size", 36)
	btn.disabled = not unlocked
	btn.focus_mode = Control.FOCUS_NONE
	# Klikanie obslugujemy sami w _handle_tap() (zeby odroznic tap od
	# przesuwania sciezki), wiec przycisk ma nie reagowac na input.
	btn.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var color: Color
	if endless and unlocked:
		color = Color(0.55, 0.3, 0.75)
	elif completed:
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

	if endless and GameState.endless_best > 0:
		var best_label := Label.new()
		best_label.text = "Rekord: %d" % GameState.endless_best
		best_label.position = Vector2(x - 70, NODE_Y + LEVEL_NODE_SIZE / 2.0 + 28)
		best_label.size = Vector2(140, 26)
		best_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		best_label.add_theme_font_size_override("font_size", 14)
		best_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
		best_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		path_layer.add_child(best_label)

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
	# Poziom przed roslina ukonczony, ale gracz jeszcze w nia nie "wszedl" -
	# kolko pulsuje na zloto i czeka na tapniecie (jak poziom do zagrania).
	var claimable := GameState.is_plant_claimable(plant_idx)

	var frame := Panel.new()
	frame.size = Vector2(PLANT_NODE_SIZE, PLANT_NODE_SIZE)
	frame.position = Vector2(x - PLANT_NODE_SIZE / 2.0, NODE_Y - PLANT_NODE_SIZE / 2.0)
	frame.pivot_offset = Vector2(PLANT_NODE_SIZE / 2.0, PLANT_NODE_SIZE / 2.0)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var sb := StyleBoxFlat.new()
	if unlocked:
		sb.bg_color = Color(0.55, 0.8, 0.4)
	elif claimable:
		sb.bg_color = CLAIMABLE_PLANT_COLOR
	else:
		sb.bg_color = Color(0.35, 0.35, 0.35)
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

	if claimable:
		var tw := frame.create_tween()
		tw.set_loops()
		tw.tween_property(frame, "scale", Vector2(1.15, 1.15), 0.5).set_trans(Tween.TRANS_SINE)
		tw.tween_property(frame, "scale", Vector2(1.0, 1.0), 0.5).set_trans(Tween.TRANS_SINE)
		plant_hit_nodes.append({
			"plant_idx": plant_idx,
			"rect": Rect2(x - PLANT_NODE_SIZE / 2.0, NODE_Y - PLANT_NODE_SIZE / 2.0, PLANT_NODE_SIZE, PLANT_NODE_SIZE),
		})

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

# --- Na starcie sciezka centruje sie na kolku rosliny do odebrania, a jesli
# takiego nie ma - na aktualnym poziomie. ---
func _current_seq_index() -> int:
	for i in range(node_sequence.size()):
		var entry = node_sequence[i]
		if entry["kind"] == "plant" and GameState.is_plant_claimable(entry["plant_idx"]):
			return i
	return level_seq_index[_current_level_index()]

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
	if popup != null:
		pointer_down = false
		return
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
	for node in plant_hit_nodes:
		var rect: Rect2 = node["rect"]
		if rect.has_point(Vector2(local_x, pos.y)):
			_show_plant_unlock(node["plant_idx"])
			return
	for node in level_hit_nodes:
		var rect: Rect2 = node["rect"]
		if rect.has_point(Vector2(local_x, pos.y)):
			if node["unlocked"]:
				GameState.current_level_index = node["level_idx"]
				get_tree().change_scene_to_file("res://scenes/PlantSelect.tscn")
			return

# --- Ikonki w rogach ekranu ---
func _build_corner_buttons() -> void:
	var book_btn := _make_corner_button(Vector2(CORNER_MARGIN, CORNER_MARGIN), "Opis gry")
	_add_centered_icon(book_btn, UiIcons.book(CORNER_BTN_SIZE - 16))
	book_btn.pressed.connect(_show_game_info)

	var shop_x := VIEWPORT_WIDTH - CORNER_MARGIN - CORNER_BTN_SIZE
	var shop_btn := _make_corner_button(Vector2(shop_x, CORNER_MARGIN), "Sklep")
	_add_centered_icon(shop_btn, UiIcons.shop(CORNER_BTN_SIZE - 16))
	shop_btn.pressed.connect(_show_shop)

	# Liczba rubinow gracza - na lewo od sklepu.
	var ruby_icon := UiIcons.ruby(40)
	ruby_icon.position = Vector2(shop_x - 52, CORNER_MARGIN + (CORNER_BTN_SIZE - 40) / 2.0)
	add_child(ruby_icon)
	var ruby_label := Label.new()
	ruby_label.text = str(GameState.rubies)
	ruby_label.position = Vector2(shop_x - 52 - 110, CORNER_MARGIN + (CORNER_BTN_SIZE - 44) / 2.0)
	ruby_label.size = Vector2(100, 44)
	ruby_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ruby_label.add_theme_font_size_override("font_size", 32)
	ruby_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ruby_label)

	var bottom_y := VIEWPORT_HEIGHT - CORNER_MARGIN - CORNER_BTN_SIZE - 22
	var plants_btn := _make_corner_button(Vector2(CORNER_MARGIN, bottom_y), "Moje roslinki")
	_add_centered_icon(plants_btn, UiIcons.plant_icon(MY_PLANTS_ICON_PLANT, CORNER_BTN_SIZE - 16))
	plants_btn.pressed.connect(_show_my_plants)

	_build_player_badge(bottom_y)

func _make_corner_button(pos: Vector2, caption: String) -> Button:
	var btn := Button.new()
	btn.position = pos
	btn.size = Vector2(CORNER_BTN_SIZE, CORNER_BTN_SIZE)
	btn.focus_mode = Control.FOCUS_NONE
	UiIcons.style_button(btn, CORNER_BTN_COLOR, int(CORNER_BTN_SIZE / 2.0))
	add_child(btn)

	var label := Label.new()
	label.text = caption
	label.position = Vector2(pos.x - 30, pos.y + CORNER_BTN_SIZE + 2)
	label.size = Vector2(CORNER_BTN_SIZE + 60, 22)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 15)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	return btn

func _add_centered_icon(btn: Button, icon: Control) -> void:
	icon.position = (btn.size - icon.size) / 2.0
	btn.add_child(icon)

# Plakietka gracza: nazwa + ikona; tapniecie otwiera zmiane nazwy i ikony.
func _build_player_badge(y: float) -> void:
	var badge := Button.new()
	badge.size = Vector2(260, CORNER_BTN_SIZE)
	badge.position = Vector2(VIEWPORT_WIDTH - CORNER_MARGIN - badge.size.x, y)
	badge.focus_mode = Control.FOCUS_NONE
	UiIcons.style_button(badge, CORNER_BTN_COLOR, 18)
	badge.pressed.connect(_show_player_edit)
	add_child(badge)

	var name_label := Label.new()
	name_label.text = GameState.player_name
	name_label.position = Vector2(16, 0)
	name_label.size = Vector2(badge.size.x - CORNER_BTN_SIZE - 16, badge.size.y)
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.clip_text = true
	name_label.add_theme_font_size_override("font_size", 26)
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.add_child(name_label)

	var icon := UiIcons.plant_icon(GameState.player_icon, CORNER_BTN_SIZE - 16)
	icon.position = Vector2(badge.size.x - CORNER_BTN_SIZE + 8, 8)
	badge.add_child(icon)

	var caption := Label.new()
	caption.text = "Gracz"
	caption.position = Vector2(badge.position.x, y + CORNER_BTN_SIZE + 2)
	caption.size = Vector2(badge.size.x, 22)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.add_theme_font_size_override("font_size", 15)
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(caption)

# --- Okienka ---
# Przyciemnione tlo i jasny panel na srodku ekranu; zwraca panel. Gdy
# closable, okienko zamyka "X" w rogu albo tapniecie w tlo poza panelem.
func _open_popup(panel_size: Vector2, title_text: String, closable := true) -> Panel:
	_close_popup()
	popup = Control.new()
	popup.position = Vector2(0, 0)
	popup.size = Vector2(VIEWPORT_WIDTH, VIEWPORT_HEIGHT)
	add_child(popup)

	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.6)
	shade.size = popup.size
	if closable:
		shade.gui_input.connect(func(event: InputEvent):
			if event is InputEventMouseButton and event.pressed:
				_close_popup())
	popup.add_child(shade)

	var panel := Panel.new()
	panel.size = panel_size
	panel.position = (popup.size - panel_size) / 2.0
	var sb := StyleBoxFlat.new()
	sb.bg_color = POPUP_BG_COLOR
	sb.set_border_width_all(5)
	sb.border_color = Color(0.25, 0.2, 0.15)
	sb.set_corner_radius_all(18)
	panel.add_theme_stylebox_override("panel", sb)
	popup.add_child(panel)

	if title_text != "":
		var title := _popup_label(title_text, 32)
		title.position = Vector2(0, 14)
		title.size = Vector2(panel_size.x, 44)
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		panel.add_child(title)

	if closable:
		var close_btn := Button.new()
		close_btn.text = "X"
		close_btn.size = Vector2(52, 52)
		close_btn.position = Vector2(panel_size.x - 62, 10)
		close_btn.focus_mode = Control.FOCUS_NONE
		close_btn.add_theme_font_size_override("font_size", 26)
		close_btn.pressed.connect(_close_popup)
		panel.add_child(close_btn)
	return panel

func _close_popup() -> void:
	if popup != null:
		popup.queue_free()
		popup = null

func _popup_label(text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", POPUP_TEXT_COLOR)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func _popup_button(text: String, color: Color, pos: Vector2, btn_size: Vector2) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.position = pos
	btn.size = btn_size
	btn.focus_mode = Control.FOCUS_NONE
	btn.add_theme_font_size_override("font_size", 24)
	UiIcons.style_button(btn, color, 16)
	return btn

func _plant_summary(plant_idx: int) -> String:
	var pt: Dictionary = PlantData.TYPES[plant_idx]
	return "%s (%d kropli): %s" % [pt["name"], pt["cost"], pt.get("description", "")]

# "Wejscie" w kolko rosliny: duza ikona, "Odblokowujesz: ..." i opis. Roslina
# odblokowuje sie (i otwiera sie nastepny poziom) po tapnieciu "Super!" -
# okienko nie ma "X", zeby nie dalo sie go zamknac bez odebrania rosliny.
func _show_plant_unlock(plant_idx: int) -> void:
	var pt: Dictionary = PlantData.TYPES[plant_idx]
	var panel := _open_popup(Vector2(640, 560), "", false)

	var header := _popup_label("Odblokowujesz:", 26)
	header.position = Vector2(0, 18)
	header.size = Vector2(panel.size.x, 36)
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(header)

	var name_label := _popup_label(pt["name"], 40)
	name_label.position = Vector2(0, 54)
	name_label.size = Vector2(panel.size.x, 52)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_color_override("font_color", Color(0.2, 0.5, 0.15))
	panel.add_child(name_label)

	var icon := UiIcons.plant_icon(plant_idx, 230)
	icon.position = Vector2((panel.size.x - 230) / 2.0, 112)
	icon.pivot_offset = Vector2(115, 115)
	icon.scale = Vector2(0.05, 0.05)
	panel.add_child(icon)
	var tw := icon.create_tween()
	tw.tween_property(icon, "scale", Vector2(1, 1), 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	var desc := _popup_label(pt.get("description", ""), 22)
	desc.position = Vector2(40, 352)
	desc.size = Vector2(panel.size.x - 80, 90)
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(desc)

	var ok_btn := _popup_button("Super!", OK_BTN_COLOR, Vector2((panel.size.x - 220) / 2.0, 462), Vector2(220, 70))
	ok_btn.pressed.connect(func():
		GameState.claim_plant(plant_idx)
		get_tree().reload_current_scene())
	panel.add_child(ok_btn)

# "Opis gry": krotkie zasady + funkcje roslin, ktore gracz juz odblokowal.
func _show_game_info() -> void:
	var panel := _open_popup(Vector2(900, 600), "Opis gry")
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(30, 70)
	scroll.size = Vector2(panel.size.x - 60, panel.size.y - 90)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)

	var row_width := scroll.size.x - 20
	var list := VBoxContainer.new()
	list.custom_minimum_size = Vector2(row_width, 0)
	list.add_theme_constant_override("separation", 10)
	scroll.add_child(list)

	var rules := _popup_label(GAME_RULES_TEXT, 20)
	rules.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rules.custom_minimum_size = Vector2(row_width, 0)
	list.add_child(rules)

	list.add_child(_popup_label("Twoje roslinki:", 24))

	var unlocked := GameState.unlocked_plant_indices()
	for p_idx in unlocked:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 14)
		row.add_child(UiIcons.plant_icon(p_idx, 64))
		var text := _popup_label(_plant_summary(p_idx), 19)
		text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text.custom_minimum_size = Vector2(row_width - 80, 0)
		text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(text)
		list.add_child(row)

	var locked_count := PlantData.TYPES.size() - unlocked.size()
	if locked_count > 0:
		var more := _popup_label("Kolejne roslinki (%d) pojawia sie tutaj, kiedy je odblokujesz." % locked_count, 18)
		more.add_theme_color_override("font_color", Color(0.4, 0.38, 0.35))
		list.add_child(more)

# "Moje roslinki": wszystkie rosliny - odblokowane w kolorze, reszta jako
# cien ze znakiem zapytania. Tapniecie odblokowanej pokazuje jej opis.
func _show_my_plants() -> void:
	var panel := _open_popup(Vector2(1000, 620), "Moje roslinki")
	var per_row := 7
	var cell := 116.0
	var gap := 14.0
	var start_x := (panel.size.x - (per_row * cell + (per_row - 1) * gap)) / 2.0

	var desc := _popup_label("Tapnij roslinke, zeby zobaczyc, co robi.", 20)
	desc.position = Vector2(40, 500)
	desc.size = Vector2(panel.size.x - 80, 100)
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(desc)

	for p_idx in range(PlantData.TYPES.size()):
		var unlocked := GameState.is_plant_unlocked(p_idx)
		var btn := Button.new()
		btn.position = Vector2(start_x + (p_idx % per_row) * (cell + gap), 80 + int(p_idx / float(per_row)) * (cell + 80))
		btn.size = Vector2(cell, cell)
		btn.focus_mode = Control.FOCUS_NONE
		UiIcons.style_button(btn, Color(0.55, 0.8, 0.4) if unlocked else Color(0.55, 0.55, 0.55), 16)
		btn.disabled = not unlocked
		var icon := UiIcons.plant_icon(p_idx, cell - 16)
		icon.position = Vector2(8, 8)
		if not unlocked:
			icon.modulate = Color(0.15, 0.15, 0.15)
		btn.add_child(icon)
		btn.pressed.connect(func(): desc.text = _plant_summary(p_idx))
		panel.add_child(btn)

		var name_label := _popup_label(PlantData.TYPES[p_idx]["name"] if unlocked else "?", 15)
		name_label.position = Vector2(btn.position.x - 10, btn.position.y + cell + 2)
		name_label.size = Vector2(cell + 20, 22)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		panel.add_child(name_label)

# Sklep: oferty rubinow z notatek 2026-10-06. Zakupy za pieniadze i reklamy
# wymagaja uslug Google Play (platnosci, AdMob), wiec na razie to tylko
# podglad ofert z nieaktywnymi przyciskami.
func _show_shop() -> void:
	var panel := _open_popup(Vector2(960, 480), "Sklep")
	var card_size := Vector2(160, 220)
	var gap := 22.0
	var start_x := (panel.size.x - (SHOP_OFFERS.size() * card_size.x + (SHOP_OFFERS.size() - 1) * gap)) / 2.0

	for i in range(SHOP_OFFERS.size()):
		var offer: Dictionary = SHOP_OFFERS[i]
		var card := Panel.new()
		card.position = Vector2(start_x + i * (card_size.x + gap), 100)
		card.size = card_size
		card.add_theme_stylebox_override("panel", UiIcons.round_style(Color(1.0, 0.98, 0.92), 14))
		panel.add_child(card)

		var amount := _popup_label(str(offer["rubies"]), 34)
		amount.position = Vector2(10, 30)
		amount.size = Vector2(76, 50)
		amount.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		card.add_child(amount)
		var ruby := UiIcons.ruby(48)
		ruby.position = Vector2(94, 32)
		card.add_child(ruby)

		var price: String = offer["price"]
		var price_btn := _popup_button(price, Color(0.3, 0.5, 0.75), Vector2(14, card_size.y - 84), Vector2(card_size.x - 28, 64))
		price_btn.add_theme_font_size_override("font_size", 24 if price.length() < 7 else 19)
		price_btn.disabled = true
		card.add_child(price_btn)

	var info := _popup_label("Sklep jeszcze nie dziala - zakupy i reklamy dodamy pozniej.", 20)
	info.position = Vector2(0, 360)
	info.size = Vector2(panel.size.x, 60)
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.add_theme_color_override("font_color", Color(0.5, 0.3, 0.2))
	panel.add_child(info)

# Zmiana nazwy i ikony gracza (do wyboru odblokowane rosliny).
func _show_player_edit() -> void:
	var panel := _open_popup(Vector2(760, 470), "Gracz")
	var chosen := {"icon": GameState.player_icon}

	var name_caption := _popup_label("Nazwa:", 22)
	name_caption.position = Vector2(40, 86)
	panel.add_child(name_caption)

	var name_edit := LineEdit.new()
	name_edit.text = GameState.player_name
	name_edit.max_length = GameState.PLAYER_NAME_MAX_LENGTH
	name_edit.position = Vector2(150, 76)
	name_edit.size = Vector2(400, 52)
	name_edit.add_theme_font_size_override("font_size", 24)
	panel.add_child(name_edit)

	var icon_caption := _popup_label("Ikona:", 22)
	icon_caption.position = Vector2(40, 182)
	panel.add_child(icon_caption)

	var icons_box := HFlowContainer.new()
	icons_box.position = Vector2(150, 170)
	icons_box.size = Vector2(panel.size.x - 190, 180)
	icons_box.add_theme_constant_override("h_separation", 10)
	icons_box.add_theme_constant_override("v_separation", 10)
	panel.add_child(icons_box)

	# p_idx -> StyleBoxFlat, zeby po wyborze przelaczyc zlota ramke.
	var icon_styles := {}
	for p_idx in GameState.unlocked_plant_indices():
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(80, 80)
		btn.focus_mode = Control.FOCUS_NONE
		var sb := UiIcons.round_style(Color(0.55, 0.8, 0.4), 14)
		sb.set_border_width_all(5)
		sb.border_color = SELECTED_ICON_BORDER if p_idx == chosen["icon"] else sb.bg_color
		for state in ["normal", "hover", "pressed"]:
			btn.add_theme_stylebox_override(state, sb)
		icon_styles[p_idx] = sb
		var icon := UiIcons.plant_icon(p_idx, 64)
		icon.position = Vector2(8, 8)
		btn.add_child(icon)
		icons_box.add_child(btn)
		btn.pressed.connect(func():
			chosen["icon"] = p_idx
			for key in icon_styles.keys():
				icon_styles[key].border_color = SELECTED_ICON_BORDER if key == p_idx else icon_styles[key].bg_color)

	var error_label := _popup_label("", 18)
	error_label.position = Vector2(150, 130)
	error_label.add_theme_color_override("font_color", Color(0.75, 0.2, 0.15))
	panel.add_child(error_label)

	# Powrot do ekranu wyboru konta (konta sa lokalne, bez hasla).
	var switch_btn := _popup_button("Zmien konto", CORNER_BTN_COLOR, Vector2(40, panel.size.y - 96), Vector2(220, 70))
	switch_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/ProfileSelect.tscn"))
	panel.add_child(switch_btn)

	var delete_btn := _popup_button("Usun konto", DELETE_BTN_COLOR, Vector2(270, panel.size.y - 96), Vector2(220, 70))
	delete_btn.pressed.connect(_show_delete_confirm)
	panel.add_child(delete_btn)

	var save_btn := _popup_button("Zapisz", OK_BTN_COLOR, Vector2(panel.size.x - 260, panel.size.y - 96), Vector2(220, 70))
	save_btn.pressed.connect(func():
		if GameState.set_player(name_edit.text, chosen["icon"]):
			get_tree().reload_current_scene()
		else:
			error_label.text = "Konto o tej nazwie juz istnieje.")
	panel.add_child(save_btn)

# "Czy na pewno?" przed usunieciem wybranego konta - postep znika na zawsze.
func _show_delete_confirm() -> void:
	var panel := _open_popup(Vector2(620, 320), "Usunac konto \"%s\"?" % GameState.player_name)

	var warning := _popup_label("Caly postep tego konta (poziomy, rubiny, roslinki) zniknie na zawsze.", 20)
	warning.position = Vector2(40, 80)
	warning.size = Vector2(panel.size.x - 80, 80)
	warning.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	warning.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(warning)

	var keep_btn := _popup_button("ZOSTAW", OK_BTN_COLOR, Vector2(70, panel.size.y - 106), Vector2(210, 70))
	keep_btn.pressed.connect(_show_player_edit)
	panel.add_child(keep_btn)

	var delete_btn := _popup_button("USUN", DELETE_BTN_COLOR, Vector2(panel.size.x - 280, panel.size.y - 106), Vector2(210, 70))
	delete_btn.pressed.connect(func():
		GameState.delete_profile(GameState.current_profile_id)
		get_tree().change_scene_to_file("res://scenes/ProfileSelect.tscn"))
	panel.add_child(delete_btn)
