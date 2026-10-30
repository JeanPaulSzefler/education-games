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
const JUNK_PILE_TEXTURE := "res://assets/sprites/ui/junk_pile.png"

# --- Kupki smieci: pojawiaja sie w prawej polowie planszy (patrz
# "junk_pile_waves" w level_data.gd), na starcie kazdej fali wypuszczaja
# jednego slabego wroga. Rosliny moga je zestrzelic (pociski, wybuch), a
# Pnacza posadzone na kupce niszcza ja od razu. Na kupce nie da sie sadzic
# innych roslin; szkodniki przechodza po niej bez przeszkod. ---
const JUNK_PILE_HP := 250
const JUNK_PILE_MIN_COL := 5
const ENDLESS_FIRST_PILE_WAVE := 2   # tryb nieskonczony: kupka od 3. fali...
const ENDLESS_PILE_EVERY := 3        # ...i potem co tyle fal

# Roza: pocisk naprowadzany na cel w dowolnym rzedzie.
const HOMING_SPEED := 320.0
const HOMING_HIT_RADIUS := 30.0
const PROJECTILE_SPEED := 300.0
const AIMED_PROJECTILE_COLOR := Color(1.0, 0.45, 0.6)
const VOLLEY_PROJECTILE_COLOR := Color(0.65, 0.35, 0.9)
const BURN_COLOR := Color(1.0, 0.6, 0.35)
const FROZEN_COLOR := Color(0.6, 0.85, 1.0)

const HEALTH_BAR_HIDE_DELAY := 2.0
const HEALTH_BAR_HEIGHT := 6

# Kropla wody / nawozu: wizualny rozmiar ikony vs wieksze (niewidoczne) pole
# reagujace na tapniecie, zeby latwiej bylo ja zlapac.
const WATER_DROP_VISUAL_SIZE := 44
const WATER_DROP_TAP_SIZE := 88
const WATER_DROP_SPEED := 36.0
# Brudna Gabka: predkosc, z jaka skradziona kropla "dolatuje" do stwora
# (celowo wolniej niz normalny lot kropli, zeby gracz mial szanse ja odzyskac).
const WATER_DROP_STEAL_SPEED := 110.0
const WATER_DROP_STOLEN_COLOR := Color(0.42, 0.4, 0.18)
const FERTILIZER_VISUAL_SIZE := 40
const FERTILIZER_TAP_SIZE := 88

# Nawoz: tapniecie ikony nawozu w HUD, potem tapniecie wlasnej rosliny -
# roslina dostaje zloty pierscien i przez chwile mocno zwiekszona intensywnosc ataku.
const FERTILIZER_BOOST_MULTIPLIER := 2.5
const FERTILIZER_BOOST_DURATION := 9.0
# Rosliny jednorazowe trzymaja nawoz az do uzycia, zamiast tracic go po czasie.
const ONE_SHOT_ROLES := ["freeze", "burn", "bomb", "gust"]

# Podmuch wiatru: tyle pikseli na sekunde przesuwa sie chmurka, a razem z nia
# wrogowie, ktorych juz dosiegnela.
const GUST_SPEED := 600.0
# Wybuch Bumorzecha: widac go w pelnym rozmiarze w tej samej klatce, w ktorej
# wrogowie traca zycie, a potem tylko zanika.
const BOMB_FADE_TIME := 0.3

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
# Kafelek wybranej rosliny: jasniejsze tlo, grubsza ramka i wysuniecie w prawo.
const TILE_BG_COLOR := Color(0.16, 0.22, 0.14)
const TILE_SELECTED_BG_COLOR := Color(0.42, 0.38, 0.1)
const TILE_BORDER_WIDTH := 4
const TILE_SELECTED_BORDER_WIDTH := 7
const TILE_SELECTED_SHIFT := 10.0
# Roslina, na ktora nie stac gracza kroplami wody - czerwony odcien i ramka.
const TILE_NO_WATER_MODULATE := Color(1.0, 0.55, 0.55)
const TILE_NO_WATER_BORDER_COLOR := Color(0.85, 0.15, 0.15)
# Cien odnawiania (jak w PvZ): ciemna nakladka, ktora kurczy sie od dolu do
# gory w miare uplywu czasu odnowienia.
const TILE_COOLDOWN_SHADE := Color(0, 0, 0, 0.6)

# --- Przycisk usuwania roslin ("X") pod prawym dolnym rogiem planszy ---
const REMOVE_BTN_SIZE := 64.0
const REMOVE_ACTIVE_BG_COLOR := Color(0.6, 0.12, 0.12)

# --- Przyciski "WYJSCIE" i pauza nad prawym gornym rogiem planszy (notatki
# 2026-10-06). Okienka pauzy i "Czy na pewno?" leza na osobnej warstwie
# (CanvasLayer), ktora dziala takze przy zatrzymanym drzewie gry. ---
const TOP_BTN_HEIGHT := 52.0
const PAUSE_BTN_WIDTH := 52.0
const EXIT_BTN_WIDTH := 120.0
const TOP_BTN_GAP := 8.0
const OVERLAY_LAYER := 10
const STAY_BTN_COLOR := Color(0.25, 0.6, 0.25)
const LEAVE_BTN_COLOR := Color(0.75, 0.18, 0.15)

const START_WATER := 100

# Zwykle poziomy: od 3. fali (indeks 2) kazda fala dostaje dodatkowych wrogow -
# tyle, ile wynosi ten ulamek jej zapisanej wielkosci (1.0 = dwa razy wiecej).
# Dodatkowi wrogowie to kopie typow z tej samej fali, w losowych rzedach.
const EXTRA_ENEMIES_FROM_WAVE_3 := 1.0
# TWARDA ZASADA: w 1. fali kazdego poziomu (i trybu nieskonczonego) najwyzej
# tylu wrogow, lacznie z tymi z kupek smieci - inaczej gracz, ktory dopiero
# zaczyna sadzic rosliny, nie ma szans. Pilnowane w _update_wave_spawning(),
# niezaleznie od danych w level_data.gd; w 1. fali nie pojawia sie tez kupka.
const MAX_FIRST_WAVE_ENEMIES := 4
const SPAWN_INTERVAL := 1.1
const BETWEEN_WAVES_TIME := 5.0

# --- Tasma roslin (wydarzenie): pasek zapelnia sie sam, co jakis czas. ---
const BELT_FIRST_PLANT_TIME := 1.0
const BELT_MIN_INTERVAL := 3.5
const BELT_MAX_INTERVAL := 6.0

# --- Pozostale wydarzenia (zasady w event_data.gd). ---
const SKY_DROP_FIRST_INTERVAL := 6.0
const SKY_DROP_INTERVAL_PER_WAVE := 1.0
const SKY_DROP_MAX_INTERVAL := 11.0
const SKY_DROP_VALUE := 20
const SKY_DROP_FALL_SPEED := 70.0
const COVER_COLOR := Color(0.03, 0.04, 0.1, 0.88)
const FOG_COLOR := Color(0.85, 0.88, 0.9, 0.9)
const FOG_FIRST_COL := 5
const FOG_ON_TIME := 20.0
const FOG_OFF_TIME := 5.0
const FOG_BLOW_TIME := 10.0
const BOSS_RUSH_BREAK := 12.0
const BOSS_RUSH_WATER := 100
const HELP_START_WATER := 50
const HELP_EXTRA_TIME := 20.0
const RACE_SPARE_TIME := 45.0
const RACE_BOSS_TIME := 30.0
const RACE_THREE_STARS := 0.45
const RACE_TWO_STARS := 0.2
const NO_FERTILIZER_LIMIT := 999
const COIN_DROP_LIFE := 6.0
const COIN_DROP_VISUAL_SIZE := 44
const BELT_PREVIEW_SIZE := 3
const BELT_PREVIEW_Y := 626.0
const BELT_PREVIEW_TILE := 72.0

# --- Gra zespolowa: wiecej wrogow (ulamek wielkosci fali), wiecej wody na start
# (woda jest wspolna), a host wysyla stan planszy tyle razy na sekunde. ---
const TEAM_EXTRA_ENEMIES := 0.5
const TEAM_START_WATER := 150
const TEAM_SNAPSHOT_INTERVAL := 1.0 / 15.0
const TEAM_VIEW_SMOOTHING := 20.0

# --- Tryb nieskonczony: trudnosc rosnie z czasem przetrwanym przez gracza
# (w minutach, patrz _endless_difficulty()). ---
const ENDLESS_FIRST_WAVE_SIZES := [2, 3]   # fale 1 i 2 celowo male
const ENDLESS_BASE_WAVE_SIZE := 5          # fala 3
const ENDLESS_SIZE_PER_WAVE := 1.0         # +wrogow z kazda kolejna fala
const ENDLESS_SIZE_PER_MINUTE := 1.5       # +wrogow za kazda przetrwana minute
const ENDLESS_HP_PER_MINUTE := 0.12        # +12% HP wrogow i bossow na minute
const ENDLESS_SPEED_PER_MINUTE := 0.04     # +4% predkosci na minute...
const ENDLESS_MAX_SPEED_MULT := 1.6        # ...ale najwyzej tyle
const ENDLESS_MIN_SPAWN_INTERVAL := 0.35
const ENDLESS_MIN_BETWEEN_WAVES := 2.0
const ENDLESS_FIRST_BOSS_WAVE := 4         # indeks fali (5. fala) z pierwszym bossem
const ENDLESS_BOSS_EVERY := 4              # potem boss co tyle fal
const ENDLESS_EXTRA_BOSS_EVERY := 12       # co tyle fal kolejny boss naraz
const ENDLESS_FIRST_FERTILIZER_WAVE := 3   # indeks fali z pierwszym nawozem
const ENDLESS_FERTILIZER_EVERY := 4        # potem nawoz co tyle fal

var PLANT_TYPES: Array
var BOSS_TYPES: Array
var waves := []
var current_wave := 0
var wave_spawn_queue := []
var time_to_next_spawn := 0.0
var between_waves_timer := 0.0
var wave_in_progress := false
var boss_spawned := false

var endless := false
var endless_time := 0.0
var kills := 0
var kills_label: Label

var water := START_WATER
var fertilizer := 0
var fertilizer_mode := false
# Indeksy fal, na poczatku ktorych na planszy pojawia sie nawoz.
var fertilizer_waves: Array = []
# Podmuchy w locie: {"x", "row", "dmg", "knockback", "hit": [wrogowie juz trafieni]}.
var active_gusts: Array = []
# Tryb usuwania: tapniecie "X", potem tapniecie rosliny - roslina znika bez
# zwrotu kropel wody.
var remove_mode := false
var remove_button: Button
var remove_border_sb: StyleBoxFlat
# Otwarte okienko pauzy albo "Czy na pewno?" (null = gra toczy sie normalnie).
var pause_layer: CanvasLayer
var top_buttons: Array = []
# plant_idx -> pozostaly czas odnowienia (s); brak wpisu = roslina gotowa.
var plant_cooldowns := {}

var grid_occupancy := []
var blocked_cells := {}
var plants := []
var enemies := []
var projectiles := []
var homing_projectiles := []
# _cell_key(col, row) -> {"node", "hp", "max_hp", "col", "row", "bar", "hurt_timer"}
var junk_piles := {}
var water_drops := []
var fertilizer_drops := []
var selected_plant_type := -1
var game_over := false
var water_count_label: Label
var wave_label: Label
var message_label: Label
# {"plant_idx", "button", "border_sb", "base_y", "cooldown_shade"} - jeden wpis
# na kafelek rosliny w pasku
var plant_tiles := []
# {"button", "border_sb", "count_label"} - kafelek nawozu (ten sam styl co rosliny)
var fertilizer_tile: Dictionary
var boss_name_label: Label
var boss_bar_bg: ColorRect
var boss_bar_fg: ColorRect

# Tekstura ostatniego wroga/bossa, ktory dotarl do domu - do duzej ikonki na
# ekranie przegranej (runda C, C7).
var last_enemy_texture := ""

# Wydarzenie: jego zasady i pomoc kupiona na ten etap ("" = bez pomocy).
var event_game := false
var event_rules := {}
var help_type := ""
var sky_drop_timer := SKY_DROP_FIRST_INTERVAL
var fertilizer_event_timer := 0.0
# Noc i mgla: nakladki na pola [kolumna][rzad]; latarnia swieci nad jednym rzedem.
var cover_cells: Array = []
var lantern_pending := false
var lantern_row := -1
var fog_on := true
var fog_phase_left := FOG_ON_TIME
var fog_blow_left := 0.0
var fog_blow_button: Button
# Darmowa roslina z pomocy (Bumorzech): jej przycisk i czy jest wybrana.
var free_plant_button: Button
var free_plant_selected := false
var shield_left := 0
var race_total := 0.0
var race_left := 0.0
var coin_drops: Array = []
# Tasma z podgladem: {"plant", "swapped"} i przyciski podgladu.
var belt_queue: Array = []
var belt_preview_layer: Control

# Tasma roslin: bez wody i talii; belt_items to rosliny na pasku po kolei,
# belt_slot to wybrane miejsce na pasku (-1 = zadne).
var belt := false
var belt_items: Array = []
var belt_slot := -1
var belt_timer := BELT_FIRST_PLANT_TIME

# Gra zespolowa: symulacje liczy host; gosc (is_guest) tylko wysyla akcje i
# rysuje to, co dostaje. net_views: klucz -> {"node", "target", pasek zycia...}.
var team := false
var is_guest := false
var next_entity_id := 1
var snapshot_timer := 0.0
var net_views := {}

func _ready() -> void:
	team = NetSession.active
	is_guest = team and not NetSession.is_host
	event_game = GameState.is_event_game()
	if event_game:
		event_rules = GameState.current_event()
		belt = event_rules["planting"] == "belt"
		if GameState.event_help_active and event_rules.has("help"):
			help_type = event_rules["help"]["type"]
		GameState.event_help_active = false
	if team:
		water = TEAM_START_WATER
	randomize()
	PLANT_TYPES = PlantData.TYPES
	BOSS_TYPES = BossData.TYPES
	endless = GameState.is_endless_level(GameState.current_level_index)
	# W trybie nieskonczonym fale sa dopisywane w locie, wiec potrzebna jest
	# wlasna (modyfikowalna) tablica zamiast stalej z LevelData.
	waves = [] if endless else _current_level()["waves"]
	_setup_fertilizer_waves()
	between_waves_timer = 3.0
	_setup_grid_occupancy()
	_setup_blocked_cells()
	_build_background()
	_build_grid_visual()
	_build_hud()
	_build_top_buttons()
	_build_water_counter()
	_build_plant_bar()
	_build_fertilizer_tile()
	_build_remove_button()
	_update_hud()
	if team:
		_setup_team()
	if event_game:
		_setup_event()

func _current_level() -> Dictionary:
	return GameState.current_level()

# Nawozy pojawiaja sie same, rozlozone rowno na kolejne etapy poziomu.
func _setup_fertilizer_waves() -> void:
	var count := LevelData.fertilizer_count(GameState.current_level_index)
	for k in range(count):
		fertilizer_waves.append(int((k + 1) * waves.size() / float(count + 1)))

func _fertilizer_appears_on_wave(wave_idx: int) -> bool:
	if endless:
		return wave_idx >= ENDLESS_FIRST_FERTILIZER_WAVE and (wave_idx - ENDLESS_FIRST_FERTILIZER_WAVE) % ENDLESS_FERTILIZER_EVERY == 0
	return fertilizer_waves.has(wave_idx)

# W grze zespolowej nawozy sa wspolne, wiec limit ustala NetSession.
func _fertilizer_limit() -> int:
	if event_rules.has("fertilizer_every"):
		return NO_FERTILIZER_LIMIT
	return NetSession.team_fertilizer_limit if team else GameState.fertilizer_limit

func _fertilizer_full_message() -> String:
	return "Komplet nawozow (%d) - najpierw ktorys wykorzystaj" % _fertilizer_limit()

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
	level_title.text = _current_level()["name"]
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

	# Tryb nieskonczony: licznik pokonanych wrogow i rekord, w prawym gornym
	# rogu, pod przyciskami WYJSCIE i pauzy.
	kills_label = Label.new()
	kills_label.position = Vector2(GRID_LEFT + COLS * CELL - 280, TOP_BTN_HEIGHT + 4)
	kills_label.size = Vector2(280, 30)
	kills_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	kills_label.add_theme_font_size_override("font_size", 20)
	kills_label.visible = endless
	add_child(kills_label)

func _build_water_counter() -> void:
	var icon := _make_sprite(WATER_DROP_TEXTURE, WATER_ICON_SIZE)
	icon.position = Vector2(SIDEBAR_X, SIDEBAR_TOP)
	icon.visible = not belt
	add_child(icon)

	water_count_label = Label.new()
	water_count_label.visible = not belt
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
	# flat = false: przycisk "flat" w ogole nie rysuje StyleBoxa (tla i ramki).
	btn.flat = false
	btn.focus_mode = Control.FOCUS_NONE

	var border_sb := StyleBoxFlat.new()
	border_sb.bg_color = TILE_BG_COLOR
	border_sb.set_border_width_all(TILE_BORDER_WIDTH)
	border_sb.border_color = TILE_BORDER_COLOR
	border_sb.set_corner_radius_all(10)
	for state in ["normal", "hover", "pressed"]:
		btn.add_theme_stylebox_override(state, border_sb)
	add_child(btn)

	var icon := _make_sprite(icon_texture, TILE_ICON_SIZE)
	icon.position = Vector2(10, (TILE_HEIGHT - TILE_ICON_SIZE) / 2.0)
	btn.add_child(icon)

	return {"button": btn, "border_sb": border_sb, "base_y": y}

# Podswietlenie wybranego kafelka: jasniejsze tlo, grubsza ramka i wysuniecie
# w prawo, zeby od razu bylo widac, co zostanie posadzone/uzyte.
func _set_tile_selected(tile: Dictionary, selected: bool, border_color: Color) -> void:
	var sb: StyleBoxFlat = tile["border_sb"]
	sb.bg_color = TILE_SELECTED_BG_COLOR if selected else TILE_BG_COLOR
	sb.set_border_width_all(TILE_SELECTED_BORDER_WIDTH if selected else TILE_BORDER_WIDTH)
	sb.border_color = TILE_SELECTED_BORDER_COLOR if selected else border_color
	tile["button"].position.x = SIDEBAR_X + (TILE_SELECTED_SHIFT if selected else 0.0)

func _build_plant_bar() -> void:
	if belt:
		return
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

		# Cien odnawiania - na starcie ukryty (wysokosc 0), patrz _update_cooldowns().
		var shade := ColorRect.new()
		shade.color = TILE_COOLDOWN_SHADE
		shade.size = Vector2(TILE_WIDTH, 0)
		shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tile["button"].add_child(shade)
		tile["cooldown_shade"] = shade

		tile["button"].pressed.connect(_on_plant_button_pressed.bind(plant_idx))
		plant_tiles.append(tile)

func _build_fertilizer_tile() -> void:
	var loadout_size: int = GameState.MAX_LOADOUT if belt else plant_tiles.size()
	var y :=_sidebar_tiles_top() + loadout_size * (TILE_HEIGHT + TILE_GAP)
	fertilizer_tile = _build_tile(y, FERTILIZER_TEXTURE)

	var count_label := Label.new()
	count_label.position = Vector2(TILE_ICON_SIZE + 22, (TILE_HEIGHT - 30) / 2.0)
	count_label.size = Vector2(90, 30)
	count_label.add_theme_font_size_override("font_size", 22)
	count_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fertilizer_tile["button"].add_child(count_label)
	fertilizer_tile["count_label"] = count_label

	fertilizer_tile["button"].pressed.connect(_on_fertilizer_button_pressed)

# Przycisk "X" pod prawym dolnym rogiem planszy - wlacza/wylacza tryb usuwania.
func _build_remove_button() -> void:
	remove_button = Button.new()
	remove_button.text = "X"
	remove_button.add_theme_font_size_override("font_size", 36)
	remove_button.add_theme_color_override("font_color", Color(0.95, 0.35, 0.3))
	remove_button.add_theme_color_override("font_hover_color", Color(0.95, 0.35, 0.3))
	remove_button.add_theme_color_override("font_pressed_color", Color(0.95, 0.35, 0.3))
	remove_button.position = Vector2(GRID_LEFT + COLS * CELL - REMOVE_BTN_SIZE, GRID_TOP + ROWS * CELL + 8)
	remove_button.size = Vector2(REMOVE_BTN_SIZE, REMOVE_BTN_SIZE)
	remove_button.focus_mode = Control.FOCUS_NONE

	remove_border_sb = StyleBoxFlat.new()
	remove_border_sb.bg_color = TILE_BG_COLOR
	remove_border_sb.set_border_width_all(TILE_BORDER_WIDTH)
	remove_border_sb.border_color = TILE_BORDER_COLOR
	remove_border_sb.set_corner_radius_all(10)
	for state in ["normal", "hover", "pressed"]:
		remove_button.add_theme_stylebox_override(state, remove_border_sb)
	remove_button.pressed.connect(_on_remove_button_pressed)
	add_child(remove_button)

# --- WYJSCIE i pauza ---
func _build_top_buttons() -> void:
	var right := GRID_LEFT + COLS * CELL

	var pause_btn := _make_top_button(Vector2(right - PAUSE_BTN_WIDTH, 2), Vector2(PAUSE_BTN_WIDTH, TOP_BTN_HEIGHT))
	var icon := UiIcons.pause(TOP_BTN_HEIGHT - 12)
	icon.position = Vector2(6, 6)
	pause_btn.add_child(icon)
	pause_btn.pressed.connect(_on_pause_pressed)
	# W grze zespolowej nie ma pauzy - gra toczy sie u obu graczy naraz.
	pause_btn.visible = not team

	var exit_btn := _make_top_button(Vector2(right - PAUSE_BTN_WIDTH - TOP_BTN_GAP - EXIT_BTN_WIDTH, 2), Vector2(EXIT_BTN_WIDTH, TOP_BTN_HEIGHT))
	exit_btn.text = "WYJSCIE"
	exit_btn.add_theme_font_size_override("font_size", 20)
	exit_btn.pressed.connect(_on_exit_pressed)

	top_buttons = [pause_btn, exit_btn]

# Po koncu gry sa juz przyciski "Zagraj ponownie" / "Wybierz poziom".
func _hide_top_buttons() -> void:
	for btn in top_buttons:
		btn.visible = false

func _make_top_button(pos: Vector2, btn_size: Vector2) -> Button:
	var btn := Button.new()
	btn.position = pos
	btn.size = btn_size
	btn.focus_mode = Control.FOCUS_NONE
	var sb := StyleBoxFlat.new()
	sb.bg_color = TILE_BG_COLOR
	sb.set_border_width_all(TILE_BORDER_WIDTH)
	sb.border_color = TILE_BORDER_COLOR
	sb.set_corner_radius_all(10)
	for state in ["normal", "hover", "pressed"]:
		btn.add_theme_stylebox_override(state, sb)
	add_child(btn)
	return btn

func _on_pause_pressed() -> void:
	if game_over or pause_layer != null:
		return
	var layer := _open_pause_layer(Color(0.1, 0.25, 0.1, 0.7))

	# Duzy przycisk "graj" na srodku ekranu - wznawia gre.
	var size := 180.0
	var resume_btn := Button.new()
	resume_btn.position = Vector2(VIEWPORT_WIDTH - size, VIEWPORT_HEIGHT - size) / 2.0
	resume_btn.size = Vector2(size, size)
	resume_btn.focus_mode = Control.FOCUS_NONE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.95, 0.95, 0.9)
	sb.set_border_width_all(6)
	sb.border_color = Color(0.2, 0.2, 0.2)
	sb.set_corner_radius_all(24)
	for state in ["normal", "hover", "pressed"]:
		resume_btn.add_theme_stylebox_override(state, sb)
	var icon := UiIcons.play(size - 40, Color(0.15, 0.15, 0.15))
	icon.position = Vector2(20, 20)
	resume_btn.add_child(icon)
	resume_btn.pressed.connect(_close_pause_layer)
	layer.add_child(resume_btn)

func _on_exit_pressed() -> void:
	if game_over or pause_layer != null:
		return
	var layer := _open_pause_layer(Color(0, 0, 0, 0.55))

	var panel := Panel.new()
	panel.size = Vector2(460, 240)
	panel.position = (Vector2(VIEWPORT_WIDTH, VIEWPORT_HEIGHT) - panel.size) / 2.0
	var panel_sb := StyleBoxFlat.new()
	panel_sb.bg_color = Color(0.95, 0.93, 0.85)
	panel_sb.set_border_width_all(5)
	panel_sb.border_color = Color(0.25, 0.2, 0.15)
	panel_sb.set_corner_radius_all(18)
	panel.add_theme_stylebox_override("panel", panel_sb)
	layer.add_child(panel)

	var question := Label.new()
	question.text = "Czy na pewno?"
	question.add_theme_font_size_override("font_size", 36)
	question.add_theme_color_override("font_color", Color(0.15, 0.12, 0.1))
	question.position = Vector2(0, 30)
	question.size = Vector2(panel.size.x, 50)
	question.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(question)

	var stay_btn := _make_dialog_button("ZOSTAN", STAY_BTN_COLOR, Vector2(40, 130))
	stay_btn.pressed.connect(_close_pause_layer)
	panel.add_child(stay_btn)

	var leave_btn := _make_dialog_button("WYJDZ", LEAVE_BTN_COLOR, Vector2(250, 130))
	leave_btn.pressed.connect(_leave_to_level_select)
	panel.add_child(leave_btn)

func _make_dialog_button(label: String, color: Color, pos: Vector2) -> Button:
	var btn := Button.new()
	btn.text = label
	btn.position = pos
	btn.size = Vector2(170, 70)
	btn.focus_mode = Control.FOCUS_NONE
	btn.add_theme_font_size_override("font_size", 26)
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(35)
	for state in ["normal", "hover", "pressed"]:
		btn.add_theme_stylebox_override(state, sb)
	return btn

# Zatrzymuje gre (wrogow, pociski, krople, animacje) i zaslania ja
# polprzezroczystym tlem, ktore tez blokuje klikanie w plansze.
func _open_pause_layer(shade: Color) -> CanvasLayer:
	pause_layer = CanvasLayer.new()
	pause_layer.layer = OVERLAY_LAYER
	pause_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(pause_layer)

	var bg := ColorRect.new()
	bg.color = shade
	bg.position = Vector2(0, 0)
	bg.size = Vector2(VIEWPORT_WIDTH, VIEWPORT_HEIGHT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	pause_layer.add_child(bg)

	get_tree().paused = not team
	return pause_layer

func _close_pause_layer() -> void:
	get_tree().paused = false
	if pause_layer != null:
		pause_layer.queue_free()
		pause_layer = null

func _leave_to_level_select() -> void:
	# W trybie nieskonczonym przerwana gra tez moze pobic rekord.
	if endless:
		GameState.submit_endless_score(kills)
	NetSession.end_session()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/Events.tscn" if event_game else "res://scenes/LevelSelect.tscn")

func _on_plant_button_pressed(idx: int) -> void:
	if game_over:
		return
	free_plant_selected = false
	if plant_cooldowns.has(idx):
		message_label.text = "Ta roslina jeszcze odrasta - poczekaj chwile"
		return
	if water < PLANT_TYPES[idx]["cost"]:
		message_label.text = "Za malo kropel wody"
		return
	# Ponowne tapniecie wybranej rosliny odznacza ja.
	selected_plant_type = -1 if selected_plant_type == idx else idx
	fertilizer_mode = false
	remove_mode = false
	message_label.text = ""
	_update_hud()

func _on_fertilizer_button_pressed() -> void:
	if game_over or fertilizer <= 0:
		return
	fertilizer_mode = true
	selected_plant_type = -1
	remove_mode = false
	_update_hud()

func _on_remove_button_pressed() -> void:
	if game_over:
		return
	remove_mode = not remove_mode
	selected_plant_type = -1
	fertilizer_mode = false
	message_label.text = ""
	_update_hud()

func _on_tile_gui_input(event: InputEvent, col: int, row: int) -> void:
	if game_over:
		return
	if not _is_tap_press(event):
		return
	if is_guest:
		_guest_tile_tap(col, row)
		return
	if lantern_pending:
		lantern_pending = false
		lantern_row = row
		message_label.text = ""
		return
	if remove_mode:
		_try_remove_plant(col, row)
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
	var error := _place_plant(selected_plant_type, col, row)
	message_label.text = error
	if error != "":
		return
	if belt:
		belt_items.remove_at(belt_slot)
		belt_slot = -1
		_rebuild_belt_tiles()
	elif free_plant_selected:
		free_plant_selected = false
		free_plant_button.queue_free()
		free_plant_button = null
	else:
		plant_cooldowns[selected_plant_type] = _recharge_time(selected_plant_type)
	selected_plant_type = -1
	_update_hud()

# Pnacza nie maja czego wzmocnic na planszy, wiec ulepszenie skraca ich odnawianie.
func _recharge_time(type_idx: int) -> float:
	var recharge: float = PLANT_TYPES[type_idx]["recharge"]
	if PLANT_TYPES[type_idx]["role"] == "vines":
		return recharge / GameState.plant_power(type_idx)
	return recharge

# Sadzi rosline (u hosta, takze na prosbe goscia). Zwraca powod odmowy albo "".
# power: sila z ulepszen gracza, ktory sadzi; 0 = gracz na tym telefonie.
func _place_plant(type_idx: int, col: int, row: int, power := 0.0) -> String:
	if power <= 0.0:
		power = GameState.plant_power(type_idx)
	if blocked_cells.has(_cell_key(col, row)):
		return "Na tym polu nie mozna sadzic"
	var pt = PLANT_TYPES[type_idx]
	var pile = junk_piles.get(_cell_key(col, row))
	if pt["role"] == "vines":
		if pile == null:
			return "Pnacza sadzi sie tylko na kupkach smieci"
	elif pile != null:
		return "Tu lezy kupka smieci - zestrzel ja albo posadz na niej Pnacza"
	if grid_occupancy[col][row] != null:
		return "To pole jest zajete"
	var cost: int = 0 if belt or free_plant_selected else pt["cost"]
	if water < cost:
		return "Za malo kropel wody"
	water -= cost
	if pt["role"] == "vines":
		_vines_destroy_pile(pile, pt["texture"])
		return ""
	var node := _make_sprite(pt["texture"], CELL - 16)
	node.position = Vector2(GRID_LEFT + col * CELL + 8, GRID_TOP + row * CELL + 8)
	add_child(node)
	var bar := _add_health_bar(node, CELL - 16)

	# Zloty pierscien pokazywany tylko podczas dzialania nawozu.
	var ring := _make_sprite(BOOST_RING_TEXTURE, CELL)
	ring.position = Vector2(-8, -8)
	ring.visible = false
	node.add_child(ring)

	var plant_hp: float = pt["hp"] * power if pt["role"] == "wall" else float(pt["hp"])
	var plant := {
		"id": _new_entity_id(), "power": power,
		"node": node, "hp": plant_hp, "max_hp": plant_hp, "col": col, "row": row,
		"type_idx": type_idx, "atk_timer": 0.0,
		"gen_timer": pt.get("water_interval", 0.0) * _cactus_water_multiplier(),
		"bar": bar, "hurt_timer": HEALTH_BAR_HIDE_DELAY + 1.0,
		"boost_ring": ring, "boosted": false, "boost_timer": 0.0,
		"disable_timer": 0.0, "used": false,
		"poison_timer": 0.0, "poison_dmg": 0,
		# Pozycja bazowa, do ktorej wracaja animacje strzalu/kontrataku (runda C).
		"base_pos": node.position,
	}
	plants.append(plant)
	grid_occupancy[col][row] = plant
	return ""

func _try_apply_fertilizer(col: int, row: int) -> void:
	var plant = grid_occupancy[col][row]
	if plant == null:
		message_label.text = "Brak rosliny na tym polu"
		return
	_apply_fertilizer(plant)
	fertilizer_mode = false
	message_label.text = ""
	_update_hud()

func _apply_fertilizer(plant: Dictionary) -> void:
	fertilizer -= 1
	plant["boosted"] = true
	var one_shot: bool = ONE_SHOT_ROLES.has(PLANT_TYPES[plant["type_idx"]]["role"])
	plant["boost_timer"] = INF if one_shot else FERTILIZER_BOOST_DURATION
	plant["boost_ring"].visible = true

# Ile razy mocniej dziala teraz roslina (nawoz).
func _plant_boost(plant: Dictionary) -> float:
	return FERTILIZER_BOOST_MULTIPLIER if plant["boosted"] else 1.0

# Usuniecie wlasnej rosliny: znika bez zwrotu kropel wody i bez nawozu.
func _try_remove_plant(col: int, row: int) -> void:
	var plant = grid_occupancy[col][row]
	if plant == null:
		message_label.text = "Brak rosliny na tym polu"
		return
	_remove_plant(plant)
	remove_mode = false
	message_label.text = ""
	_update_hud()

func _update_hud() -> void:
	water_count_label.text = str(water)

	for i in range(plant_tiles.size()):
		var tile: Dictionary = plant_tiles[i]
		var pt = PLANT_TYPES[tile["plant_idx"]]
		var affordable: bool = belt or water >= pt["cost"]
		tile["button"].modulate = Color(1, 1, 1) if affordable else TILE_NO_WATER_MODULATE
		var is_selected: bool = (i == belt_slot and selected_plant_type >= 0) if belt else selected_plant_type == tile["plant_idx"]
		_set_tile_selected(tile, is_selected, TILE_BORDER_COLOR if affordable else TILE_NO_WATER_BORDER_COLOR)

	var limit := _fertilizer_limit()
	fertilizer_tile["count_label"].text = str(fertilizer) if limit == NO_FERTILIZER_LIMIT else "%d / %d" % [fertilizer, limit]
	fertilizer_tile["button"].modulate = Color(1, 1, 1) if fertilizer > 0 else TILE_UNAFFORDABLE_MODULATE
	_set_tile_selected(fertilizer_tile, fertilizer_mode, TILE_BORDER_COLOR)

	remove_border_sb.bg_color = REMOVE_ACTIVE_BG_COLOR if remove_mode else TILE_BG_COLOR
	remove_border_sb.set_border_width_all(TILE_SELECTED_BORDER_WIDTH if remove_mode else TILE_BORDER_WIDTH)
	remove_border_sb.border_color = TILE_SELECTED_BORDER_COLOR if remove_mode else TILE_BORDER_COLOR
	remove_button.add_theme_color_override("font_color", Color(1, 1, 1) if remove_mode else Color(0.95, 0.35, 0.3))

	if remove_mode:
		wave_label.text = "Tryb usuwania: tapnij rosline, ktora chcesz usunac (woda nie wraca)"
	elif fertilizer_mode:
		wave_label.text = "Tryb nawozu: tapnij wlasna rosline, by ja wzmocnic"
	elif selected_plant_type >= 0:
		wave_label.text = "Wybrano: %s (tapnij pole ogrodu)" % PLANT_TYPES[selected_plant_type]["name"]
	elif endless:
		wave_label.text = "Fala: %d" % current_wave
	else:
		wave_label.text = "Fala: %d / %d" % [current_wave, waves.size()]

	if endless:
		kills_label.text = "Pokonani: %d    Rekord: %d" % [kills, max(kills, GameState.endless_best)]

func _process(delta: float) -> void:
	if game_over:
		return
	if is_guest:
		_update_cooldowns(delta)
		_update_guest_view(delta)
		return
	# Host nie zaczyna, dopoki gosc nie wczyta planszy.
	if team and not NetSession.guest_in_game:
		return

	if endless:
		endless_time += delta
	_update_cooldowns(delta)
	if belt:
		_update_belt(delta)
	_update_wave_spawning(delta)
	_update_plants(delta)
	_update_projectiles(delta)
	_update_homing_projectiles(delta)
	_update_gusts(delta)
	_update_enemies(delta)
	_update_boss_specials(delta)
	_update_boss_bar()
	_update_water_theft(delta)
	_update_water_drops(delta)
	_update_fertilizer_drops(delta)
	_update_health_bars(delta)
	if event_game:
		_update_event(delta)
	if game_over:
		return
	_check_win_condition()
	if team and not game_over:
		_update_snapshot(delta)

# --- Odnawianie roslin w pasku (jak w PvZ): cien zakrywa kafelek i kurczy
# sie ku gorze, az roslina znow bedzie gotowa do posadzenia. ---
func _update_cooldowns(delta: float) -> void:
	for idx in plant_cooldowns.keys():
		plant_cooldowns[idx] -= delta
		if plant_cooldowns[idx] <= 0.0:
			plant_cooldowns.erase(idx)
	for tile in plant_tiles:
		var idx: int = tile["plant_idx"]
		var ratio := 0.0
		if plant_cooldowns.has(idx):
			ratio = plant_cooldowns[idx] / PLANT_TYPES[idx]["recharge"]
		tile["cooldown_shade"].size.y = TILE_HEIGHT * ratio

# --- Fale ---
func _update_wave_spawning(delta: float) -> void:
	# Tryb nieskonczony: kolejna fala jest generowana, zanim bedzie potrzebna.
	if endless and current_wave >= waves.size():
		waves.append(_generate_endless_wave(current_wave))
	# Wielkie sprzatanie: fale trwaja, dopoki sa kupki.
	if event_rules.has("clean_piles") and current_wave >= waves.size():
		waves.append(waves.back())

	if current_wave < waves.size():
		if not wave_in_progress:
			between_waves_timer -= delta
			if between_waves_timer <= 0.0:
				wave_in_progress = true
				wave_spawn_queue = waves[current_wave].duplicate()
				if not endless and current_wave >= 2 and not event_rules.has("boss_rush"):
					_add_extra_enemies(wave_spawn_queue, EXTRA_ENEMIES_FROM_WAVE_3)
				if team:
					_add_extra_enemies(wave_spawn_queue, TEAM_EXTRA_ENEMIES)
				if current_wave > 0 and _pile_appears_on_wave(current_wave):
					_spawn_junk_pile()
				if _fertilizer_appears_on_wave(current_wave):
					_spawn_fertilizer_drop()
				_add_pile_enemies(wave_spawn_queue)
				if current_wave == 0 and wave_spawn_queue.size() > MAX_FIRST_WAVE_ENEMIES:
					wave_spawn_queue.resize(MAX_FIRST_WAVE_ENEMIES)
				time_to_next_spawn = 0.0
				_announce("Fala %d nadchodzi!" % (current_wave + 1))
			return

		time_to_next_spawn -= delta
		if time_to_next_spawn <= 0.0 and wave_spawn_queue.size() > 0:
			var spawn_info = wave_spawn_queue.pop_front()
			time_to_next_spawn = _spawn_interval()
			if spawn_info.has("boss"):
				_announce("%s nadchodzi!" % BOSS_TYPES[spawn_info["boss"]]["name"])
				_spawn_boss(spawn_info["boss"], spawn_info["row"], spawn_info.get("hp", 1.0))
			elif spawn_info.has("pile"):
				# Kupka zniszczona, zanim wrog zdazyl wyjsc - nic nie wychodzi.
				var pile: Dictionary = spawn_info["pile"]
				if junk_piles.get(_cell_key(pile["col"], pile["row"])) == pile:
					_spawn_enemy(spawn_info["type"], pile["row"], _pile_x(pile))
					_animate_pile_release(pile)
				else:
					time_to_next_spawn = 0.0
			else:
				_spawn_enemy(spawn_info["type"], spawn_info["row"])

		if wave_spawn_queue.is_empty() and enemies.is_empty() and wave_in_progress:
			wave_in_progress = false
			current_wave += 1
			between_waves_timer = _between_waves_time()
			if help_type == "boss_water" and current_wave < waves.size():
				water += BOSS_RUSH_WATER
			_update_hud()
		return

	# Wszystkie fale zrobione - jesli poziom ma bossa, wystaw go po chwili.
	var boss_idx: int = _current_level().get("boss", -1)
	if boss_idx >= 0 and not boss_spawned and enemies.is_empty():
		between_waves_timer -= delta
		if between_waves_timer <= 0.0:
			boss_spawned = true
			_announce("%s nadchodzi!" % BOSS_TYPES[boss_idx]["name"])
			_spawn_boss(boss_idx, ROWS / 2)

# Dopisuje do kolejki kopie typow wrogow z tej samej fali (ratio = ulamek jej
# wielkosci, w losowych rzedach), rozrzucone miedzy oryginalnych wrogow.
func _add_extra_enemies(queue: Array, ratio: float) -> void:
	var originals := queue.duplicate()
	var extra := int(ceil(originals.size() * ratio))
	for i in range(extra):
		var src: Dictionary = originals[i % originals.size()]
		var copy := {"type": src["type"], "row": randi_range(0, ROWS - 1)}
		queue.insert(randi_range(1, queue.size()), copy)

# --- Tryb nieskonczony ---
# Trudnosc = liczba przetrwanych minut.
func _endless_difficulty() -> float:
	return endless_time / 60.0

func _enemy_hp_multiplier() -> float:
	if event_game:
		return event_rules.get("enemy_hp", 1.0)
	return 1.0 + ENDLESS_HP_PER_MINUTE * _endless_difficulty() if endless else 1.0

func _enemy_speed_multiplier() -> float:
	if event_game:
		return event_rules.get("enemy_speed", 1.0)
	if not endless:
		return 1.0
	return min(1.0 + ENDLESS_SPEED_PER_MINUTE * _endless_difficulty(), ENDLESS_MAX_SPEED_MULT)

func _spawn_interval() -> float:
	if not endless:
		return SPAWN_INTERVAL
	return max(ENDLESS_MIN_SPAWN_INTERVAL, SPAWN_INTERVAL - 0.06 * _endless_difficulty())

func _between_waves_time() -> float:
	if event_rules.has("boss_rush"):
		return BOSS_RUSH_BREAK
	if not endless:
		return BETWEEN_WAVES_TIME
	return max(ENDLESS_MIN_BETWEEN_WAVES, BETWEEN_WAVES_TIME - 0.25 * _endless_difficulty())

# Fale 1-2 sa male i tylko z Butelek/Puszek; potem fale rosna z numerem fali
# i z czasem gry, dochodza Golemy (od 4. fali) i Gabki (od 6.), a od 5. fali
# co kilka fal na koncu pojawia sie losowy boss (pozniej nawet kilku naraz).
func _generate_endless_wave(n: int) -> Array:
	var size: int
	if n < ENDLESS_FIRST_WAVE_SIZES.size():
		size = ENDLESS_FIRST_WAVE_SIZES[n]
	else:
		var growth := (n - ENDLESS_FIRST_WAVE_SIZES.size()) * ENDLESS_SIZE_PER_WAVE
		size = ENDLESS_BASE_WAVE_SIZE + int(growth + ENDLESS_SIZE_PER_MINUTE * _endless_difficulty())

	var pool := [0, 0, 1, 1]
	if n >= 3:
		for i in range(min(n - 2, 4)):
			pool.append(2)
	if n >= 5:
		for i in range(min(n - 4, 3)):
			pool.append(3)

	var wave := []
	for i in range(size):
		wave.append({"type": pool[randi() % pool.size()], "row": randi_range(0, ROWS - 1)})

	if n >= ENDLESS_FIRST_BOSS_WAVE and (n - ENDLESS_FIRST_BOSS_WAVE) % ENDLESS_BOSS_EVERY == 0:
		var boss_count := 1 + (n - ENDLESS_FIRST_BOSS_WAVE) / ENDLESS_EXTRA_BOSS_EVERY
		for i in range(boss_count):
			wave.append({"boss": randi() % BOSS_TYPES.size(), "row": randi_range(0, ROWS - 1)})
	return wave

# --- Kupki smieci ---
func _pile_appears_on_wave(wave_idx: int) -> bool:
	if event_rules.has("clean_piles"):
		return false
	if endless:
		return wave_idx >= ENDLESS_FIRST_PILE_WAVE and (wave_idx - ENDLESS_FIRST_PILE_WAVE) % ENDLESS_PILE_EVERY == 0
	return _current_level().get("junk_pile_waves", []).has(wave_idx)

func _pile_x(pile: Dictionary) -> float:
	return float(GRID_LEFT + pile["col"] * CELL + 8)

# Nowa kupka na losowym wolnym polu w prawej czesci planszy (bez rosliny,
# bez innej kupki, nie na polu zablokowanym). Brak miejsca = brak kupki.
func _spawn_junk_pile() -> void:
	var free := []
	for c in range(JUNK_PILE_MIN_COL, COLS):
		for r in range(ROWS):
			var key := _cell_key(c, r)
			if grid_occupancy[c][r] == null and not blocked_cells.has(key) and not junk_piles.has(key):
				free.append(Vector2i(c, r))
	if free.is_empty():
		return
	var cell: Vector2i = free[randi() % free.size()]
	var node := _make_sprite(JUNK_PILE_TEXTURE, CELL - 16)
	node.position = Vector2(GRID_LEFT + cell.x * CELL + 8, GRID_TOP + cell.y * CELL + 8)
	node.scale = Vector2(0.2, 0.2)
	add_child(node)
	var tw := node.create_tween()
	tw.tween_property(node, "scale", Vector2(1, 1), 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var bar := _add_health_bar(node, CELL - 16)
	junk_piles[_cell_key(cell.x, cell.y)] = {
		"node": node, "hp": JUNK_PILE_HP, "max_hp": JUNK_PILE_HP,
		"col": cell.x, "row": cell.y, "bar": bar, "hurt_timer": HEALTH_BAR_HIDE_DELAY + 1.0,
	}
	_announce("Pojawila sie kupka smieci! Wychodza z niej szkodniki.")

# Kazda kupka wypuszcza na fale jednego slabego wroga (Butelke albo Puszke),
# wstawionego w losowe miejsce kolejki.
func _add_pile_enemies(queue: Array) -> void:
	for pile in junk_piles.values():
		var entry := {"type": randi() % 2, "row": pile["row"], "pile": pile}
		queue.insert(randi_range(0, queue.size()), entry)

func _animate_pile_release(pile: Dictionary) -> void:
	var node: Control = pile["node"]
	var tw := node.create_tween()
	tw.tween_property(node, "scale", Vector2(1.15, 0.85), 0.1)
	tw.tween_property(node, "scale", Vector2(1, 1), 0.15)

func _damage_pile(pile: Dictionary, dmg: float) -> void:
	pile["hp"] -= dmg
	_flash_health_bar(pile)
	if pile["hp"] <= 0:
		_remove_pile(pile)

# Kupka znika (kurczy sie i zanika) - od razu przestaje istniec w grze.
func _remove_pile(pile: Dictionary) -> void:
	var key := _cell_key(pile["col"], pile["row"])
	if junk_piles.get(key) != pile:
		return
	junk_piles.erase(key)
	var node: Control = pile["node"]
	var tw := node.create_tween()
	tw.tween_property(node, "scale", Vector2(0.1, 0.1), 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(node, "modulate:a", 0.0, 0.4)
	tw.tween_callback(node.queue_free)

# Pnacza: wyrastaja na kupce, oplataja ja (kupka znika), po czym same znikaja.
func _vines_destroy_pile(pile: Dictionary, vines_texture: String) -> void:
	var vines := _make_sprite(vines_texture, CELL - 16)
	vines.position = pile["node"].position
	vines.scale = Vector2(0.3, 0.3)
	add_child(vines)
	_remove_pile(pile)
	var tw := vines.create_tween()
	tw.tween_property(vines, "scale", Vector2(1.1, 1.1), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(0.3)
	tw.tween_property(vines, "modulate:a", 0.0, 0.3)
	tw.tween_callback(vines.queue_free)

func _pile_in_row_between(row: int, from_x: float, to_x: float) -> Variant:
	for pile in junk_piles.values():
		if pile["row"] == row and _pile_x(pile) >= from_x and _pile_x(pile) <= to_x:
			return pile
	return null

func _spawn_enemy(type_idx: int, row: int, start_x: float = -1.0) -> void:
	var et = ENEMY_TYPES[type_idx]
	var node := _make_sprite(et["texture"], CELL - 16)
	var x := start_x if start_x >= 0.0 else float(GRID_LEFT + COLS * CELL)
	node.position = Vector2(x, GRID_TOP + row * CELL + 8)
	add_child(node)
	var bar := _add_health_bar(node, CELL - 16)
	var hp := int(et["hp"] * _enemy_hp_multiplier())
	enemies.append({
		"id": _new_entity_id(),
		"node": node, "hp": hp, "max_hp": hp, "row": row, "x": x, "type_idx": type_idx,
		"speed": et["speed"] * _enemy_speed_multiplier(), "bite_dmg": et["bite_dmg"], "bite_interval": et["bite_interval"],
		"bite_timer": 0.0, "bar": bar, "hurt_timer": HEALTH_BAR_HIDE_DELAY + 1.0,
		"slow_timer": 0.0, "slow_factor": 1.0, "burn_timer": 0.0, "burn_dps": 0.0, "flames": null, "is_boss": false,
		"water_thief": et.get("water_thief", false), "steal_target": null,
		# Chodzenie/jedzenie (runda C): base_y do animacji podskakiwania,
		# faza losowa zeby wrogowie nie kolysali sie w idealnym takcie.
		"base_y": node.position.y, "phase": randf_range(0.0, TAU), "anim_t": 0.0,
	})

func _spawn_boss(boss_idx: int, row: int, hp_multiplier := 1.0) -> void:
	var bt = BOSS_TYPES[boss_idx]
	var hp := int(bt["hp"] * _current_level().get("boss_hp_multiplier", 1.0) * _enemy_hp_multiplier() * hp_multiplier)
	var node := _make_sprite(bt["texture"], CELL - 4)
	var x := float(GRID_LEFT + COLS * CELL)
	node.position = Vector2(x, GRID_TOP + row * CELL + 2)
	add_child(node)
	var bar := _add_health_bar(node, CELL - 4)
	enemies.append({
		"id": _new_entity_id(),
		"node": node, "hp": hp, "max_hp": hp, "row": row, "x": x, "type_idx": -1,
		"speed": bt["speed"] * _enemy_speed_multiplier(), "bite_dmg": bt["bite_dmg"], "bite_interval": bt["bite_interval"],
		"bite_timer": 0.0, "bar": bar, "hurt_timer": HEALTH_BAR_HIDE_DELAY + 1.0,
		"slow_timer": 0.0, "slow_factor": 1.0, "burn_timer": 0.0, "burn_dps": 0.0, "flames": null,
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
		var boost := _plant_boost(plant)
		var power: float = plant["power"]

		match pt["role"]:
			"shooter":
				if plant["disable_timer"] <= 0.0:
					plant["atk_timer"] -= delta * boost
					if plant["atk_timer"] <= 0.0:
						var target := _find_enemy_in_row(plant["row"])
						if not target.is_empty() or _pile_in_row_between(plant["row"], plant["base_pos"].x, INF) != null:
							plant["atk_timer"] = pt["interval"]
							var row: int = plant["row"]
							var muzzle_x: float = plant["base_pos"].x + CELL
							var dmg: float = pt["dmg"] * boost * power
							var pierce: bool = pt.get("pierce", false)
							_animate_shooter_shot(plant, func(): _spawn_projectile(row, muzzle_x, dmg, pierce))
			"volley":
				# Aronia: krotki zasieg (range_cells pol przed nia), salwa kilku
				# pociskow naraz - od gory do dolu pola.
				if plant["disable_timer"] <= 0.0:
					plant["atk_timer"] -= delta * boost
					if plant["atk_timer"] <= 0.0:
						var from_x: float = plant["base_pos"].x
						var max_x: float = from_x + CELL * (pt["range_cells"] + 1)
						if not _find_enemy_in_row_between(plant["row"], from_x, max_x).is_empty() or _pile_in_row_between(plant["row"], from_x, max_x) != null:
							plant["atk_timer"] = pt["interval"]
							var vrow: int = plant["row"]
							var vdmg: float = pt["dmg"] * boost * power
							var count: int = pt["volley_count"]
							_animate_shooter_shot(plant, func(): _spawn_volley(vrow, from_x + CELL, vdmg, count, max_x))
			"aimed":
				# Roza: celuje w szkodnika najblizszego domu, w dowolnym rzedzie.
				if plant["disable_timer"] <= 0.0:
					plant["atk_timer"] -= delta * boost
					if plant["atk_timer"] <= 0.0:
						var aim_target := _find_enemy_closest_to_house()
						if not aim_target.is_empty():
							plant["atk_timer"] = pt["interval"]
							var origin: Vector2 = plant["base_pos"] + Vector2(CELL - 16, (CELL - 16) * 0.3)
							var admg: float = pt["dmg"] * boost * power
							_animate_shooter_shot(plant, func(): _spawn_homing_projectile(origin, aim_target, admg))
			"generator":
				plant["gen_timer"] -= delta * boost * power
				if plant["gen_timer"] <= 0.0:
					plant["gen_timer"] = pt["water_interval"] * _cactus_water_multiplier()
					for i in range(pt.get("water_drops", 1)):
						_spawn_water_drop(plant["node"].position, pt["water_value"])
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
		_plant_beaten(plant)

# Widoczne wyrzucenie pocisku (Kukurydza, Pokrzywa, Aronia, Roza): nabiera
# (odchylenie w lewo + skala 0.9 w poziomie), wyrzut (do przodu + skala 1.1,
# w tej chwili wywolywane jest "fire", ktore tworzy pocisk(i) z bazowej
# pozycji rosliny - przesuniecie jest tylko wizualne), powrot do pozycji bazowej.
func _animate_shooter_shot(plant: Dictionary, fire: Callable) -> void:
	var node = plant["node"]
	var base_pos: Vector2 = plant["base_pos"]
	var running_tween = plant.get("anim_tween")
	if running_tween != null and is_instance_valid(running_tween):
		running_tween.kill()
	node.position = base_pos
	node.scale = Vector2(1, 1)

	var tw: Tween = node.create_tween()
	plant["anim_tween"] = tw
	tw.tween_property(node, "position", base_pos + Vector2(-6, 0), 0.08)
	tw.parallel().tween_property(node, "scale:x", 0.9, 0.08)
	tw.tween_callback(fire)
	tw.tween_property(node, "position", base_pos + Vector2(8, 0), 0.08)
	tw.parallel().tween_property(node, "scale:x", 1.1, 0.08)
	tw.tween_property(node, "position", base_pos, 0.1)
	tw.parallel().tween_property(node, "scale:x", 1.0, 0.1)

func _find_enemy_in_row(row: int) -> Dictionary:
	for e in enemies:
		if e["row"] == row:
			return e
	return {}

func _find_enemy_in_row_between(row: int, from_x: float, to_x: float) -> Dictionary:
	for e in enemies:
		if e["row"] == row and e["x"] >= from_x - CELL / 2.0 and e["x"] <= to_x:
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

# Roza: szkodnik (juz caly na planszy) najblizej domu, w dowolnym rzedzie.
func _find_enemy_closest_to_house() -> Dictionary:
	var board_right := float(GRID_LEFT + COLS * CELL)
	var best := {}
	for e in enemies:
		if e["x"] + e["node"].size.x > board_right:
			continue
		if best.is_empty() or e["x"] < best["x"]:
			best = e
	return best

# y_frac: wysokosc pocisku w polu (0 = gora, 1 = dol) - czysto wizualne,
# trafienia licza sie po x/rzedzie. max_x: pocisk znika po tej odleglosci
# (Aronia strzela tylko na kilka pol).
func _spawn_projectile(row: int, x: float, dmg: float, pierce: bool = false, y_frac: float = 0.4, max_x: float = INF, tint: Color = Color(1, 1, 1)) -> void:
	var node := _make_sprite(THORN_TEXTURE, 16)
	node.position = Vector2(x, GRID_TOP + row * CELL + y_frac * (CELL - 16))
	node.scale = Vector2(0.4, 0.4)
	node.modulate = tint
	add_child(node)
	var tw := node.create_tween()
	tw.tween_property(node, "scale", Vector2(1, 1), 0.1)
	projectiles.append({"id": _new_entity_id(), "node": node, "row": row, "x": x, "dmg": dmg, "pierce": pierce, "hit_enemies": [], "max_x": max_x})

# Aronia: kilka pociskow naraz, rozlozonych od gory do dolu pola.
func _spawn_volley(row: int, x: float, dmg: float, count: int, max_x: float) -> void:
	for i in range(count):
		var y_frac: float = 0.05 + 0.9 * i / float(max(1, count - 1))
		_spawn_projectile(row, x, dmg, false, y_frac, max_x, VOLLEY_PROJECTILE_COLOR)

func _update_projectiles(delta: float) -> void:
	var to_remove := []
	for proj in projectiles:
		proj["x"] += PROJECTILE_SPEED * delta
		proj["node"].position.x = proj["x"]
		for e in enemies:
			if e["row"] == proj["row"] and abs(e["x"] - proj["x"]) < CELL / 2 and not proj["hit_enemies"].has(e):
				e["hp"] -= proj["dmg"]
				_flash_health_bar(e)
				proj["hit_enemies"].append(e)
				if not proj["pierce"]:
					to_remove.append(proj)
					break
		if not to_remove.has(proj):
			for pile in junk_piles.values():
				if pile["row"] == proj["row"] and abs(_pile_x(pile) - proj["x"]) < CELL / 2 and not proj["hit_enemies"].has(pile):
					proj["hit_enemies"].append(pile)
					_damage_pile(pile, proj["dmg"])
					if not proj["pierce"]:
						to_remove.append(proj)
					break
		if (proj["x"] > GRID_LEFT + COLS * CELL or proj["x"] > proj["max_x"]) and not to_remove.has(proj):
			to_remove.append(proj)
	for proj in to_remove:
		proj["node"].queue_free()
		projectiles.erase(proj)

# --- Roza: pocisk leci za celem; jesli cel zginal wczesniej, leci dalej
# prosto i trafia pierwszego napotkanego szkodnika. ---
func _spawn_homing_projectile(origin: Vector2, target: Dictionary, dmg: float) -> void:
	var node := _make_sprite(THORN_TEXTURE, 18)
	node.position = origin
	node.modulate = AIMED_PROJECTILE_COLOR
	add_child(node)
	var dir := (_enemy_center(target) - origin).normalized() if enemies.has(target) else Vector2.RIGHT
	homing_projectiles.append({"id": _new_entity_id(), "node": node, "pos": origin, "dir": dir, "target": target, "dmg": dmg})

func _enemy_center(e: Dictionary) -> Vector2:
	return e["node"].position + e["node"].size / 2.0

func _update_homing_projectiles(delta: float) -> void:
	var to_remove := []
	for proj in homing_projectiles:
		if enemies.has(proj["target"]):
			proj["dir"] = (_enemy_center(proj["target"]) - proj["pos"] - Vector2(8, 8)).normalized()
		proj["pos"] += proj["dir"] * HOMING_SPEED * delta
		proj["node"].position = proj["pos"]
		proj["node"].rotation = proj["dir"].angle()
		var center: Vector2 = proj["pos"] + Vector2(8, 8)
		for e in enemies:
			if center.distance_to(_enemy_center(e)) < HOMING_HIT_RADIUS:
				e["hp"] -= proj["dmg"]
				_flash_health_bar(e)
				to_remove.append(proj)
				break
		var p: Vector2 = proj["pos"]
		if not to_remove.has(proj) and (p.x < GRID_LEFT - CELL or p.x > GRID_LEFT + COLS * CELL + CELL or p.y < GRID_TOP - CELL or p.y > GRID_TOP + ROWS * CELL):
			to_remove.append(proj)
	for proj in to_remove:
		proj["node"].queue_free()
		homing_projectiles.erase(proj)

# --- Szkodniki: ruch i "zjadanie" roslin ---
func _update_enemies(delta: float) -> void:
	var dead := []
	var reached_house := false
	var bombs := []
	for e in enemies:
		_update_burn(e, delta)
		if e["hp"] <= 0:
			dead.append(e)
			continue

		# Popychany przez podmuch: jedzie razem z chmurka, nie idzie i nie gryzie.
		if e.get("push_left", 0.0) > 0.0:
			var step: float = min(e["push_left"], GUST_SPEED * delta)
			e["push_left"] -= step
			e["x"] = min(e["x"] + step, float(GRID_LEFT + COLS * CELL))
			e["node"].position.x = e["x"]
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
			if bpt["role"] == "burn" and not blocking_plant["used"]:
				blocking_plant["used"] = true
				_trigger_burn(blocking_plant, bpt, e)
				e["bite_timer"] = 0.0
				continue
			# Bumorzech wybucha po petli, bo wybuch usuwa wrogow z tej listy.
			if bpt["role"] == "bomb":
				if not blocking_plant["used"]:
					blocking_plant["used"] = true
					bombs.append(blocking_plant)
				continue

			var slow_mult: float = e["slow_factor"] if e["slow_timer"] > 0.0 else 1.0
			e["bite_timer"] -= delta * slow_mult
			if e["bite_timer"] <= 0.0:
				e["bite_timer"] = e["bite_interval"]
				# Lisc Bananowca z nawozem lepiej znosi ugryzienia.
				var toughness: float = _plant_boost(blocking_plant) if bpt["role"] == "wall" else 1.0
				blocking_plant["hp"] -= e["bite_dmg"] / toughness
				_flash_health_bar(blocking_plant)
				_animate_bite(e, blocking_plant)
				if bpt["role"] == "melee":
					e["hp"] -= bpt["counter_dmg"] * _plant_boost(blocking_plant) * blocking_plant["power"]
					_flash_health_bar(e)
					_animate_melee_punch(blocking_plant, e["node"].position + e["node"].size / 2.0)
				if blocking_plant["hp"] <= 0:
					_plant_beaten(blocking_plant)
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
				e["node"].modulate = _enemy_base_modulate(e)

	for e in dead:
		_kill_enemy(e)
	for bomb in bombs:
		_trigger_bomb(bomb, PLANT_TYPES[bomb["type_idx"]])

	if reached_house:
		_lose_game()

# Kolor wroga poza efektami chwilowymi: zamrozony > plonacy > normalny.
func _enemy_base_modulate(e: Dictionary) -> Color:
	if e["slow_timer"] > 0.0:
		return FROZEN_COLOR
	if e["burn_timer"] > 0.0:
		return BURN_COLOR
	return Color(1, 1, 1)

# Ognioroslinka: plonacy wrog traci HP rownomiernie przez caly czas palenia.
func _update_burn(e: Dictionary, delta: float) -> void:
	if e["burn_timer"] <= 0.0:
		return
	var tick: float = min(delta, e["burn_timer"])
	e["burn_timer"] -= delta
	e["hp"] -= e["burn_dps"] * tick
	_flash_health_bar(e)
	if e["burn_timer"] <= 0.0:
		_stop_flames(e)
		if not e.get("telegraphing", false):
			e["node"].modulate = _enemy_base_modulate(e)

func _stop_flames(e: Dictionary) -> void:
	var flames = e["flames"]
	e["flames"] = null
	if flames != null and is_instance_valid(flames):
		flames.emitting = false
		get_tree().create_timer(0.6).timeout.connect(flames.queue_free)
# Jedyne miejsce, w ktorym pokonany wrog znika z gry (strzaly, kontratak,
# wybuch, wichura) - oddaje ewentualnie porwana krople i liczy pokonanych.
func _kill_enemy(e: Dictionary) -> void:
	if not enemies.has(e):
		return
	_release_stolen_drop(e)
	if event_rules.has("coin_hunt") and randf() < EventData.HUNT_DROP_CHANCE:
		_spawn_coin_drop(e["node"].position)
	e["node"].queue_free()
	enemies.erase(e)
	kills += 1
	if endless:
		_update_hud()
		if GameState.try_award_endless_ruby(kills):
			_show_ruby_reward(kills_label.position + Vector2(kills_label.size.x - 120, 34), 42)

func _plant_ahead(e: Dictionary) -> Variant:
	var col := int((e["x"] - GRID_LEFT) / CELL)
	col = clamp(col, 0, COLS - 1)
	var candidate = grid_occupancy[col][e["row"]]
	if candidate != null and abs((GRID_LEFT + col * CELL) - e["x"]) < CELL:
		return candidate
	return null

# Roslina pokonana przez wrogow. W "Zadnych strat" konczy to etap, chyba ze
# zostala tarcza, ktora raz przywraca roslinie cale zycie.
func _plant_beaten(plant: Dictionary) -> void:
	if event_rules.has("no_losses"):
		if shield_left > 0:
			shield_left -= 1
			plant["hp"] = plant["max_hp"]
			message_label.text = "Tarcza uratowala rosline!"
			return
		_remove_plant(plant)
		if not game_over:
			_lose_game("Stracona roslina - etap przepada!")
		return
	_remove_plant(plant)

func _remove_plant(plant: Dictionary) -> void:
	grid_occupancy[plant["col"]][plant["row"]] = null
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
	target["slow_timer"] = pt["slow_duration"] * _plant_boost(plant) * plant["power"]
	target["slow_factor"] = pt["slow_factor"]
	target["node"].modulate = FROZEN_COLOR
	_remove_plant(plant)

# Ognioroslinka znika, a szkodnik, ktory na nia wszedl, staje w ogniu: przez
# burn_duration s traci w sumie burn_dmg HP, ale moze isc dalej.
func _trigger_burn(plant: Dictionary, pt: Dictionary, target: Dictionary) -> void:
	target["burn_timer"] = pt["burn_duration"]
	target["burn_dps"] = pt["burn_dmg"] * _plant_boost(plant) * plant["power"] / pt["burn_duration"]
	if not target.get("telegraphing", false):
		target["node"].modulate = _enemy_base_modulate(target)
	if target["flames"] == null:
		target["flames"] = _make_flames(target["node"])
	_remove_plant(plant)

# Plomienie: male pomaranczowo-zolte kwadraciki unoszace sie z wroga.
func _make_flames(enemy_node: Control) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.position = Vector2(enemy_node.size.x / 2.0, enemy_node.size.y * 0.7)
	p.texture = _make_square_texture(6)
	p.amount = 18
	p.lifetime = 0.6
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(enemy_node.size.x * 0.3, 6)
	p.direction = Vector2(0, -1)
	p.spread = 20.0
	p.gravity = Vector2(0, -60)
	p.initial_velocity_min = 20.0
	p.initial_velocity_max = 50.0
	p.scale_amount_min = 0.8
	p.scale_amount_max = 1.6
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([Color(1.0, 0.9, 0.3), Color(1.0, 0.45, 0.1), Color(0.8, 0.2, 0.05, 0.0)])
	gradient.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	p.color_ramp = gradient
	enemy_node.add_child(p)
	p.emitting = true
	return p

func _trigger_gust(plant: Dictionary, pt: Dictionary) -> void:
	_spawn_gust_cloud(plant["node"].position.x, plant["row"])
	if team:
		NetSession.send_event("gust", [plant["node"].position.x, plant["row"]])
	var boost: float = _plant_boost(plant) * plant["power"]
	active_gusts.append({
		"x": plant["node"].position.x, "row": plant["row"],
		"dmg": pt["gust_dmg"] * boost, "knockback": pt["knockback"] * boost, "hit": [],
	})
	_remove_plant(plant)

# Chmurka leci przez rzad; kazdy wrog dostaje obrazenia dopiero, gdy go dosiegnie,
# i od tej chwili jedzie razem z nia. Pokonanych wrogow usuwa _update_enemies().
func _update_gusts(delta: float) -> void:
	var board_right := float(GRID_LEFT + COLS * CELL)
	for gust in active_gusts.duplicate():
		gust["x"] += GUST_SPEED * delta
		for e in enemies:
			if e["row"] == gust["row"] and e["x"] <= gust["x"] + CELL / 2.0 and not gust["hit"].has(e):
				gust["hit"].append(e)
				if gust["dmg"] > 0.0:
					e["hp"] -= gust["dmg"]
					_flash_health_bar(e)
				e["push_left"] = gust["knockback"]
		if gust["x"] >= board_right:
			active_gusts.erase(gust)

# Przesuwajaca sie niebieska chmurka: startuje w polu rosliny i leci do prawej
# krawedzi planszy w tym rzedzie, potem zanika. Leci z predkoscia GUST_SPEED,
# tak jak front podmuchu w _update_gusts(), wiec wrogowie ruszaja razem z nia.
func _spawn_gust_cloud(start_x: float, row: int) -> void:
	var y: float = GRID_TOP + row * CELL + CELL / 2.0
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
	tw.tween_property(cloud, "position:x", end_x, (end_x - start_x) / GUST_SPEED)
	tw.tween_property(cloud, "modulate:a", 0.0, 0.2)
	tw.tween_callback(cloud.queue_free)

func _trigger_bomb(plant: Dictionary, pt: Dictionary) -> void:
	_spawn_bomb_explosion(plant["col"], plant["row"])
	if team:
		NetSession.send_event("bomb", [plant["col"], plant["row"]])
	var blast_x := float(GRID_LEFT + plant["col"] * CELL)
	var radius_cells: int = pt["blast_radius_cells"]
	var blast_dmg: float = pt["blast_dmg"] * _plant_boost(plant) * plant["power"]
	var dead := []
	for e in enemies:
		if abs(e["row"] - plant["row"]) <= radius_cells and abs(e["x"] - blast_x) <= CELL * (radius_cells + 0.9):
			e["hp"] -= blast_dmg
			_flash_health_bar(e)
			if e["hp"] <= 0:
				dead.append(e)
	for e in dead:
		_kill_enemy(e)
	for pile in junk_piles.values():
		if abs(pile["row"] - plant["row"]) <= radius_cells and abs(pile["col"] - plant["col"]) <= radius_cells:
			_damage_pile(pile, blast_dmg)
	_remove_plant(plant)

# Wybuch Bumorzecha: pomaranczowe kolko na ok. 3 pola srednicy z zoltym srodkiem
# i bialym blyskiem jest widoczne od razu w pelnym rozmiarze - w tej samej
# klatce, w ktorej wrogowie obrywaja - a potem zanika, z lekkim potrzasnieciem plansza.
func _spawn_bomb_explosion(col: int, row: int) -> void:
	var center := Vector2(
		GRID_LEFT + col * CELL + CELL / 2.0,
		GRID_TOP + row * CELL + CELL / 2.0
	)
	var effect := Node2D.new()
	effect.position = center
	add_child(effect)

	var radius := CELL * 1.5

	var outer := Polygon2D.new()
	outer.polygon = _circle_points(20)
	outer.color = Color(0.95, 0.5, 0.1, 0.85)
	outer.scale = Vector2(radius, radius)
	effect.add_child(outer)

	var inner := Polygon2D.new()
	inner.polygon = _circle_points(20)
	inner.color = Color(1.0, 0.9, 0.3, 0.9)
	inner.scale = Vector2(radius * 0.6, radius * 0.6)
	effect.add_child(inner)

	var flash := Polygon2D.new()
	flash.polygon = _circle_points(20)
	flash.color = Color(1, 1, 1, 0.9)
	flash.scale = Vector2(radius, radius)
	effect.add_child(flash)

	var tw := effect.create_tween()
	tw.tween_property(flash, "modulate:a", 0.0, 0.1)
	tw.parallel().tween_property(outer, "modulate:a", 0.0, BOMB_FADE_TIME)
	tw.parallel().tween_property(inner, "modulate:a", 0.0, BOMB_FADE_TIME)
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
			e["node"].modulate = _enemy_base_modulate(e)
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
					_plant_beaten(bite_target)
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
					_plant_beaten(plant)
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
		"id": _new_entity_id(),
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
	_collect_water_drop(drop)

func _collect_water_drop(drop: Dictionary) -> void:
	if not water_drops.has(drop):
		return
	water += drop["value"]
	drop["node"].queue_free()
	water_drops.erase(drop)
	_update_hud()

func _update_water_drops(delta: float) -> void:
	for drop in water_drops.duplicate():
		if drop["stolen_by"] != null:
			continue
		if drop.get("falling", false):
			drop["node"].position.y += SKY_DROP_FALL_SPEED * delta
			if drop["node"].position.y > GRID_TOP + ROWS * CELL:
				drop["node"].queue_free()
				water_drops.erase(drop)
		else:
			_fly_over_board(drop, delta)

# Krople i nawozy lataja nad plansza, odbijajac sie od jej krawedzi.
func _fly_over_board(drop: Dictionary, delta: float) -> void:
	var min_x := float(GRID_LEFT)
	var max_x := float(GRID_LEFT + COLS * CELL - WATER_DROP_TAP_SIZE)
	var min_y := float(GRID_TOP)
	var max_y := float(GRID_TOP + ROWS * CELL - WATER_DROP_TAP_SIZE)
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

# --- Nawozy: pojawiaja sie same (patrz _setup_fertilizer_waves), lataja nad
# plansza jak krople wody i czekaja na tapniecie ---
func _spawn_fertilizer_drop() -> void:
	var hit_area := Control.new()
	hit_area.size = Vector2(FERTILIZER_TAP_SIZE, FERTILIZER_TAP_SIZE)
	var visual_offset := (FERTILIZER_TAP_SIZE - FERTILIZER_VISUAL_SIZE) / 2
	hit_area.position = Vector2(
		randf_range(GRID_LEFT, GRID_LEFT + COLS * CELL - FERTILIZER_TAP_SIZE),
		randf_range(GRID_TOP, GRID_TOP + ROWS * CELL - FERTILIZER_TAP_SIZE)
	)
	hit_area.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(hit_area)

	var visual := _make_sprite(FERTILIZER_TEXTURE, FERTILIZER_VISUAL_SIZE)
	visual.position = Vector2(visual_offset, visual_offset)
	hit_area.add_child(visual)

	var angle := randf_range(0.0, TAU)
	var drop := {"id": _new_entity_id(), "node": hit_area, "vx": cos(angle) * WATER_DROP_SPEED, "vy": sin(angle) * WATER_DROP_SPEED}
	hit_area.gui_input.connect(_on_fertilizer_drop_gui_input.bind(drop))
	fertilizer_drops.append(drop)

func _on_fertilizer_drop_gui_input(event: InputEvent, drop: Dictionary) -> void:
	if not _is_tap_press(event):
		return
	_collect_fertilizer_drop(drop)

func _collect_fertilizer_drop(drop: Dictionary) -> void:
	if not fertilizer_drops.has(drop):
		return
	if fertilizer >= _fertilizer_limit():
		message_label.text = _fertilizer_full_message()
		return
	fertilizer += 1
	drop["node"].queue_free()
	fertilizer_drops.erase(drop)
	_update_hud()

func _update_fertilizer_drops(delta: float) -> void:
	for drop in fertilizer_drops:
		_fly_over_board(drop, delta)

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
	for e in enemies + junk_piles.values():
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

# --- Tasma roslin: pasek jest pusty, co jakis czas dochodzi losowa roslina (takze
# jeszcze nieodblokowana). Pelny pasek czeka, az gracz zwolni miejsce. ---
func _update_belt(delta: float) -> void:
	belt_timer -= delta
	if belt_timer > 0.0 or belt_items.size() >= GameState.MAX_LOADOUT:
		return
	belt_timer = randf_range(BELT_MIN_INTERVAL, BELT_MAX_INTERVAL)
	belt_items.append(_next_belt_plant())
	_rebuild_belt_tiles()
	# Nowa roslina wjezdza od dolu ekranu.
	var new_tile: Button = plant_tiles.back()["button"]
	var target_y := new_tile.position.y
	new_tile.position.y = VIEWPORT_HEIGHT
	new_tile.create_tween().tween_property(new_tile, "position:y", target_y, 0.4).set_trans(Tween.TRANS_SINE)
	_update_hud()

# Bez Kaktusow (woda nie jest tu potrzebna), a Pnacza tylko gdy jest na czym je sadzic.
func _random_belt_plant() -> int:
	var pool := []
	for i in range(PLANT_TYPES.size()):
		var role: String = PLANT_TYPES[i]["role"]
		if role == "generator" or (role == "vines" and junk_piles.is_empty()):
			continue
		pool.append(i)
	return pool.pick_random()

func _rebuild_belt_tiles() -> void:
	for tile in plant_tiles:
		tile["button"].queue_free()
	plant_tiles.clear()
	for i in range(belt_items.size()):
		var plant_idx: int = belt_items[i]
		var tile := _build_tile(_sidebar_tiles_top() + i * (TILE_HEIGHT + TILE_GAP), PLANT_TYPES[plant_idx]["texture"])
		tile["plant_idx"] = plant_idx
		var shade := ColorRect.new()
		shade.size = Vector2(TILE_WIDTH, 0)
		shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tile["button"].add_child(shade)
		tile["cooldown_shade"] = shade
		tile["button"].pressed.connect(_on_belt_tile_pressed.bind(i))
		plant_tiles.append(tile)

func _on_belt_tile_pressed(slot: int) -> void:
	if game_over:
		return
	var deselect: bool = belt_slot == slot and selected_plant_type >= 0
	belt_slot = -1 if deselect else slot
	selected_plant_type = -1 if deselect else belt_items[slot]
	fertilizer_mode = false
	remove_mode = false
	message_label.text = ""
	_update_hud()

# Tasma z podgladem bierze rosline z kolejki widocznej pod plansza.
func _next_belt_plant() -> int:
	if belt_queue.is_empty():
		return _random_belt_plant()
	var next: int = belt_queue.pop_front()["plant"]
	belt_queue.append({"plant": _random_belt_plant(), "swapped": false})
	_rebuild_belt_preview()
	return next

func _rebuild_belt_preview() -> void:
	for child in belt_preview_layer.get_children():
		child.queue_free()
	for i in range(belt_queue.size()):
		var entry: Dictionary = belt_queue[i]
		var btn := Button.new()
		btn.position = Vector2(GRID_LEFT + 110 + i * (BELT_PREVIEW_TILE + 10), BELT_PREVIEW_Y)
		btn.size = Vector2(BELT_PREVIEW_TILE, BELT_PREVIEW_TILE)
		btn.focus_mode = Control.FOCUS_NONE
		UiIcons.style_button(btn, TILE_BG_COLOR, 10)
		btn.disabled = entry["swapped"]
		var icon := _make_sprite(PLANT_TYPES[entry["plant"]]["texture"], int(BELT_PREVIEW_TILE - 12))
		icon.position = Vector2(6, 6)
		btn.add_child(icon)
		btn.pressed.connect(_on_preview_pressed.bind(i))
		belt_preview_layer.add_child(btn)

# Kazda rosline z podgladu mozna raz wymienic za roslimonety.
func _on_preview_pressed(i: int) -> void:
	if game_over:
		return
	if not GameState.use_swap_credit() and not GameState.spend_coins(event_rules["preview_swap_cost"]):
		message_label.text = "Za malo roslimonet na wymiane"
		return
	belt_queue[i] = {"plant": _random_belt_plant(), "swapped": true}
	_rebuild_belt_preview()

# --- Wydarzenia: przygotowanie etapu ---
func _setup_event() -> void:
	match help_type:
		"start_water":
			water += HELP_START_WATER
		"start_fertilizer":
			fertilizer = 1
		"shield":
			shield_left = 1
		"lantern":
			lantern_pending = true
			message_label.text = "Tapnij rzad, ktory ma oswietlic latarnia"
		"belt_vines":
			belt_items.append(_plant_index("vines"))
		"belt_frost":
			belt_items.append(_plant_index("freeze"))
		"free_bomb":
			_build_free_plant_button(_plant_index("bomb"))
		"fog_blow":
			_build_fog_blow_button()
	if event_rules.get("darkness", false) or event_rules.get("fog", false):
		_build_cover()
	if event_rules.has("clean_piles"):
		for i in range(event_rules["clean_piles"][GameState.event_stage]):
			_spawn_junk_pile()
		message_label.text = "Zniszcz wszystkie kupki smieci!"
	if event_rules.get("time_race", false):
		race_total = _race_time() + (HELP_EXTRA_TIME if help_type == "extra_time" else 0.0)
		race_left = race_total
		kills_label.visible = true
	if event_rules.get("coin_hunt", false):
		kills_label.visible = true
	if event_rules.get("belt_preview", false):
		belt_preview_layer = Control.new()
		belt_preview_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(belt_preview_layer)
		for i in range(BELT_PREVIEW_SIZE):
			belt_queue.append({"plant": _random_belt_plant(), "swapped": false})
		_rebuild_belt_preview()
		var caption := Label.new()
		caption.text = "Nastepne:"
		caption.position = Vector2(GRID_LEFT, BELT_PREVIEW_Y + 20)
		caption.add_theme_font_size_override("font_size", 20)
		add_child(caption)
	if belt and not belt_items.is_empty():
		_rebuild_belt_tiles()
	_update_hud()

func _plant_index(role: String) -> int:
	for i in range(PLANT_TYPES.size()):
		if PLANT_TYPES[i]["role"] == role:
			return i
	return 0

func _build_free_plant_button(plant_idx: int) -> void:
	free_plant_button = Button.new()
	free_plant_button.position = Vector2(SIDEBAR_X + 170, SIDEBAR_TOP - 8)
	free_plant_button.size = Vector2(64, 56)
	free_plant_button.focus_mode = Control.FOCUS_NONE
	UiIcons.style_button(free_plant_button, Color(0.85, 0.7, 0.15), 10)
	var icon := _make_sprite(PLANT_TYPES[plant_idx]["texture"], 48)
	icon.position = Vector2(8, 4)
	free_plant_button.add_child(icon)
	free_plant_button.pressed.connect(func():
		selected_plant_type = plant_idx
		free_plant_selected = true
		fertilizer_mode = false
		remove_mode = false
		message_label.text = "Darmowy Bumorzech - tapnij pole"
		_update_hud())
	add_child(free_plant_button)

func _build_fog_blow_button() -> void:
	var x := GRID_LEFT + COLS * CELL - PAUSE_BTN_WIDTH - TOP_BTN_GAP * 2 - EXIT_BTN_WIDTH - 130.0
	fog_blow_button = _make_top_button(Vector2(x, 2), Vector2(130, TOP_BTN_HEIGHT))
	fog_blow_button.text = "Podmuch"
	fog_blow_button.add_theme_font_size_override("font_size", 20)
	fog_blow_button.pressed.connect(func():
		fog_blow_left = FOG_BLOW_TIME
		fog_blow_button.queue_free()
		fog_blow_button = null)

func _build_cover() -> void:
	var darkness: bool = event_rules.get("darkness", false)
	for c in range(COLS):
		var column := []
		for r in range(ROWS):
			var rect: Control = null if darkness else UiIcons.fog_tile(CELL)
			if rect == null:
				rect = ColorRect.new()
				rect.color = COVER_COLOR if darkness else FOG_COLOR
			rect.position = Vector2(GRID_LEFT + c * CELL, GRID_TOP + r * CELL)
			rect.size = Vector2(CELL, CELL)
			rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
			add_child(rect)
			column.append(rect)
		cover_cells.append(column)

# Limit czasu Wyscigu: tyle, ile trwa wypuszczenie wszystkich wrogow, plus zapas.
func _race_time() -> float:
	var total := RACE_SPARE_TIME
	for i in range(waves.size()):
		var size: int = waves[i].size() * (2 if i >= 2 else 1)
		total += size * SPAWN_INTERVAL + BETWEEN_WAVES_TIME
	if _current_level().get("boss", -1) >= 0:
		total += RACE_BOSS_TIME
	return total

func _race_stars() -> int:
	var part := race_left / race_total
	if part >= RACE_THREE_STARS:
		return 3
	return 2 if part >= RACE_TWO_STARS else 1

# --- Wydarzenia: co klatke ---
func _update_event(delta: float) -> void:
	if event_rules.get("sky_drops", false):
		_update_sky_drops(delta)
	if event_rules.has("fertilizer_every"):
		fertilizer_event_timer -= delta
		if fertilizer_event_timer <= 0.0:
			fertilizer_event_timer = event_rules["fertilizer_every"]
			_spawn_fertilizer_drop()
	if event_rules.get("fog", false):
		_update_fog(delta)
	if not cover_cells.is_empty():
		_update_cover()
	if not coin_drops.is_empty():
		_update_coin_drops(delta)
	if event_rules.get("coin_hunt", false):
		kills_label.text = "Monety: %d" % GameState.event_hunt_coins
	if event_rules.get("time_race", false):
		race_left -= delta
		kills_label.text = "Czas: %d s" % ceili(max(race_left, 0.0))
		if race_left <= 0.0:
			_lose_game("Koniec czasu!")

# Krople spadaja coraz rzadziej i przepadaja, gdy mina dol planszy.
func _update_sky_drops(delta: float) -> void:
	sky_drop_timer -= delta
	if sky_drop_timer <= 0.0:
		sky_drop_timer = min(SKY_DROP_FIRST_INTERVAL + current_wave * SKY_DROP_INTERVAL_PER_WAVE, SKY_DROP_MAX_INTERVAL)
		var x := randf_range(GRID_LEFT, GRID_LEFT + COLS * CELL - WATER_DROP_TAP_SIZE)
		_spawn_water_drop(Vector2(x, GRID_TOP), SKY_DROP_VALUE)
		var drop: Dictionary = water_drops.back()
		drop["falling"] = true
		drop["node"].position = Vector2(x, GRID_TOP - WATER_DROP_TAP_SIZE / 2.0)

func _update_fog(delta: float) -> void:
	fog_blow_left = max(0.0, fog_blow_left - delta)
	fog_phase_left -= delta
	if fog_phase_left <= 0.0:
		fog_on = not fog_on
		fog_phase_left = FOG_ON_TIME if fog_on else FOG_OFF_TIME

func _is_covered(col: int, row: int, lit: Dictionary) -> bool:
	if event_rules.get("darkness", false):
		return row != lantern_row and not lit.has(_cell_key(col, row))
	return fog_on and fog_blow_left <= 0.0 and col >= FOG_FIRST_COL

func _update_cover() -> void:
	var lit := {}
	for plant in plants:
		for c in range(plant["col"] - 1, plant["col"] + 2):
			for r in range(plant["row"] - 1, plant["row"] + 2):
				lit[_cell_key(c, r)] = true
	for c in range(COLS):
		for r in range(ROWS):
			cover_cells[c][r].visible = _is_covered(c, r, lit)
	for e in enemies:
		var col := clampi(int((e["x"] - GRID_LEFT) / CELL), 0, COLS - 1)
		e["node"].visible = not _is_covered(col, e["row"], lit)
	for pile in junk_piles.values():
		pile["node"].visible = not _is_covered(pile["col"], pile["row"], lit)

# Lowy: moneta wypada z pokonanego wroga, lata nad plansza i po chwili znika.
func _spawn_coin_drop(origin: Vector2) -> void:
	var hit_area := Control.new()
	hit_area.size = Vector2(FERTILIZER_TAP_SIZE, FERTILIZER_TAP_SIZE)
	hit_area.position = Vector2(
		clamp(origin.x, GRID_LEFT, GRID_LEFT + COLS * CELL - FERTILIZER_TAP_SIZE),
		clamp(origin.y, GRID_TOP, GRID_TOP + ROWS * CELL - FERTILIZER_TAP_SIZE)
	)
	hit_area.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(hit_area)
	var visual := UiIcons.plant_coin(COIN_DROP_VISUAL_SIZE)
	visual.position = Vector2.ONE * (FERTILIZER_TAP_SIZE - COIN_DROP_VISUAL_SIZE) / 2.0
	hit_area.add_child(visual)
	var angle := randf_range(0.0, TAU)
	var drop := {"node": hit_area, "vx": cos(angle) * WATER_DROP_SPEED, "vy": sin(angle) * WATER_DROP_SPEED, "life": COIN_DROP_LIFE}
	hit_area.gui_input.connect(func(event: InputEvent):
		if _is_tap_press(event) and coin_drops.has(drop):
			_collect_coin_drop(drop))
	coin_drops.append(drop)

func _collect_coin_drop(drop: Dictionary) -> void:
	var saplings := GameState.add_hunt_coins(EventData.HUNT_COIN_VALUE)
	if saplings > 0:
		message_label.text = "Prog zdobyty: +%d sadzonek!" % saplings
	drop["node"].queue_free()
	coin_drops.erase(drop)

func _update_coin_drops(delta: float) -> void:
	for drop in coin_drops.duplicate():
		_fly_over_board(drop, delta)
		drop["life"] -= delta
		if drop["life"] <= 0.0:
			drop["node"].queue_free()
			coin_drops.erase(drop)

# --- Gra zespolowa ---
func _setup_team() -> void:
	NetSession.session_lost.connect(_on_team_session_lost)
	if is_guest:
		NetSession.snapshot_received.connect(_apply_snapshot)
		NetSession.event_received.connect(_on_team_event)
		NetSession.action_error_received.connect(func(text: String): message_label.text = text)
		NetSession.place_confirmed.connect(_on_place_confirmed)
		NetSession.game_over_received.connect(_on_team_game_over)
		NetSession.notify_guest_in_game()
	else:
		NetSession.action_received.connect(_on_guest_action)

func _new_entity_id() -> int:
	next_entity_id += 1
	return next_entity_id

# Komunikat o przebiegu gry (fale, bossowie) - widza go obaj gracze. Podpowiedzi
# typu "To pole jest zajete" trafiaja tylko do gracza, ktory je wywolal.
func _announce(text: String) -> void:
	message_label.text = text
	if team:
		NetSession.send_event("message", [text])

func _on_team_session_lost() -> void:
	if game_over:
		NetSession.notice = ""
		return
	game_over = true
	_close_pause_layer()
	_hide_top_buttons()
	message_label.text = NetSession.notice
	NetSession.notice = ""
	_show_end_buttons()

# --- Host: stan planszy dla goscia i wykonywanie jego akcji ---
func _update_snapshot(delta: float) -> void:
	snapshot_timer -= delta
	if snapshot_timer <= 0.0:
		snapshot_timer = TEAM_SNAPSHOT_INTERVAL
		NetSession.send_snapshot(_build_snapshot())

func _build_snapshot() -> Dictionary:
	var enemy_rows := []
	var boss := []
	for e in enemies:
		var kind: int = -1 - e["boss_type_idx"] if e["is_boss"] else e["type_idx"]
		enemy_rows.append([e["id"], kind, e["node"].position, e["node"].rotation, e["hp"], e["max_hp"], e["node"].modulate])
		if e["is_boss"] and boss.is_empty():
			boss = [boss_name_label.text, float(e["hp"]) / float(e["max_hp"])]
	var plant_rows := []
	for p in plants:
		plant_rows.append([p["id"], p["type_idx"], p["node"].position, p["hp"], p["max_hp"], p["boosted"]])
	var shot_rows := []
	for s in projectiles + homing_projectiles:
		shot_rows.append([s["id"], s["node"].position, s["node"].rotation, s["node"].modulate, int(s["node"].size.x)])
	var pile_rows := []
	for pile in junk_piles.values():
		pile_rows.append([_cell_key(pile["col"], pile["row"]), pile["node"].position, pile["hp"], pile["max_hp"]])
	var water_rows := []
	for d in water_drops:
		water_rows.append([d["id"], d["node"].position, d["stolen_by"] != null])
	var fertilizer_rows := []
	for d in fertilizer_drops:
		fertilizer_rows.append([d["id"], d["node"].position])
	return {
		"water": water, "fertilizer": fertilizer, "wave": current_wave, "boss": boss,
		"enemies": enemy_rows, "plants": plant_rows, "shots": shot_rows, "piles": pile_rows,
		"water_drops": water_rows, "fertilizer_drops": fertilizer_rows,
	}

func _on_guest_action(kind: String, args: Array) -> void:
	if game_over:
		return
	match kind:
		"place":
			if _is_valid_cell(args, 1) and args[0] is int and args[0] >= 0 and args[0] < PLANT_TYPES.size():
				var guest_power := clampf(float(args[3]), 1.0, GameState.max_plant_power()) if args.size() > 3 else 1.0
				var error := _place_plant(args[0], args[1], args[2], guest_power)
				if error == "":
					NetSession.send_place_confirmed(args[0])
				else:
					NetSession.send_action_error(error)
				_update_hud()
		"remove":
			if _is_valid_cell(args, 0):
				if grid_occupancy[args[0]][args[1]] == null:
					NetSession.send_action_error("Brak rosliny na tym polu")
				else:
					_remove_plant(grid_occupancy[args[0]][args[1]])
		"fertilizer":
			if _is_valid_cell(args, 0) and fertilizer > 0:
				if grid_occupancy[args[0]][args[1]] == null:
					NetSession.send_action_error("Brak rosliny na tym polu")
				else:
					_apply_fertilizer(grid_occupancy[args[0]][args[1]])
					_update_hud()
		"water":
			for d in water_drops:
				if not args.is_empty() and d["id"] == args[0]:
					_collect_water_drop(d)
					break
		"fertilizer_drop":
			if fertilizer >= _fertilizer_limit():
				NetSession.send_action_error(_fertilizer_full_message())
				return
			for d in fertilizer_drops:
				if not args.is_empty() and d["id"] == args[0]:
					_collect_fertilizer_drop(d)
					break

func _is_valid_cell(args: Array, offset: int) -> bool:
	if args.size() < offset + 2 or not (args[offset] is int) or not (args[offset + 1] is int):
		return false
	return args[offset] >= 0 and args[offset] < COLS and args[offset + 1] >= 0 and args[offset + 1] < ROWS

# --- Gosc: akcje ida do hosta, a plansza jest rysowana ze stanu od niego ---
func _guest_tile_tap(col: int, row: int) -> void:
	if remove_mode:
		NetSession.send_action("remove", [col, row])
		remove_mode = false
	elif fertilizer_mode:
		NetSession.send_action("fertilizer", [col, row])
		fertilizer_mode = false
	elif selected_plant_type < 0:
		message_label.text = "Wybierz rosline z paska po lewej"
		return
	else:
		NetSession.send_action("place", [selected_plant_type, col, row, GameState.plant_power(selected_plant_type)])
		selected_plant_type = -1
	message_label.text = ""
	_update_hud()

func _on_place_confirmed(plant_idx: int) -> void:
	plant_cooldowns[plant_idx] = _recharge_time(plant_idx)

func _on_team_event(kind: String, args: Array) -> void:
	match kind:
		"message":
			message_label.text = args[0]
		"bomb":
			_spawn_bomb_explosion(args[0], args[1])
		"gust":
			_spawn_gust_cloud(args[0], args[1])

func _on_team_game_over(won: bool, enemy_texture: String) -> void:
	if won:
		# Ostatni stan planszy moze nie zdazyc dojsc, a wszyscy wrogowie sa juz pokonani.
		for key in net_views.keys():
			if key.begins_with("e"):
				net_views[key]["node"].queue_free()
				net_views.erase(key)
		_apply_boss_bar([])
		_win_game()
	else:
		if enemy_texture.begins_with("res://assets/"):
			last_enemy_texture = enemy_texture
		_lose_game()

func _apply_snapshot(s: Dictionary) -> void:
	if game_over:
		return
	var seen := {}
	for row in s["enemies"]:
		var key := "e%d" % row[0]
		seen[key] = true
		var view: Dictionary = net_views.get(key, {})
		if view.is_empty():
			view = _make_enemy_view(key, row[1], row[2])
		view["target"] = row[2]
		view["node"].rotation = row[3]
		view["node"].modulate = row[6]
		_update_view_hp(view, row[4], row[5])
	for row in s["plants"]:
		var key := "p%d" % row[0]
		seen[key] = true
		var view: Dictionary = net_views.get(key, {})
		if view.is_empty():
			view = _make_plant_view(key, row[1], row[2])
		view["target"] = row[2]
		view["ring"].visible = row[5]
		_update_view_hp(view, row[3], row[4])
	for row in s["shots"]:
		var key := "s%d" % row[0]
		seen[key] = true
		var view: Dictionary = net_views.get(key, {})
		if view.is_empty():
			view = _add_view(key, _make_sprite(THORN_TEXTURE, row[4]), row[1])
			view["node"].modulate = row[3]
		view["target"] = row[1]
		view["node"].rotation = row[2]
	for row in s["piles"]:
		var key := "j" + str(row[0])
		seen[key] = true
		var view: Dictionary = net_views.get(key, {})
		if view.is_empty():
			var node := _make_sprite(JUNK_PILE_TEXTURE, CELL - 16)
			view = _add_view(key, node, row[1])
			view["bar"] = _add_health_bar(node, CELL - 16)
		_update_view_hp(view, row[2], row[3])
	for row in s["water_drops"]:
		var key := "w%d" % row[0]
		seen[key] = true
		var view: Dictionary = net_views.get(key, {})
		if view.is_empty():
			view = _make_drop_view(key, row[1], WATER_DROP_TEXTURE, WATER_DROP_VISUAL_SIZE, WATER_DROP_TAP_SIZE, "water", row[0])
		view["target"] = row[1]
		view["visual"].modulate = WATER_DROP_STOLEN_COLOR if row[2] else Color(1, 1, 1)
	for row in s["fertilizer_drops"]:
		var key := "f%d" % row[0]
		seen[key] = true
		var view: Dictionary = net_views.get(key, {})
		if view.is_empty():
			view = _make_drop_view(key, row[1], FERTILIZER_TEXTURE, FERTILIZER_VISUAL_SIZE, FERTILIZER_TAP_SIZE, "fertilizer_drop", row[0])
		view["target"] = row[1]
	for key in net_views.keys():
		if not seen.has(key):
			net_views[key]["node"].queue_free()
			net_views.erase(key)

	var hud_changed: bool = water != s["water"] or fertilizer != s["fertilizer"] or current_wave != s["wave"]
	water = s["water"]
	fertilizer = s["fertilizer"]
	current_wave = s["wave"]
	if hud_changed:
		_update_hud()
	_apply_boss_bar(s["boss"])

func _add_view(key: String, node: Control, pos: Vector2) -> Dictionary:
	node.position = pos
	add_child(node)
	var view := {"node": node, "target": pos}
	net_views[key] = view
	return view

func _make_enemy_view(key: String, kind: int, pos: Vector2) -> Dictionary:
	var is_boss := kind < 0
	var texture: String = BOSS_TYPES[-1 - kind]["texture"] if is_boss else ENEMY_TYPES[kind]["texture"]
	var size: int = CELL - 4 if is_boss else CELL - 16
	var node := _make_sprite(texture, size)
	var view := _add_view(key, node, pos)
	view["bar"] = _add_health_bar(node, size)
	return view

func _make_plant_view(key: String, type_idx: int, pos: Vector2) -> Dictionary:
	var node := _make_sprite(PLANT_TYPES[type_idx]["texture"], CELL - 16)
	var view := _add_view(key, node, pos)
	view["bar"] = _add_health_bar(node, CELL - 16)
	var ring := _make_sprite(BOOST_RING_TEXTURE, CELL)
	ring.position = Vector2(-8, -8)
	node.add_child(ring)
	view["ring"] = ring
	return view

# Kropla u goscia: po tapnieciu od razu znika, a host zbiera ja u siebie.
func _make_drop_view(key: String, pos: Vector2, texture: String, visual_size: int, tap_size: int, action: String, id: int) -> Dictionary:
	var hit_area := Control.new()
	hit_area.size = Vector2(tap_size, tap_size)
	hit_area.mouse_filter = Control.MOUSE_FILTER_STOP
	var visual := _make_sprite(texture, visual_size)
	visual.position = Vector2.ONE * (tap_size - visual_size) / 2.0
	hit_area.add_child(visual)
	hit_area.gui_input.connect(func(event: InputEvent):
		if _is_tap_press(event) and hit_area.visible:
			if action == "fertilizer_drop" and fertilizer >= _fertilizer_limit():
				message_label.text = _fertilizer_full_message()
				return
			hit_area.visible = false
			NetSession.send_action(action, [id]))
	var view := _add_view(key, hit_area, pos)
	view["visual"] = visual
	return view

# Pasek zycia rysujemy tak jak u hosta: pokazuje sie przy utracie HP.
func _update_view_hp(view: Dictionary, hp: float, max_hp: float) -> void:
	var hurt: bool = view.has("hp") and hp < view["hp"]
	view["hp"] = hp
	view["max_hp"] = max_hp
	if not view.has("hurt_timer"):
		view["hurt_timer"] = HEALTH_BAR_HIDE_DELAY + 1.0
	if hurt:
		_flash_health_bar(view)

func _update_guest_view(delta: float) -> void:
	var weight := 1.0 - exp(-TEAM_VIEW_SMOOTHING * delta)
	for view in net_views.values():
		view["node"].position = view["node"].position.lerp(view["target"], weight)
		if view.has("hurt_timer"):
			view["hurt_timer"] += delta
			if view["hurt_timer"] > HEALTH_BAR_HIDE_DELAY:
				view["bar"]["bg"].visible = false
				view["bar"]["fg"].visible = false

func _apply_boss_bar(boss: Array) -> void:
	var alive := not boss.is_empty()
	boss_name_label.visible = alive
	boss_bar_bg.visible = alive
	boss_bar_fg.visible = alive
	if alive:
		boss_name_label.text = boss[0]
		boss_bar_fg.size.x = 300 * clampf(boss[1], 0.0, 1.0)

# --- Koniec gry ---
func _check_win_condition() -> void:
	if endless:
		return
	if event_rules.has("clean_piles"):
		if junk_piles.is_empty():
			_win_game()
		return
	if current_wave < waves.size():
		return
	if not enemies.is_empty() or wave_in_progress:
		return
	var boss_idx: int = _current_level().get("boss", -1)
	if boss_idx >= 0 and not boss_spawned:
		return
	_win_game()

func _lose_game(reason := "Smieci dotarly do domu!") -> void:
	game_over = true
	# Przegrana bez wroga w domu (czas, stracona roslina): ogolny smieciostwor.
	if last_enemy_texture == "":
		last_enemy_texture = ENEMY_TYPES[0]["texture"]
	if team and not is_guest:
		NetSession.send_game_over(false, last_enemy_texture)
	_hide_top_buttons()
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
	lose_label.text = reason
	lose_label.add_theme_font_size_override("font_size", 32)
	lose_label.add_theme_color_override("font_color", Color(0.95, 0.4, 0.3))
	lose_label.position = Vector2(VIEWPORT_WIDTH / 2.0 - 300, VIEWPORT_HEIGHT / 2.0 + 110)
	lose_label.size = Vector2(600, 50)
	lose_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lose_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(lose_label)

	if endless:
		var new_record := GameState.submit_endless_score(kills)
		var score_label := Label.new()
		score_label.text = ("NOWY REKORD! " if new_record else "") + "Pokonani wrogowie: %d  (rekord: %d)" % [kills, GameState.endless_best]
		score_label.add_theme_font_size_override("font_size", 26)
		score_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
		score_label.position = Vector2(VIEWPORT_WIDTH / 2.0 - 400, VIEWPORT_HEIGHT / 2.0 + 160)
		score_label.size = Vector2(800, 40)
		score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		score_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(score_label)
		_update_hud()

	_show_end_buttons()

func _win_game() -> void:
	game_over = true
	_hide_top_buttons()
	message_label.text = "WYGRANA - obronles ogrod!"
	# Gra zespolowa nie posuwa sciezki: gosc moze grac na poziomie, ktorego
	# jeszcze nie ma otwartego.
	if team and not is_guest:
		NetSession.send_game_over(true, "")
	if not team and not event_game:
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

	if event_game:
		_show_event_reward()
	elif team:
		# Nagroda za kazda wygrana gre zespolowa, u obu graczy.
		GameState.award_team_win()
		var reward_y := VIEWPORT_HEIGHT / 2.0 - 10
		_show_ruby_reward(Vector2(VIEWPORT_WIDTH / 2.0 - 190, reward_y), 64, false, "+%d" % GameState.TEAM_WIN_RUBIES)
		_show_ruby_reward(Vector2(VIEWPORT_WIDTH / 2.0 + 30, reward_y), 64, false, "+%d" % GameState.TEAM_WIN_COINS, UiIcons.plant_coin(64))
	# Rubin tylko za pierwsze wygranie tego poziomu.
	elif GameState.award_level_ruby(GameState.current_level_index):
		_show_ruby_reward(Vector2(VIEWPORT_WIDTH / 2.0 - 70, VIEWPORT_HEIGHT / 2.0 - 10), 64, false)

	var delay := get_tree().create_timer(1.5)
	delay.timeout.connect(_show_end_buttons)

func _show_event_reward() -> void:
	var stars: int = _race_stars() if event_rules.get("time_race", false) else 0
	var reward := GameState.complete_event_stage(stars)
	var y := VIEWPORT_HEIGHT / 2.0 - 10
	if stars > 0:
		message_label.text = "Gwiazdki: %d z 3" % stars
	if reward["saplings"] > 0:
		var x: float = VIEWPORT_WIDTH / 2.0 - (190.0 if reward["rubies"] > 0 else 70.0)
		_show_ruby_reward(Vector2(x, y), 64, false, "+%d" % reward["saplings"], UiIcons.sapling(64))
	if reward["rubies"] > 0:
		_show_ruby_reward(Vector2(VIEWPORT_WIDTH / 2.0 + 30, y), 64, false, "+%d" % reward["rubies"])

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

# "+1 [rubin]" wyskakujacy w danym miejscu; fade = po chwili znika (w trakcie
# gry), bez fade zostaje na ekranie (ekran wygranej).
func _show_ruby_reward(pos: Vector2, icon_size: float, fade := true, amount := "+1", icon: Control = null) -> void:
	var box := Control.new()
	box.position = pos
	box.size = Vector2(icon_size * 2.2, icon_size)
	box.pivot_offset = box.size / 2.0
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.scale = Vector2(0.01, 0.01)
	add_child(box)

	var plus := Label.new()
	plus.text = amount
	plus.add_theme_font_size_override("font_size", int(icon_size * 0.75))
	plus.add_theme_color_override("font_color", UiIcons.RUBY_LIGHT_COLOR)
	plus.add_theme_color_override("font_outline_color", UiIcons.RUBY_DARK_COLOR.darkened(0.5))
	plus.add_theme_constant_override("outline_size", 8)
	plus.position = Vector2(0, 0)
	plus.size = Vector2(icon_size * 1.1, icon_size)
	plus.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	plus.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	plus.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(plus)

	var reward_icon: Control = icon if icon != null else UiIcons.ruby(icon_size)
	reward_icon.position = Vector2(icon_size * 1.2, 0)
	box.add_child(reward_icon)

	var tw := box.create_tween()
	tw.tween_property(box, "scale", Vector2(1, 1), 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if fade:
		tw.tween_interval(1.5)
		tw.tween_property(box, "modulate:a", 0.0, 0.6)
		tw.tween_callback(box.queue_free)

func _make_square_texture(size: int) -> ImageTexture:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(1, 1, 1, 1))
	return ImageTexture.create_from_image(img)

func _show_end_buttons() -> void:
	var y := GRID_TOP + ROWS * CELL + 150
	if team:
		var back_btn := Button.new()
		back_btn.text = "Wroc na sciezke"
		back_btn.position = Vector2(GRID_LEFT, y)
		back_btn.size = Vector2(250, 40)
		back_btn.pressed.connect(_leave_to_level_select)
		add_child(back_btn)
		return
	var retry_btn := Button.new()
	retry_btn.text = "Zagraj ponownie"
	retry_btn.position = Vector2(GRID_LEFT, y)
	retry_btn.size = Vector2(250, 40)
	retry_btn.pressed.connect(func(): get_tree().reload_current_scene())
	add_child(retry_btn)

	var select_btn := Button.new()
	select_btn.text = "Wroc do wydarzenia" if event_game else "Wybierz poziom"
	select_btn.position = Vector2(GRID_LEFT + 270, y)
	select_btn.size = Vector2(250, 40)
	select_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/Events.tscn" if event_game else "res://scenes/LevelSelect.tscn"))
	add_child(select_btn)
