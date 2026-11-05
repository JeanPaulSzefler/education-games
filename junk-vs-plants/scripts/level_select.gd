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
const GREETING_SECONDS := 5.0
const DELETE_BTN_COLOR := Color(0.75, 0.18, 0.15)
const MOVES_BADGE_COLOR := Color(0.85, 0.3, 0.2)
# Ikonka "Moich roslinek" - Lisc Bananowca (indeks w PlantData.TYPES).
const MY_PLANTS_ICON_PLANT := 2
const LOCKED_BTN_COLOR := Color(0.35, 0.35, 0.35)
const NEW_SECTION_COLOR := Color(0.75, 0.35, 0.1)
const SHOP_OFFERS := [
	{"rubies": 2, "price": "", "ad": true},
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
# Skrzynie, ktore mozna teraz otworzyc: lista {"chest_level", "rect"}
var chest_hit_nodes: Array = []
var ruby_label: Label
var coin_label: Label
# Przyciski funkcji wedlug nazwy celu przewodnika (GuideData) i jego strzalka.
var feature_buttons := {}
var guide_arrow: Control
var guide_tween: Tween

var min_offset := 0.0
var max_offset := 0.0

var pointer_down := false
var drag_total := 0.0

func _ready() -> void:
	GameState.clear_event_game()
	add_child(UiIcons.screen_background("menu"))

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
	_update_guide_arrow()

	# Np. znajomy wyszedl z gry zespolowej, zanim sie zaczela.
	if NetSession.notice != "":
		_show_net_notice()

# --- Budowa sekwencji wezlow: P1, P2, [Lisc], P3, P4, [Mroz], ... ---
func _build_node_sequence() -> void:
	var plants_by_level := {}
	for p_idx in range(PlantData.TYPES.size()):
		var unlock_level: int = PlantData.TYPES[p_idx].get("unlock_level", 1)
		if unlock_level > 1:
			if not plants_by_level.has(unlock_level):
				plants_by_level[unlock_level] = []
			plants_by_level[unlock_level].append(p_idx)

	var chests := GameState.chest_levels()
	node_sequence.clear()
	for i in range(LevelData.LEVELS.size()):
		var level_num := i + 1
		if chests.has(level_num):
			node_sequence.append({"kind": "chest", "chest_level": level_num})
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
	if entry["kind"] == "chest":
		return not GameState.is_level_completed(entry["chest_level"] - 2)
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
	chest_hit_nodes.clear()
	for i in range(node_sequence.size()):
		var entry = node_sequence[i]
		var x: float = node_x_positions[i]
		if entry["kind"] == "level":
			_build_level_node(entry["level_idx"], x)
		elif entry["kind"] == "chest":
			_build_chest_node(entry["chest_level"], x)
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
	name_label.text = LevelData.place_name(level)
	name_label.position = Vector2(x - 70, NODE_Y + LEVEL_NODE_SIZE / 2.0 + 4)
	name_label.size = Vector2(140, 30)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 13)
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	path_layer.add_child(name_label)

	if endless and GameState.endless_best > 0:
		var best_label := Label.new()
		best_label.text = Lang.f("record", [GameState.endless_best])
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
	name_label.text = PlantData.name_of(plant_idx)
	name_label.position = Vector2(x - 60, NODE_Y + PLANT_NODE_SIZE / 2.0 + 4)
	name_label.size = Vector2(120, 26)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 13)
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	path_layer.add_child(name_label)

# Skrzynia: zablokowana (szara), do otwarcia (pulsuje na zloto) albo otwarta
# (zielona). Nie blokuje sciezki, wiec mozna ja otworzyc takze pozniej.
func _build_chest_node(chest_level: int, x: float) -> void:
	var claimable := GameState.is_chest_claimable(chest_level)
	var opened: bool = GameState.opened_chests.has(chest_level)

	var frame := Panel.new()
	frame.size = Vector2(PLANT_NODE_SIZE, PLANT_NODE_SIZE)
	frame.position = Vector2(x - PLANT_NODE_SIZE / 2.0, NODE_Y - PLANT_NODE_SIZE / 2.0)
	frame.pivot_offset = Vector2(PLANT_NODE_SIZE / 2.0, PLANT_NODE_SIZE / 2.0)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var color := Color(0.35, 0.35, 0.35)
	if opened:
		color = Color(0.55, 0.8, 0.4)
	elif claimable:
		color = CLAIMABLE_PLANT_COLOR
	frame.add_theme_stylebox_override("panel", UiIcons.round_style(color, int(PLANT_NODE_SIZE / 2.0)))
	path_layer.add_child(frame)

	var icon := UiIcons.chest(PLANT_NODE_SIZE - 18)
	icon.position = Vector2(9, 9)
	if not claimable and not opened:
		icon.modulate = Color(0.5, 0.5, 0.5)
	frame.add_child(icon)

	if claimable:
		var tw := frame.create_tween()
		tw.set_loops()
		tw.tween_property(frame, "scale", Vector2(1.15, 1.15), 0.5).set_trans(Tween.TRANS_SINE)
		tw.tween_property(frame, "scale", Vector2(1.0, 1.0), 0.5).set_trans(Tween.TRANS_SINE)
		chest_hit_nodes.append({
			"chest_level": chest_level,
			"rect": Rect2(x - PLANT_NODE_SIZE / 2.0, NODE_Y - PLANT_NODE_SIZE / 2.0, PLANT_NODE_SIZE, PLANT_NODE_SIZE),
		})

	var name_label := Label.new()
	name_label.text = Lang.t("chest")
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

# --- Na starcie sciezka centruje sie na kolku rosliny albo skrzyni do odebrania,
# a jesli takiego nie ma - na aktualnym poziomie. ---
func _current_seq_index() -> int:
	for i in range(node_sequence.size()):
		var entry = node_sequence[i]
		if entry["kind"] == "plant" and GameState.is_plant_claimable(entry["plant_idx"]):
			return i
		if entry["kind"] == "chest" and GameState.is_chest_claimable(entry["chest_level"]):
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
	for node in chest_hit_nodes:
		var rect: Rect2 = node["rect"]
		if rect.has_point(Vector2(local_x, pos.y)):
			_show_chest(node["chest_level"])
			return
	for node in level_hit_nodes:
		var rect: Rect2 = node["rect"]
		if rect.has_point(Vector2(local_x, pos.y)):
			if node["unlocked"]:
				GameState.current_level_index = node["level_idx"]
				get_tree().change_scene_to_file("res://scenes/PlantSelect.tscn")
			return

# --- Ikonki na ekranie ---
# Gora: ustawienia, opis gry, Roslinne trojki; po prawej monety, rubiny i sklep.
# Dol: moje roslinki, ogrod, wydarzenie, dodatki, gry edukacyjne; po prawej gra z
# innym graczem nad plakietka gracza. Funkcje odblokowuja sie po kolei (GuideData).
func _build_corner_buttons() -> void:
	var gear_btn := _make_corner_button(Vector2(CORNER_MARGIN, CORNER_MARGIN), Lang.t("settings"))
	_add_centered_icon(gear_btn, UiIcons.gear(CORNER_BTN_SIZE - 20))
	gear_btn.pressed.connect(_show_settings)

	var info_btn := _feature_button("info", Vector2(CORNER_MARGIN + 130, CORNER_MARGIN), Lang.t("game_info"), UiIcons.book(CORNER_BTN_SIZE - 16))
	info_btn.pressed.connect(_show_game_info)

	# Roslinne trojki: wydarzenie stale, u gory ekranu, z liczba ruchow.
	var match_btn := _feature_button("match", Vector2(CORNER_MARGIN + 260, CORNER_MARGIN), Lang.t("plant_match"), UiIcons.match_event(CORNER_BTN_SIZE - 16))
	match_btn.pressed.connect(func(): _open_feature("match", "res://scenes/PlantMatch.tscn"))
	if not match_btn.disabled:
		_add_count_badge(match_btn, GameState.match_moves)

	var shop_x := VIEWPORT_WIDTH - CORNER_MARGIN - CORNER_BTN_SIZE
	var shop_btn := _feature_button("shop", Vector2(shop_x, CORNER_MARGIN), Lang.t("shop"), UiIcons.shop(CORNER_BTN_SIZE - 16))
	shop_btn.pressed.connect(func():
		GuideData.mark_target_seen("shop")
		_show_shop())

	# Liczba rubinow gracza - na lewo od sklepu.
	var ruby_icon := UiIcons.ruby(40)
	ruby_icon.position = Vector2(shop_x - 52, CORNER_MARGIN + (CORNER_BTN_SIZE - 40) / 2.0)
	add_child(ruby_icon)
	# Roslimonety - jeszcze dalej na lewo.
	var coin_icon := UiIcons.plant_coin(40)
	coin_icon.position = Vector2(shop_x - 190, CORNER_MARGIN + (CORNER_BTN_SIZE - 40) / 2.0)
	add_child(coin_icon)
	coin_label = _counter_label(str(GameState.plant_coins), Vector2(shop_x - 190 - 110, CORNER_MARGIN + (CORNER_BTN_SIZE - 44) / 2.0))
	ruby_label = _counter_label(str(GameState.rubies), Vector2(shop_x - 52 - 110, CORNER_MARGIN + (CORNER_BTN_SIZE - 44) / 2.0))

	var bottom_y := VIEWPORT_HEIGHT - CORNER_MARGIN - CORNER_BTN_SIZE - 22
	var plants_btn := _feature_button("my_plants", Vector2(CORNER_MARGIN, bottom_y), Lang.t("my_plants"), UiIcons.plant_icon(MY_PLANTS_ICON_PLANT, CORNER_BTN_SIZE - 16))
	plants_btn.pressed.connect(func():
		GuideData.mark_target_seen("my_plants")
		_show_my_plants())

	# Wydarzenia poza sciezka: ogrod, wydarzenie tygodnia, dodatki i gry edukacyjne.
	var x := 390.0
	var garden_btn := _feature_button("garden", Vector2(x, bottom_y), Lang.t("garden"), UiIcons.sapling(CORNER_BTN_SIZE - 16))
	garden_btn.pressed.connect(func(): _open_feature("garden", "res://scenes/Garden.tscn"))
	var event_btn := _feature_button("event", Vector2(x + 140, bottom_y), Lang.t("weekly_event"), UiIcons.star(CORNER_BTN_SIZE - 16))
	event_btn.pressed.connect(func(): _open_feature("event", "res://scenes/Events.tscn"))
	var addon_btn := _feature_button("addons", Vector2(x + 280, bottom_y), Lang.t("addons"), UiIcons.addon(CORNER_BTN_SIZE - 16))
	addon_btn.pressed.connect(func():
		GameState.rotation_view = AddonData.KIND_ADDON
		_open_feature("addons", "res://scenes/Rotation.tscn"))
	var edu_btn := _feature_button("education", Vector2(x + 420, bottom_y), Lang.t("edu_games"), UiIcons.education(CORNER_BTN_SIZE - 16))
	edu_btn.pressed.connect(func():
		GameState.rotation_view = AddonData.KIND_EDU
		_open_feature("education", "res://scenes/Rotation.tscn"))

	# Gra z innym graczem: nad plakietka gracza (notatki 2026-11-03).
	var mp_btn := _feature_button("multiplayer", Vector2(VIEWPORT_WIDTH - CORNER_MARGIN - CORNER_BTN_SIZE - 40, bottom_y - 112), Lang.t("multiplayer"), UiIcons.multiplayer_icon(CORNER_BTN_SIZE - 12))
	mp_btn.pressed.connect(func():
		NetSession.mode = NetSession.MODE_GAME
		_open_feature("multiplayer", "res://scenes/TeamPlay.tscn"))

	_build_player_badge(bottom_y)

	guide_arrow = UiIcons.guide_arrow(54)
	guide_arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	guide_arrow.visible = false
	add_child(guide_arrow)

func _counter_label(text: String, pos: Vector2) -> Label:
	var label := Label.new()
	label.text = text
	label.position = pos
	label.size = Vector2(100, 44)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	label.add_theme_font_size_override("font_size", 32)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	return label

# Przycisk funkcji: zablokowany (szary, z klodka i numerem poziomu), dopoki
# przewodnik jej nie odblokuje.
func _feature_button(target: String, pos: Vector2, caption: String, icon: Control) -> Button:
	var unlocked := GuideData.is_target_unlocked(target)
	var btn := _make_corner_button(pos, caption if unlocked else Lang.f("unlocks_after", [GuideData.step_for_target(target)["after"]]))
	_add_centered_icon(btn, icon)
	feature_buttons[target] = btn
	if not unlocked:
		btn.disabled = true
		icon.modulate = Color(0.3, 0.3, 0.3)
		UiIcons.style_button(btn, LOCKED_BTN_COLOR, int(CORNER_BTN_SIZE / 2.0))
		var lock := UiIcons.padlock(34)
		lock.position = Vector2(CORNER_BTN_SIZE - 30, CORNER_BTN_SIZE - 34)
		btn.add_child(lock)
	return btn

func _open_feature(target: String, scene: String) -> void:
	GuideData.mark_target_seen(target)
	get_tree().change_scene_to_file(scene)

func _add_count_badge(btn: Button, count: int) -> void:
	var badge := Label.new()
	badge.text = str(count)
	badge.size = Vector2(36, 36)
	badge.position = Vector2(CORNER_BTN_SIZE - 26, -10)
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge.add_theme_font_size_override("font_size", 18)
	badge.add_theme_stylebox_override("normal", UiIcons.round_style(MOVES_BADGE_COLOR, 18))
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(badge)

# Strzalka przewodnika nad przyciskiem kolejnej nowej funkcji (jedna naraz).
func _update_guide_arrow() -> void:
	if guide_arrow == null:
		return
	var step := GuideData.next_step()
	if step.is_empty() or not feature_buttons.has(step["target"]):
		guide_arrow.visible = false
		return
	var btn: Button = feature_buttons[step["target"]]
	var top := btn.position.y < VIEWPORT_HEIGHT / 2.0
	guide_arrow.visible = true
	guide_arrow.rotation = PI if top else 0.0
	guide_arrow.pivot_offset = guide_arrow.size / 2.0
	var base := btn.position + Vector2((CORNER_BTN_SIZE - guide_arrow.size.x) / 2.0, CORNER_BTN_SIZE + 26 if top else -guide_arrow.size.y - 6)
	guide_arrow.position = base
	if guide_tween != null:
		guide_tween.kill()
	guide_tween = guide_arrow.create_tween().set_loops()
	var tw := guide_tween
	var shift := Vector2(0, 10 if top else -10)
	tw.tween_property(guide_arrow, "position", base + shift, 0.45).set_trans(Tween.TRANS_SINE)
	tw.tween_property(guide_arrow, "position", base, 0.45).set_trans(Tween.TRANS_SINE)

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
	label.add_theme_color_override("font_outline_color", Color(0.05, 0.1, 0.05))
	label.add_theme_constant_override("outline_size", 4)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	return btn

func _add_centered_icon(btn: Button, icon: Control) -> void:
	icon.position = (btn.size - icon.size) / 2.0
	btn.add_child(icon)

# Plakietka gracza: nazwa + ikona; tapniecie otwiera zmiane nazwy i ikony. Pelny
# album naklejek daje zlota ramke.
func _build_player_badge(y: float) -> void:
	var badge := Button.new()
	badge.size = Vector2(260, CORNER_BTN_SIZE)
	badge.position = Vector2(VIEWPORT_WIDTH - CORNER_MARGIN - badge.size.x, y)
	badge.focus_mode = Control.FOCUS_NONE
	UiIcons.style_button(badge, CORNER_BTN_COLOR, 18)
	if GameState.album_frame:
		var sb := UiIcons.round_style(CORNER_BTN_COLOR, 18)
		sb.set_border_width_all(5)
		sb.border_color = Color(1.0, 0.8, 0.2)
		badge.add_theme_stylebox_override("normal", sb)
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
	caption.text = Lang.t("player")
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
	_update_guide_arrow()

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

# Lista w okienku z przewijaniem palcem. Wiersze i przyciski przepuszczaja
# przesuwanie do ScrollContainer (inaczej dalo sie przewijac tylko w szparach
# miedzy wierszami - blad z notatek 2026-11-03).
func _scroll_list(panel: Panel, pos: Vector2, size: Vector2, separation: int) -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.position = pos
	scroll.size = size
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.scroll_deadzone = 8
	panel.add_child(scroll)
	var list := VBoxContainer.new()
	list.custom_minimum_size = Vector2(size.x - 20, 0)
	list.add_theme_constant_override("separation", separation)
	list.mouse_filter = Control.MOUSE_FILTER_PASS
	scroll.add_child(list)
	return list

func _plant_summary(plant_idx: int) -> String:
	return Lang.f("plant_summary", [PlantData.name_of(plant_idx), PlantData.TYPES[plant_idx]["cost"], PlantData.description_of(plant_idx)])

# "Wejscie" w kolko rosliny: duza ikona, "Odblokowujesz: ..." i opis. Roslina
# odblokowuje sie (i otwiera sie nastepny poziom) po tapnieciu "Super!" -
# okienko nie ma "X", zeby nie dalo sie go zamknac bez odebrania rosliny.
func _show_plant_unlock(plant_idx: int) -> void:
	var panel := _open_popup(Vector2(640, 560), "", false)

	var header := _popup_label(Lang.t("you_unlock"), 26)
	header.position = Vector2(0, 18)
	header.size = Vector2(panel.size.x, 36)
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(header)

	var name_label := _popup_label(PlantData.name_of(plant_idx), 40)
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

	var desc := _popup_label(PlantData.description_of(plant_idx), 22)
	desc.position = Vector2(40, 352)
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiIcons.wrap_label(desc, Vector2(panel.size.x - 80, 90))
	panel.add_child(desc)

	var ok_btn := _popup_button(Lang.t("great"), OK_BTN_COLOR, Vector2((panel.size.x - 220) / 2.0, 462), Vector2(220, 70))
	ok_btn.pressed.connect(func():
		GameState.claim_plant(plant_idx)
		get_tree().reload_current_scene())
	panel.add_child(ok_btn)

# Skrzynia: nagroda jest losowana i zapisywana od razu po otwarciu, wiec zamkniecie
# gry w tym okienku nie pozwala losowac od nowa.
func _show_chest(chest_level: int) -> void:
	var reward := GameState.open_chest(chest_level)
	if reward.is_empty():
		return
	var panel := _open_popup(Vector2(640, 500), Lang.t("chest_title"), false)

	var icon := UiIcons.chest(170)
	icon.position = Vector2((panel.size.x - 170) / 2.0, 70)
	icon.pivot_offset = Vector2(85, 85)
	icon.scale = Vector2(0.05, 0.05)
	panel.add_child(icon)
	var tw := icon.create_tween()
	tw.tween_property(icon, "scale", Vector2(1, 1), 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	if reward["moves"] > 0:
		_add_reward_row(panel, 50.0, "+%d" % reward["rubies"], UiIcons.ruby(56))
		_add_reward_row(panel, 240.0, "+%d" % reward["coins"], UiIcons.plant_coin(56))
		_add_reward_row(panel, 430.0, "+%d" % reward["moves"], UiIcons.match_move(56))
	else:
		_add_reward_row(panel, 150.0, "+%d" % reward["rubies"], UiIcons.ruby(56))
		_add_reward_row(panel, 340.0, "+%d" % reward["coins"], UiIcons.plant_coin(56))

	var ok_btn := _popup_button(Lang.t("great"), OK_BTN_COLOR, Vector2((panel.size.x - 220) / 2.0, 400), Vector2(220, 70))
	ok_btn.pressed.connect(func(): get_tree().reload_current_scene())
	panel.add_child(ok_btn)

func _add_reward_row(panel: Panel, x: float, amount: String, icon: Control) -> void:
	var label := _popup_label(amount, 38)
	label.position = Vector2(x - 20, 290)
	label.size = Vector2(90, 56)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	panel.add_child(label)
	icon.position = Vector2(x + 76, 290)
	panel.add_child(icon)

# "Opis gry": rozdzialy przewodnika, ktore gracz juz odblokowal (najnowsze z
# napisem "Nowe!"), i funkcje jego roslin. Otwarcie oznacza rozdzialy jako obejrzane.
func _show_game_info() -> void:
	var panel := _open_popup(Vector2(900, 600), Lang.t("game_info"))
	var list := _scroll_list(panel, Vector2(30, 70), Vector2(panel.size.x - 60, panel.size.y - 90), 10)
	var row_width: float = list.custom_minimum_size.x

	for step in GuideData.unlocked_steps():
		var fresh := not GameState.is_guide_seen(step["id"])
		var heading := _popup_label(Lang.t("guide_" + step["id"]) + ("   " + Lang.t("new_label") if fresh else ""), 24)
		if fresh:
			heading.add_theme_color_override("font_color", NEW_SECTION_COLOR)
		list.add_child(heading)
		var text := _popup_label(Lang.t("guide_%s_text" % step["id"]), 19)
		text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text.custom_minimum_size = Vector2(row_width, 0)
		list.add_child(text)
	GuideData.mark_target_seen("info")

	list.add_child(_popup_label(Lang.t("your_plants"), 24))
	var unlocked := GameState.unlocked_plant_indices()
	for p_idx in PlantData.unlock_order():
		if not unlocked.has(p_idx):
			continue
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 14)
		row.mouse_filter = Control.MOUSE_FILTER_PASS
		row.add_child(UiIcons.plant_icon(p_idx, 64))
		var text := _popup_label(_plant_summary(p_idx), 19)
		text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text.custom_minimum_size = Vector2(row_width - 80, 0)
		text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(text)
		list.add_child(row)

	var locked_steps := GuideData.STEPS.size() - GuideData.unlocked_steps().size()
	if locked_steps > 0:
		var more := _popup_label(Lang.t("more_chapters_later"), 18)
		more.add_theme_color_override("font_color", Color(0.4, 0.38, 0.35))
		list.add_child(more)

# "Moje roslinki": wszystkie rosliny w kolejnosci odblokowywania - odblokowane
# w kolorze, reszta jako cien. Tapniecie rosliny pokazuje jej opis i ulepszenie;
# ulepszac mozna takze te, ktorych gracz jeszcze nie odblokowal.
func _show_my_plants(selected := -1) -> void:
	var panel := _open_popup(Vector2(1000, 620), Lang.t("my_plants"))
	var per_row := 7
	var cell := 116.0
	var gap := 14.0
	var start_x := (panel.size.x - (per_row * cell + (per_row - 1) * gap)) / 2.0

	var desc := _popup_label(Lang.t("my_plants_hint"), 20)
	if selected >= 0:
		desc.text = _plant_summary(selected)
		if not GameState.is_plant_unlocked(selected):
			desc.text += " " + Lang.f("unlock_at_level", [PlantData.TYPES[selected].get("unlock_level", 1)])
		_build_plant_upgrade(panel, selected)
	desc.position = Vector2(40, 442)
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiIcons.wrap_label(desc, Vector2(panel.size.x - 80, 76))
	panel.add_child(desc)

	var order := PlantData.unlock_order()
	for k in range(order.size()):
		var p_idx: int = order[k]
		var unlocked := GameState.is_plant_unlocked(p_idx)
		var btn := Button.new()
		btn.position = Vector2(start_x + (k % per_row) * (cell + gap), 80 + int(k / float(per_row)) * (cell + 80))
		btn.size = Vector2(cell, cell)
		btn.focus_mode = Control.FOCUS_NONE
		UiIcons.style_button(btn, Color(0.55, 0.8, 0.4) if unlocked else Color(0.55, 0.55, 0.55), 16)
		var icon := UiIcons.plant_icon(p_idx, cell - 16)
		icon.position = Vector2(8, 8)
		if not unlocked:
			icon.modulate = Color(0.15, 0.15, 0.15)
		btn.add_child(icon)
		btn.pressed.connect(func(): _show_my_plants(p_idx))
		panel.add_child(btn)

		var name_label := _popup_label(PlantData.name_of(p_idx), 15)
		name_label.position = Vector2(btn.position.x - 10, btn.position.y + cell + 2)
		name_label.size = Vector2(cell + 20, 22)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.clip_text = true
		panel.add_child(name_label)

		var level_bar := UiIcons.segment_bar(Vector2(cell, 14), GameState.plant_upgrade_level(p_idx), GameState.PLANT_UPGRADE_MAX_LEVEL)
		level_bar.position = Vector2(btn.position.x, btn.position.y + cell + 28)
		panel.add_child(level_bar)

# Poziom ulepszenia wybranej rosliny (pasek jak w Plants vs Zombies) i przycisk
# zakupu kolejnego.
func _build_plant_upgrade(panel: Panel, plant_idx: int) -> void:
	var level := GameState.plant_upgrade_level(plant_idx)
	var level_bar := UiIcons.segment_bar(Vector2(260, 28), level, GameState.PLANT_UPGRADE_MAX_LEVEL)
	level_bar.position = Vector2(40, 547)
	panel.add_child(level_bar)

	var effect := Lang.t("upgrade_" + PlantData.TYPES[plant_idx]["role"])
	var bonus := (GameState.plant_power(plant_idx) - 1.0) * 100.0
	var info := _popup_label(Lang.f("upgrade_info", [bonus, effect, GameState.rubies]), 20)
	info.position = Vector2(316, 526)
	UiIcons.wrap_label(info, Vector2(panel.size.x - 316 - 350, 70))
	info.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	panel.add_child(info)

	var price := GameState.plant_upgrade_price(plant_idx)
	var buy_text := Lang.t("maximum") if price < 0 else Lang.f("upgrade_buy", [price])
	var buy_btn := _popup_button(buy_text, OK_BTN_COLOR, Vector2(panel.size.x - 330, 526), Vector2(250, 70))
	buy_btn.disabled = price < 0 or GameState.rubies < price
	buy_btn.add_theme_font_size_override("font_size", 20)
	buy_btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	buy_btn.pressed.connect(func():
		if GameState.buy_plant_upgrade(plant_idx):
			ruby_label.text = str(GameState.rubies)
			_show_my_plants(plant_idx))
	panel.add_child(buy_btn)
	var ruby := UiIcons.ruby(40)
	ruby.position = Vector2(panel.size.x - 70, 541)
	panel.add_child(ruby)

# Oferta "za reklame": zamiast reklamy gra pokazuje napis, a potem daje nagrode.
func _on_ad_offer_pressed() -> void:
	_show_greeting(func():
		GameState.claim_ad_offer()
		ruby_label.text = str(GameState.rubies)
		_show_shop())

# Sklep: oferty rubinow z notatek 2026-10-06. Zakupy za pieniadze wymagaja uslug
# Google Play, wiec na razie to tylko podglad ofert z nieaktywnymi przyciskami.
# Ponizej lista wszystkiego, co mozna kupic za rubiny i roslimonety.
func _show_shop() -> void:
	var panel := _open_popup(Vector2(960, 640), Lang.t("shop"))
	var card_size := Vector2(160, 220)
	var gap := 22.0
	var start_x := (panel.size.x - (SHOP_OFFERS.size() * card_size.x + (SHOP_OFFERS.size() - 1) * gap)) / 2.0

	for i in range(SHOP_OFFERS.size()):
		var offer: Dictionary = SHOP_OFFERS[i]
		var card := Panel.new()
		card.position = Vector2(start_x + i * (card_size.x + gap), 70)
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

		var price: String = Lang.t("ad") if offer.get("ad", false) else offer["price"]
		var price_btn := _popup_button(price, Color(0.3, 0.5, 0.75), Vector2(14, card_size.y - 84), Vector2(card_size.x - 28, 64))
		price_btn.add_theme_font_size_override("font_size", 24 if price.length() < 7 else 19)
		price_btn.disabled = true
		if offer.get("ad", false):
			price_btn.disabled = not GameState.is_ad_offer_ready()
			if price_btn.disabled:
				price_btn.text = Lang.t("tomorrow")
			price_btn.pressed.connect(_on_ad_offer_pressed)
		card.add_child(price_btn)

	var info := _popup_label(Lang.f("shop_you_have", [GameState.rubies, GameState.plant_coins]), 20)
	info.position = Vector2(0, 294)
	info.size = Vector2(panel.size.x, 34)
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.add_theme_color_override("font_color", Color(0.5, 0.3, 0.2))
	panel.add_child(info)

	var list := _scroll_list(panel, Vector2(30, 334), Vector2(panel.size.x - 60, panel.size.y - 350), 8)
	_build_ruby_offers(list)
	_build_coin_offers(list)

# Wiersz listy zakupow: opis i przycisk z cena. Nieaktywny przycisk, gdy kupno
# nie jest teraz mozliwe; "on_buy" zwraca true po udanym zakupie.
func _add_shop_row(list: VBoxContainer, text: String, price_text: String, price_icon: Control, enabled: bool, on_buy: Callable) -> void:
	var row := Panel.new()
	row.custom_minimum_size = Vector2(list.custom_minimum_size.x, 66)
	row.mouse_filter = Control.MOUSE_FILTER_PASS
	row.add_theme_stylebox_override("panel", UiIcons.round_style(Color(1.0, 0.98, 0.92), 12))
	list.add_child(row)

	var label := _popup_label(text, 19)
	label.position = Vector2(14, 0)
	UiIcons.wrap_label(label, Vector2(row.custom_minimum_size.x - 360, 66))
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(label)

	var btn := _popup_button(price_text, OK_BTN_COLOR, Vector2(row.custom_minimum_size.x - 330, 8), Vector2(270, 50))
	btn.add_theme_font_size_override("font_size", 18)
	btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	btn.mouse_filter = Control.MOUSE_FILTER_PASS
	btn.disabled = not enabled
	btn.pressed.connect(func():
		if on_buy.call():
			ruby_label.text = str(GameState.rubies)
			coin_label.text = str(GameState.plant_coins)
			_show_shop())
	row.add_child(btn)
	price_icon.position = Vector2(row.custom_minimum_size.x - 50, 15)
	row.add_child(price_icon)

func _list_note(list: VBoxContainer, text: String) -> void:
	var note := _popup_label(text, 18)
	note.custom_minimum_size = Vector2(list.custom_minimum_size.x, 30)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	list.add_child(note)

func _build_ruby_offers(list: VBoxContainer) -> void:
	list.add_child(_popup_label(Lang.t("for_rubies"), 24))
	var limit_price := GameState.next_fertilizer_limit_price()
	if limit_price < 0:
		_add_shop_row(list, Lang.f("shop_fertilizer_max", [GameState.fertilizer_limit]), Lang.t("maximum"), UiIcons.ruby(36), false, func(): return false)
	else:
		_add_shop_row(list, Lang.f("shop_fertilizer", [GameState.fertilizer_limit]), Lang.f("buy_for_rubies", [limit_price]), UiIcons.ruby(36),
			GameState.rubies >= limit_price, GameState.buy_fertilizer_limit)

	var plot := GameState.soonest_growing_plot()
	var rush_text := Lang.t("shop_rush") if plot >= 0 else Lang.t("shop_rush_none")
	_add_shop_row(list, rush_text, Lang.f("buy_for_rubies", [GameState.GARDEN_RUSH_RUBIES]), UiIcons.ruby(36),
		plot >= 0 and GameState.rubies >= GameState.GARDEN_RUSH_RUBIES,
		func():
			var bought := GameState.rush_plot(plot)
			GameState.mark_ready_plots()
			return bought)

	_list_note(list, Lang.t("shop_upgrades_note"))
	_list_note(list, Lang.f("shop_rent_note", [GameState.RENT_SLOT_RUBIES]))

# Pomoce do wydarzen widac wszystkie, ale kupic mozna tylko te z biezacego.
func _build_coin_offers(list: VBoxContainer) -> void:
	list.add_child(_popup_label(Lang.t("for_coins"), 24))
	var current := GameState.current_event()
	for event in EventData.ROTATION:
		var is_current: bool = not current.is_empty() and event["id"] == current["id"]
		var event_name := Lang.t("event_" + event["id"])
		if event.has("help"):
			var help_text := Lang.t("event_%s_help" % event["id"])
			var cost: int = event["help"]["cost"]
			if is_current and GameState.event_help_prepaid:
				_add_shop_row(list, "%s: %s" % [event_name, help_text], Lang.t("bought"), UiIcons.plant_coin(36), false, func(): return false)
			else:
				var suffix := "" if is_current else " " + Lang.t("when_event_runs")
				_add_shop_row(list, "%s: %s%s" % [event_name, help_text, suffix], Lang.f("buy_for_coins", [cost]), UiIcons.plant_coin(36),
					is_current and GameState.plant_coins >= cost, GameState.buy_event_help)
		if event.get("belt_preview", false):
			var swap_cost: int = event["preview_swap_cost"]
			var swap_text := Lang.f("shop_swap", [event_name, GameState.event_swap_credits]) if is_current else Lang.f("shop_swap_later", [event_name])
			_add_shop_row(list, swap_text, Lang.f("buy_for_coins", [swap_cost]), UiIcons.plant_coin(36),
				is_current and GameState.plant_coins >= swap_cost, GameState.buy_swap_credit)
		if event.get("shared_garden", false):
			var ready: bool = is_current and GameState.is_shared_garden_on()
			var gift_text := Lang.f("shop_gift", [GameState.shared_gift_credits]) if ready else Lang.t("shop_gift_later")
			_add_shop_row(list, gift_text, Lang.f("buy_for_coins", [EventData.GIFT_COST]), UiIcons.plant_coin(36),
				ready and GameState.plant_coins >= EventData.GIFT_COST, GameState.buy_gift_credit)
	_list_note(list, Lang.t("shop_addon_help_note"))

# --- Ustawienia: jezyk konta ---
func _show_settings() -> void:
	var panel := _open_popup(Vector2(760, 520), Lang.t("settings"))
	var caption := _popup_label(Lang.t("language_choose"), 24)
	caption.position = Vector2(40, 76)
	panel.add_child(caption)
	var columns := 2
	var btn_size := Vector2(320, 70)
	for i in range(Lang.CODES.size()):
		var pos := Vector2(40 + (i % columns) * (btn_size.x + 40), 120 + int(i / float(columns)) * (btn_size.y + 16))
		var active := Lang.current == i
		var btn := _popup_button(Lang.NAMES[i], OK_BTN_COLOR if active else CORNER_BTN_COLOR, pos, btn_size)
		var lang_code: String = Lang.CODES[i]
		btn.pressed.connect(func():
			GameState.set_language(lang_code)
			get_tree().reload_current_scene())
		panel.add_child(btn)

# Zmiana nazwy i ikony gracza. Ikonka roslinki ma trzy stany: klodka (roslina
# jeszcze zablokowana), szara (do odblokowania w kilku krokach) i kolorowa (do
# wyboru; dwie startowe sa kolorowe od razu).
# draft_* przechowuja niezapisane zmiany na czas okienka odblokowania ikonki.
func _show_player_edit(draft_name := GameState.player_name, draft_icon := GameState.player_icon) -> void:
	var panel := _open_popup(Vector2(1000, 470), Lang.t("player"))
	var chosen := {"icon": draft_icon}

	var name_caption := _popup_label(Lang.t("name_label"), 22)
	name_caption.position = Vector2(40, 86)
	panel.add_child(name_caption)

	var name_edit := LineEdit.new()
	name_edit.text = draft_name
	name_edit.max_length = GameState.PLAYER_NAME_MAX_LENGTH
	name_edit.position = Vector2(150, 76)
	name_edit.size = Vector2(400, 52)
	name_edit.add_theme_font_size_override("font_size", 24)
	panel.add_child(name_edit)

	var code_btn := _popup_button(Lang.t("test_code"), CORNER_BTN_COLOR, Vector2(570, 76), Vector2(200, 52))
	code_btn.pressed.connect(_show_code_entry)
	panel.add_child(code_btn)

	var icon_caption := _popup_label(Lang.t("icon_label"), 22)
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
	for p_idx in PlantData.unlock_order():
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(80, 80)
		btn.focus_mode = Control.FOCUS_NONE
		icons_box.add_child(btn)
		var icon: Control
		if GameState.is_icon_unlocked(p_idx):
			var sb := UiIcons.round_style(Color(0.55, 0.8, 0.4), 14)
			sb.set_border_width_all(5)
			sb.border_color = SELECTED_ICON_BORDER if p_idx == chosen["icon"] else sb.bg_color
			for state in ["normal", "hover", "pressed"]:
				btn.add_theme_stylebox_override(state, sb)
			icon_styles[p_idx] = sb
			icon = UiIcons.plant_icon(p_idx, 64)
			btn.pressed.connect(func():
				chosen["icon"] = p_idx
				for key in icon_styles.keys():
					icon_styles[key].border_color = SELECTED_ICON_BORDER if key == p_idx else icon_styles[key].bg_color)
		elif GameState.is_plant_unlocked(p_idx):
			UiIcons.style_button(btn, Color(0.7, 0.7, 0.68), 14)
			icon = UiIcons.plant_icon_gray(p_idx, 64)
			btn.pressed.connect(func(): _show_icon_unlock(p_idx, name_edit.text, chosen["icon"]))
		else:
			UiIcons.style_button(btn, Color(0.5, 0.5, 0.5), 14)
			btn.disabled = true
			icon = UiIcons.padlock(64)
		icon.position = Vector2(8, 8)
		btn.add_child(icon)

	var icons_hint := _popup_label(Lang.t("icons_hint"), 18)
	icons_hint.position = Vector2(40, 344)
	icons_hint.size = Vector2(panel.size.x - 80, 26)
	icons_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(icons_hint)

	var error_label := _popup_label("", 18)
	error_label.position = Vector2(150, 130)
	error_label.add_theme_color_override("font_color", Color(0.75, 0.2, 0.15))
	panel.add_child(error_label)

	# Powrot do ekranu wyboru konta (konta sa lokalne, bez hasla).
	var switch_btn := _popup_button(Lang.t("switch_account"), CORNER_BTN_COLOR, Vector2(40, panel.size.y - 96), Vector2(240, 70))
	switch_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/ProfileSelect.tscn"))
	panel.add_child(switch_btn)

	var delete_btn := _popup_button(Lang.t("delete_account"), DELETE_BTN_COLOR, Vector2(300, panel.size.y - 96), Vector2(240, 70))
	delete_btn.pressed.connect(_show_delete_confirm)
	panel.add_child(delete_btn)

	var save_btn := _popup_button(Lang.t("save"), OK_BTN_COLOR, Vector2(panel.size.x - 260, panel.size.y - 96), Vector2(220, 70))
	save_btn.pressed.connect(func():
		if GameState.set_player(name_edit.text, chosen["icon"]):
			get_tree().reload_current_scene()
		else:
			error_label.text = Lang.t("name_taken"))
	panel.add_child(save_btn)

# Odblokowanie ikonki: szara ikona, postep i przycisk kolejnego kroku. Po
# ostatnim kroku ikonka staje sie kolorowa i od razu jest wybrana.
func _show_icon_unlock(plant_idx: int, draft_name: String, draft_icon: int) -> void:
	var panel := _open_popup(Vector2(600, 500), Lang.t("unlock_icon"), false)

	var icon := UiIcons.plant_icon_gray(plant_idx, 180)
	icon.position = Vector2((panel.size.x - 180) / 2.0, 70)
	panel.add_child(icon)

	var name_label := _popup_label(PlantData.name_of(plant_idx), 28)
	name_label.position = Vector2(0, 256)
	name_label.size = Vector2(panel.size.x, 40)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(name_label)

	var progress := _popup_label(Lang.f("icon_progress", [GameState.icon_steps_done(plant_idx), GameState.icon_steps_required(plant_idx)]), 22)
	progress.position = Vector2(0, 302)
	progress.size = Vector2(panel.size.x, 34)
	progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(progress)

	var back_btn := _popup_button(Lang.t("back"), CORNER_BTN_COLOR, Vector2(40, panel.size.y - 100), Vector2(190, 70))
	back_btn.pressed.connect(func(): _show_player_edit(draft_name, draft_icon))
	panel.add_child(back_btn)

	var step_btn := _popup_button(Lang.t("unlock_step"), OK_BTN_COLOR, Vector2(panel.size.x - 330, panel.size.y - 100), Vector2(290, 70))
	step_btn.pressed.connect(func():
		_show_greeting(func():
			GameState.record_icon_step(plant_idx)
			if GameState.is_icon_unlocked(plant_idx):
				_show_player_edit(draft_name, plant_idx)
			else:
				_show_icon_unlock(plant_idx, draft_name, draft_icon)))
	panel.add_child(step_btn)

# Zamiast reklam: napis z ikonka sadzonki i odliczaniem przez 5 sekund. Wszystkie
# opcje "za reklame" uzywaja tego samego okienka.
func _show_greeting(on_finished: Callable) -> void:
	var panel := _open_popup(Vector2(640, 300), "", false)
	var row := HBoxContainer.new()
	row.position = Vector2(0, 50)
	row.size = Vector2(panel.size.x, 90)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 18)
	panel.add_child(row)
	row.add_child(_popup_label(Lang.t("have_fun"), 48))
	row.add_child(UiIcons.sapling(80))

	var countdown := _popup_label(str(int(GREETING_SECONDS)), 56)
	countdown.position = Vector2(0, 170)
	countdown.size = Vector2(panel.size.x, 80)
	countdown.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(countdown)

	var tw := popup.create_tween()
	tw.tween_method(func(left: float): countdown.text = str(ceili(left)), GREETING_SECONDS, 0.0, GREETING_SECONDS)
	tw.tween_callback(on_finished)

# --- Kod testowy: poprawny kod pozwala raz zmienic wydarzenie, dodatek albo gre
# edukacyjna. Wyjscie z tych okienek albo zmiana zuzywa kod, wiec nastepnym razem
# trzeba wpisac go znowu. ---
func _show_code_entry() -> void:
	var panel := _open_popup(Vector2(620, 320), Lang.t("test_code"))

	var code_edit := LineEdit.new()
	code_edit.placeholder_text = Lang.t("enter_code")
	code_edit.position = Vector2(110, 86)
	code_edit.size = Vector2(400, 56)
	code_edit.add_theme_font_size_override("font_size", 26)
	panel.add_child(code_edit)

	var error_label := _popup_label("", 20)
	error_label.position = Vector2(0, 150)
	error_label.size = Vector2(panel.size.x, 30)
	error_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	error_label.add_theme_color_override("font_color", Color(0.75, 0.2, 0.15))
	panel.add_child(error_label)

	var ok_btn := _popup_button(Lang.t("check"), OK_BTN_COLOR, Vector2((panel.size.x - 220) / 2.0, 206), Vector2(220, 70))
	ok_btn.pressed.connect(func():
		if GameState.try_test_code(code_edit.text):
			_show_event_switch()
		else:
			_update_code_entry(code_edit, error_label, ok_btn, Lang.t("wrong_code")))
	panel.add_child(ok_btn)
	_update_code_entry(code_edit, error_label, ok_btn, "")

# Podczas blokady pole i przycisk sa nieaktywne, a napis podaje pozostaly czas.
func _update_code_entry(code_edit: LineEdit, error_label: Label, ok_btn: Button, message: String) -> void:
	var lock_left := GameState.test_code_lock_seconds_left()
	code_edit.editable = lock_left == 0
	ok_btn.disabled = lock_left > 0
	error_label.text = message
	if lock_left > 0:
		code_edit.text = ""
		error_label.text = Lang.f("code_locked", [ceili(lock_left / 60.0)])

# Lista do wyboru: wydarzenia tygodnia, dodatki i gry edukacyjne.
func _show_event_switch() -> void:
	var panel := _open_popup(Vector2(1080, 640), Lang.t("choose_event"))
	var list := _scroll_list(panel, Vector2(30, 70), Vector2(panel.size.x - 60, panel.size.y - 90), 10)
	var sections := [
		[Lang.t("weekly_event"), EventData.ROTATION, "weekly"],
		[Lang.t("addons"), AddonData.ADDONS, AddonData.KIND_ADDON],
		[Lang.t("edu_games"), AddonData.EDU, AddonData.KIND_EDU],
	]
	for section in sections:
		list.add_child(_popup_label(section[0], 24))
		var flow := HFlowContainer.new()
		flow.custom_minimum_size = Vector2(list.custom_minimum_size.x, 0)
		flow.add_theme_constant_override("h_separation", 12)
		flow.add_theme_constant_override("v_separation", 12)
		flow.mouse_filter = Control.MOUSE_FILTER_PASS
		list.add_child(flow)
		var entries: Array = section[1]
		var kind: String = section[2]
		for i in range(entries.size()):
			var entry: Dictionary = entries[i]
			var title := Lang.t("event_" + entry["id"]) if kind == "weekly" else AddonData.title(entry)
			var btn := _popup_button(title, CORNER_BTN_COLOR, Vector2.ZERO, Vector2(320, 70))
			btn.custom_minimum_size = Vector2(320, 70)
			btn.add_theme_font_size_override("font_size", 20)
			btn.mouse_filter = Control.MOUSE_FILTER_PASS
			var idx := i
			if kind == "weekly":
				btn.disabled = i == GameState.event_index and not GameState.current_event().is_empty()
				btn.pressed.connect(func(): _show_progress_choice(idx))
			else:
				btn.disabled = int(GameState.rotations.get(kind, {}).get("index", 0)) == i
				btn.pressed.connect(func():
					GameState.switch_rotation(kind, idx)
					GameState.rotation_view = kind
					get_tree().change_scene_to_file("res://scenes/Rotation.tscn"))
			flow.add_child(btn)

# Postepy obecnego wydarzenia: gracz decyduje, czy maja zostac na pozniej.
func _show_progress_choice(event_idx: int) -> void:
	var current := GameState.current_event()
	if current.is_empty():
		_finish_event_switch(event_idx, false)
		return
	var panel := _open_popup(Vector2(680, 340), "", false)
	var question := _popup_label(Lang.f("keep_progress_question", [Lang.t("event_" + current["id"])]), 28)
	question.position = Vector2(40, 40)
	question.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiIcons.wrap_label(question, Vector2(panel.size.x - 80, 130))
	panel.add_child(question)

	var drop_btn := _popup_button(Lang.t("dont_save"), DELETE_BTN_COLOR, Vector2(50, 220), Vector2(270, 80))
	drop_btn.pressed.connect(func(): _finish_event_switch(event_idx, false))
	panel.add_child(drop_btn)

	var keep_btn := _popup_button(Lang.t("save"), OK_BTN_COLOR, Vector2(panel.size.x - 320, 220), Vector2(270, 80))
	keep_btn.pressed.connect(func(): _finish_event_switch(event_idx, true))
	panel.add_child(keep_btn)

func _finish_event_switch(event_idx: int, keep_progress: bool) -> void:
	GameState.switch_event(event_idx, keep_progress)
	get_tree().change_scene_to_file("res://scenes/Events.tscn")

func _show_net_notice() -> void:
	var panel := _open_popup(Vector2(640, 220), Lang.t("multiplayer"))
	var info := _popup_label(NetSession.notice, 22)
	info.position = Vector2(40, 90)
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiIcons.wrap_label(info, Vector2(panel.size.x - 80, 90))
	panel.add_child(info)
	NetSession.notice = ""

# "Czy na pewno?" przed usunieciem wybranego konta - postep znika na zawsze.
func _show_delete_confirm() -> void:
	var panel := _open_popup(Vector2(620, 320), Lang.f("delete_account_question", [GameState.player_name]))

	var warning := _popup_label(Lang.t("delete_account_warning"), 20)
	warning.position = Vector2(40, 80)
	warning.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiIcons.wrap_label(warning, Vector2(panel.size.x - 80, 80))
	panel.add_child(warning)

	var keep_btn := _popup_button(Lang.t("keep"), OK_BTN_COLOR, Vector2(70, panel.size.y - 106), Vector2(210, 70))
	keep_btn.pressed.connect(_show_player_edit)
	panel.add_child(keep_btn)

	var delete_btn := _popup_button(Lang.t("delete"), DELETE_BTN_COLOR, Vector2(panel.size.x - 280, panel.size.y - 106), Vector2(210, 70))
	delete_btn.pressed.connect(func():
		GameState.delete_profile(GameState.current_profile_id)
		get_tree().change_scene_to_file("res://scenes/ProfileSelect.tscn"))
	panel.add_child(delete_btn)
