extends Node2D

# --- Grid layout ---
const COLS := 8
const ROWS := 5
const CELL := 90
const GRID_LEFT := 0
const GRID_TOP := 160

# --- Enemy types (mix of junk). bite_interval/bite_dmg = jak czesto i ile
# szkodnik "odgryza" z rosliny, ktora go blokuje. ---
const ENEMY_TYPES := [
	{"name": "Butelka PET", "hp": 80, "speed": 18.0, "bite_dmg": 14, "bite_interval": 1.0, "texture": "res://assets/sprites/enemies/bottle.svg"},
	{"name": "Puszka", "hp": 60, "speed": 26.0, "bite_dmg": 10, "bite_interval": 0.8, "texture": "res://assets/sprites/enemies/can.svg"},
	{"name": "Kartonowy Golem", "hp": 220, "speed": 12.0, "bite_dmg": 24, "bite_interval": 1.2, "texture": "res://assets/sprites/enemies/cardboard_golem.svg"},
]

const THORN_TEXTURE := "res://assets/sprites/ui/thorn.svg"
const WATER_DROP_TEXTURE := "res://assets/sprites/ui/water_drop.svg"

const HEALTH_BAR_HIDE_DELAY := 2.0
const HEALTH_BAR_HEIGHT := 6

# --- Levels: kazdy poziom to lista fal, kazda fala to lista {type, row} ---
# Fale mieszaja pojedynczych szkodnikow z wiekszymi grupami, ostatnia fala
# na kazdym poziomie jest najwieksza.
const LEVELS := [
	{
		"name": "Poziom 1 - Podworko",
		"waves": [
			[{"type": 0, "row": 2}],
			[{"type": 0, "row": 1}, {"type": 1, "row": 3}],
			[{"type": 2, "row": 2}],
			[{"type": 0, "row": 0}, {"type": 1, "row": 2}, {"type": 0, "row": 4}],
			[{"type": 0, "row": 0}, {"type": 1, "row": 1}, {"type": 0, "row": 2}, {"type": 1, "row": 3}, {"type": 2, "row": 4}, {"type": 1, "row": 2}],
		],
	},
	{
		"name": "Poziom 2 - Park",
		"waves": [
			[{"type": 0, "row": 1}, {"type": 0, "row": 3}],
			[{"type": 2, "row": 2}],
			[{"type": 1, "row": 0}, {"type": 1, "row": 1}, {"type": 0, "row": 3}, {"type": 1, "row": 4}],
			[{"type": 1, "row": 2}, {"type": 1, "row": 3}],
			[{"type": 0, "row": 0}, {"type": 2, "row": 1}, {"type": 1, "row": 2}, {"type": 0, "row": 2}, {"type": 2, "row": 3}, {"type": 1, "row": 4}, {"type": 1, "row": 0}],
		],
	},
	{
		"name": "Poziom 3 - Wysypisko",
		"waves": [
			[{"type": 1, "row": 0}, {"type": 1, "row": 4}, {"type": 0, "row": 2}],
			[{"type": 2, "row": 2}],
			[{"type": 0, "row": 0}, {"type": 2, "row": 1}, {"type": 1, "row": 2}, {"type": 0, "row": 3}, {"type": 2, "row": 4}],
			[{"type": 1, "row": 1}, {"type": 1, "row": 2}, {"type": 1, "row": 3}],
			[{"type": 2, "row": 0}, {"type": 0, "row": 0}, {"type": 1, "row": 1}, {"type": 2, "row": 2}, {"type": 1, "row": 2}, {"type": 0, "row": 3}, {"type": 2, "row": 3}, {"type": 1, "row": 4}, {"type": 2, "row": 4}],
		],
	},
]

var PLANT_TYPES: Array
var waves := []
var current_wave := 0
var wave_spawn_queue := []
var time_to_next_spawn := 0.0
var between_waves_timer := 0.0
var wave_in_progress := false

var water := 150

var grid_occupancy := []
var plants := []
var enemies := []
var projectiles := []
var water_drops := []
var selected_plant_type := -1
var game_over := false
var water_label: Label
var wave_label: Label
var message_label: Label
var plant_buttons := []

func _ready() -> void:
	randomize()
	PLANT_TYPES = PlantData.TYPES
	waves = LEVELS[GameState.current_level_index]["waves"]
	between_waves_timer = 3.0
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
	var level_title := Label.new()
	level_title.text = LEVELS[GameState.current_level_index]["name"]
	level_title.position = Vector2(20, 10)
	level_title.add_theme_font_size_override("font_size", 20)
	add_child(level_title)

	water_label = Label.new()
	water_label.position = Vector2(20, 40)
	water_label.add_theme_font_size_override("font_size", 30)
	add_child(water_label)

	wave_label = Label.new()
	wave_label.position = Vector2(20, 78)
	wave_label.add_theme_font_size_override("font_size", 22)
	add_child(wave_label)

	message_label = Label.new()
	message_label.position = Vector2(20, GRID_TOP + ROWS * CELL + 20)
	message_label.add_theme_font_size_override("font_size", 26)
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
	if not _is_tap_press(event):
		return
	_try_place_plant(col, row)

func _is_tap_press(event: InputEvent) -> bool:
	if event is InputEventScreenTouch:
		return event.pressed
	if event is InputEventMouseButton:
		return event.pressed
	return false

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
	var bar := _add_health_bar(node, CELL - 16)
	var plant := {
		"node": node, "hp": pt["hp"], "max_hp": pt["hp"], "col": col, "row": row,
		"type_idx": selected_plant_type, "atk_timer": 0.0, "gen_timer": pt.get("water_interval", 0.0),
		"bar": bar, "hurt_timer": HEALTH_BAR_HIDE_DELAY + 1.0,
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

	_update_wave_spawning(delta)
	_update_plants(delta)
	_update_projectiles(delta)
	_update_enemies(delta)
	_update_water_drops(delta)
	_update_health_bars(delta)
	_check_win_condition()

# --- Fale ---
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
		time_to_next_spawn = 1.1

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
	var bar := _add_health_bar(node, CELL - 16)
	enemies.append({
		"node": node, "hp": et["hp"], "max_hp": et["hp"], "row": row, "x": x, "type_idx": type_idx,
		"bite_timer": 0.0, "bar": bar, "hurt_timer": HEALTH_BAR_HIDE_DELAY + 1.0,
	})

# --- Rosliny: strzelanie i generowanie wody ---
func _update_plants(delta: float) -> void:
	for plant in plants:
		var pt = PLANT_TYPES[plant["type_idx"]]
		match pt["role"]:
			"shooter":
				plant["atk_timer"] -= delta
				if plant["atk_timer"] <= 0.0:
					var target := _find_enemy_in_row(plant["row"])
					if not target.is_empty():
						plant["atk_timer"] = pt["interval"]
						_spawn_projectile(plant["row"], plant["node"].position.x + CELL, pt["dmg"])
			"generator":
				plant["gen_timer"] -= delta
				if plant["gen_timer"] <= 0.0:
					plant["gen_timer"] = pt["water_interval"]
					_spawn_water_drop(plant["node"].position, pt["water_value"])
			_:
				pass

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

func _update_projectiles(delta: float) -> void:
	var speed := 300.0
	var to_remove := []
	for proj in projectiles:
		proj["x"] += speed * delta
		proj["node"].position.x = proj["x"]
		var hit_enemy = null
		for e in enemies:
			if e["row"] == proj["row"] and abs(e["x"] - proj["x"]) < CELL / 2:
				hit_enemy = e
				break
		if hit_enemy != null:
			hit_enemy["hp"] -= proj["dmg"]
			_flash_health_bar(hit_enemy)
			to_remove.append(proj)
		elif proj["x"] > COLS * CELL:
			to_remove.append(proj)
	for proj in to_remove:
		proj["node"].queue_free()
		projectiles.erase(proj)

# --- Szkodniki: ruch i "zjadanie" roslin ---
func _update_enemies(delta: float) -> void:
	var dead := []
	var reached_house := false
	for e in enemies:
		if e["hp"] <= 0:
			dead.append(e)
			continue

		var et = ENEMY_TYPES[e["type_idx"]]
		var blocking_plant = _plant_ahead(e)
		if blocking_plant != null:
			e["bite_timer"] -= delta
			if e["bite_timer"] <= 0.0:
				e["bite_timer"] = et["bite_interval"]
				blocking_plant["hp"] -= et["bite_dmg"]
				_flash_health_bar(blocking_plant)
				if blocking_plant["hp"] <= 0:
					_remove_plant(blocking_plant)
		else:
			e["bite_timer"] = 0.0
			e["x"] -= et["speed"] * delta
			e["node"].position.x = e["x"]
			if e["x"] <= GRID_LEFT:
				reached_house = true

	for e in dead:
		e["node"].queue_free()
		enemies.erase(e)

	if reached_house:
		_lose_game()

func _plant_ahead(e: Dictionary):
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

# --- Krople wody: pojawiaja sie z Kaktusa, uciekaja w gore, zbierane tapnieciem ---
func _spawn_water_drop(origin: Vector2, value: int) -> void:
	var node := _make_sprite(WATER_DROP_TEXTURE, 44)
	node.position = origin + Vector2(CELL / 2 - 22, -10)
	node.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(node)
	var drop := {"node": node, "vx": randf_range(-10.0, 10.0), "vy": randf_range(24.0, 40.0), "life": 6.0, "value": value}
	node.gui_input.connect(_on_water_drop_gui_input.bind(drop))
	water_drops.append(drop)

func _on_water_drop_gui_input(event: InputEvent, drop: Dictionary) -> void:
	if not _is_tap_press(event):
		return
	if not water_drops.has(drop):
		return
	water += drop["value"]
	drop["node"].queue_free()
	water_drops.erase(drop)
	_update_hud()

func _update_water_drops(delta: float) -> void:
	var to_remove := []
	for drop in water_drops:
		drop["node"].position.y -= drop["vy"] * delta
		drop["node"].position.x += drop["vx"] * delta
		drop["life"] -= delta
		if drop["life"] <= 0.0:
			to_remove.append(drop)
	for drop in to_remove:
		drop["node"].queue_free()
		water_drops.erase(drop)

# --- Paski zycia: widoczne tylko podczas ataku ---
func _add_health_bar(parent_node: Control, width: int) -> Dictionary:
	var bg := ColorRect.new()
	bg.color = Color(0.1, 0.1, 0.1, 0.8)
	bg.position = Vector2(0, -12)
	bg.size = Vector2(width, HEALTH_BAR_HEIGHT)
	bg.visible = false
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent_node.add_child(bg)

	var fg := ColorRect.new()
	fg.color = Color(0.2, 0.85, 0.3)
	fg.position = Vector2(0, -12)
	fg.size = Vector2(width, HEALTH_BAR_HEIGHT)
	fg.visible = false
	fg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent_node.add_child(fg)

	return {"bg": bg, "fg": fg, "width": width}

func _flash_health_bar(entity: Dictionary) -> void:
	entity["hurt_timer"] = 0.0
	var bar = entity["bar"]
	var ratio: float = clamp(float(entity["hp"]) / float(entity["max_hp"]), 0.0, 1.0)
	bar["bg"].visible = true
	bar["fg"].visible = true
	bar["fg"].size.x = bar["width"] * ratio
	bar["fg"].color = Color(0.85, 0.2, 0.2) if ratio < 0.34 else (Color(0.9, 0.8, 0.2) if ratio < 0.7 else Color(0.2, 0.85, 0.3))

func _update_health_bars(delta: float) -> void:
	for plant in plants:
		plant["hurt_timer"] += delta
		if plant["hurt_timer"] > HEALTH_BAR_HIDE_DELAY:
			plant["bar"]["bg"].visible = false
			plant["bar"]["fg"].visible = false
	for e in enemies:
		e["hurt_timer"] += delta
		if e["hurt_timer"] > HEALTH_BAR_HIDE_DELAY:
			e["bar"]["bg"].visible = false
			e["bar"]["fg"].visible = false

func _make_sprite(texture_path: String, target_size: int) -> TextureRect:
	var node := TextureRect.new()
	node.texture = load(texture_path)
	node.size = Vector2(target_size, target_size)
	node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node

# --- Koniec gry ---
func _check_win_condition() -> void:
	if current_wave >= waves.size() and enemies.is_empty() and not wave_in_progress:
		_win_game()

func _lose_game() -> void:
	game_over = true
	message_label.text = "PRZEGRANA - smieci dotarly do domu!"
	_show_end_buttons()

func _win_game() -> void:
	game_over = true
	message_label.text = "WYGRANA - obronles ogrod!"
	GameState.complete_level(GameState.current_level_index)
	_show_end_buttons()

func _show_end_buttons() -> void:
	var y := GRID_TOP + ROWS * CELL + 160
	var retry_btn := Button.new()
	retry_btn.text = "Zagraj ponownie"
	retry_btn.position = Vector2(20, y)
	retry_btn.size = Vector2(300, 70)
	retry_btn.pressed.connect(func(): get_tree().reload_current_scene())
	add_child(retry_btn)

	var select_btn := Button.new()
	select_btn.text = "Wybierz poziom"
	select_btn.position = Vector2(340, y)
	select_btn.size = Vector2(300, 70)
	select_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/LevelSelect.tscn"))
	add_child(select_btn)
