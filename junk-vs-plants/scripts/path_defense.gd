extends Control

# Budowanie sciezki (dodatek): najpierw gracz uklada z kamieni kreta sciezke od
# wejscia smieci (po prawej) do domu (po lewej) - kazdy kamien to pole dluzszej
# drogi niz prosta. Potem smieciostwory ida ta sciezka, a roslinki posadzone
# obok niej strzelaja we wszystkie strony. Wygrana: wszyscy wrogowie pokonani.

const VIEWPORT_WIDTH := 1280
const VIEWPORT_HEIGHT := 720
const COLS := 12
const ROWS := 7
const CELL := 72.0
const ORIGIN := Vector2(330, 110)
const ENTRY := Vector2i(11, 3)
const HOUSE := Vector2i(0, 3)
const BASE_STONES := 8
const HELP_STONES := 3
const START_WATER := 150
const KILL_WATER := 20
const SPAWN_EVERY := 1.6
const GROUP_SIZE := 6
const GROUP_PAUSE := 5.0
const BACK_COLOR := Color(0.3, 0.45, 0.25)
const OK_BTN_COLOR := Color(0.25, 0.6, 0.25)
const PATH_COLOR := Color(0.6, 0.5, 0.38)
const GRASS_COLOR := Color(0.35, 0.62, 0.3)
# Roslinki obrony: indeks w PlantData, koszt, zasieg (pola), odstep (s), obrazenia.
# Mrozoroslinka nie rani, tylko spowalnia wrogow w zasiegu.
const TOWERS := [
	{"plant": 0, "cost": 50, "range": 2.2, "interval": 1.0, "dmg": 22.0, "kind": "shot"},
	{"plant": 3, "cost": 70, "range": 1.6, "interval": 1.5, "dmg": 14.0, "kind": "area"},
	{"plant": 5, "cost": 40, "range": 1.6, "interval": 0.0, "dmg": 0.0, "kind": "slow"},
]
# Wrogowie: [tekstura, zycie, predkosc w polach na sekunde].
const ENEMIES := [
	["res://assets/sprites/enemies/bottle.png", 80.0, 0.35],
	["res://assets/sprites/enemies/can.png", 60.0, 0.45],
	["res://assets/sprites/enemies/cardboard_golem.png", 220.0, 0.25],
]

var kind := GameState.play_kind
var stage := GameState.event_stage
var stones := BASE_STONES
var path: Array = [ENTRY]
var path_nodes := {}
var building := true
var towers: Array = []
var enemies: Array = []
var to_spawn := 0
var spawned := 0
var spawn_timer := 1.0
var water := START_WATER
var selected_tower := -1
var running := true
var board: Control
var info_label: Label
var message_label: Label
var start_btn: Button
var tower_buttons: Array = []

func _ready() -> void:
	if GameState.event_help_active:
		stones += HELP_STONES
	GameState.event_help_active = false
	stones += stage
	to_spawn = 8 + 4 * stage

	add_child(UiIcons.screen_background("yard"))
	var title := Label.new()
	title.text = Lang.f("stage_title", [Lang.t("addon_path_build"), stage + 1])
	title.position = Vector2(ORIGIN.x, 10)
	title.add_theme_font_size_override("font_size", 30)
	add_child(title)
	info_label = Label.new()
	info_label.position = Vector2(ORIGIN.x, 50)
	info_label.add_theme_font_size_override("font_size", 20)
	add_child(info_label)
	message_label = Label.new()
	message_label.position = Vector2(ORIGIN.x, ORIGIN.y + ROWS * CELL + 8)
	UiIcons.wrap_label(message_label, Vector2(COLS * CELL, 60))
	message_label.add_theme_font_size_override("font_size", 20)
	add_child(message_label)

	board = Control.new()
	board.position = ORIGIN
	board.size = Vector2(COLS, ROWS) * CELL
	board.gui_input.connect(_on_board_input)
	add_child(board)
	for c in range(COLS):
		for r in range(ROWS):
			var tile := ColorRect.new()
			tile.color = GRASS_COLOR if (c + r) % 2 == 0 else GRASS_COLOR.darkened(0.08)
			tile.position = Vector2(c, r) * CELL
			tile.size = Vector2(CELL - 2, CELL - 2)
			tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
			board.add_child(tile)
	var house := UiIcons.file_icon("house", CELL)
	if house == null:
		house = UiIcons.sapling(CELL)
	house.position = ORIGIN + Vector2(HOUSE) * CELL - Vector2(CELL, 0)
	add_child(house)

	var back_btn := Button.new()
	back_btn.text = Lang.t("back")
	back_btn.position = Vector2(20, 630)
	back_btn.size = Vector2(180, 64)
	back_btn.focus_mode = Control.FOCUS_NONE
	UiIcons.style_button(back_btn, BACK_COLOR, 14)
	back_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/Rotation.tscn"))
	add_child(back_btn)

	var clear_btn := Button.new()
	clear_btn.text = Lang.t("path_clear")
	clear_btn.position = Vector2(20, 120)
	clear_btn.size = Vector2(220, 60)
	clear_btn.focus_mode = Control.FOCUS_NONE
	UiIcons.style_button(clear_btn, BACK_COLOR, 14)
	clear_btn.pressed.connect(func():
		if building:
			path = [ENTRY]
			_redraw_path())
	add_child(clear_btn)
	set_meta("clear_btn", clear_btn)

	start_btn = Button.new()
	start_btn.text = Lang.t("path_start")
	start_btn.position = Vector2(20, 190)
	start_btn.size = Vector2(220, 70)
	start_btn.focus_mode = Control.FOCUS_NONE
	start_btn.add_theme_font_size_override("font_size", 24)
	UiIcons.style_button(start_btn, OK_BTN_COLOR, 14)
	start_btn.pressed.connect(_start_defense)
	add_child(start_btn)

	for i in range(TOWERS.size()):
		var tower: Dictionary = TOWERS[i]
		var btn := Button.new()
		btn.position = Vector2(20, 290 + i * 100)
		btn.size = Vector2(220, 88)
		btn.focus_mode = Control.FOCUS_NONE
		btn.visible = false
		var icon := UiIcons.plant_icon(tower["plant"], 72)
		icon.position = Vector2(8, 8)
		btn.add_child(icon)
		var cost := Label.new()
		cost.text = "%s\n%d" % [PlantData.name_of(tower["plant"]), tower["cost"]]
		cost.position = Vector2(90, 10)
		cost.add_theme_font_size_override("font_size", 18)
		btn.add_child(cost)
		var tower_idx := i
		btn.pressed.connect(func():
			selected_tower = -1 if selected_tower == tower_idx else tower_idx
			_update_tower_buttons())
		add_child(btn)
		tower_buttons.append(btn)

	_redraw_path()

func _cell_rect(cell: Vector2i) -> Rect2:
	return Rect2(Vector2(cell) * CELL, Vector2(CELL, CELL))

func _cell_center(cell: Vector2i) -> Vector2:
	return ORIGIN + (Vector2(cell) + Vector2(0.5, 0.5)) * CELL

func _max_length() -> int:
	return COLS + stones

func _redraw_path() -> void:
	for node in path_nodes.values():
		node.queue_free()
	path_nodes.clear()
	for i in range(path.size()):
		var cell: Vector2i = path[i]
		var tile := ColorRect.new()
		tile.color = PATH_COLOR if i > 0 else Color(0.5, 0.35, 0.3)
		tile.position = Vector2(cell) * CELL
		tile.size = Vector2(CELL - 2, CELL - 2)
		tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
		board.add_child(tile)
		path_nodes[cell] = tile
	var done: bool = path.back() == HOUSE
	start_btn.disabled = not done
	info_label.text = Lang.f("path_build_info", [_max_length() - path.size(), path.size()])
	message_label.text = Lang.t("path_ready") if done else Lang.t("path_hint")

func _on_board_input(event: InputEvent) -> void:
	if not running or not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	var cell := Vector2i(int(event.position.x / CELL), int(event.position.y / CELL))
	if cell.x < 0 or cell.y < 0 or cell.x >= COLS or cell.y >= ROWS:
		return
	if building:
		_build_tap(cell)
	else:
		_place_tower(cell)

# Tapniecie pola obok konca sciezki ja przedluza, a pola na sciezce - skraca.
func _build_tap(cell: Vector2i) -> void:
	var at := path.find(cell)
	if at >= 0:
		path = path.slice(0, at + 1)
	else:
		var last: Vector2i = path.back()
		if last == HOUSE:
			message_label.text = Lang.t("path_ready")
			return
		if abs(cell.x - last.x) + abs(cell.y - last.y) != 1:
			message_label.text = Lang.t("path_next_to_end")
			return
		if path.size() >= _max_length():
			message_label.text = Lang.t("path_no_stones")
			return
		path.append(cell)
	_redraw_path()

func _start_defense() -> void:
	building = false
	start_btn.visible = false
	get_meta("clear_btn").visible = false
	for btn in tower_buttons:
		btn.visible = true
	message_label.text = Lang.t("path_defend_hint")
	_update_tower_buttons()

func _update_tower_buttons() -> void:
	for i in range(tower_buttons.size()):
		var color := Color(0.42, 0.38, 0.1) if i == selected_tower else Color(0.16, 0.22, 0.14)
		UiIcons.style_button(tower_buttons[i], color, 12)
		tower_buttons[i].modulate = Color(1, 1, 1) if water >= TOWERS[i]["cost"] else Color(1, 0.55, 0.55)
	info_label.text = Lang.f("path_defend_info", [water, spawned, to_spawn])

func _place_tower(cell: Vector2i) -> void:
	if selected_tower < 0:
		message_label.text = Lang.t("path_choose_plant")
		return
	if path.has(cell) or towers.any(func(t): return t["cell"] == cell):
		message_label.text = Lang.t("path_cell_taken")
		return
	var tower: Dictionary = TOWERS[selected_tower]
	if water < tower["cost"]:
		message_label.text = Lang.t("too_little_water")
		return
	water -= tower["cost"]
	var icon := UiIcons.plant_icon(tower["plant"], CELL - 10)
	icon.position = ORIGIN + Vector2(cell) * CELL + Vector2(5, 5)
	add_child(icon)
	towers.append({"cell": cell, "data": tower, "timer": 0.0, "node": icon,
		"power": GameState.plant_power(tower["plant"])})
	selected_tower = -1
	message_label.text = ""
	_update_tower_buttons()

func _process(delta: float) -> void:
	if not running or building:
		return
	_spawn(delta)
	_move_enemies(delta)
	_shoot(delta)
	if spawned >= to_spawn and enemies.is_empty():
		_finish(true)

func _spawn(delta: float) -> void:
	if spawned >= to_spawn:
		return
	spawn_timer -= delta
	if spawn_timer > 0.0:
		return
	spawned += 1
	spawn_timer = SPAWN_EVERY + (GROUP_PAUSE if spawned % GROUP_SIZE == 0 else 0.0)
	var type := randi() % 2
	if stage >= 2 and spawned % 4 == 0:
		type = 2
	var data: Array = ENEMIES[type]
	var node := TextureRect.new()
	node.texture = load(data[0])
	node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	node.size = Vector2(CELL - 14, CELL - 14)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(node)
	var hp: float = data[1] * (1.0 + 0.25 * stage)
	enemies.append({"node": node, "hp": hp, "max_hp": hp, "speed": data[2], "progress": 0.0, "slow": 1.0})
	_update_tower_buttons()

# Pozycja na sciezce: progress to liczba przebytych pol od wejscia.
func _path_point(progress: float) -> Vector2:
	var i := clampi(int(progress), 0, path.size() - 1)
	var j := mini(i + 1, path.size() - 1)
	return _cell_center(path[i]).lerp(_cell_center(path[j]), progress - i)

func _move_enemies(delta: float) -> void:
	for e in enemies:
		e["slow"] = 1.0
		var pos := _path_point(e["progress"])
		for t in towers:
			if t["data"]["kind"] == "slow" and pos.distance_to(_cell_center(t["cell"])) <= t["data"]["range"] * CELL:
				e["slow"] = 0.5 / t["power"]
		e["progress"] += e["speed"] * e["slow"] * delta
		e["node"].position = _path_point(e["progress"]) - e["node"].size / 2.0
		if e["progress"] >= path.size() - 1:
			_finish(false)
			return

func _shoot(delta: float) -> void:
	for t in towers:
		var data: Dictionary = t["data"]
		if data["kind"] == "slow":
			continue
		t["timer"] -= delta
		if t["timer"] > 0.0:
			continue
		var center := _cell_center(t["cell"])
		var in_range := enemies.filter(func(e): return _path_point(e["progress"]).distance_to(center) <= data["range"] * CELL)
		if in_range.is_empty():
			continue
		t["timer"] = data["interval"]
		var dmg: float = data["dmg"] * t["power"]
		if data["kind"] == "area":
			for e in in_range:
				_hit(e, dmg, center)
		else:
			# Kukurydza celuje w smiecia, ktory zaszedl najdalej.
			in_range.sort_custom(func(a, b): return a["progress"] > b["progress"])
			_hit(in_range[0], dmg, center)

func _hit(e: Dictionary, dmg: float, from: Vector2) -> void:
	var line := Line2D.new()
	line.points = PackedVector2Array([from, _path_point(e["progress"])])
	line.width = 4
	line.default_color = Color(1.0, 0.9, 0.3, 0.8)
	add_child(line)
	var tw := line.create_tween()
	tw.tween_property(line, "modulate:a", 0.0, 0.2)
	tw.tween_callback(line.queue_free)
	e["hp"] -= dmg
	if e["hp"] <= 0.0 and enemies.has(e):
		e["node"].queue_free()
		enemies.erase(e)
		water += KILL_WATER
		_update_tower_buttons()

func _finish(won: bool) -> void:
	running = false
	var text := ""
	if won:
		var reward := GameState.complete_rotation_stage(kind, stage)
		text = Lang.t("win_title")
		for key in ["saplings", "moves", "rubies", "coins"]:
			if reward.get(key, 0) > 0:
				text += "\n" + Lang.f("reward_" + key, [reward[key]])
	else:
		text = Lang.t("lose_reason_house")
	var panel := Panel.new()
	panel.size = Vector2(620, 320)
	panel.position = (Vector2(VIEWPORT_WIDTH, VIEWPORT_HEIGHT) - panel.size) / 2.0
	var sb := UiIcons.round_style(Color(0.95, 0.93, 0.85), 18)
	sb.set_border_width_all(5)
	sb.border_color = Color(0.25, 0.2, 0.15)
	panel.add_theme_stylebox_override("panel", sb)
	add_child(panel)
	var label := Label.new()
	label.text = text
	label.position = Vector2(20, 24)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiIcons.wrap_label(label, Vector2(580, 160))
	label.add_theme_font_size_override("font_size", 26)
	label.add_theme_color_override("font_color", Color(0.15, 0.12, 0.1))
	panel.add_child(label)
	var again := Button.new()
	again.text = Lang.t("play_again")
	again.position = Vector2(40, 220)
	again.size = Vector2(250, 70)
	again.focus_mode = Control.FOCUS_NONE
	UiIcons.style_button(again, OK_BTN_COLOR, 14)
	again.pressed.connect(func(): get_tree().reload_current_scene())
	panel.add_child(again)
	var back := Button.new()
	back.text = Lang.t("back")
	back.position = Vector2(330, 220)
	back.size = Vector2(250, 70)
	back.focus_mode = Control.FOCUS_NONE
	UiIcons.style_button(back, BACK_COLOR, 14)
	back.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/Rotation.tscn"))
	panel.add_child(back)
