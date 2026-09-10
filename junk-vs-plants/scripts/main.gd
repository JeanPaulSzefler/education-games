extends Node2D

# --- Grid layout ---
const COLS := 8
const ROWS := 5
const CELL := 90
const GRID_LEFT := 0
const GRID_TOP := 160

# --- Plant types (data-driven so more can be added later) ---
# hp, cost, dmg, atk_interval (0 = does not attack), texture = grafika rosliny
const PLANT_TYPES := [
	{"name": "Kaktus", "cost": 50, "hp": 100, "dmg": 20, "interval": 1.2, "texture": "res://assets/sprites/plants/cactus.svg"},
	{"name": "Lisc Bananowca", "cost": 75, "hp": 300, "dmg": 0, "interval": 0.0, "texture": "res://assets/sprites/plants/banana_leaf.svg"},
]

# --- Enemy types (mix of junk) ---
const ENEMY_TYPES := [
	{"name": "Butelka PET", "hp": 80, "speed": 18.0, "dmg": 10, "texture": "res://assets/sprites/enemies/bottle.svg"},
	{"name": "Puszka", "hp": 60, "speed": 26.0, "dmg": 8, "texture": "res://assets/sprites/enemies/can.svg"},
	{"name": "Kartonowy Golem", "hp": 220, "speed": 12.0, "dmg": 18, "texture": "res://assets/sprites/enemies/cardboard_golem.svg"},
]

const THORN_TEXTURE := "res://assets/sprites/ui/thorn.svg"

# --- Waves (list of waves, each wave = list of {type, row, delay_after_previous}) ---
var waves := []
var current_wave := 0
var wave_spawn_queue := []
var time_to_next_spawn := 0.0
var between_waves_timer := 0.0
var wave_in_progress := false

# --- Economy ---
var water := 100
var water_income_timer := 0.0
const WATER_INCOME_AMOUNT := 25
const WATER_INCOME_INTERVAL := 5.0

# --- State ---
var grid_occupancy := []  # [col][row] -> plant dict or null
var plants := []          # list of {node, hp, col, row, type_idx, atk_timer}
var enemies := []         # list of {node, hp, row, x, type_idx}
var projectiles := []     # list of {node, row, x, dmg}
var selected_plant_type := -1
var game_over := false
var water_label: Label
var wave_label: Label
var message_label: Label
var plant_buttons := []

func _ready() -> void:
	randomize()
	_build_waves()
	_setup_grid_occupancy()
	_build_background()
	_build_grid_visual()
	_build_hud()
	_build_plant_bar()

func _setup_grid_occupancy() -> void:
	grid_occupancy.clear()
	for c in range(COLS):
		var col_arr := []
		for r in range(ROWS):
			col_arr.append(null)
		grid_occupancy.append(col_arr)

func _build_waves() -> void:
	# 3 waves of increasing size/difficulty. Enemy type index references ENEMY_TYPES.
	waves = [
		[{"type": 0, "row": 1}, {"type": 0, "row": 3}, {"type": 1, "row": 2}],
		[{"type": 0, "row": 0}, {"type": 1, "row": 1}, {"type": 1, "row": 3}, {"type": 0, "row": 4}, {"type": 2, "row": 2}],
		[{"type": 2, "row": 0}, {"type": 1, "row": 1}, {"type": 0, "row": 2}, {"type": 2, "row": 3}, {"type": 1, "row": 4}, {"type": 2, "row": 2}],
	]
	between_waves_timer = 3.0

func _build_background() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.55, 0.45, 0.3)
	bg.position = Vector2(0, 0)
	bg.size = Vector2(COLS * CELL, GRID_TOP + ROWS * CELL)
	add_child(bg)

func _build_grid_visual() -> void:
	var grass_texture := load("res://assets/sprites/ui/grass_tile.svg")
	for c in range(COLS):
		for r in range(ROWS):
			var tile := TextureRect.new()
			tile.texture = grass_texture
			tile.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tile.stretch_mode = TextureRect.STRETCH_SCALE
			tile.modulate = Color(1, 1, 1) if (c + r) % 2 == 0 else Color(0.88, 0.92, 0.85)
			tile.position = Vector2(GRID_LEFT + c * CELL, GRID_TOP + r * CELL)
			tile.size = Vector2(CELL - 2, CELL - 2)
			tile.mouse_filter = Control.MOUSE_FILTER_STOP
			tile.gui_input.connect(_on_tile_gui_input.bind(c, r))
			add_child(tile)

func _build_hud() -> void:
	water_label = Label.new()
	water_label.position = Vector2(20, 20)
	water_label.add_theme_font_size_override("font_size", 32)
	add_child(water_label)

	wave_label = Label.new()
	wave_label.position = Vector2(20, 60)
	wave_label.add_theme_font_size_override("font_size", 24)
	add_child(wave_label)

	message_label = Label.new()
	message_label.position = Vector2(20, GRID_TOP + ROWS * CELL + 20)
	message_label.add_theme_font_size_override("font_size", 28)
	add_child(message_label)

	_update_hud()

func _build_plant_bar() -> void:
	var bar_y := GRID_TOP + ROWS * CELL + 70
	for i in range(PLANT_TYPES.size()):
		var pt = PLANT_TYPES[i]
		var btn := Button.new()
		btn.text = "%s\n%d kropel" % [pt["name"], pt["cost"]]
		btn.position = Vector2(20 + i * 180, bar_y)
		btn.size = Vector2(160, 80)
		btn.pressed.connect(_on_plant_button_pressed.bind(i))
		add_child(btn)
		plant_buttons.append(btn)

func _on_plant_button_pressed(idx: int) -> void:
	if game_over:
		return
	selected_plant_type = idx
	_update_hud()

func _on_tile_gui_input(event: InputEvent, col: int, row: int) -> void:
	if game_over:
		return
	if not (event is InputEventScreenTouch or event is InputEventMouseButton):
		return
	if event is InputEventMouseButton and not event.pressed:
		return
	if event is InputEventScreenTouch and not event.pressed:
		return
	_try_place_plant(col, row)

func _try_place_plant(col: int, row: int) -> void:
	if selected_plant_type < 0:
		message_label.text = "Wybierz roslin z paska ponizej"
		return
	if grid_occupancy[col][row] != null:
		message_label.text = "To pole jest zajete"
		return
	var pt = PLANT_TYPES[selected_plant_type]
	if water < pt["cost"]:
		message_label.text = "Za malo kropel wody"
		return
	water -= pt["cost"]
	var node := _make_sprite(pt["texture"], CELL - 16)
	node.position = Vector2(GRID_LEFT + col * CELL + 8, GRID_TOP + row * CELL + 8)
	add_child(node)
	var plant := {
		"node": node, "hp": pt["hp"], "col": col, "row": row,
		"type_idx": selected_plant_type, "atk_timer": 0.0
	}
	plants.append(plant)
	grid_occupancy[col][row] = plant
	message_label.text = ""
	selected_plant_type = -1
	_update_hud()

func _update_hud() -> void:
	water_label.text = "Krople wody: %d" % water
	if selected_plant_type >= 0:
		wave_label.text = "Wybrano: %s (tapnij pole ogrodu)" % PLANT_TYPES[selected_plant_type]["name"]
	else:
		wave_label.text = "Fala: %d / %d" % [current_wave, waves.size()]

func _process(delta: float) -> void:
	if game_over:
		return

	_update_economy(delta)
	_update_wave_spawning(delta)
	_update_plants(delta)
	_update_projectiles(delta)
	_update_enemies(delta)
	_check_win_condition()

func _update_economy(delta: float) -> void:
	water_income_timer += delta
	if water_income_timer >= WATER_INCOME_INTERVAL:
		water_income_timer = 0.0
		water += WATER_INCOME_AMOUNT
		if selected_plant_type < 0:
			_update_hud()
		else:
			water_label.text = "Krople wody: %d" % water

func _update_wave_spawning(delta: float) -> void:
	if current_wave >= waves.size():
		return

	if not wave_in_progress:
		between_waves_timer -= delta
		if between_waves_timer <= 0.0:
			wave_in_progress = true
			wave_spawn_queue = waves[current_wave].duplicate()
			time_to_next_spawn = 0.0
			message_label.text = "Fala %d nadchodzi!" % (current_wave + 1)
		return

	time_to_next_spawn -= delta
	if time_to_next_spawn <= 0.0 and wave_spawn_queue.size() > 0:
		var spawn_info = wave_spawn_queue.pop_front()
		_spawn_enemy(spawn_info["type"], spawn_info["row"])
		time_to_next_spawn = 1.5

	if wave_spawn_queue.is_empty() and enemies.is_empty() and wave_in_progress:
		wave_in_progress = false
		current_wave += 1
		between_waves_timer = 5.0
		_update_hud()

func _spawn_enemy(type_idx: int, row: int) -> void:
	var et = ENEMY_TYPES[type_idx]
	var node := _make_sprite(et["texture"], CELL - 16)
	var x := float(COLS * CELL)
	node.position = Vector2(x, GRID_TOP + row * CELL + 8)
	add_child(node)
	enemies.append({"node": node, "hp": et["hp"], "row": row, "x": x, "type_idx": type_idx})

func _update_plants(delta: float) -> void:
	for plant in plants:
		var pt = PLANT_TYPES[plant["type_idx"]]
		if pt["interval"] <= 0.0:
			continue
		plant["atk_timer"] -= delta
		if plant["atk_timer"] <= 0.0:
			var target := _find_enemy_in_row(plant["row"])
			if not target.is_empty():
				plant["atk_timer"] = pt["interval"]
				_spawn_projectile(plant["row"], plant["node"].position.x + CELL, pt["dmg"])

func _find_enemy_in_row(row: int) -> Dictionary:
	for e in enemies:
		if e["row"] == row:
			return e
	return {}

func _spawn_projectile(row: int, x: float, dmg: int) -> void:
	var node := _make_sprite(THORN_TEXTURE, 16)
	node.position = Vector2(x, GRID_TOP + row * CELL + CELL / 2 - 8)
	add_child(node)
	projectiles.append({"node": node, "row": row, "x": x, "dmg": dmg})

func _make_sprite(texture_path: String, target_size: int) -> TextureRect:
	var node := TextureRect.new()
	node.texture = load(texture_path)
	node.size = Vector2(target_size, target_size)
	node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node

func _update_projectiles(delta: float) -> void:
	var SPEED := 300.0
	var to_remove := []
	for proj in projectiles:
		proj["x"] += SPEED * delta
		proj["node"].position.x = proj["x"]
		var hit_enemy = null
		for e in enemies:
			if e["row"] == proj["row"] and abs(e["x"] - proj["x"]) < CELL / 2:
				hit_enemy = e
				break
		if hit_enemy != null:
			hit_enemy["hp"] -= proj["dmg"]
			to_remove.append(proj)
		elif proj["x"] > COLS * CELL:
			to_remove.append(proj)
	for proj in to_remove:
		proj["node"].queue_free()
		projectiles.erase(proj)

func _update_enemies(delta: float) -> void:
	var dead := []
	var reached_house := false
	for e in enemies:
		var et = ENEMY_TYPES[e["type_idx"]]
		if e["hp"] <= 0:
			dead.append(e)
			continue

		var blocking_plant = grid_occupancy_at_row_ahead(e)
		if blocking_plant != null:
			blocking_plant["hp"] -= et["dmg"] * delta
			if blocking_plant["hp"] <= 0:
				_remove_plant(blocking_plant)
		else:
			e["x"] -= et["speed"] * delta
			e["node"].position.x = e["x"]
			if e["x"] <= GRID_LEFT:
				reached_house = true

	for e in dead:
		e["node"].queue_free()
		enemies.erase(e)

	if reached_house:
		_lose_game()

func grid_occupancy_at_row_ahead(e: Dictionary):
	var col := int((e["x"] - GRID_LEFT) / CELL)
	col = clamp(col, 0, COLS - 1)
	var candidate = grid_occupancy[col][e["row"]]
	if candidate != null and abs((GRID_LEFT + col * CELL) - e["x"]) < CELL:
		return candidate
	return null

func _remove_plant(plant: Dictionary) -> void:
	grid_occupancy[plant["col"]][plant["row"]] = null
	plant["node"].queue_free()
	plants.erase(plant)

func _check_win_condition() -> void:
	if current_wave >= waves.size() and enemies.is_empty() and not wave_in_progress:
		_win_game()

func _lose_game() -> void:
	game_over = true
	message_label.text = "PRZEGRANA - smieci dotarly do domu!"

func _win_game() -> void:
	game_over = true
	message_label.text = "WYGRANA - obronles ogrod!"
