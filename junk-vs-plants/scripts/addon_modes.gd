class_name AddonModes
extends RefCounted

# Zasady trybow walki z rotacji dodatkow i gier edukacyjnych (AddonData). main.gd
# tworzy ten obiekt, gdy zasady etapu maja ktorys z trybow, i wywoluje jego
# funkcje w swoich miejscach (sadzenie, ruch wrogow, obrazenia, koniec fali).
# m to scena gry (main.gd); korzystamy z jej planszy i funkcji.

const STATUS_POS := Vector2(560, 26)
const SEASON_TINTS := [Color(0.6, 1.0, 0.6, 0.1), Color(1.0, 0.85, 0.3, 0.12), Color(0.9, 0.5, 0.2, 0.12), Color(0.8, 0.9, 1.0, 0.18)]
const SUMMER_TICK := 5.0
const SUMMER_HEAT := 6.0
const AUTUMN_WIND_EVERY := 20.0
const WINTER_SLOW := 0.7
const SPRING_WATER := 1.5
const UMBRELLA_TIME := 30.0
const CONVEYOR_EVERY := 15.0
const CONVEYOR_STOP_TIME := 20.0
const STORM_MIN := 25.0
const STORM_MAX := 35.0
const STORM_WARNING := 3.0
const STORM_RAIN := 8.0
const STORM_RAIN_SPEED := 1.5
const RIVER_SPEED := 2.0
const RIVER_CACTUS := 1.25
const BRIDGE_COST := 20
const FREE_BRIDGES := 2
const TREE_COL := 1
const TREE_ROW := 2
const TREE_BASE_HP := 1200.0
const TREE_HP_PER_STAGE := 300.0
const TREE_WAVE_WATER := 50
const TREE_TURN_SPEED := 45.0
const TREASURE_WATER := 50
const TREASURE_COINS := 20
const CAGE_HP := 250
const BIRD_EVERY := 15.0
const BIRD_DROP := 25
const BUTTERFLY_RECHARGE := 1.5
const SEED_CHANCE := 0.3
const SEEDS_PER_PLANT := 5
const SEED_LIFE := 8.0
const DOUBLE_SEED_WAVES := 2
const TRANSPLANT_COOLDOWN := 10.0
const TRANSPLANT_FAST := 5.0
const GHOST_ALPHA := 0.12
const GHOST_SIGHT_CELLS := 3.0
const GIANT_HP := 4.0
const SWARM_BEE_LIFE := 5.0
const SWARM_EARLY_LIFE := 10.0
const SWARM_BONUS_TIME := 15.0
const SORT_MATCH := 2.0
const SORT_MISMATCH := 0.5

var m
var rules: Dictionary
var stage := 0
var help := ""
var status_label: Label
var time := 0.0

# Pory roku
var season := -1
var season_overlay: ColorRect
var heat_timer := SUMMER_TICK
var wind_timer := AUTUMN_WIND_EVERY
var umbrella_left := 0.0
# Ruchome pasy
var conveyor_timer := CONVEYOR_EVERY
var conveyor_stop_left := 0.0
# Burza: "idle", "warning", "rain"
var storm_phase := "idle"
var storm_timer := 0.0
var storm_rows: Array = []
var storm_overlays: Array = []
var rod_cell := Vector2i(-1, -1)
var rod_pending := false
# Rzeka: pola z kladka i tryb budowania kladki
var bridges := {}
var bridge_mode := false
var free_bridges := 0
var bridge_button: Button
# Drzewko
var tree_plant: Dictionary = {}
# Skarby: klucz pola -> rodzaj nagrody
var treasures := {}
var treasure_marks := {}
# Zagadka
var puzzle_started := false
var puzzle_button: Button
var fixed_plants: Array = []
# Zwierzatka
var birds: Array = []
var bird_timer := BIRD_EVERY
var pending_frogs := 0
var recharge_bonus := 1.0
# Nasiona
var seeds := 0
var seed_drops: Array = []
var free_plants_waiting: Array = []
# Przesadzanie
var move_plant: Dictionary = {}
var move_cooldown := 0.0
var move_frame: Panel
# Niewidzialne smieci
var firefly_row := -1
var firefly_pending := false
# Olbrzym
var giant_type := -1
var giant_used := false
var giant_selected := false
var giant_layer: Control
var giant_button: Button
# Pszczeli roj
var swarm_timer := 0.0
var swarm_bee: Button
var swarm_choice: Control
var bonus_left := {}
# Sortowanie: indeks rosliny -> kolor pojemnika
var plant_bins := {}

func _init(main_scene, event_rules: Dictionary, help_type: String) -> void:
	m = main_scene
	rules = event_rules
	stage = GameState.event_stage
	help = help_type

static func is_needed(event_rules: Dictionary) -> bool:
	for key in ["seasons", "conveyor_rows", "storm", "river_row", "tree", "treasures", "puzzle",
			"single_plant", "transplant", "animals", "seeds", "invisible", "giant", "swarm", "sorting"]:
		if event_rules.has(key):
			return true
	return false

func _cell_pos(col: int, row: int) -> Vector2:
	return Vector2(m.GRID_LEFT + col * m.CELL, m.GRID_TOP + row * m.CELL)

func _rect(pos: Vector2, size: Vector2, color: Color) -> ColorRect:
	var r := ColorRect.new()
	r.position = pos
	r.size = size
	r.color = color
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	m.add_child(r)
	return r

func _top_button(text: String, x: float) -> Button:
	var btn: Button = m._make_top_button(Vector2(x, 2), Vector2(150, m.TOP_BTN_HEIGHT))
	btn.text = text
	btn.add_theme_font_size_override("font_size", 18)
	return btn

func _say(text: String) -> void:
	m.message_label.text = text

func _free_cells(min_col: int, max_col: int) -> Array:
	var cells := []
	for c in range(min_col, max_col + 1):
		for r in range(m.ROWS):
			var key: String = m._cell_key(c, r)
			if m.grid_occupancy[c][r] == null and not m.blocked_cells.has(key) and not m.junk_piles.has(key):
				cells.append(Vector2i(c, r))
	return cells

# --- Przygotowanie etapu ---
func setup() -> void:
	status_label = Label.new()
	status_label.position = STATUS_POS
	status_label.add_theme_font_size_override("font_size", 18)
	status_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.5))
	m.add_child(status_label)
	if rules.has("seasons"):
		season_overlay = _rect(_cell_pos(0, 0), Vector2(m.COLS, m.ROWS) * m.CELL, Color(0, 0, 0, 0))
		if help == "umbrella":
			var umbrella := _top_button(Lang.t("am_umbrella"), m.GRID_LEFT + 150)
			umbrella.pressed.connect(func():
				umbrella_left = UMBRELLA_TIME
				umbrella.queue_free())
		_update_season()
	if rules.has("conveyor_rows"):
		for row in rules["conveyor_rows"]:
			_rect(_cell_pos(0, row), Vector2(m.COLS * m.CELL, m.CELL), Color(0.3, 0.3, 0.35, 0.3))
			for c in range(m.COLS):
				var arrow := Label.new()
				arrow.text = "<"
				arrow.position = _cell_pos(c, row) + Vector2(4, m.CELL - 30)
				arrow.add_theme_font_size_override("font_size", 20)
				arrow.modulate = Color(1, 1, 1, 0.5)
				arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
				m.add_child(arrow)
		if help == "belt_stop":
			var stop := _top_button(Lang.t("am_belt_stop"), m.GRID_LEFT + 150)
			stop.pressed.connect(func():
				conveyor_stop_left = CONVEYOR_STOP_TIME
				stop.queue_free())
	if rules.has("storm"):
		storm_timer = randf_range(STORM_MIN, STORM_MAX)
		if help == "rod":
			rod_pending = true
			_say(Lang.t("am_rod_place"))
	if rules.has("river_row"):
		_rect(_cell_pos(0, rules["river_row"]), Vector2(m.COLS * m.CELL, m.CELL), Color(0.2, 0.5, 0.95, 0.55))
		free_bridges = FREE_BRIDGES if help == "bridges" else 0
		bridge_button = _top_button("", m.GRID_LEFT + 150)
		bridge_button.pressed.connect(func():
			bridge_mode = not bridge_mode
			m.selected_plant_type = -1
			_say(Lang.t("am_bridge_place") if bridge_mode else "")
			_update_bridge_button())
		_update_bridge_button()
	if rules.has("tree"):
		_setup_tree()
	if rules.has("treasures"):
		_setup_treasures()
	if rules.has("puzzle"):
		_setup_puzzle()
	if rules.has("single_plant"):
		for idx in GameState.current_loadout:
			if ["shooter", "volley", "aimed"].has(PlantData.TYPES[idx]["role"]):
				m.fertilizer = max(m.fertilizer, 1)
	if rules.has("animals"):
		_setup_cages()
	if rules.has("invisible") and help == "firefly":
		firefly_pending = true
		_say(Lang.t("am_firefly_place"))
	if rules.has("giant"):
		_show_giant_choice()
	if rules.has("swarm"):
		var interval: Array = AddonData.SWARM_INTERVALS[stage]
		swarm_timer = 0.5 if help == "early_bee" else randf_range(interval[0], interval[1])
	if rules.has("sorting"):
		_setup_sorting()
	if rules.has("transplant"):
		move_frame = Panel.new()
		move_frame.size = Vector2(m.CELL, m.CELL)
		move_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var sb := UiIcons.round_style(Color(1, 1, 1, 0.12), 10)
		sb.set_border_width_all(5)
		sb.border_color = Color(0.4, 0.9, 1.0)
		move_frame.add_theme_stylebox_override("panel", sb)
		move_frame.visible = false
		m.add_child(move_frame)
		_say(Lang.t("am_transplant_hint"))
	_update_status()

func _update_bridge_button() -> void:
	if free_bridges > 0:
		bridge_button.text = Lang.f("am_bridge_free", [free_bridges])
	else:
		bridge_button.text = Lang.f("am_bridge_cost", [BRIDGE_COST])
	bridge_button.modulate = Color(1, 0.9, 0.5) if bridge_mode else Color(1, 1, 1)

# --- Co klatke ---
func update(delta: float) -> void:
	time += delta
	if rules.has("seasons"):
		_update_seasons(delta)
	if rules.has("conveyor_rows"):
		_update_conveyor(delta)
	if rules.has("storm"):
		_update_storm(delta)
	if rules.has("animals"):
		_update_animals(delta)
	if rules.has("seeds"):
		_update_seed_drops(delta)
	if rules.has("invisible"):
		_update_ghosts()
	if rules.has("swarm"):
		_update_swarm(delta)
	if rules.has("transplant"):
		move_cooldown = max(0.0, move_cooldown - delta)
	for key in bonus_left.keys():
		bonus_left[key] -= delta
		if bonus_left[key] <= 0.0:
			bonus_left.erase(key)
	_update_status()

func _update_status() -> void:
	var parts := []
	if rules.has("seasons"):
		parts.append(Lang.t("am_season_" + AddonData.SEASONS[season]) + (" (" + Lang.t("am_umbrella") + ")" if umbrella_left > 0.0 else ""))
	if rules.has("conveyor_rows"):
		parts.append(Lang.t("am_belt_stopped") if conveyor_stop_left > 0.0 else Lang.f("am_belt_in", [ceili(conveyor_timer)]))
	if rules.has("tree") and not tree_plant.is_empty():
		parts.append(Lang.f("am_tree_hp", [roundi(100.0 * tree_plant["hp"] / tree_plant["max_hp"])]))
	if rules.has("seeds"):
		parts.append(Lang.f("am_seeds", [seeds, SEEDS_PER_PLANT]))
	if rules.has("transplant"):
		parts.append(Lang.t("am_move_ready") if move_cooldown <= 0.0 else Lang.f("am_move_in", [ceili(move_cooldown)]))
	for key in bonus_left.keys():
		parts.append(Lang.f("am_bonus_left", [Lang.t("am_bonus_" + key), ceili(bonus_left[key])]))
	status_label.text = "   ".join(parts)

# --- Mnozniki uzywane przez main.gd ---
# Predkosc konkretnego wroga.
func enemy_speed(e: Dictionary) -> float:
	var mult := 1.0
	if season == 3 and _season_on():
		mult *= WINTER_SLOW
	if storm_phase == "rain" and storm_rows.has(e["row"]):
		mult *= STORM_RAIN_SPEED
	if rules.has("river_row") and e["row"] == rules["river_row"]:
		mult *= RIVER_SPEED
	if bonus_left.has("slow"):
		mult *= 0.5
	return mult

func projectile_speed() -> float:
	return WINTER_SLOW if season == 3 and _season_on() else 1.0

# Szybkosc dawania kropel przez konkretna rosline.
func water_speed(plant: Dictionary) -> float:
	var mult := 1.0
	if season == 0 and _season_on():
		mult *= SPRING_WATER
	if rules.has("river_row") and abs(plant["row"] - rules["river_row"]) == 1:
		mult *= RIVER_CACTUS
	if bonus_left.has("water"):
		mult *= 2.0
	return mult

func recharge_speed() -> float:
	return recharge_bonus * (2.0 if bonus_left.has("recharge") else 1.0)

# Czas odnawiania rosliny (Jedna roslinka: jednorazowe odnawiaja sie 2 razy szybciej).
func recharge_time(type_idx: int, recharge: float) -> float:
	if rules.has("single_plant") and m.ONE_SHOT_ROLES.has(PlantData.TYPES[type_idx]["role"]):
		return recharge * 0.5
	return recharge

# Sortowanie: kolor pojemnika rosliny i wroga decyduje o sile ciosu.
func damage_mult(src_type: int, e: Dictionary) -> float:
	if not rules.has("sorting") or src_type < 0 or not e.has("bin"):
		return 1.0
	return SORT_MATCH if plant_bins.get(src_type, "") == e["bin"] else SORT_MISMATCH

func blocks_waves() -> bool:
	return rules.has("puzzle") and not puzzle_started

# --- Zdarzenia z planszy ---
# Tapniecie pola, zanim main.gd sprobuje cos posadzic. true = obsluzone tutaj.
func on_tile_tap(col: int, row: int) -> bool:
	if rod_pending:
		rod_pending = false
		rod_cell = Vector2i(col, row)
		var rod := _rect(_cell_pos(col, row) + Vector2(m.CELL / 2.0 - 3, 6), Vector2(6, m.CELL - 20), Color(0.6, 0.6, 0.65))
		_rect(rod.position - Vector2(5, 6), Vector2(16, 10), Color(1.0, 0.85, 0.2))
		_say("")
		return true
	if firefly_pending:
		firefly_pending = false
		firefly_row = row
		_rect(_cell_pos(0, row) + Vector2(4, 4), Vector2(14, 14), Color(1.0, 1.0, 0.4, 0.9))
		_say("")
		return true
	if bridge_mode:
		_try_build_bridge(col, row)
		return true
	if giant_selected:
		_try_place_giant(col, row)
		return true
	if rules.has("transplant") and m.selected_plant_type < 0 and not m.remove_mode and not m.fertilizer_mode:
		return _transplant_tap(col, row)
	return false

# Powod, dla ktorego nie mozna tu sadzic, albo "".
func can_place(_type_idx: int, col: int, row: int) -> String:
	if rules.has("puzzle") and puzzle_started:
		return Lang.t("am_puzzle_locked")
	if rules.has("river_row") and row == rules["river_row"] and not bridges.has(m._cell_key(col, row)):
		return Lang.t("am_river_no_plant")
	return ""

func on_plant_placed(plant: Dictionary) -> void:
	if rules.has("treasures"):
		_reveal_treasure(plant["col"], plant["row"])
	if rules.has("sorting"):
		_add_bin_badge(plant["node"], plant_bins.get(plant["type_idx"], ""))

func can_remove(plant: Dictionary) -> bool:
	return not plant.get("tree", false) and not fixed_plants.has(plant)

func on_enemy_spawned(e: Dictionary) -> void:
	if rules.has("invisible") and not e["is_boss"] and randf() < AddonData.INVISIBLE_SHARE[stage]:
		e["ghost"] = true
		e["node"].self_modulate.a = GHOST_ALPHA
	if rules.has("sorting"):
		e["bin"] = AddonData.BOSS_BINS[e["boss_type_idx"]] if e["is_boss"] else AddonData.ENEMY_BINS[e["type_idx"]]
		_add_bin_badge(e["node"], e["bin"])
	if pending_frogs > 0 and not e["is_boss"]:
		pending_frogs -= 1
		_frog_eats(e)

func on_enemy_killed(e: Dictionary) -> void:
	if rules.has("seeds") and not e["is_boss"] and randf() < SEED_CHANCE:
		_spawn_seed(e["node"].position)

# Ruch wroga przejety przez tryb (Drzewko). true = main.gd nie rusza go dalej.
func move_enemy(e: Dictionary, delta: float) -> bool:
	if rules.has("treasures"):
		_steal_treasure(e)
	if rules.has("animals"):
		_drag_cage(e)
	if not rules.has("tree") or tree_plant.is_empty() or e["row"] == TREE_ROW and not e.has("turn_target"):
		return false
	var divert_x: float = m.GRID_LEFT + (TREE_COL + 1.5) * m.CELL
	if e["x"] > divert_x and not e.has("turn_target"):
		return false
	# Wrog skreca do rzedu Drzewka i dopiero tam idzie dalej w lewo.
	var target_y: float = m.GRID_TOP + TREE_ROW * m.CELL + (e["node"].position.y - (m.GRID_TOP + e["row"] * m.CELL))
	if not e.has("turn_target"):
		e["turn_target"] = target_y
	var step: float = TREE_TURN_SPEED * delta * signf(e["turn_target"] - e["base_y"])
	if abs(e["turn_target"] - e["base_y"]) <= abs(step):
		e["base_y"] = e["turn_target"]
		e["row"] = TREE_ROW
		e.erase("turn_target")
	else:
		e["base_y"] += step
		e["row"] = clampi(roundi((e["base_y"] - m.GRID_TOP) / m.CELL), 0, m.ROWS - 1)
	e["node"].position.y = e["base_y"]
	return true

# Pokonana roslina: zwraca true, gdy to koniec etapu (Drzewko).
func on_plant_beaten(plant: Dictionary) -> bool:
	if plant.get("tree", false):
		m._remove_plant(plant)
		m._lose_game(Lang.t("am_tree_lost"))
		return true
	return false

func on_wave_end() -> void:
	if rules.has("tree"):
		m.water += TREE_WAVE_WATER
		_say(Lang.f("am_tree_water", [TREE_WAVE_WATER]))

func on_pile_destroyed(pile: Dictionary) -> void:
	if pile.has("cage") and not pile.get("lost", false):
		_free_animal(pile)

# --- Pory roku ---
func _season_on() -> bool:
	return umbrella_left <= 0.0

func _update_season() -> void:
	var s := AddonData.season_for_stage(stage)
	if s < 0:
		s = int(time / AddonData.SEASON_CYCLE_TIME) % AddonData.SEASONS.size()
	if s != season:
		season = s
		_say(Lang.t("am_season_start_" + AddonData.SEASONS[season]))
	season_overlay.color = SEASON_TINTS[season] if _season_on() else Color(0, 0, 0, 0)

func _update_seasons(delta: float) -> void:
	umbrella_left = max(0.0, umbrella_left - delta)
	_update_season()
	if not _season_on():
		return
	if season == 1:
		heat_timer -= delta
		if heat_timer <= 0.0:
			heat_timer = SUMMER_TICK
			_summer_heat()
	elif season == 2:
		wind_timer -= delta
		if wind_timer <= 0.0:
			wind_timer = AUTUMN_WIND_EVERY
			for e in m.enemies:
				e["push_left"] = float(m.CELL)
			_say(Lang.t("am_wind"))

# Latem rosliny bez Lisci Bananowca obok powoli traca zycie.
func _summer_heat() -> void:
	for plant in m.plants.duplicate():
		if plant.get("tree", false) or _has_wall_nearby(plant):
			continue
		plant["hp"] -= SUMMER_HEAT
		m._flash_health_bar(plant)
		if plant["hp"] <= 0:
			m._plant_beaten(plant)

func _has_wall_nearby(plant: Dictionary) -> bool:
	for c in range(plant["col"] - 1, plant["col"] + 2):
		for r in range(plant["row"] - 1, plant["row"] + 2):
			if c < 0 or r < 0 or c >= m.COLS or r >= m.ROWS:
				continue
			var other = m.grid_occupancy[c][r]
			if other != null and other != plant and PlantData.TYPES[other["type_idx"]]["role"] == "wall":
				return true
	return false

# --- Ruchome pasy ---
func _update_conveyor(delta: float) -> void:
	if conveyor_stop_left > 0.0:
		conveyor_stop_left -= delta
		return
	conveyor_timer -= delta
	if conveyor_timer > 0.0:
		return
	conveyor_timer = CONVEYOR_EVERY
	for row in rules["conveyor_rows"]:
		for c in range(m.COLS):
			var plant = m.grid_occupancy[c][row]
			if plant == null or plant.get("cells", []).size() > 1:
				continue
			if c == 0:
				# Zepchnieta z planszy wraca do paska i musi sie odnowic.
				m.plant_cooldowns[plant["type_idx"]] = m._recharge_time(plant["type_idx"])
				m._remove_plant(plant)
			elif m.grid_occupancy[c - 1][row] == null and not m.blocked_cells.has(m._cell_key(c - 1, row)) and not m.junk_piles.has(m._cell_key(c - 1, row)):
				_move_plant_to(plant, c - 1, row)

func _move_plant_to(plant: Dictionary, col: int, row: int) -> void:
	m.grid_occupancy[plant["col"]][plant["row"]] = null
	plant["col"] = col
	plant["row"] = row
	m.grid_occupancy[col][row] = plant
	var target := _cell_pos(col, row) + Vector2(8, 8)
	plant["base_pos"] = target
	var node: Control = plant["node"]
	var running = plant.get("anim_tween")
	if running != null and is_instance_valid(running):
		running.kill()
	var tw := node.create_tween()
	tw.tween_property(node, "position", target, 0.3).set_trans(Tween.TRANS_SINE)
	if rules.has("treasures"):
		_reveal_treasure(col, row)

# --- Burza ---
func _update_storm(delta: float) -> void:
	storm_timer -= delta
	match storm_phase:
		"idle":
			if storm_timer <= 0.0:
				var first := randi_range(0, m.ROWS - 2)
				storm_rows = [first, first + 1]
				storm_phase = "warning"
				storm_timer = STORM_WARNING
				for row in storm_rows:
					storm_overlays.append(_rect(_cell_pos(0, row), Vector2(m.COLS * m.CELL, m.CELL), Color(0.1, 0.1, 0.2, 0.35)))
				_say(Lang.t("am_storm_warning"))
		"warning":
			if storm_timer <= 0.0:
				storm_phase = "rain"
				storm_timer = STORM_RAIN
				for overlay in storm_overlays:
					overlay.color = Color(0.3, 0.45, 0.9, 0.3)
				_lightning()
		"rain":
			if storm_timer <= 0.0:
				storm_phase = "idle"
				storm_timer = randf_range(STORM_MIN, STORM_MAX)
				for overlay in storm_overlays:
					overlay.queue_free()
				storm_overlays.clear()
				storm_rows.clear()

func _protected_by_rod(col: int, row: int) -> bool:
	return rod_cell.x >= 0 and abs(col - rod_cell.x) <= 1 and abs(row - rod_cell.y) <= 1

# Piorun trafia losowa kupke albo rosline, ktorej nie chroni piorunochron.
func _lightning() -> void:
	var targets := []
	for pile in m.junk_piles.values():
		targets.append(pile)
	for plant in m.plants:
		if storm_rows.has(plant["row"]) and not _protected_by_rod(plant["col"], plant["row"]) and not plant.get("tree", false):
			targets.append(plant)
	if targets.is_empty():
		_say(Lang.t("am_storm_rain"))
		return
	var target: Dictionary = targets.pick_random()
	var center: Vector2 = _cell_pos(target["col"], target["row"]) + Vector2(m.CELL, m.CELL) / 2.0
	var bolt := Line2D.new()
	bolt.points = PackedVector2Array([center + Vector2(10, -m.CELL * 2), center + Vector2(-12, -m.CELL), center + Vector2(8, -m.CELL * 0.5), center])
	bolt.width = 8
	bolt.default_color = Color(1.0, 0.95, 0.4)
	m.add_child(bolt)
	var tw := bolt.create_tween()
	tw.tween_property(bolt, "modulate:a", 0.0, 0.5)
	tw.tween_callback(bolt.queue_free)
	if target.has("type_idx"):
		m._remove_plant(target)
		_say(Lang.t("am_storm_hit_plant"))
	else:
		m._remove_pile(target)
		_say(Lang.t("am_storm_hit_pile"))

# --- Rzeka ---
func _try_build_bridge(col: int, row: int) -> void:
	if row != rules["river_row"]:
		_say(Lang.t("am_bridge_only_river"))
		return
	var key: String = m._cell_key(col, row)
	if bridges.has(key):
		_say(Lang.t("am_bridge_exists"))
		return
	if free_bridges > 0:
		free_bridges -= 1
	elif m.water >= BRIDGE_COST:
		m.water -= BRIDGE_COST
	else:
		_say(Lang.t("too_little_water"))
		return
	var planks := _rect(_cell_pos(col, row) + Vector2(2, 10), Vector2(m.CELL - 4, m.CELL - 20), Color(0.6, 0.4, 0.2))
	bridges[key] = planks
	m.move_child(planks, m.get_child_count() - 1)
	bridge_mode = false
	_say("")
	_update_bridge_button()
	m._update_hud()

# --- Drzewko ---
func _setup_tree() -> void:
	var hp := TREE_BASE_HP + TREE_HP_PER_STAGE * stage
	if help == "tree_hp":
		hp *= 2.0
	var banana: int = m._plant_index("wall")
	var saved_water: int = m.water
	m.water = 99999
	m._place_plant(banana, TREE_COL, TREE_ROW, 1.0)
	m.water = saved_water
	tree_plant = m.grid_occupancy[TREE_COL][TREE_ROW]
	tree_plant["tree"] = true
	tree_plant["hp"] = hp
	tree_plant["max_hp"] = hp
	var node: TextureRect = tree_plant["node"]
	var tree_icon := UiIcons.tree(m.CELL + 30)
	if tree_icon is TextureRect:
		node.texture = tree_icon.texture
	else:
		node.self_modulate.a = 0.0
		tree_icon.position = Vector2(-23, -30)
		node.add_child(tree_icon)

# --- Skarby ---
func _setup_treasures() -> void:
	var cells := _free_cells(0, m.COLS - 1)
	cells.shuffle()
	for k in range(min(rules["treasures"], cells.size())):
		var roll := randf()
		var kind := "water"
		if roll >= 0.95:
			kind = "ruby"
		elif roll >= 0.65:
			kind = "coins"
		elif roll >= 0.4:
			kind = "fertilizer"
		treasures[m._cell_key(cells[k].x, cells[k].y)] = kind
		if help == "detector" and k < 2:
			var mark := UiIcons.star(28)
			mark.position = _cell_pos(cells[k].x, cells[k].y) + Vector2(m.CELL - 32, 4)
			m.add_child(mark)
			treasure_marks[m._cell_key(cells[k].x, cells[k].y)] = mark

func _reveal_treasure(col: int, row: int) -> void:
	var key: String = m._cell_key(col, row)
	if not treasures.has(key):
		return
	var kind: String = treasures[key]
	treasures.erase(key)
	_clear_mark(key)
	if kind == "fertilizer" and m.fertilizer >= m._fertilizer_limit():
		kind = "water"
	match kind:
		"water":
			m.water += TREASURE_WATER
		"fertilizer":
			m.fertilizer += 1
		"coins":
			GameState.plant_coins += TREASURE_COINS
			GameState.save_progress()
		"ruby":
			GameState.rubies += 1
			GameState.save_progress()
	_say(Lang.t("am_treasure_" + kind))
	m._update_hud()

func _steal_treasure(e: Dictionary) -> void:
	var col := clampi(int((e["x"] - m.GRID_LEFT) / m.CELL), 0, m.COLS - 1)
	var key: String = m._cell_key(col, e["row"])
	if treasures.has(key) and e["x"] < m.GRID_LEFT + (col + 0.5) * m.CELL:
		treasures.erase(key)
		_clear_mark(key)
		_say(Lang.t("am_treasure_stolen"))

func _clear_mark(key: String) -> void:
	if treasure_marks.has(key):
		treasure_marks[key].queue_free()
		treasure_marks.erase(key)

# --- Zagadka obronna ---
func _setup_puzzle() -> void:
	var puzzle: Dictionary = AddonData.PUZZLES[stage]
	for entry in puzzle["plants"]:
		var saved_water: int = m.water
		m.water = 99999
		m._place_plant(entry[0], entry[1], entry[2], 1.0)
		m.water = saved_water
		fixed_plants.append(m.grid_occupancy[entry[1]][entry[2]])
	m.water = puzzle["water"]
	if help == "hint":
		var hint: Array = puzzle["hint"]
		var ghost := UiIcons.plant_icon(hint[2], m.CELL - 24)
		ghost.position = _cell_pos(hint[0], hint[1]) + Vector2(12, 12)
		ghost.modulate = Color(1, 1, 1, 0.45)
		m.add_child(ghost)
	puzzle_button = _top_button(Lang.t("am_puzzle_start"), m.GRID_LEFT + 150)
	puzzle_button.pressed.connect(func():
		puzzle_started = true
		m.selected_plant_type = -1
		puzzle_button.queue_free()
		_say(Lang.t("am_puzzle_go")))
	_say(Lang.t("am_puzzle_hint"))
	m._update_hud()

# --- Uwolnij zwierzatka ---
func _setup_cages() -> void:
	var cells := _free_cells(3, 8)
	cells.shuffle()
	var animals: Array = AddonData.ANIMALS.duplicate()
	animals.shuffle()
	var hp := CAGE_HP / 2 if help == "weak_cages" else CAGE_HP
	for k in range(min(AddonData.CAGE_COUNTS[stage], cells.size())):
		var cell: Vector2i = cells[k]
		var animal: String = animals[k % animals.size()]
		var node := UiIcons.cage(m.CELL - 16)
		node.position = _cell_pos(cell.x, cell.y) + Vector2(8, 8)
		node.pivot_offset = node.size / 2.0
		m.add_child(node)
		var pet := UiIcons.animal(animal, (m.CELL - 16) * 0.55)
		pet.position = Vector2(m.CELL - 16, m.CELL - 16) * 0.225
		node.add_child(pet)
		# Prety klatki przed zwierzatkiem.
		node.move_child(pet, 0)
		var bar: Dictionary = m._add_health_bar(node, m.CELL - 16)
		m.junk_piles[m._cell_key(cell.x, cell.y)] = {
			"node": node, "hp": hp, "max_hp": hp, "col": cell.x, "row": cell.y,
			"bar": bar, "hurt_timer": m.HEALTH_BAR_HIDE_DELAY + 1.0, "cage": animal,
		}

# Wrog, ktory dojdzie do klatki, odciaga ja z planszy.
func _drag_cage(e: Dictionary) -> void:
	for pile in m.junk_piles.values():
		if pile.has("cage") and pile["row"] == e["row"] and abs(m._pile_x(pile) - e["x"]) < m.CELL * 0.4:
			pile["lost"] = true
			m._remove_pile(pile)
			_say(Lang.t("am_cage_lost"))
			return

func _free_animal(pile: Dictionary) -> void:
	var animal: String = pile["cage"]
	_say(Lang.t("am_freed_" + animal))
	match animal:
		"hedgehog":
			var wall: int = m._plant_index("wall")
			var col: int = pile["col"]
			var row: int = pile["row"]
			# Kupka znika z planszy dopiero po tej klatce - jez staje od razu.
			m.junk_piles.erase(m._cell_key(col, row))
			var saved_water: int = m.water
			m.water = 99999
			if m._place_plant(wall, col, row, 1.0) == "":
				var hedgehog: Dictionary = m.grid_occupancy[col][row]
				var pet := UiIcons.animal("hedgehog", m.CELL - 16)
				if pet is TextureRect:
					hedgehog["node"].texture = pet.texture
				else:
					hedgehog["node"].self_modulate.a = 0.0
					hedgehog["node"].add_child(pet)
			m.water = saved_water
		"bird":
			var bird := UiIcons.animal("bird", 48)
			bird.position = _cell_pos(pile["col"], 0) + Vector2(20, -46)
			m.add_child(bird)
			birds.append(bird)
		"frog":
			var target: Dictionary = {}
			for e in m.enemies:
				if not e["is_boss"]:
					target = e
					break
			if target.is_empty():
				pending_frogs += 1
			else:
				_frog_eats(target)
		"butterfly":
			recharge_bonus *= BUTTERFLY_RECHARGE

func _frog_eats(e: Dictionary) -> void:
	e["hp"] = 0
	var frog := UiIcons.animal("frog", 56)
	frog.position = e["node"].position
	m.add_child(frog)
	var tw := frog.create_tween()
	tw.tween_property(frog, "position:y", frog.position.y - 30, 0.25)
	tw.tween_property(frog, "modulate:a", 0.0, 0.4)
	tw.tween_callback(frog.queue_free)

func _update_animals(delta: float) -> void:
	if birds.is_empty():
		return
	bird_timer -= delta
	if bird_timer <= 0.0:
		bird_timer = BIRD_EVERY
		for bird in birds:
			m._spawn_water_drop(bird.position + Vector2(0, 60), BIRD_DROP)

# --- Zbieracz nasion ---
func _spawn_seed(origin: Vector2) -> void:
	var hit := Control.new()
	hit.size = Vector2(m.FERTILIZER_TAP_SIZE, m.FERTILIZER_TAP_SIZE)
	hit.position = origin
	hit.mouse_filter = Control.MOUSE_FILTER_STOP
	m.add_child(hit)
	var icon := UiIcons.seed_icon(40)
	icon.position = Vector2(24, 24)
	hit.add_child(icon)
	var angle := randf_range(0.0, TAU)
	var drop := {"node": hit, "vx": cos(angle) * m.WATER_DROP_SPEED, "vy": sin(angle) * m.WATER_DROP_SPEED, "life": SEED_LIFE}
	hit.gui_input.connect(func(event: InputEvent):
		if m._is_tap_press(event) and seed_drops.has(drop):
			_collect_seed(drop))
	seed_drops.append(drop)

func _collect_seed(drop: Dictionary) -> void:
	seed_drops.erase(drop)
	drop["node"].queue_free()
	seeds += 2 if help == "double_seeds" and m.current_wave < DOUBLE_SEED_WAVES else 1
	while seeds >= SEEDS_PER_PLANT:
		seeds -= SEEDS_PER_PLANT
		var pool: Array = GameState.current_loadout.filter(func(idx): return PlantData.TYPES[idx]["role"] != "vines")
		if pool.is_empty():
			pool = [0]
		free_plants_waiting.append(pool.pick_random())
	_offer_free_plant()

func _offer_free_plant() -> void:
	if free_plants_waiting.is_empty() or m.free_plant_button != null:
		return
	var idx: int = free_plants_waiting.pop_front()
	m._build_free_plant_button(idx)
	_say(Lang.f("am_seed_plant", [PlantData.name_of(idx)]))

func _update_seed_drops(delta: float) -> void:
	for drop in seed_drops.duplicate():
		m._fly_over_board(drop, delta)
		drop["life"] -= delta
		if drop["life"] <= 0.0:
			drop["node"].queue_free()
			seed_drops.erase(drop)
	_offer_free_plant()

# --- Przesadzanie ---
func _transplant_tap(col: int, row: int) -> bool:
	var plant = m.grid_occupancy[col][row]
	if move_plant.is_empty():
		if plant == null or plant.get("cells", []).size() > 1 or not can_remove(plant):
			return false
		if move_cooldown > 0.0:
			_say(Lang.f("am_move_in", [ceili(move_cooldown)]))
			return true
		move_plant = plant
		move_frame.position = _cell_pos(col, row)
		move_frame.visible = true
		_say(Lang.t("am_move_where"))
		return true
	var from: Dictionary = move_plant
	move_plant = {}
	move_frame.visible = false
	var key: String = m._cell_key(col, row)
	var adjacent: bool = abs(col - from["col"]) + abs(row - from["row"]) == 1
	if plant != null or not adjacent or m.blocked_cells.has(key) or m.junk_piles.has(key) or can_place(from["type_idx"], col, row) != "":
		_say(Lang.t("am_move_bad"))
		return true
	_move_plant_to(from, col, row)
	move_cooldown = TRANSPLANT_FAST if help == "fast_move" else TRANSPLANT_COOLDOWN
	_say("")
	return true

# --- Niewidzialne smieci ---
func _update_ghosts() -> void:
	for e in m.enemies:
		if not e.get("ghost", false):
			continue
		var seen: bool = e["hp"] < e["max_hp"] or e["row"] == firefly_row
		if not seen:
			for plant in m.plants:
				if plant["row"] == e["row"] and e["x"] - plant["base_pos"].x <= GHOST_SIGHT_CELLS * m.CELL:
					seen = true
					break
		if seen:
			e["ghost"] = false
			e["node"].self_modulate.a = 1.0

# --- Olbrzym ---
func _show_giant_choice() -> void:
	giant_layer = Control.new()
	giant_layer.position = Vector2(m.GRID_LEFT, m.GRID_TOP + m.ROWS * m.CELL + 40)
	m.add_child(giant_layer)
	var caption := Label.new()
	caption.text = Lang.t("am_giant_choose")
	caption.add_theme_font_size_override("font_size", 20)
	giant_layer.add_child(caption)
	var x := 0.0
	for idx in GameState.current_loadout:
		if PlantData.TYPES[idx]["role"] == "vines":
			continue
		var btn := Button.new()
		btn.position = Vector2(x, 30)
		btn.size = Vector2(70, 70)
		btn.focus_mode = Control.FOCUS_NONE
		UiIcons.style_button(btn, m.TILE_BG_COLOR, 10)
		var icon := UiIcons.plant_icon(idx, 58)
		icon.position = Vector2(6, 6)
		btn.add_child(icon)
		var plant_idx: int = idx
		btn.pressed.connect(func(): _choose_giant(plant_idx))
		giant_layer.add_child(btn)
		x += 80.0

func _choose_giant(idx: int) -> void:
	giant_type = idx
	giant_layer.queue_free()
	var btn := Button.new()
	btn.position = Vector2(m.SIDEBAR_X + 170, m.SIDEBAR_TOP - 8)
	btn.size = Vector2(110, 56)
	btn.focus_mode = Control.FOCUS_NONE
	UiIcons.style_button(btn, Color(0.85, 0.5, 0.15), 10)
	var icon := UiIcons.plant_icon(idx, 50)
	icon.position = Vector2(4, 3)
	btn.add_child(icon)
	var cost := Label.new()
	cost.text = str(_giant_cost())
	cost.position = Vector2(58, 14)
	cost.add_theme_font_size_override("font_size", 20)
	btn.add_child(cost)
	btn.pressed.connect(func():
		if giant_used:
			return
		giant_selected = not giant_selected
		m.selected_plant_type = -1
		_say(Lang.t("am_giant_place") if giant_selected else "")
		m._update_hud())
	m.add_child(btn)
	_say(Lang.t("am_giant_ready"))
	giant_button = btn

func _giant_cost() -> int:
	return PlantData.TYPES[giant_type]["cost"] * 2

func _try_place_giant(col: int, row: int) -> void:
	if col >= m.COLS - 1 or row >= m.ROWS - 1:
		_say(Lang.t("am_giant_no_room"))
		return
	var cells := [Vector2i(col, row), Vector2i(col + 1, row), Vector2i(col, row + 1), Vector2i(col + 1, row + 1)]
	for cell in cells:
		var key: String = m._cell_key(cell.x, cell.y)
		if m.grid_occupancy[cell.x][cell.y] != null or m.blocked_cells.has(key) or m.junk_piles.has(key):
			_say(Lang.t("am_giant_no_room"))
			return
	if m.water < _giant_cost():
		_say(Lang.t("too_little_water"))
		return
	m.water -= _giant_cost() - PlantData.TYPES[giant_type]["cost"]
	if m._place_plant(giant_type, col, row) != "":
		return
	var plant: Dictionary = m.grid_occupancy[col][row]
	plant["giant"] = true
	plant["cells"] = cells
	plant["hp"] *= GIANT_HP
	plant["max_hp"] = plant["hp"]
	for cell in cells:
		m.grid_occupancy[cell.x][cell.y] = plant
	var node: Control = plant["node"]
	node.size = Vector2(m.CELL * 2 - 16, m.CELL * 2 - 16)
	node.pivot_offset = node.size / 2.0
	plant["boost_ring"].size = node.size + Vector2(16, 16)
	if help == "giant_boost":
		plant["fertilizer_free"] = true
		plant["boosted"] = true
		plant["boost_timer"] = INF
		plant["boost_ring"].visible = true
	giant_used = true
	giant_selected = false
	giant_button.queue_free()
	_say("")
	m._update_hud()

# --- Pszczeli roj ---
func _update_swarm(delta: float) -> void:
	if swarm_bee != null or swarm_choice != null:
		return
	swarm_timer -= delta
	if swarm_timer > 0.0:
		return
	var interval: Array = AddonData.SWARM_INTERVALS[stage]
	swarm_timer = randf_range(interval[0], interval[1])
	var life := SWARM_EARLY_LIFE if help == "early_bee" and time < SWARM_EARLY_LIFE else SWARM_BEE_LIFE
	swarm_bee = Button.new()
	swarm_bee.flat = true
	swarm_bee.size = Vector2(70, 70)
	swarm_bee.focus_mode = Control.FOCUS_NONE
	swarm_bee.add_child(UiIcons.bee(70))
	var y: float = m.GRID_TOP + randi_range(0, m.ROWS - 1) * m.CELL + 8
	swarm_bee.position = Vector2(m.GRID_LEFT + m.COLS * m.CELL - 70, y)
	m.add_child(swarm_bee)
	var bee := swarm_bee
	var tw := bee.create_tween()
	tw.tween_property(bee, "position:x", float(m.GRID_LEFT), life)
	tw.tween_callback(func():
		if swarm_bee == bee:
			swarm_bee = null
		bee.queue_free())
	bee.pressed.connect(func():
		tw.kill()
		swarm_bee = null
		bee.queue_free()
		_show_swarm_choice())

func _show_swarm_choice() -> void:
	swarm_choice = Control.new()
	swarm_choice.position = Vector2(m.GRID_LEFT + 160, m.GRID_TOP + m.ROWS * m.CELL + 40)
	m.add_child(swarm_choice)
	var x := 0.0
	for bonus in AddonData.SWARM_BONUSES:
		var btn := Button.new()
		btn.text = Lang.t("am_bonus_" + bonus)
		btn.position = Vector2(x, 0)
		btn.size = Vector2(200, 60)
		btn.focus_mode = Control.FOCUS_NONE
		btn.add_theme_font_size_override("font_size", 18)
		UiIcons.style_button(btn, Color(0.85, 0.65, 0.1), 12)
		var chosen: String = bonus
		btn.pressed.connect(func():
			bonus_left[chosen] = SWARM_BONUS_TIME
			swarm_choice.queue_free()
			swarm_choice = null)
		swarm_choice.add_child(btn)
		x += 215.0
	_say(Lang.t("am_bonus_choose"))

# --- Sortowanie smieci ---
func _setup_sorting() -> void:
	var colors := [AddonData.BIN_YELLOW, AddonData.BIN_BLUE, AddonData.BIN_BLACK]
	colors.shuffle()
	var deck: Array = GameState.current_loadout.duplicate()
	deck.shuffle()
	for k in range(deck.size()):
		plant_bins[deck[k]] = colors[k % colors.size()]
	for tile in m.plant_tiles:
		var badge := _bin_badge(plant_bins.get(tile["plant_idx"], ""), 22)
		badge.position = Vector2(m.TILE_ICON_SIZE - 10, 4)
		tile["button"].add_child(badge)
	_say(Lang.t("am_sorting_hint"))

func _bin_badge(bin: String, size: float) -> Control:
	var badge := Panel.new()
	badge.size = Vector2(size, size)
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := UiIcons.round_style(AddonData.BIN_COLORS.get(bin, Color(0.5, 0.5, 0.5)), int(size / 2.0))
	sb.set_border_width_all(2)
	sb.border_color = Color(1, 1, 1)
	badge.add_theme_stylebox_override("panel", sb)
	return badge

func _add_bin_badge(node: Control, bin: String) -> void:
	if bin == "":
		return
	var badge := _bin_badge(bin, 20)
	badge.position = Vector2(node.size.x - 18, -4)
	node.add_child(badge)
