extends Node2D

# --- Viewport (landscape) ---
const VIEWPORT_WIDTH := 1280
const VIEWPORT_HEIGHT := 720

# --- Grid layout ---
const COLS := 10
const ROWS := 5
const CELL := 88
# 1280 - COLS * CELL - 68: po prawej zostaje ten sam margines co dawniej na
# wchodzacych wrogow.
const GRID_LEFT := 332
const GRID_TOP := 92
const GRID_CENTER_X := GRID_LEFT + COLS * CELL / 2.0

# --- Enemy types (mix of junk). bite_interval/bite_dmg = jak czesto i ile
# szkodnik "odgryza" z rosliny, ktora go blokuje. ---
const ENEMY_TYPES := [
	{"name": "Butelka PET", "hp": 80, "speed": 18.0, "bite_dmg": 14, "bite_interval": 1.0, "texture": "res://assets/sprites/enemies/bottle.png"},
	{"name": "Puszka", "hp": 60, "speed": 26.0, "bite_dmg": 10, "bite_interval": 0.8, "texture": "res://assets/sprites/enemies/can.png"},
	{"name": "Kartonowy Golem", "hp": 220, "speed": 12.0, "bite_dmg": 24, "bite_interval": 1.2, "texture": "res://assets/sprites/enemies/cardboard_golem.png"},
	# Brudna Gabka: kradnie krople wody zamiast (albo oprocz) gryzc rosliny -
	# patrz _update_water_theft().
	{"name": "Brudna Gabka", "hp": 50, "speed": 20.0, "bite_dmg": 8, "bite_interval": 1.0, "texture": "res://assets/sprites/enemies/sponge.png", "water_thief": true},
]

const THORN_TEXTURE := "res://assets/sprites/ui/thorn.png"
const WATER_DROP_TEXTURE := "res://assets/sprites/ui/water_drop.png"
const FERTILIZER_TEXTURE := "res://assets/sprites/ui/fertilizer.png"
const BOOST_RING_TEXTURE := "res://assets/sprites/ui/boost_ring.png"

const HEALTH_BAR_HIDE_DELAY := 2.0
const HEALTH_BAR_HEIGHT := 6

# Kropla wody / nawozu: wizualny rozmiar ikony vs wieksze (niewidoczne) pole
# reagujace na tapniecie, zeby latwiej bylo ja zlapac.
const WATER_DROP_VISUAL_SIZE := 44
const WATER_DROP_TAP_SIZE := 88
const WATER_DROP_SPEED := 36.0
# Brudna Gabka: predkosc, z jaka skradziona kropla "dolatuje" do stwora
# (celowo wolniej niz normalny lot kropli, zeby gracz mial szanse ja odzyskac).
const WATER_DROP_STEAL_SPEED := 22.0
const WATER_DROP_STOLEN_COLOR := Color(0.42, 0.4, 0.18)
const FERTILIZER_VISUAL_SIZE := 40
const FERTILIZER_TAP_SIZE := 88

# Nawoz: tapniecie ikony nawozu w HUD, potem tapniecie wlasnej rosliny -
# roslina dostaje zloty pierscien i przez chwile mocno zwiekszona intensywnosc ataku.
const FERTILIZER_BOOST_MULTIPLIER := 2.5
const FERTILIZER_BOOST_DURATION := 9.0

# Boss: 1s przed atakiem specjalnym boss miga na czerwono (telegraf), zeby
# gracz mial szanse zareagowac (np. postawic Bumorzecha).
const BOSS_TELEGRAPH_TIME := 1.0

# --- Pionowy pasek po lewej (licznik wody, kafelki roslin, nawoz) ---
const SIDEBAR_X := 16.0
const SIDEBAR_TOP := 16.0
const WATER_ICON_SIZE := 40
const TILE_WIDTH := 300.0
const TILE_HEIGHT := 76.0
const TILE_GAP := 8.0
const TILE_ICON_SIZE := 64
const TILE_BORDER_COLOR := Color(0.35, 0.3, 0.22)
const TILE_SELECTED_BORDER_COLOR := Color(0.95, 0.85, 0.15)
const TILE_UNAFFORDABLE_MODULATE := Color(0.45, 0.45, 0.45)

const START_WATER := 100

var PLANT_TYPES: Array
var BOSS_TYPES: Array
var waves := []
var current_wave := 0
var wave_spawn_queue := []
var time_to_next_spawn := 0.0
var between_waves_timer := 0.0
var wave_in_progress := false
var boss_spawned := false

var water := START_WATER
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
var water_count_label: Label
var wave_label: Label
var message_label: Label
# {"plant_idx", "button", "border_sb"} - jeden wpis na kafelek rosliny w pasku
var plant_tiles := []
# {"button", "border_sb", "count_label"} - kafelek nawozu (ten sam styl co rosliny)
var fertilizer_tile: Dictionary
var boss_name_label: Label
var boss_bar_bg: ColorRect
var boss_bar_fg: ColorRect

# Tekstura ostatniego wroga/bossa, ktory dotarl do domu - do duzej ikonki na
# ekranie przegranej (runda C, C7).
var last_enemy_texture := ""

func _ready() -> void:
	randomize()
	PLANT_TYPES = PlantData.TYPES
	BOSS_TYPES = BossData.TYPES
	waves = LevelData.LEVELS[GameState.current_level_index]["waves"]
	between_waves_timer = 3.0
	_setup_grid_occupancy()
	_setup_blocked_cells()
	_build_background()
	_build_grid_visual()
	_build_hud()
	_build_water_counter()
	_build_plant_bar()
	_build_fertilizer_tile()
	_update_hud()

func _current_level() -> Dictionary:
	return LevelData.LEVELS[GameState.current_level_index]

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
	bg.size = Vector2(VIEWPORT_WIDTH, VIEWPORT_HEIGHT)
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
	level_title.text = LevelData.LEVELS[GameState.current_level_index]["name"]
	level_title.position = Vector2(GRID_LEFT, 4)
	level_title.add_theme_font_size_override("font_size", 16)
	add_child(level_title)

	wave_label = Label.new()
	wave_label.position = Vector2(GRID_LEFT, 26)
	wave_label.add_theme_font_size_override("font_size", 18)
	add_child(wave_label)

	message_label = Label.new()
	message_label.position = Vector2(GRID_LEFT, GRID_TOP + ROWS * CELL + 8)
	message_label.add_theme_font_size_override("font_size", 20)
	add_child(message_label)

	# Pasek HP bossa: na stale nad siatka, wysrodkowany wzgledem niej (nie
	# calego ekranu, bo po lewej jest teraz pasek roslin), widoczny tylko
	# gdy boss zyje.
	boss_name_label = Label.new()
	boss_name_label.position = Vector2(GRID_CENTER_X - 150, 2)
	boss_name_label.add_theme_font_size_override("font_size", 18)
	boss_name_label.visible = false
	add_child(boss_name_label)

	boss_bar_bg = ColorRect.new()
	boss_bar_bg.color = Color(0.1, 0.1, 0.1, 0.85)
	boss_bar_bg.position = Vector2(GRID_CENTER_X - 150, 24)
	boss_bar_bg.size = Vector2(300, 14)
	boss_bar_bg.visible = false
	add_child(boss_bar_bg)

	boss_bar_fg = ColorRect.new()
	boss_bar_fg.color = Color(0.8, 0.15, 0.15)
	boss_bar_fg.position = boss_bar_bg.position
	boss_bar_fg.size = Vector2(300, 14)
	boss_bar_fg.visible = false
	add_child(boss_bar_fg)

func _build_water_counter() -> void:
	var icon := _make_sprite(WATER_DROP_TEXTURE, WATER_ICON_SIZE)
	icon.position = Vector2(SIDEBAR_X, SIDEBAR_TOP)
	add_child(icon)

	water_count_label = Label.new()
	water_count_label.position = Vector2(SIDEBAR_X + WATER_ICON_SIZE + 10, SIDEBAR_TOP - 4)
	water_count_label.add_theme_font_size_override("font_size", 30)
	add_child(water_count_label)

func _sidebar_tiles_top() -> float:
	return SIDEBAR_TOP + WATER_ICON_SIZE + 18.0

# Wspolny wyglad kafelka w pasku po lewej (roslina albo nawoz): Button z
# wlasnym StyleBoxFlat i ikonka po lewej; dzieci maja mouse_filter = IGNORE,
# zeby tapniecie zawsze trafialo w sam przycisk.
func _build_tile(y: float, icon_texture: String) -> Dictionary:
	var btn := Button.new()
	btn.position = Vector2(SIDEBAR_X, y)
	btn.size = Vector2(TILE_WIDTH, TILE_HEIGHT)
	btn.flat = true
	btn.focus_mode = Control.FOCUS_NONE

	var border_sb := StyleBoxFlat.new()
	border_sb.bg_color = Color(0.16, 0.22, 0.14)
	border_sb.border_width_left = 4
	border_sb.border_width_right = 4
	border_sb.border_width_top = 4
	border_sb.border_width_bottom = 4
	border_sb.border_color = TILE_BORDER_COLOR
	border_sb.corner_radius_top_left = 10
	border_sb.corner_radius_top_right = 10
	border_sb.corner_radius_bottom_left = 10
	border_sb.corner_radius_bottom_right = 10
	for state in ["normal", "hover", "pressed"]:
		btn.add_theme_stylebox_override(state, border_sb)
	add_child(btn)

	var icon := _make_sprite(icon_texture, TILE_ICON_SIZE)
	icon.position = Vector2(10, (TILE_HEIGHT - TILE_ICON_SIZE) / 2.0)
	btn.add_child(icon)

	return {"button": btn, "border_sb": border_sb}

func _build_plant_bar() -> void:
	var tiles_top := _sidebar_tiles_top()
	var loadout: Array = GameState.current_loadout
	if loadout.is_empty():
		# Np. Main.tscn odpalone wprost z edytora, bez przejscia przez
		# PlantSelect - pokaz wszystkie odblokowane rosliny (max talia).
		var unlocked := GameState.unlocked_plant_indices()
		loadout = unlocked.slice(0, min(GameState.MAX_LOADOUT, unlocked.size()))
	plant_tiles.clear()
	for i in range(loadout.size()):
		var plant_idx: int = loadout[i]
		var pt = PLANT_TYPES[plant_idx]
		var y := tiles_top + i * (TILE_HEIGHT + TILE_GAP)
		var tile := _build_tile(y, pt["texture"])
		tile["plant_idx"] = plant_idx

		# Koszt: liczba na tle malej ikonki kropli, przy prawej krawedzi kafelka.
		var cost_icon := _make_sprite(WATER_DROP_TEXTURE, 34)
		cost_icon.position = Vector2(TILE_WIDTH - 66, (TILE_HEIGHT - 34) / 2.0)
		tile["button"].add_child(cost_icon)

		var cost_label := Label.new()
		cost_label.text = str(pt["cost"])
		cost_label.position = Vector2(TILE_WIDTH - 66, (TILE_HEIGHT - 24) / 2.0)
		cost_label.size = Vector2(34, 24)
		cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cost_label.add_theme_font_size_override("font_size", 15)
		cost_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tile["button"].add_child(cost_label)

		tile["button"].pressed.connect(_on_plant_button_pressed.bind(plant_idx))
		plant_tiles.append(tile)

func _build_fertilizer_tile() -> void:
	var loadout_size: int = plant_tiles.size()
	var y := _sidebar_tiles_top() + loadout_size * (TILE_HEIGHT + TILE_GAP)
	fertilizer_tile = _build_tile(y, FERTILIZER_TEXTURE)

	var count_label := Label.new()
	count_label.position = Vector2(TILE_ICON_SIZE + 22, (TILE_HEIGHT - 30) / 2.0)
	count_label.size = Vector2(60, 30)
	count_label.add_theme_font_size_override("font_size", 22)
	count_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fertilizer_tile["button"].add_child(count_label)
	fertilizer_tile["count_label"] = count_label

	fertilizer_tile["button"].pressed.connect(_on_fertilizer_button_pressed)

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
		message_label.text = "Wybierz rosline z paska po lewej"
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
		# Pozycja bazowa, do ktorej wracaja animacje strzalu/kontrataku (runda C).
		"base_pos": node.position,
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
	water_count_label.text = str(water)

	for tile in plant_tiles:
		var pt = PLANT_TYPES[tile["plant_idx"]]
		var affordable: bool = water >= pt["cost"]
		tile["button"].modulate = Color(1, 1, 1) if affordable else TILE_UNAFFORDABLE_MODULATE
		var is_selected: bool = selected_plant_type == tile["plant_idx"]
		tile["border_sb"].border_color = TILE_SELECTED_BORDER_COLOR if is_selected else TILE_BORDER_COLOR

	fertilizer_tile["count_label"].text = str(fertilizer)
	fertilizer_tile["button"].modulate = Color(1, 1, 1) if fertilizer > 0 else TILE_UNAFFORDABLE_MODULATE
	fertilizer_tile["border_sb"].border_color = TILE_SELECTED_BORDER_COLOR if fertilizer_mode else TILE_BORDER_COLOR

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
	_update_water_theft(delta)
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
		"water_thief": et.get("water_thief", false), "steal_target": null,
		# Chodzenie/jedzenie (runda C): base_y do animacji podskakiwania,
		# faza losowa zeby wrogowie nie kolysali sie w idealnym takcie.
		"base_y": node.position.y, "phase": randf_range(0.0, TAU), "anim_t": 0.0,
	})

func _spawn_boss(boss_idx: int) -> void:
	var bt = BOSS_TYPES[boss_idx]
	var hp := int(bt["hp"] * _current_level().get("boss_hp_multiplier", 1.0))
	var row := ROWS / 2
	var node := _make_sprite(bt["texture"], CELL - 4)
	var x := float(GRID_LEFT + COLS * CELL)
	node.position = Vector2(x, GRID_TOP + row * CELL + 2)
	add_child(node)
	var bar := _add_health_bar(node, CELL - 4)
	enemies.append({
		"node": node, "hp": hp, "max_hp": hp, "row": row, "x": x, "type_idx": -1,
		"speed": bt["speed"], "bite_dmg": bt["bite_dmg"], "bite_interval": bt["bite_interval"],
		"bite_timer": 0.0, "bar": bar, "hurt_timer": HEALTH_BAR_HIDE_DELAY + 1.0,
		"slow_timer": 0.0, "slow_factor": 1.0,
		"is_boss": true, "boss_type_idx": boss_idx,
		"special_timer": bt["special_interval"], "telegraphing": false,
		"base_y": node.position.y, "phase": randf_range(0.0, TAU), "anim_t": 0.0,
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
							_animate_shooter_shot(plant, pt["dmg"] * boost, pt.get("pierce", false))
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
			"gust":
				# Jednorazowa: wyzwala sie, gdy jakikolwiek szkodnik jest juz
				# CALY widoczny w jej rzedzie (a nie tylko czubkiem nosa przy
				# prawej krawedzi planszy) - nie trzeba czekac, az ja dotknie.
				if not plant["used"]:
					if not _find_fully_entered_enemy_in_row(plant["row"]).is_empty():
						plant["used"] = true
						_trigger_gust(plant, pt)
			_:
				pass

		if plant["hp"] <= 0:
			dead.append(plant)

	for plant in dead:
		_remove_plant(plant)

# Widoczne wyrzucenie pocisku (Kukurydza, Pokrzywa): nabiera (odchylenie w
# lewo + skala 0.9 w poziomie), wyrzut (do przodu + skala 1.1, w tej chwili
# rodzi sie pocisk z bazowej pozycji rosliny - przesuniecie jest tylko
# wizualne, trafienia licza sie jak dotad), powrot do pozycji bazowej.
func _animate_shooter_shot(plant: Dictionary, dmg: float, pierce: bool) -> void:
	var node = plant["node"]
	var base_pos: Vector2 = plant["base_pos"]
	var row: int = plant["row"]
	var running_tween = plant.get("anim_tween")
	if running_tween != null and is_instance_valid(running_tween):
		running_tween.kill()
	node.position = base_pos
	node.scale = Vector2(1, 1)

	var tw: Tween = node.create_tween()
	plant["anim_tween"] = tw
	tw.tween_property(node, "position", base_pos + Vector2(-6, 0), 0.08)
	tw.parallel().tween_property(node, "scale:x", 0.9, 0.08)
	tw.tween_callback(func(): _spawn_projectile(row, base_pos.x + CELL, dmg, pierce))
	tw.tween_property(node, "position", base_pos + Vector2(8, 0), 0.08)
	tw.parallel().tween_property(node, "scale:x", 1.1, 0.08)
	tw.tween_property(node, "position", base_pos, 0.1)
	tw.parallel().tween_property(node, "scale:x", 1.0, 0.1)

func _find_enemy_in_row(row: int) -> Dictionary:
	for e in enemies:
		if e["row"] == row:
			return e
	return {}

# Jak _find_enemy_in_row, ale liczy sie tylko szkodnik, ktory juz w calosci
# wszedl na plansze (jego tylna/prawa krawedz jest juz w obrebie siatki) -
# enemies spawnuja sie tuz ZA prawa krawedzia planszy, wiec "istnieje w
# enemies[]" nie znaczy jeszcze "widac go na planszy".
func _find_fully_entered_enemy_in_row(row: int) -> Dictionary:
	var board_right := float(GRID_LEFT + COLS * CELL)
	for e in enemies:
		if e["row"] == row and e["x"] + e["node"].size.x <= board_right:
			return e
	return {}

func _spawn_projectile(row: int, x: float, dmg: float, pierce: bool = false) -> void:
	var node := _make_sprite(THORN_TEXTURE, 16)
	# "Pyszczek" rosliny: prawa krawedz sprite'a, ok. 40% wysokosci od gory
	# (a nie srodek rzedu) - czysto wizualne, trafienia licza sie po x/rzedzie.
	node.position = Vector2(x, GRID_TOP + row * CELL + 0.4 * (CELL - 16))
	node.scale = Vector2(0.4, 0.4)
	add_child(node)
	var tw := node.create_tween()
	tw.tween_property(node, "scale", Vector2(1, 1), 0.1)
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
		var is_walking := false
		if blocking_plant != null:
			var bpt = PLANT_TYPES[blocking_plant["type_idx"]]

			# Roslina jednorazowa reagujaca na kontakt: aktywuje sie raz i znika.
			# ("gust" nie jest tu obslugiwany - wyzwala sie wczesniej, w
			# _update_plants(), od razu gdy szkodnik pojawi sie w jej rzedzie.)
			if bpt["role"] == "freeze" and not blocking_plant["used"]:
				blocking_plant["used"] = true
				_trigger_freeze(blocking_plant, bpt, e)
				e["bite_timer"] = 0.0
				continue

			var slow_mult: float = e["slow_factor"] if e["slow_timer"] > 0.0 else 1.0
			e["bite_timer"] -= delta * slow_mult
			if e["bite_timer"] <= 0.0:
				e["bite_timer"] = e["bite_interval"]
				blocking_plant["hp"] -= e["bite_dmg"]
				_flash_health_bar(blocking_plant)
				_animate_bite(e, blocking_plant)
				if bpt["role"] == "melee":
					e["hp"] -= bpt["counter_dmg"]
					_flash_health_bar(e)
					_animate_melee_punch(blocking_plant, e["node"].position + e["node"].size / 2.0)
				if blocking_plant["hp"] <= 0:
					_remove_plant(blocking_plant)
		else:
			e["bite_timer"] = 0.0
			var slow_mult2: float = e["slow_factor"] if e["slow_timer"] > 0.0 else 1.0
			e["x"] -= e["speed"] * slow_mult2 * delta
			e["node"].position.x = e["x"]
			if e["x"] <= GRID_LEFT:
				reached_house = true
				last_enemy_texture = BOSS_TYPES[e["boss_type_idx"]]["texture"] if e["is_boss"] else ENEMY_TYPES[e["type_idx"]]["texture"]
			# Chodzenie: podskakiwanie/kolysanie tylko gdy wrog faktycznie sie
			# porusza (nie jest calkowicie unieruchomiony przez Mrozoroslinke).
			is_walking = e["slow_timer"] <= 0.0 or e["slow_factor"] > 0.0

		if is_walking:
			e["anim_t"] += delta
			var bob: float = 6.0 if e["is_boss"] else 3.0
			var sway: float = 0.05 if e["is_boss"] else 0.08
			var wave := sin(e["anim_t"] * 10.0 + e["phase"])
			e["node"].position.y = e["base_y"] + wave * bob
			e["node"].rotation = wave * sway
		else:
			e["node"].position.y = e["base_y"]
			e["node"].rotation = 0.0

		if e["slow_timer"] > 0.0:
			e["slow_timer"] -= delta
			if e["slow_timer"] <= 0.0:
				e["node"].modulate = Color(1, 1, 1)

	for e in dead:
		_release_stolen_drop(e)
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

# --- Proste ksztalty (kolko/gwiazdka) rysowane w kodzie na potrzeby animacji
# (runda C) - kazdy Polygon2D uzywajacy tych punktow ma promien 1.0, wlasciwy
# rozmiar ustawia sie przez node.scale. ---
func _circle_points(segments: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(segments):
		var angle := TAU * i / segments
		pts.append(Vector2(cos(angle), sin(angle)))
	return pts

func _star_points(spikes: int, inner_ratio: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var total := spikes * 2
	for i in range(total):
		var r := 1.0 if i % 2 == 0 else inner_ratio
		var angle := TAU * i / total - PI / 2.0
		pts.append(Vector2(cos(angle), sin(angle)) * r)
	return pts

# --- "Jedzenie": przy kazdym ugryzieniu wrog wypada w lewo i splaszcza sie,
# a z rosliny odlatuja zielone okruszki. ---
func _animate_bite(e: Dictionary, plant: Dictionary) -> void:
	var node = e["node"]
	var lunge: float = 14.0 if e["is_boss"] else 8.0
	var half_dur: float = 0.15 if e["is_boss"] else 0.075
	var base_x: float = node.position.x

	var running_tween = e.get("bite_tween")
	if running_tween != null and is_instance_valid(running_tween):
		running_tween.kill()
	node.scale = Vector2(1, 1)

	var tw: Tween = node.create_tween()
	e["bite_tween"] = tw
	tw.tween_property(node, "position:x", base_x - lunge, half_dur)
	tw.parallel().tween_property(node, "scale:y", 0.85, half_dur)
	tw.tween_property(node, "position:x", base_x, half_dur)
	tw.parallel().tween_property(node, "scale:y", 1.0, half_dur)

	_spawn_bite_crumbs(plant["node"].position + Vector2(CELL / 2.0, CELL / 2.0))

func _spawn_bite_crumbs(origin: Vector2) -> void:
	var count := randi_range(3, 4)
	for i in range(count):
		var crumb := ColorRect.new()
		crumb.color = Color(0.35, 0.55, 0.2)
		crumb.size = Vector2(6, 6)
		crumb.position = origin + Vector2(randf_range(-6.0, 6.0), randf_range(-6.0, 6.0))
		crumb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(crumb)
		var drift := Vector2(randf_range(-24.0, 24.0), randf_range(-40.0, -10.0))
		var tw := crumb.create_tween()
		tw.tween_property(crumb, "position", crumb.position + drift, 0.4)
		tw.parallel().tween_property(crumb, "modulate:a", 0.0, 0.4)
		tw.tween_callback(crumb.queue_free)

# --- Cios piescia Bitnego Brokula przy kontrataku. ---
func _animate_melee_punch(plant: Dictionary, enemy_center: Vector2) -> void:
	var node = plant["node"]
	var base_pos: Vector2 = plant["base_pos"]

	var running_tween = plant.get("anim_tween")
	if running_tween != null and is_instance_valid(running_tween):
		running_tween.kill()
	node.position = base_pos

	var tw: Tween = node.create_tween()
	plant["anim_tween"] = tw
	tw.tween_property(node, "position", base_pos + Vector2(14, 0), 0.075)
	tw.tween_property(node, "position", base_pos, 0.075)

	_spawn_punch_effect(enemy_center)

func _spawn_punch_effect(center: Vector2) -> void:
	var effect := Node2D.new()
	effect.position = center
	add_child(effect)

	var fist := Polygon2D.new()
	fist.polygon = _circle_points(10)
	fist.scale = Vector2(13, 13)
	fist.color = Color(0.25, 0.75, 0.25)
	effect.add_child(fist)

	var star := Polygon2D.new()
	star.polygon = _star_points(5, 0.45)
	star.scale = Vector2(5, 5)
	star.color = Color(0.95, 0.85, 0.2)
	effect.add_child(star)

	var tw := effect.create_tween()
	tw.tween_property(star, "scale", Vector2(16, 16), 0.2)
	tw.parallel().tween_property(effect, "modulate:a", 0.0, 0.2)
	tw.tween_callback(effect.queue_free)

# --- Rosliny jednorazowe: mrozoroslinka, bumorzech, wichurowy ---
func _trigger_freeze(plant: Dictionary, pt: Dictionary, target: Dictionary) -> void:
	# Mrozoroslinka znika, ale szkodnik, ktory na nia stanal, zostaje
	# calkowicie unieruchomiony (nie moze sie ruszyc ani nic zniszczyc) az do
	# rozmrozenia - reszta rzedu porusza sie normalnie.
	target["slow_timer"] = pt["slow_duration"]
	target["slow_factor"] = pt["slow_factor"]
	target["node"].modulate = Color(0.6, 0.85, 1.0)
	_remove_plant(plant, false)

func _trigger_gust(plant: Dictionary, pt: Dictionary) -> void:
	_spawn_gust_cloud(plant)
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

# Przesuwajaca sie niebieska chmurka: startuje w polu rosliny i leci do
# prawej krawedzi planszy w tym rzedzie, potem zanika. Sam efekt odrzutu
# wrogow dzieje sie jak dotad, niezaleznie od animacji.
func _spawn_gust_cloud(plant: Dictionary) -> void:
	var start_x: float = plant["node"].position.x
	var y: float = GRID_TOP + plant["row"] * CELL + CELL / 2.0
	var end_x: float = float(GRID_LEFT + COLS * CELL)

	var cloud := Node2D.new()
	cloud.position = Vector2(start_x, y)
	add_child(cloud)

	var puff_offsets := [Vector2(-10, -6), Vector2(6, -10), Vector2(0, 8), Vector2(16, 0)]
	for i in range(puff_offsets.size()):
		var puff := Polygon2D.new()
		puff.polygon = _circle_points(12)
		puff.scale = Vector2(18.0 + i * 2.0, 18.0 + i * 2.0)
		puff.position = puff_offsets[i]
		puff.color = Color(0.6, 0.8, 1.0, 0.55)
		cloud.add_child(puff)

	var tw := cloud.create_tween()
	tw.tween_property(cloud, "position:x", end_x, 0.5)
	tw.tween_property(cloud, "modulate:a", 0.0, 0.2)
	tw.tween_callback(cloud.queue_free)

func _trigger_bomb(plant: Dictionary, pt: Dictionary) -> void:
	_spawn_bomb_explosion(plant)
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

# Wybuch Bumorzecha: pomaranczowe kolko rosnie do ok. 3 pol srednicy z
# zoltym srodkiem, jednoczesnie zanikajac, plus krotkie biale miegniecie
# i lekkie potrzasniecie plansza.
func _spawn_bomb_explosion(plant: Dictionary) -> void:
	var center := Vector2(
		GRID_LEFT + plant["col"] * CELL + CELL / 2.0,
		GRID_TOP + plant["row"] * CELL + CELL / 2.0
	)
	var effect := Node2D.new()
	effect.position = center
	add_child(effect)

	var outer := Polygon2D.new()
	outer.polygon = _circle_points(20)
	outer.color = Color(0.95, 0.5, 0.1, 0.85)
	outer.scale = Vector2(4, 4)
	effect.add_child(outer)

	var inner := Polygon2D.new()
	inner.polygon = _circle_points(20)
	inner.color = Color(1.0, 0.9, 0.3, 0.9)
	inner.scale = Vector2(2, 2)
	effect.add_child(inner)

	var flash := Polygon2D.new()
	flash.polygon = _circle_points(20)
	flash.color = Color(1, 1, 1, 0.9)
	flash.scale = Vector2(6, 6)
	effect.add_child(flash)

	var target_radius := CELL * 1.5
	var tw := effect.create_tween()
	tw.tween_property(flash, "modulate:a", 0.0, 0.1)
	tw.parallel().tween_property(outer, "scale", Vector2(target_radius, target_radius), 0.3)
	tw.parallel().tween_property(outer, "modulate:a", 0.0, 0.3)
	tw.parallel().tween_property(inner, "scale", Vector2(target_radius * 0.6, target_radius * 0.6), 0.3)
	tw.parallel().tween_property(inner, "modulate:a", 0.0, 0.3)
	tw.tween_callback(effect.queue_free)

	_shake_board()

func _shake_board() -> void:
	var tw := create_tween()
	tw.tween_property(self, "position", Vector2(4, 0), 0.05)
	tw.tween_property(self, "position", Vector2(-4, 0), 0.05)
	tw.tween_property(self, "position", Vector2(4, 0), 0.05)
	tw.tween_property(self, "position", Vector2(0, 0), 0.05)

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
		"visual": visual,
		"vx": cos(angle) * WATER_DROP_SPEED,
		"vy": sin(angle) * WATER_DROP_SPEED,
		"value": value,
		"stolen_by": null,
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
		if drop["stolen_by"] != null:
			continue
		var node: Control = drop["node"]
		var pos: Vector2 = node.position + Vector2(drop["vx"], drop["vy"]) * delta
		if pos.x < min_x or pos.x > max_x:
			drop["vx"] *= -1.0
			pos.x = clamp(pos.x, min_x, max_x)
		if pos.y < min_y or pos.y > max_y:
			drop["vy"] *= -1.0
			pos.y = clamp(pos.y, min_y, max_y)
		node.position = pos

# --- Brudna Gabka: po pojawieniu sie "przyciaga" najblizsza wolna kropla wody -
# przebarwia ja na brudno-zielono i powoli sciaga w swoja strone. Gracz moze ja
# jeszcze tapnac i odzyskac, zanim dolatuje do stwora - wtedy znika bez zwrotu wody. ---
func _update_water_theft(delta: float) -> void:
	for e in enemies:
		if not e.get("water_thief", false) or e["hp"] <= 0:
			continue
		var target = e.get("steal_target")
		if target != null and not water_drops.has(target):
			target = null
			e["steal_target"] = null
		if target == null:
			target = _find_unstolen_water_drop(e)
			if target != null:
				target["stolen_by"] = e
				target["visual"].modulate = WATER_DROP_STOLEN_COLOR
				e["steal_target"] = target
		if target == null:
			continue
		var drop_node: Control = target["node"]
		var enemy_center: Vector2 = e["node"].position + e["node"].size / 2
		var drop_center: Vector2 = drop_node.position + drop_node.size / 2
		var to_enemy: Vector2 = enemy_center - drop_center
		if to_enemy.length() <= 6.0:
			water_drops.erase(target)
			drop_node.queue_free()
			e["steal_target"] = null
			continue
		drop_node.position += to_enemy.normalized() * WATER_DROP_STEAL_SPEED * delta

func _find_unstolen_water_drop(e: Dictionary) -> Variant:
	var closest = null
	var closest_dist := INF
	for drop in water_drops:
		if drop["stolen_by"] != null:
			continue
		var d: float = e["node"].position.distance_to(drop["node"].position)
		if d < closest_dist:
			closest_dist = d
			closest = drop
	return closest

func _release_stolen_drop(e: Dictionary) -> void:
	var target = e.get("steal_target")
	if target == null or not water_drops.has(target):
		return
	target["stolen_by"] = null
	target["visual"].modulate = Color(1, 1, 1)
	var angle := randf_range(0.0, TAU)
	target["vx"] = cos(angle) * WATER_DROP_SPEED
	target["vy"] = sin(angle) * WATER_DROP_SPEED

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
	# Wysrodkowany pivot, zeby skalowanie/obrot w animacjach (runda C) dzialy
	# sie wokol srodka sprite'a, a nie lewego gornego rogu.
	node.pivot_offset = node.size / 2.0
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

	var overlay := ColorRect.new()
	overlay.color = Color(0.05, 0.05, 0.05, 0.75)
	overlay.position = Vector2(0, 0)
	overlay.size = Vector2(VIEWPORT_WIDTH, VIEWPORT_HEIGHT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)

	var icon := _make_sprite(last_enemy_texture, 320)
	icon.position = Vector2(VIEWPORT_WIDTH / 2.0 - 160, VIEWPORT_HEIGHT / 2.0 - 220)
	icon.scale = Vector2(0.01, 0.01)
	add_child(icon)
	var icon_tw := icon.create_tween()
	icon_tw.tween_property(icon, "scale", Vector2(1, 1), 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	var lose_label := Label.new()
	lose_label.text = "Smieci dotarly do domu!"
	lose_label.add_theme_font_size_override("font_size", 32)
	lose_label.add_theme_color_override("font_color", Color(0.95, 0.4, 0.3))
	lose_label.position = Vector2(VIEWPORT_WIDTH / 2.0 - 300, VIEWPORT_HEIGHT / 2.0 + 110)
	lose_label.size = Vector2(600, 50)
	lose_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lose_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(lose_label)

	_show_end_buttons()

func _win_game() -> void:
	game_over = true
	message_label.text = "WYGRANA - obronles ogrod!"
	GameState.complete_level(GameState.current_level_index)

	_spawn_confetti()

	var win_label := Label.new()
	win_label.text = "WYGRANA!"
	win_label.add_theme_font_size_override("font_size", 64)
	win_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	win_label.position = Vector2(VIEWPORT_WIDTH / 2.0 - 300, VIEWPORT_HEIGHT / 2.0 - 120)
	win_label.size = Vector2(600, 100)
	win_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	win_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(win_label)

	var delay := get_tree().create_timer(1.5)
	delay.timeout.connect(_show_end_buttons)

# Konfetti: kolorowe prostokaciki spadajace z gravitacja i obrotem z gory
# ekranu. Tekstura kwadratu tworzona w kodzie (bez nowych plikow graficznych).
func _spawn_confetti() -> void:
	var particles := CPUParticles2D.new()
	particles.position = Vector2(VIEWPORT_WIDTH / 2.0, -20.0)
	particles.texture = _make_square_texture(8)
	particles.emitting = true
	particles.one_shot = true
	particles.amount = 180
	particles.lifetime = 3.0
	particles.explosiveness = 0.15
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	particles.emission_rect_extents = Vector2(VIEWPORT_WIDTH / 2.0, 4.0)
	particles.direction = Vector2(0, 1)
	particles.spread = 25.0
	particles.gravity = Vector2(0, 220.0)
	particles.initial_velocity_min = 40.0
	particles.initial_velocity_max = 120.0
	particles.angular_velocity_min = -180.0
	particles.angular_velocity_max = 180.0
	particles.scale_amount_min = 0.5
	particles.scale_amount_max = 1.0

	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([
		Color(0.95, 0.3, 0.3), Color(0.3, 0.6, 0.95), Color(0.95, 0.85, 0.2),
		Color(0.4, 0.85, 0.4), Color(0.8, 0.4, 0.9),
	])
	particles.color_ramp = gradient
	add_child(particles)

	var cleanup := get_tree().create_timer(3.2)
	cleanup.timeout.connect(particles.queue_free)

func _make_square_texture(size: int) -> ImageTexture:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(1, 1, 1, 1))
	return ImageTexture.create_from_image(img)

func _show_end_buttons() -> void:
	var y := GRID_TOP + ROWS * CELL + 150
	var retry_btn := Button.new()
	retry_btn.text = "Zagraj ponownie"
	retry_btn.position = Vector2(GRID_LEFT, y)
	retry_btn.size = Vector2(250, 40)
	retry_btn.pressed.connect(func(): get_tree().reload_current_scene())
	add_child(retry_btn)

	var select_btn := Button.new()
	select_btn.text = "Wybierz poziom"
	select_btn.position = Vector2(GRID_LEFT + 270, y)
	select_btn.size = Vector2(250, 40)
	select_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/LevelSelect.tscn"))
	add_child(select_btn)
