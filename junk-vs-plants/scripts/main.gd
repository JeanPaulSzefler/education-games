extends Node2D

# --- Viewport (landscape) ---
const VIEWPORT_WIDTH := 1280
const VIEWPORT_HEIGHT := 720

# --- Grid layout ---
const COLS := 13
const ROWS := 5
const CELL := 88
const GRID_LEFT := 68
const GRID_TOP := 92

# --- Enemy types (mix of junk). bite_interval/bite_dmg = jak czesto i ile
# szkodnik "odgryza" z rosliny, ktora go blokuje. ---
const ENEMY_TYPES := [
	{"name": "Butelka PET", "hp": 80, "speed": 18.0, "bite_dmg": 14, "bite_interval": 1.0, "texture": "res://assets/sprites/enemies/bottle.png"},
	{"name": "Puszka", "hp": 60, "speed": 26.0, "bite_dmg": 10, "bite_interval": 0.8, "texture": "res://assets/sprites/enemies/can.png"},
	{"name": "Kartonowy Golem", "hp": 220, "speed": 12.0, "bite_dmg": 24, "bite_interval": 1.2, "texture": "res://assets/sprites/enemies/cardboard_golem.png"},
]

const THORN_TEXTURE := "res://assets/sprites/ui/thorn.png"
const WATER_DROP_TEXTURE := "res://assets/sprites/ui/water_drop.png"
const FERTILIZER_TEXTURE := "res://assets/sprites/ui/fertilizer.svg"
const BOOST_RING_TEXTURE := "res://assets/sprites/ui/boost_ring.svg"

const HEALTH_BAR_HIDE_DELAY := 2.0
const HEALTH_BAR_HEIGHT := 6

# Kropla wody / nawozu: wizualny rozmiar ikony vs wieksze (niewidoczne) pole
# reagujace na tapniecie, zeby latwiej bylo ja zlapac.
const WATER_DROP_VISUAL_SIZE := 44
const WATER_DROP_TAP_SIZE := 88
const WATER_DROP_SPEED := 36.0
const FERTILIZER_VISUAL_SIZE := 40
const FERTILIZER_TAP_SIZE := 88

# Nawoz: tapniecie ikony nawozu w HUD, potem tapniecie wlasnej rosliny -
# roslina dostaje zloty pierscien i przez chwile mocno zwiekszona intensywnosc ataku.
const FERTILIZER_BOOST_MULTIPLIER := 2.5
const FERTILIZER_BOOST_DURATION := 9.0

# Boss: 1s przed atakiem specjalnym boss miga na czerwono (telegraf), zeby
# gracz mial szanse zareagowac (np. postawic Bumorzecha).
const BOSS_TELEGRAPH_TIME := 1.0

# --- Levels: kazdy poziom to lista fal, kazda fala to lista {type, row}.
# "boss" to indeks w BossData.TYPES, spawnowany po ostatniej fali. ---
# Fale mieszaja pojedynczych szkodnikow z wiekszymi grupami, ostatnia fala
# na kazdym poziomie jest najwieksza.
const LEVELS := [
	{
		"name": "Poziom 1 - Podworko",
		"boss": 0,
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
		"boss": 1,
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
		"boss": 2,
		"waves": [
			[{"type": 1, "row": 0}, {"type": 1, "row": 4}, {"type": 0, "row": 2}],
			[{"type": 2, "row": 2}],
			[{"type": 0, "row": 0}, {"type": 2, "row": 1}, {"type": 1, "row": 2}, {"type": 0, "row": 3}, {"type": 2, "row": 4}],
			[{"type": 1, "row": 1}, {"type": 1, "row": 2}, {"type": 1, "row": 3}],
			[{"type": 2, "row": 0}, {"type": 0, "row": 0}, {"type": 1, "row": 1}, {"type": 2, "row": 2}, {"type": 1, "row": 2}, {"type": 0, "row": 3}, {"type": 2, "row": 3}, {"type": 1, "row": 4}, {"type": 2, "row": 4}],
		],
	},
	{
		# Pierwsze utrudnienie: kaktus produkuje wode wolniej (mnoznik odstepu).
		"name": "Poziom 4 - Sortownia Odpadow",
		"boss": 3,
		"cactus_water_multiplier": 1.6,
		"waves": [
			[{"type": 2, "row": 2}],
			[{"type": 0, "row": 0}, {"type": 1, "row": 4}],
			[{"type": 1, "row": 1}, {"type": 1, "row": 2}, {"type": 1, "row": 3}],
			[{"type": 2, "row": 1}, {"type": 2, "row": 3}],
			[{"type": 0, "row": 0}, {"type": 2, "row": 0}, {"type": 1, "row": 1}, {"type": 0, "row": 1}, {"type": 2, "row": 2}, {"type": 1, "row": 3}, {"type": 0, "row": 3}, {"type": 2, "row": 4}, {"type": 1, "row": 4}],
		],
	},
	{
		# Drugie utrudnienie: dodatkowo pola na planszy, na ktorych nie mozna sadzic.
		"name": "Poziom 5 - Skladowisko",
		"boss": 4,
		"cactus_water_multiplier": 2.0,
		"blocked_tiles": [[4, 1], [4, 3], [2, 2]],
		"waves": [
			[{"type": 2, "row": 2}, {"type": 2, "row": 0}],
			[{"type": 0, "row": 1}, {"type": 1, "row": 1}, {"type": 0, "row": 3}, {"type": 1, "row": 3}],
			[{"type": 2, "row": 1}, {"type": 2, "row": 2}, {"type": 2, "row": 3}],
			[{"type": 1, "row": 0}, {"type": 1, "row": 1}, {"type": 1, "row": 2}, {"type": 1, "row": 3}, {"type": 1, "row": 4}],
			[{"type": 2, "row": 0}, {"type": 0, "row": 0}, {"type": 1, "row": 0}, {"type": 2, "row": 1}, {"type": 0, "row": 1}, {"type": 2, "row": 2}, {"type": 1, "row": 2}, {"type": 0, "row": 2}, {"type": 2, "row": 3}, {"type": 0, "row": 3}, {"type": 1, "row": 3}, {"type": 2, "row": 4}, {"type": 1, "row": 4}],
		],
	},
]

var PLANT_TYPES: Array
var BOSS_TYPES: Array
var waves := []
var current_wave := 0
var wave_spawn_queue := []
var time_to_next_spawn := 0.0
var between_waves_timer := 0.0
var wave_in_progress := false
var boss_spawned := false

var water := 150
var fertilizer := 0
var fertilizer_mode := false

var grid_occupancy := []
var blocked_cells := {}
var plants := []
var enemies := []
var projectiles := []
var water_drops := []
var fertilizer_drops := []
var selected_plant_type := -1
var game_over := false
var water_label: Label
var fertilizer_label: Label
var wave_label: Label
var message_label: Label
var plant_buttons := []
var fertilizer_button: Button
var boss_name_label: Label
var boss_bar_bg: ColorRect
var boss_bar_fg: ColorRect

func _ready() -> void:
	randomize()
	PLANT_TYPES = PlantData.TYPES
	BOSS_TYPES = BossData.TYPES
	waves = LEVELS[GameState.current_level_index]["waves"]
	between_waves_timer = 3.0
	_setup_grid_occupancy()
	_setup_blocked_cells()
	_build_background()
	_build_grid_visual()
	_build_hud()
	_build_plant_bar()
	_build_fertilizer_button()
	_update_hud()

func _current_level() -> Dictionary:
	return LEVELS[GameState.current_level_index]

func _cactus_water_multiplier() -> float:
	return _current_level().get("cactus_water_multiplier", 1.0)

func _cell_key(col: int, row: int) -> String:
	return "%d_%d" % [col, row]

func _setup_grid_occupancy() -> void:
	grid_occupancy.clear()
	for c in range(COLS):
		var col_arr := []
		for r in range(ROWS):
			col_arr.append(null)
		grid_occupancy.append(col_arr)

func _setup_blocked_cells() -> void:
	blocked_cells.clear()
	for pos in _current_level().get("blocked_tiles", []):
		blocked_cells[_cell_key(pos[0], pos[1])] = true

func _build_background() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.55, 0.45, 0.3)
	bg.position = Vector2(0, 0)
	bg.size = Vector2(VIEWPORT_WIDTH, GRID_TOP + ROWS * CELL)
	add_child(bg)

func _build_grid_visual() -> void:
	var grass_texture := load("res://assets/sprites/ui/grass_tile.png")
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
			if blocked_cells.has(_cell_key(c, r)):
				tile.modulate = tile.modulate.darkened(0.45)
				var blocked_overlay := ColorRect.new()
				blocked_overlay.color = Color(0.5, 0.1, 0.1, 0.4)
				blocked_overlay.size = Vector2(CELL - 2, CELL - 2)
				blocked_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
				tile.add_child(blocked_overlay)
			add_child(tile)

func _build_hud() -> void:
	var level_title := Label.new()
	level_title.text = LEVELS[GameState.current_level_index]["name"]
	level_title.position = Vector2(20, 4)
	level_title.add_theme_font_size_override("font_size", 16)
	add_child(level_title)

	water_label = Label.new()
	water_label.position = Vector2(20, 24)
	water_label.add_theme_font_size_override("font_size", 26)
	add_child(water_label)

	fertilizer_label = Label.new()
	fertilizer_label.position = Vector2(230, 30)
	fertilizer_label.add_theme_font_size_override("font_size", 20)
	fertilizer_label.add_theme_color_override("font_color", Color(0.85, 0.65, 0.15))
	add_child(fertilizer_label)

	wave_label = Label.new()
	wave_label.position = Vector2(20, 52)
	wave_label.add_theme_font_size_override("font_size", 18)
	add_child(wave_label)

	message_label = Label.new()
	message_label.position = Vector2(20, GRID_TOP + ROWS * CELL + 8)
	message_label.add_theme_font_size_override("font_size", 20)
	add_child(message_label)

	# Pasek HP bossa: na stale u gory ekranu, widoczny tylko gdy boss zyje.
	boss_name_label = Label.new()
	boss_name_label.position = Vector2(VIEWPORT_WIDTH / 2 - 150, 2)
	boss_name_label.add_theme_font_size_override("font_size", 18)
	boss_name_label.visible = false
	add_child(boss_name_label)

	boss_bar_bg = ColorRect.new()
	boss_bar_bg.color = Color(0.1, 0.1, 0.1, 0.85)
	boss_bar_bg.position = Vector2(VIEWPORT_WIDTH / 2 - 150, 24)
	boss_bar_bg.size = Vector2(300, 14)
	boss_bar_bg.visible = false
	add_child(boss_bar_bg)

	boss_bar_fg = ColorRect.new()
	boss_bar_fg.color = Color(0.8, 0.15, 0.15)
	boss_bar_fg.position = boss_bar_bg.position
	boss_bar_fg.size = Vector2(300, 14)
	boss_bar_fg.visible = false
	add_child(boss_bar_fg)

func _build_plant_bar() -> void:
	var bar_y := GRID_TOP + ROWS * CELL + 36
	for i in range(PLANT_TYPES.size()):
		var pt = PLANT_TYPES[i]
		var btn := Button.new()
		btn.text = "%s\n%d kropel" % [pt["name"], pt["cost"]]
		btn.position = Vector2(20 + i * 150, bar_y)
		btn.size = Vector2(140, 56)
		btn.pressed.connect(_on_plant_button_pressed.bind(i))
		add_child(btn)
		plant_buttons.append(btn)

func _build_fertilizer_button() -> void:
	var bar_y := GRID_TOP + ROWS * CELL + 96
	fertilizer_button = Button.new()
	fertilizer_button.position = Vector2(20, bar_y)
	fertilizer_button.size = Vector2(180, 40)
	fertilizer_button.pressed.connect(_on_fertilizer_button_pressed)
	add_child(fertilizer_button)

func _on_plant_button_pressed(idx: int) -> void:
	if game_over:
		return
	selected_plant_type = idx
	fertilizer_mode = false
	_update_hud()

func _on_fertilizer_button_pressed() -> void:
	if game_over or fertilizer <= 0:
		return
	fertilizer_mode = true
	selected_plant_type = -1
	_update_hud()

func _on_tile_gui_input(event: InputEvent, col: int, row: int) -> void:
	if game_over:
		return
	if not _is_tap_press(event):
		return
	if fertilizer_mode:
		_try_apply_fertilizer(col, row)
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
	if blocked_cells.has(_cell_key(col, row)):
		message_label.text = "Na tym polu nie mozna sadzic"
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

	# Zloty pierscien pokazywany tylko podczas dzialania nawozu.
	var ring := _make_sprite(BOOST_RING_TEXTURE, CELL)
	ring.position = Vector2(-8, -8)
	ring.visible = false
	node.add_child(ring)

	var plant := {
		"node": node, "hp": pt["hp"], "max_hp": pt["hp"], "col": col, "row": row,
		"type_idx": selected_plant_type, "atk_timer": 0.0,
		"gen_timer": pt.get("water_interval", 0.0) * _cactus_water_multiplier(),
		"bar": bar, "hurt_timer": HEALTH_BAR_HIDE_DELAY + 1.0,
		"boost_ring": ring, "boosted": false, "boost_timer": 0.0,
		"disable_timer": 0.0, "used": false,
		"fuse_timer": pt.get("fuse_time", 0.0),
		"poison_timer": 0.0, "poison_dmg": 0,
	}
	plants.append(plant)
	grid_occupancy[col][row] = plant
	message_label.text = ""
	selected_plant_type = -1
	_update_hud()

func _try_apply_fertilizer(col: int, row: int) -> void:
	var plant = grid_occupancy[col][row]
	if plant == null:
		message_label.text = "Brak rosliny na tym polu"
		return
	fertilizer -= 1
	fertilizer_mode = false
	plant["boosted"] = true
	plant["boost_timer"] = FERTILIZER_BOOST_DURATION
	plant["boost_ring"].visible = true
	message_label.text = ""
	_update_hud()

func _update_hud() -> void:
	water_label.text = "Krople wody: %d" % water
	fertilizer_label.text = "Nawozy: %d" % fertilizer
	fertilizer_button.text = "Uzyj nawozu (%d)" % fertilizer
	fertilizer_button.disabled = fertilizer <= 0
	if fertilizer_mode:
		wave_label.text = "Tryb nawozu: tapnij wlasna rosline, by ja wzmocnic"
	elif selected_plant_type >= 0:
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
	_update_boss_specials(delta)
	_update_boss_bar()
	_update_water_drops(delta)
	_update_fertilizer_drops(delta)
	_update_health_bars(delta)
	_check_win_condition()

# --- Fale ---
func _update_wave_spawning(delta: float) -> void:
	if current_wave < waves.size():
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
		return

	# Wszystkie fale zrobione - jesli poziom ma bossa, wystaw go po chwili.
	var boss_idx: int = _current_level().get("boss", -1)
	if boss_idx >= 0 and not boss_spawned and enemies.is_empty():
		between_waves_timer -= delta
		if between_waves_timer <= 0.0:
			boss_spawned = true
			message_label.text = "%s nadchodzi!" % BOSS_TYPES[boss_idx]["name"]
			_spawn_boss(boss_idx)

func _spawn_enemy(type_idx: int, row: int) -> void:
	var et = ENEMY_TYPES[type_idx]
	var node := _make_sprite(et["texture"], CELL - 16)
	var x := float(GRID_LEFT + COLS * CELL)
	node.position = Vector2(x, GRID_TOP + row * CELL + 8)
	add_child(node)
	var bar := _add_health_bar(node, CELL - 16)
	enemies.append({
		"node": node, "hp": et["hp"], "max_hp": et["hp"], "row": row, "x": x, "type_idx": type_idx,
		"speed": et["speed"], "bite_dmg": et["bite_dmg"], "bite_interval": et["bite_interval"],
		"bite_timer": 0.0, "bar": bar, "hurt_timer": HEALTH_BAR_HIDE_DELAY + 1.0,
		"slow_timer": 0.0, "slow_factor": 1.0, "is_boss": false,
	})

func _spawn_boss(boss_idx: int) -> void:
	var bt = BOSS_TYPES[boss_idx]
	var row := ROWS / 2
	var node := _make_sprite(bt["texture"], CELL - 4)
	var x := float(GRID_LEFT + COLS * CELL)
	node.position = Vector2(x, GRID_TOP + row * CELL + 2)
	add_child(node)
	var bar := _add_health_bar(node, CELL - 4)
	enemies.append({
		"node": node, "hp": bt["hp"], "max_hp": bt["hp"], "row": row, "x": x, "type_idx": -1,
		"speed": bt["speed"], "bite_dmg": bt["bite_dmg"], "bite_interval": bt["bite_interval"],
		"bite_timer": 0.0, "bar": bar, "hurt_timer": HEALTH_BAR_HIDE_DELAY + 1.0,
		"slow_timer": 0.0, "slow_factor": 1.0,
		"is_boss": true, "boss_type_idx": boss_idx,
		"special_timer": bt["special_interval"], "telegraphing": false,
	})
	_show_boss_bar(bt["name"])

# --- Rosliny: strzelanie, generowanie wody i akcje jednorazowe ---
func _update_plants(delta: float) -> void:
	var dead := []
	for plant in plants:
		if plant["boost_timer"] > 0.0:
			plant["boost_timer"] -= delta
			if plant["boost_timer"] <= 0.0:
				plant["boosted"] = false
				plant["boost_ring"].visible = false
		if plant["disable_timer"] > 0.0:
			plant["disable_timer"] -= delta
		if plant["poison_timer"] > 0.0:
			plant["poison_timer"] -= delta
			if plant["poison_timer"] <= 0.0:
				plant["hp"] -= plant["poison_dmg"]
				_flash_health_bar(plant)

		var pt = PLANT_TYPES[plant["type_idx"]]
		var boost: float = FERTILIZER_BOOST_MULTIPLIER if plant["boosted"] else 1.0

		match pt["role"]:
			"shooter":
				if plant["disable_timer"] <= 0.0:
					plant["atk_timer"] -= delta * boost
					if plant["atk_timer"] <= 0.0:
						var target := _find_enemy_in_row(plant["row"])
						if not target.is_empty():
							plant["atk_timer"] = pt["interval"]
							_spawn_projectile(plant["row"], plant["node"].position.x + CELL, pt["dmg"] * boost, pt.get("pierce", false))
			"generator":
				plant["gen_timer"] -= delta
				if plant["gen_timer"] <= 0.0:
					plant["gen_timer"] = pt["water_interval"] * _cactus_water_multiplier()
					_spawn_water_drop(plant["node"].position, pt["water_value"])
			"bomb":
				if not plant["used"]:
					plant["fuse_timer"] -= delta
					if plant["fuse_timer"] <= 0.0:
						plant["used"] = true
						_trigger_bomb(plant, pt)
			_:
				pass

		if plant["hp"] <= 0:
			dead.append(plant)

	for plant in dead:
		_remove_plant(plant)

func _find_enemy_in_row(row: int) -> Dictionary:
	for e in enemies:
		if e["row"] == row:
			return e
	return {}

func _spawn_projectile(row: int, x: float, dmg: float, pierce: bool = false) -> void:
	var node := _make_sprite(THORN_TEXTURE, 16)
	node.position = Vector2(x, GRID_TOP + row * CELL + CELL / 2 - 8)
	add_child(node)
	projectiles.append({"node": node, "row": row, "x": x, "dmg": dmg, "pierce": pierce, "hit_enemies": []})

func _update_projectiles(delta: float) -> void:
	var speed := 300.0
	var to_remove := []
	for proj in projectiles:
		proj["x"] += speed * delta
		proj["node"].position.x = proj["x"]
		for e in enemies:
			if e["row"] == proj["row"] and abs(e["x"] - proj["x"]) < CELL / 2 and not proj["hit_enemies"].has(e):
				e["hp"] -= proj["dmg"]
				_flash_health_bar(e)
				proj["hit_enemies"].append(e)
				if not proj["pierce"]:
					to_remove.append(proj)
					break
		if proj["x"] > GRID_LEFT + COLS * CELL and not to_remove.has(proj):
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

		var blocking_plant = _plant_ahead(e)
		if blocking_plant != null:
			var bpt = PLANT_TYPES[blocking_plant["type_idx"]]

			# Rosliny jednorazowe reagujace na kontakt: aktywuja sie raz i znikaja.
			if bpt["role"] == "freeze" and not blocking_plant["used"]:
				blocking_plant["used"] = true
				_trigger_freeze(blocking_plant, bpt)
				e["bite_timer"] = 0.0
				continue
			if bpt["role"] == "gust" and not blocking_plant["used"]:
				blocking_plant["used"] = true
				_trigger_gust(blocking_plant, bpt)
				e["bite_timer"] = 0.0
				continue

			var slow_mult: float = e["slow_factor"] if e["slow_timer"] > 0.0 else 1.0
			e["bite_timer"] -= delta * slow_mult
			if e["bite_timer"] <= 0.0:
				e["bite_timer"] = e["bite_interval"]
				blocking_plant["hp"] -= e["bite_dmg"]
				_flash_health_bar(blocking_plant)
				if bpt["role"] == "melee":
					e["hp"] -= bpt["counter_dmg"]
					_flash_health_bar(e)
				if blocking_plant["hp"] <= 0:
					_remove_plant(blocking_plant)
		else:
			e["bite_timer"] = 0.0
			var slow_mult2: float = e["slow_factor"] if e["slow_timer"] > 0.0 else 1.0
			e["x"] -= e["speed"] * slow_mult2 * delta
			e["node"].position.x = e["x"]
			if e["x"] <= GRID_LEFT:
				reached_house = true

		if e["slow_timer"] > 0.0:
			e["slow_timer"] -= delta
			if e["slow_timer"] <= 0.0:
				e["node"].modulate = Color(1, 1, 1)

	for e in dead:
		e["node"].queue_free()
		enemies.erase(e)

	if reached_house:
		_lose_game()

func _plant_ahead(e: Dictionary) -> Variant:
	var col := int((e["x"] - GRID_LEFT) / CELL)
	col = clamp(col, 0, COLS - 1)
	var candidate = grid_occupancy[col][e["row"]]
	if candidate != null and abs((GRID_LEFT + col * CELL) - e["x"]) < CELL:
		return candidate
	return null

func _remove_plant(plant: Dictionary, drop_fertilizer: bool = true) -> void:
	grid_occupancy[plant["col"]][plant["row"]] = null
	if drop_fertilizer:
		_spawn_fertilizer_drop(plant["node"].position)
	plant["node"].queue_free()
	plants.erase(plant)

# --- Rosliny jednorazowe: mrozoroslinka, bumorzech, wichurowy ---
func _trigger_freeze(plant: Dictionary, pt: Dictionary) -> void:
	for e in enemies:
		if e["row"] == plant["row"]:
			e["slow_timer"] = pt["slow_duration"]
			e["slow_factor"] = pt["slow_factor"]
			e["node"].modulate = Color(0.6, 0.85, 1.0)
	_remove_plant(plant, false)

func _trigger_gust(plant: Dictionary, pt: Dictionary) -> void:
	var dead := []
	for e in enemies:
		if e["row"] == plant["row"]:
			e["hp"] -= pt["gust_dmg"]
			_flash_health_bar(e)
			e["x"] = min(e["x"] + pt["knockback"], float(GRID_LEFT + COLS * CELL))
			e["node"].position.x = e["x"]
			if e["hp"] <= 0:
				dead.append(e)
	for e in dead:
		e["node"].queue_free()
		enemies.erase(e)
	_remove_plant(plant, false)

func _trigger_bomb(plant: Dictionary, pt: Dictionary) -> void:
	var blast_x := float(GRID_LEFT + plant["col"] * CELL)
	var radius_cells: int = pt["blast_radius_cells"]
	var dead := []
	for e in enemies:
		if abs(e["row"] - plant["row"]) <= radius_cells and abs(e["x"] - blast_x) <= CELL * (radius_cells + 0.9):
			e["hp"] -= pt["blast_dmg"]
			_flash_health_bar(e)
			if e["hp"] <= 0:
				dead.append(e)
	for e in dead:
		e["node"].queue_free()
		enemies.erase(e)
	_remove_plant(plant, false)

# --- Bossowie: telegrafowany atak specjalny ---
func _update_boss_specials(delta: float) -> void:
	for e in enemies:
		if not e["is_boss"]:
			continue
		e["special_timer"] -= delta
		if e["special_timer"] <= BOSS_TELEGRAPH_TIME and not e["telegraphing"]:
			e["telegraphing"] = true
			e["node"].modulate = Color(1.0, 0.35, 0.35)
		if e["special_timer"] <= 0.0:
			_trigger_boss_special(e)
			e["telegraphing"] = false
			e["node"].modulate = Color(1, 1, 1)
			e["special_timer"] = BOSS_TYPES[e["boss_type_idx"]]["special_interval"]

func _trigger_boss_special(e: Dictionary) -> void:
	var bt = BOSS_TYPES[e["boss_type_idx"]]
	match bt["special"]:
		"power_bite":
			var bite_target = _plant_ahead(e)
			if bite_target != null:
				var dmg := int(e["bite_dmg"] * bt["power_bite_multiplier"])
				bite_target["hp"] -= dmg
				_flash_health_bar(bite_target)
				if bite_target["hp"] <= 0:
					_remove_plant(bite_target)
		"phase_jump":
			var jump_target = _plant_ahead(e)
			if jump_target != null:
				e["x"] -= CELL
				e["node"].position.x = e["x"]
		"row_crush":
			for plant in plants:
				if plant["row"] == e["row"]:
					plant["hp"] -= bt["row_crush_dmg"]
					_flash_health_bar(plant)
			for plant in plants.duplicate():
				if plant["row"] == e["row"] and plant["hp"] <= 0:
					_remove_plant(plant)
		"magnet_pulse":
			for plant in plants:
				if plant["row"] == e["row"]:
					plant["disable_timer"] = bt["disable_duration"]
		"toxic_cloud":
			var poison_target = _plant_ahead(e)
			if poison_target != null:
				poison_target["poison_timer"] = bt["poison_delay"]
				poison_target["poison_dmg"] = bt["poison_dmg"]

func _show_boss_bar(boss_name: String) -> void:
	boss_name_label.text = boss_name
	boss_name_label.visible = true
	boss_bar_bg.visible = true
	boss_bar_fg.visible = true
	boss_bar_fg.size.x = 300

func _update_boss_bar() -> void:
	var boss = null
	for e in enemies:
		if e["is_boss"]:
			boss = e
			break
	if boss == null:
		if boss_bar_bg.visible:
			boss_bar_bg.visible = false
			boss_bar_fg.visible = false
			boss_name_label.visible = false
		return
	var ratio: float = clamp(float(boss["hp"]) / float(boss["max_hp"]), 0.0, 1.0)
	boss_bar_fg.size.x = 300 * ratio

# --- Krople wody: pojawiaja sie z Kaktusa, lataja losowo nad plansza odbijajac
# sie od jej krawedzi, i czekaja na tapniecie (nie znikaja same) ---
func _spawn_water_drop(origin: Vector2, value: int) -> void:
	# hit_area to wieksze, niewidoczne pole reagujace na tapniecie; visual to
	# mniejsza ikonka kropli wysrodkowana wewnatrz niego.
	var hit_area := Control.new()
	hit_area.size = Vector2(WATER_DROP_TAP_SIZE, WATER_DROP_TAP_SIZE)
	var visual_offset := (WATER_DROP_TAP_SIZE - WATER_DROP_VISUAL_SIZE) / 2
	hit_area.position = origin + Vector2(CELL / 2 - WATER_DROP_TAP_SIZE / 2, -10 - visual_offset)
	hit_area.position.x = clamp(hit_area.position.x, GRID_LEFT, GRID_LEFT + COLS * CELL - WATER_DROP_TAP_SIZE)
	hit_area.position.y = clamp(hit_area.position.y, GRID_TOP, GRID_TOP + ROWS * CELL - WATER_DROP_TAP_SIZE)
	hit_area.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(hit_area)

	var visual := _make_sprite(WATER_DROP_TEXTURE, WATER_DROP_VISUAL_SIZE)
	visual.position = Vector2(visual_offset, visual_offset)
	hit_area.add_child(visual)

	var angle := randf_range(0.0, TAU)
	var drop := {
		"node": hit_area,
		"vx": cos(angle) * WATER_DROP_SPEED,
		"vy": sin(angle) * WATER_DROP_SPEED,
		"value": value,
	}
	hit_area.gui_input.connect(_on_water_drop_gui_input.bind(drop))
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
	var min_x := float(GRID_LEFT)
	var max_x := float(GRID_LEFT + COLS * CELL - WATER_DROP_TAP_SIZE)
	var min_y := float(GRID_TOP)
	var max_y := float(GRID_TOP + ROWS * CELL - WATER_DROP_TAP_SIZE)
	for drop in water_drops:
		var node: Control = drop["node"]
		var pos: Vector2 = node.position + Vector2(drop["vx"], drop["vy"]) * delta
		if pos.x < min_x or pos.x > max_x:
			drop["vx"] *= -1.0
			pos.x = clamp(pos.x, min_x, max_x)
		if pos.y < min_y or pos.y > max_y:
			drop["vy"] *= -1.0
			pos.y = clamp(pos.y, min_y, max_y)
		node.position = pos

# --- Nawozy: pojawiaja sie po pokonaniu rosliny, zbierane tapnieciem ---
func _spawn_fertilizer_drop(origin: Vector2) -> void:
	var hit_area := Control.new()
	hit_area.size = Vector2(FERTILIZER_TAP_SIZE, FERTILIZER_TAP_SIZE)
	var visual_offset := (FERTILIZER_TAP_SIZE - FERTILIZER_VISUAL_SIZE) / 2
	hit_area.position = origin + Vector2(CELL / 2 - FERTILIZER_TAP_SIZE / 2, -10 - visual_offset)
	hit_area.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(hit_area)

	var visual := _make_sprite(FERTILIZER_TEXTURE, FERTILIZER_VISUAL_SIZE)
	visual.position = Vector2(visual_offset, visual_offset)
	hit_area.add_child(visual)

	var drop := {"node": hit_area, "vx": randf_range(-10.0, 10.0), "vy": randf_range(20.0, 34.0), "life": 6.0}
	hit_area.gui_input.connect(_on_fertilizer_drop_gui_input.bind(drop))
	fertilizer_drops.append(drop)

func _on_fertilizer_drop_gui_input(event: InputEvent, drop: Dictionary) -> void:
	if not _is_tap_press(event):
		return
	if not fertilizer_drops.has(drop):
		return
	fertilizer += 1
	drop["node"].queue_free()
	fertilizer_drops.erase(drop)
	_update_hud()

func _update_fertilizer_drops(delta: float) -> void:
	var to_remove := []
	for drop in fertilizer_drops:
		drop["node"].position.y -= drop["vy"] * delta
		drop["node"].position.x += drop["vx"] * delta
		drop["life"] -= delta
		if drop["life"] <= 0.0:
			to_remove.append(drop)
	for drop in to_remove:
		drop["node"].queue_free()
		fertilizer_drops.erase(drop)

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
	# Kolejnosc ma znaczenie: expand_mode/stretch_mode musza byc ustawione
	# PRZED size, inaczej Control chwilowo liczy minimalny rozmiar na
	# podstawie natywnej rozdzielczosci tekstury i "zatrzaskuje" node na tym
	# duzym rozmiarze, zanim zdazymy powiedziec mu, zeby ja ignorowal.
	node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	node.size = Vector2(target_size, target_size)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node

# --- Koniec gry ---
func _check_win_condition() -> void:
	if current_wave < waves.size():
		return
	if not enemies.is_empty() or wave_in_progress:
		return
	var boss_idx: int = _current_level().get("boss", -1)
	if boss_idx >= 0 and not boss_spawned:
		return
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
	var y := GRID_TOP + ROWS * CELL + 150
	var retry_btn := Button.new()
	retry_btn.text = "Zagraj ponownie"
	retry_btn.position = Vector2(20, y)
	retry_btn.size = Vector2(250, 40)
	retry_btn.pressed.connect(func(): get_tree().reload_current_scene())
	add_child(retry_btn)

	var select_btn := Button.new()
	select_btn.text = "Wybierz poziom"
	select_btn.position = Vector2(290, y)
	select_btn.size = Vector2(250, 40)
	select_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/LevelSelect.tscn"))
	add_child(select_btn)
