extends Node

# Konta graczy sa lokalne (na tym urzadzeniu, bez hasla): lista kont w
# PROFILES_PATH, a postep kazdego konta w osobnym pliku save_<id>.json.
# Zapis sprzed kont (LEGACY_SAVE_PATH) staje sie pierwszym kontem.
const PROFILES_PATH := "user://profiles.json"
const PROFILE_SAVE_PATH := "user://save_%s.json"
const LEGACY_SAVE_PATH := "user://savegame.json"
const MAX_PROFILES := 6
const SAVE_VERSION := 5
const LEVEL_COUNT := 60
const MAX_LOADOUT := 6
# Poziomy z zapisow sprzed wersji 4 (kazdy dal potem dwa nowe poziomy).
const OLD_LEVEL_COUNT := 28
# Indeks trybu nieskonczonego w zapisach wersji 4.
const V4_ENDLESS_INDEX := 56

# Skrzynie na sciezce: {wartosc: waga} - nizsze wartosci sa bardziej
# prawdopodobne.
const CHEST_RUBY_WEIGHTS := {1: 60, 2: 30, 3: 10}
const CHEST_COIN_WEIGHTS := {100: 40, 150: 28, 200: 18, 250: 10, 300: 4}

# Nagroda za wygrana gre zespolowa, dla obu graczy.
const TEAM_WIN_RUBIES := 1
const TEAM_WIN_COINS := 50

# Limit nawozow: startowy, a kolejne zwiekszenia w sklepie po tych cenach
# (w rubinach) - az do 6.
const FERTILIZER_START_LIMIT := 2
const FERTILIZER_LIMIT_PRICES := [5, 6, 7, 8]

# Oferta "za reklame" w sklepie: raz dziennie (notatki 2026-10-06).
const AD_OFFER_RUBIES := 2

# Ulepszenia roslin: kazdy z 10 poziomow to tylko +1,5% sily (razem +15%), a cena
# rosnie od 10 do 28 rubinow. Cala sciezka daje ok. 75 rubinow, wiec ulepszenia
# nie zastepuja planowania na planszy.
const PLANT_UPGRADE_MAX_LEVEL := 10
const PLANT_UPGRADE_STEP := 0.015
const PLANT_UPGRADE_BASE_PRICE := 10
const PLANT_UPGRADE_PRICE_STEP := 2

# Kod testowy pozwala raz zmienic wydarzenie. W kodzie gry jest tylko jego skrot.
const TEST_CODE_SHA256 := "e0277cd898e021d443fe6817322b8f98623cb9a0a366e5daa39e03c47bf79959"
const TEST_CODE_MAX_FAILURES := 3
const TEST_CODE_LOCK_SECONDS := 10 * 60

# Ogrod: 8 pol, roslinka rosnie 15 godzin i daje 50 roslimonet. Przyspieszenie
# kosztuje 15 rubinow, a pszczolka zabiera 3 godziny i wraca po 15-30 minutach.
const GARDEN_PLOTS := 8
const GARDEN_GROW_SECONDS := 15 * 3600
const GARDEN_HARVEST_COINS := 50
const GARDEN_RUSH_RUBIES := 15
const GARDEN_BEE_SECONDS := 3 * 3600
const BEE_RETURN_MIN_SECONDS := 15 * 60
const BEE_RETURN_MAX_SECONDS := 30 * 60
const PLOT_EMPTY := "empty"
const PLOT_SAPLING := "sapling"
const PLOT_GROWING := "growing"

# Tryb nieskonczony daje rubin (jeden raz), gdy gracz pokona w jednej grze
# co najmniej tylu wrogow ("umowiona ilosc punktow" z notatek 2026-10-06).
const ENDLESS_RUBY_KILLS := 50
const DEFAULT_PLAYER_NAME := "Gracz"
const PLAYER_NAME_MAX_LENGTH := 14

var current_level_index := 0
# Plansza gry zespolowej (pusta poza gra zespolowa) - patrz current_level().
var team_level := {}
# Plansza etapu wydarzenia (pusta poza wydarzeniem) i numer tego etapu.
var event_level := {}
var event_stage := 0
# Pomoc kupiona na ten etap (zuzywa ja nastepne wejscie na plansze) i rosliny
# wylosowane na etap Narzuconej talii.
var event_help_active := false
var event_forced_plants: Array = []

# Talia na biezaca gre - ustawiana przez ekran wyboru talii (PlantSelect),
# odczytywana przez main.gd przy budowie paska roslin.
var current_loadout: Array = []

var completed_levels: Array = []

# Talia zapamietana per poziom: klucz to String(indeks poziomu od 0), wartosc
# to Array indeksow w PlantData.TYPES. Klucze trzymamy jako String, bo tak
# i tak wychodza z JSON.
var loadouts: Dictionary = {}

# Rekord trybu nieskonczonego: najwieksza liczba pokonanych wrogow w jednej grze.
var endless_best := 0

# Rubiny: 1 za pierwsze wygranie kazdego poziomu (ruby_levels[i] = juz dany)
# i 1 za przekroczenie ENDLESS_RUBY_KILLS w trybie nieskonczonym.
var rubies := 0
var ruby_levels: Array = []
var endless_ruby_awarded := false

# Roslimonety: ze skrzyn i z wygranych gier zespolowych.
var plant_coins := 0
# Otwarte skrzynie: numery poziomow, przed ktorymi stoja na sciezce.
var opened_chests: Array = []
var fertilizer_limit := FERTILIZER_START_LIMIT
# Ulepszenia roslin: String(indeks rosliny) -> poziom.
var plant_upgrades: Dictionary = {}
# Dzien (Unix), w ktorym gracz ostatnio wzial rubiny z oferty "za reklame".
var ad_offer_day := 0

# Ogrod: sadzonki, pola {"state", "end" (czas Unix konca wzrostu)} i czas
# powrotu pszczolki (0 = jeszcze nie ustalony).
var saplings := 0
var garden_plots: Array = []
var next_bee_time := 0

# Wydarzenie czasowe: indeks w EventData.ROTATION, czas startu (0 = czeka na
# start) i ukonczone etapy. Postepy znikaja razem z wydarzeniem.
var event_index := 0
var event_started := 0
var event_completed_stages: Array = []
# Wyscig: najlepsze gwiazdki na etap (String(etap) -> 1-3).
var event_stars: Dictionary = {}
# Lowy: suma monet z tygodnia i liczba osiagnietych progow.
var event_hunt_coins := 0
var event_hunt_thresholds := 0
# Sadzenie razem: wybor gracza ("" = jeszcze nie zapytany, "yes", "no"), zbiory
# obojga, czy cel juz wyplacony i kiedy poszedl darmowy prezent (dzien Unix).
var shared_choice := ""
var shared_my_harvests := 0
var shared_friend_harvests := 0
var shared_goal_paid := false
var shared_gift_day := 0
# Kupione w sklepie na zapas w biezacym wydarzeniu: pomoc na etap, wymiany roslin
# i dodatkowe sadzonki dla znajomego. Znikaja razem z wydarzeniem.
var event_help_prepaid := false
var event_swap_credits := 0
var shared_gift_credits := 0
# Kod testowy: zapisane postepy wydarzen, id wydarzenia -> postepy.
var event_saved_progress: Dictionary = {}

# Rosliny, w ktorych kolko na sciezce gracz juz "wszedl" (indeksy w PlantData.TYPES).
# Rosliny z unlock_level 1 sa dostepne od startu i nie trzeba ich odbierac.
var claimed_plants: Array = []

# Ikonki roslin (notatki 2026-10-30): dwie startowe sa dostepne od razu, kolejne
# zablokowane, dopoki gracz nie odblokuje rosliny, a potem trzeba je odblokowac
# w kilku krokach. unlocked_icons to indeksy w PlantData.TYPES,
# icon_unlock_steps: String(indeks) -> wykonane kroki.
var unlocked_icons: Array = []
var icon_unlock_steps: Dictionary = {}

# Konta: lista {"id": String, "name": String, "icon": int}. Nazwa i ikona
# (indeks rosliny w PlantData.TYPES) sa trzymane tutaj, a nie w pliku
# postepu, zeby ekran wyboru konta nie musial wczytywac wszystkich zapisow.
var profiles: Array = []
var next_profile_id := 1
# Wybrane konto ("" = jeszcze zadnego nie wybrano - wtedy nic nie zapisujemy).
var current_profile_id := ""
# Kod testowy: nieudane proby i koniec blokady (czas Unix). Sa wspolne dla
# wszystkich kont, zeby zmiana konta nie omijala blokady.
var test_code_failures := 0
var test_code_locked_until := 0

# Nazwa i ikona wybranego konta (plakietka w prawym dolnym rogu sciezki).
var player_name := DEFAULT_PLAYER_NAME
var player_icon := 0

func _ready() -> void:
	_reset_progress()
	load_profiles()

func _reset_progress() -> void:
	completed_levels = []
	ruby_levels = []
	for i in range(LEVEL_COUNT):
		completed_levels.append(false)
		ruby_levels.append(false)
	loadouts = {}
	current_loadout = []
	current_level_index = 0
	endless_best = 0
	rubies = 0
	endless_ruby_awarded = false
	plant_coins = 0
	opened_chests = []
	fertilizer_limit = FERTILIZER_START_LIMIT
	plant_upgrades = {}
	ad_offer_day = 0
	saplings = 0
	garden_plots = []
	for i in range(GARDEN_PLOTS):
		garden_plots.append({"state": PLOT_EMPTY, "end": 0})
	next_bee_time = 0
	event_index = 0
	event_started = 0
	event_level = {}
	event_help_active = false
	event_saved_progress = {}
	_reset_event_progress()
	claimed_plants = []
	unlocked_icons = []
	icon_unlock_steps = {}
	player_name = DEFAULT_PLAYER_NAME
	player_icon = 0

# --- Konta ---
func load_profiles() -> void:
	profiles = []
	if not FileAccess.file_exists(PROFILES_PATH):
		if FileAccess.file_exists(LEGACY_SAVE_PATH):
			_migrate_legacy_save()
		return
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(PROFILES_PATH))
	if not (parsed is Dictionary):
		return
	test_code_failures = _loaded_int(parsed, "test_code_failures")
	test_code_locked_until = _loaded_int(parsed, "test_code_locked_until")
	var raw_next = parsed.get("next_id", 1)
	if typeof(raw_next) == TYPE_FLOAT or typeof(raw_next) == TYPE_INT:
		next_profile_id = max(1, int(raw_next))
	var raw_list = parsed.get("profiles", [])
	if not (raw_list is Array):
		return
	for raw in raw_list:
		if not (raw is Dictionary) or not raw.has("id"):
			continue
		var icon = raw.get("icon", 0)
		var icon_idx := int(icon) if (typeof(icon) == TYPE_FLOAT or typeof(icon) == TYPE_INT) else 0
		profiles.append({
			"id": str(raw["id"]),
			"name": _clean_name(str(raw.get("name", ""))),
			"icon": clampi(icon_idx, 0, PlantData.TYPES.size() - 1),
		})

func save_profiles() -> void:
	var file := FileAccess.open(PROFILES_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({
			"next_id": next_profile_id,
			"profiles": profiles,
			"test_code_failures": test_code_failures,
			"test_code_locked_until": test_code_locked_until,
		}))
		file.close()

# Zapis sprzed kont przenosimy do pierwszego konta (z domyslna nazwa, ktora
# gracz moze potem zmienic na plakietce).
func _migrate_legacy_save() -> void:
	var id := str(next_profile_id)
	next_profile_id += 1
	DirAccess.rename_absolute(LEGACY_SAVE_PATH, PROFILE_SAVE_PATH % id)
	profiles.append({"id": id, "name": DEFAULT_PLAYER_NAME, "icon": 0})
	save_profiles()

func _clean_name(raw_name: String) -> String:
	var trimmed := raw_name.strip_edges().left(PLAYER_NAME_MAX_LENGTH)
	return trimmed if not trimmed.is_empty() else DEFAULT_PLAYER_NAME

# Czy inne konto (niz except_id) ma juz taka nazwe (bez wzgledu na wielkosc liter).
func is_profile_name_taken(raw_name: String, except_id := "") -> bool:
	var wanted := _clean_name(raw_name).to_lower()
	for p in profiles:
		if p["id"] != except_id and str(p["name"]).to_lower() == wanted:
			return true
	return false

func can_create_profile() -> bool:
	return profiles.size() < MAX_PROFILES

# Tworzy nowe konto i od razu je wybiera. Zwraca false, gdy nazwa jest zajeta
# albo kont jest juz za duzo.
func create_profile(raw_name: String, icon_idx: int) -> bool:
	if not can_create_profile() or is_profile_name_taken(raw_name):
		return false
	var id := str(next_profile_id)
	next_profile_id += 1
	# Nowe konto ma tylko rosliny startowe, wiec tylko takie moga byc ikona.
	var icon := icon_idx if PlantData.TYPES[icon_idx].get("unlock_level", 1) <= 1 else 0
	profiles.append({"id": id, "name": _clean_name(raw_name), "icon": icon})
	save_profiles()
	select_profile(id)
	save_progress()
	return true

# Usuwa konto razem z jego plikiem postepu. Jesli to bylo wybrane konto,
# zadne nie zostaje wybrane (trzeba wrocic do ekranu kont).
func delete_profile(id: String) -> void:
	for i in range(profiles.size()):
		if profiles[i]["id"] == id:
			profiles.remove_at(i)
			break
	var path := PROFILE_SAVE_PATH % id
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	save_profiles()
	if current_profile_id == id:
		_reset_progress()
		current_profile_id = ""

func select_profile(id: String) -> void:
	_reset_progress()
	for p in profiles:
		if p["id"] == id:
			current_profile_id = id
			player_name = p["name"]
			player_icon = p["icon"]
			load_progress()
			# Konta sprzed blokady ikonek zachowuja ikone, ktora juz wybraly.
			if not is_icon_unlocked(player_icon):
				unlocked_icons.append(player_icon)
				save_progress()
			refresh_event()
			return

func current_level() -> Dictionary:
	if not event_level.is_empty():
		return event_level
	return team_level if not team_level.is_empty() else LevelData.LEVELS[current_level_index]

func _now() -> int:
	return int(Time.get_unix_time_from_system())

# --- Wydarzenie czasowe ---
# Po uplywie tygodnia wydarzenie znika z postepami, a startuje nastepne. Gdy
# nastepnego jeszcze nie ma, indeks na nie czeka - pojawi sie po dopisaniu do
# EventData.ROTATION w aktualizacji gry.
func refresh_event() -> void:
	var changed := false
	if event_started > 0 and _now() - event_started >= EventData.DURATION_DAYS * 86400:
		event_index += 1
		event_started = 0
		_reset_event_progress()
		changed = true
	if event_started == 0 and event_index < EventData.ROTATION.size():
		event_started = _now()
		changed = true
	if changed:
		save_progress()

func current_event() -> Dictionary:
	if event_started == 0 or event_index >= EventData.ROTATION.size():
		return {}
	return EventData.ROTATION[event_index]

func event_seconds_left() -> int:
	return max(0, EventData.DURATION_DAYS * 86400 - (_now() - event_started))

func _reset_event_progress() -> void:
	event_completed_stages = []
	event_stars = {}
	event_hunt_coins = 0
	event_hunt_thresholds = 0
	shared_choice = ""
	shared_my_harvests = 0
	shared_friend_harvests = 0
	shared_goal_paid = false
	shared_gift_day = 0
	event_help_prepaid = false
	event_swap_credits = 0
	shared_gift_credits = 0

# --- Kod testowy: zmiana wydarzenia ---
func is_test_code(code: String) -> bool:
	return code.strip_edges().sha256_text() == TEST_CODE_SHA256

# Ile sekund zostalo do konca blokady. Cofniety zegar nie wydluza jej ponad 10 minut.
func test_code_lock_seconds_left() -> int:
	return clampi(test_code_locked_until - _now(), 0, TEST_CODE_LOCK_SECONDS)

# Sprawdza kod wpisany przez gracza. Trzecia zla proba z rzedu blokuje kod na
# 10 minut, a podczas blokady zaden kod nie dziala.
func try_test_code(code: String) -> bool:
	if test_code_lock_seconds_left() > 0:
		return false
	if is_test_code(code):
		test_code_failures = 0
		save_profiles()
		return true
	test_code_failures += 1
	if test_code_failures >= TEST_CODE_MAX_FAILURES:
		test_code_failures = 0
		test_code_locked_until = _now() + TEST_CODE_LOCK_SECONDS
	save_profiles()
	return false

# Przechodzi na wybrane wydarzenie, ktore startuje z pelnym tygodniem. Postepy
# obecnego mozna zachowac na powrot do niego; bez zachowania przepadaja.
func switch_event(event_idx: int, keep_progress: bool) -> void:
	var current := current_event()
	if not current.is_empty():
		if keep_progress:
			event_saved_progress[current["id"]] = _event_progress()
		else:
			event_saved_progress.erase(current["id"])
	event_index = event_idx
	event_started = _now()
	_reset_event_progress()
	var event_id: String = EventData.ROTATION[event_idx]["id"]
	if event_saved_progress.has(event_id):
		_restore_event_progress(event_saved_progress[event_id])
		event_saved_progress.erase(event_id)
	save_progress()

func _event_progress() -> Dictionary:
	return {
		"completed_stages": event_completed_stages,
		"stars": event_stars,
		"hunt_coins": event_hunt_coins,
		"hunt_thresholds": event_hunt_thresholds,
		"shared_choice": shared_choice,
		"shared_my_harvests": shared_my_harvests,
		"shared_friend_harvests": shared_friend_harvests,
		"shared_goal_paid": shared_goal_paid,
		"shared_gift_day": shared_gift_day,
		"help_prepaid": event_help_prepaid,
		"swap_credits": event_swap_credits,
		"gift_credits": shared_gift_credits,
	}

func _restore_event_progress(saved: Dictionary) -> void:
	event_help_prepaid = bool(saved.get("help_prepaid", false))
	event_swap_credits = _loaded_int(saved, "swap_credits")
	shared_gift_credits = _loaded_int(saved, "gift_credits")
	for stage in saved.get("completed_stages", []):
		event_completed_stages.append(int(stage))
	var stars: Dictionary = saved.get("stars", {})
	for key in stars.keys():
		event_stars[str(key)] = int(stars[key])
	event_hunt_coins = _loaded_int(saved, "hunt_coins")
	event_hunt_thresholds = _loaded_int(saved, "hunt_thresholds")
	shared_choice = str(saved.get("shared_choice", ""))
	shared_my_harvests = _loaded_int(saved, "shared_my_harvests")
	shared_friend_harvests = _loaded_int(saved, "shared_friend_harvests")
	shared_goal_paid = bool(saved.get("shared_goal_paid", false))
	shared_gift_day = _loaded_int(saved, "shared_gift_day")

func is_event_stage_open(stage: int) -> bool:
	# Lowy: mozna grac dowolny etap, bo liczy sie suma monet.
	if current_event().get("coin_hunt", false):
		return true
	return stage == 0 or event_completed_stages.has(stage - 1)

# Przygotowuje etap. Pomoc pobiera roslimonety; bez nich etap nie startuje. Nie
# startuje tez, gdy wydarzenie wlasnie sie skonczylo (zwraca false).
func start_event_game(stage: int, with_help := false) -> bool:
	var event_before := current_event()
	refresh_event()
	var event := current_event()
	if event.is_empty() or event["id"] != event_before.get("id"):
		return false
	if with_help:
		if event_help_prepaid:
			event_help_prepaid = false
			save_progress()
		elif not spend_coins(event["help"]["cost"]):
			return false
	event_help_active = with_help
	event_stage = stage
	current_level_index = EventData.STAGES[stage]["level_idx"]
	current_loadout = []
	event_level = LevelData.event_level(event, stage)
	if event.get("forced_deck", false):
		event_forced_plants = _random_forced_deck(stage)
	return true

# Narzucona talia: zawsze zrodlo wody (na trudniejszych etapach takze
# Megakaktus) i 2 losowe rosliny, bez Pnaczy, ktore nie zawsze maja na czym rosnac.
func _random_forced_deck(stage: int) -> Array:
	var water_plants := []
	var others := []
	for i in range(PlantData.TYPES.size()):
		var role: String = PlantData.TYPES[i]["role"]
		if role == "generator":
			if PlantData.TYPES[i]["cost"] <= 25 or stage >= 3:
				water_plants.append(i)
		elif role != "vines":
			others.append(i)
	others.shuffle()
	var deck := [water_plants.pick_random(), others[0], others[1]]
	deck.sort()
	return deck

func is_event_game() -> bool:
	return not event_level.is_empty()

func clear_event_game() -> void:
	event_level = {}

# Wygrany etap: nagroda zalezna od wydarzenia. Zwraca {"saplings", "rubies"}.
# stars: gwiazdki z Wyscigu (0 w innych wydarzeniach).
func complete_event_stage(stars := 0) -> Dictionary:
	var event := current_event()
	var first_win: bool = not event_completed_stages.has(event_stage)
	var reward := {"saplings": 0, "rubies": 0}
	if first_win:
		event_completed_stages.append(event_stage)
	if event.get("coin_hunt", false):
		pass
	elif event.get("time_race", false):
		# Sadzonki tylko za nowe gwiazdki: po pierwszej w etapie, za kazda kolejna.
		var best: int = event_stars.get(str(event_stage), 0)
		reward["saplings"] = max(0, stars - best)
		event_stars[str(event_stage)] = max(best, stars)
	else:
		reward["saplings"] = EventData.STAGES[event_stage]["saplings"] if first_win else EventData.REPLAY_SAPLINGS
	if first_win and event_stage == EventData.STAGES.size() - 1:
		reward["rubies"] = event.get("final_rubies", 0)
	saplings += reward["saplings"]
	rubies += reward["rubies"]
	save_progress()
	return reward

# Moneta z Low: trafia do roslimonet i do sumy tygodnia. Zwraca liczbe sadzonek
# za progi osiagniete ta moneta.
func add_hunt_coins(amount: int) -> int:
	plant_coins += amount
	event_hunt_coins += amount
	var gained := 0
	while event_hunt_thresholds < EventData.HUNT_THRESHOLDS.size():
		var threshold: Dictionary = EventData.HUNT_THRESHOLDS[event_hunt_thresholds]
		if event_hunt_coins < threshold["coins"]:
			break
		gained += threshold["saplings"]
		event_hunt_thresholds += 1
	saplings += gained
	save_progress()
	return gained

func spend_coins(amount: int) -> bool:
	if plant_coins < amount:
		return false
	plant_coins -= amount
	save_progress()
	return true

# --- Zakupy w sklepie ---
func is_ad_offer_ready() -> bool:
	return ad_offer_day != _today()

func claim_ad_offer() -> bool:
	if not is_ad_offer_ready():
		return false
	ad_offer_day = _today()
	rubies += AD_OFFER_RUBIES
	save_progress()
	return true

# Pomoc na nastepny etap biezacego wydarzenia, kupiona na zapas.
func buy_event_help() -> bool:
	var event := current_event()
	if not event.has("help") or event_help_prepaid or not spend_coins(event["help"]["cost"]):
		return false
	event_help_prepaid = true
	save_progress()
	return true

func buy_swap_credit() -> bool:
	var event := current_event()
	if not event.get("belt_preview", false) or not spend_coins(event["preview_swap_cost"]):
		return false
	event_swap_credits += 1
	save_progress()
	return true

func use_swap_credit() -> bool:
	if event_swap_credits <= 0:
		return false
	event_swap_credits -= 1
	save_progress()
	return true

func buy_gift_credit() -> bool:
	if not is_shared_garden_on() or not spend_coins(EventData.GIFT_COST):
		return false
	shared_gift_credits += 1
	save_progress()
	return true

# Pole, na ktorym roslinka urosnie najszybciej (-1, gdy nic nie rosnie).
func soonest_growing_plot() -> int:
	var best := -1
	for i in range(garden_plots.size()):
		if garden_plots[i]["state"] == PLOT_GROWING:
			if best < 0 or plot_seconds_left(i) < plot_seconds_left(best):
				best = i
	return best

# --- Ulepszenia roslin ---
func plant_upgrade_level(plant_idx: int) -> int:
	return plant_upgrades.get(str(plant_idx), 0)

# Mnoznik sily rosliny (1.0 bez ulepszen).
func plant_power(plant_idx: int) -> float:
	return 1.0 + plant_upgrade_level(plant_idx) * PLANT_UPGRADE_STEP

func max_plant_power() -> float:
	return 1.0 + PLANT_UPGRADE_MAX_LEVEL * PLANT_UPGRADE_STEP

# Cena kolejnego poziomu; -1, gdy roslina jest juz w pelni ulepszona.
func plant_upgrade_price(plant_idx: int) -> int:
	var level := plant_upgrade_level(plant_idx)
	if level >= PLANT_UPGRADE_MAX_LEVEL:
		return -1
	return PLANT_UPGRADE_BASE_PRICE + level * PLANT_UPGRADE_PRICE_STEP

func buy_plant_upgrade(plant_idx: int) -> bool:
	var price := plant_upgrade_price(plant_idx)
	if price < 0 or rubies < price or not is_plant_unlocked(plant_idx):
		return false
	rubies -= price
	plant_upgrades[str(plant_idx)] = plant_upgrade_level(plant_idx) + 1
	save_progress()
	return true

# --- Sadzenie razem (opcja w tygodniu Low) ---
func is_shared_garden_offered() -> bool:
	return current_event().get("shared_garden", false)

func is_shared_garden_on() -> bool:
	return is_shared_garden_offered() and shared_choice == "yes"

func set_shared_choice(accepted: bool) -> void:
	shared_choice = "yes" if accepted else "no"
	save_progress()

func _today() -> int:
	return _now() / 86400

func is_free_gift_ready() -> bool:
	return shared_gift_day != _today()

# Sadzonka dla znajomego: pierwsza danego dnia za darmo, kolejne za roslimonety.
func pay_for_gift() -> bool:
	if is_free_gift_ready():
		shared_gift_day = _today()
		save_progress()
		return true
	if shared_gift_credits > 0:
		shared_gift_credits -= 1
		save_progress()
		return true
	return spend_coins(EventData.GIFT_COST)

func receive_gift() -> void:
	saplings += 1
	save_progress()

func set_friend_harvests(count: int) -> void:
	shared_friend_harvests = max(shared_friend_harvests, count)
	save_progress()

func shared_total_harvests() -> int:
	return shared_my_harvests + shared_friend_harvests

# Wspolny cel osiagniety: jednorazowa nagroda. Zwraca true, gdy wyplacono ja teraz.
func try_pay_shared_goal() -> bool:
	if shared_goal_paid or shared_total_harvests() < EventData.SHARED_GOAL_HARVESTS:
		return false
	shared_goal_paid = true
	saplings += EventData.SHARED_REWARD_SAPLINGS
	save_progress()
	return true

# --- Ogrod ---
func plant_sapling(i: int) -> void:
	if saplings > 0 and garden_plots[i]["state"] == PLOT_EMPTY:
		saplings -= 1
		garden_plots[i]["state"] = PLOT_SAPLING
		save_progress()

func water_plot(i: int) -> void:
	if garden_plots[i]["state"] == PLOT_SAPLING:
		garden_plots[i]["state"] = PLOT_GROWING
		garden_plots[i]["end"] = _now() + GARDEN_GROW_SECONDS
		save_progress()

func plot_seconds_left(i: int) -> int:
	return max(0, int(garden_plots[i]["end"]) - _now())

# Postep wzrostu od 0 do 1.
func plot_growth(i: int) -> float:
	return 1.0 - plot_seconds_left(i) / float(GARDEN_GROW_SECONDS)

func rush_plot(i: int) -> bool:
	if garden_plots[i]["state"] != PLOT_GROWING or rubies < GARDEN_RUSH_RUBIES:
		return false
	rubies -= GARDEN_RUSH_RUBIES
	garden_plots[i]["end"] = _now()
	save_progress()
	return true

func is_bee_here() -> bool:
	if next_bee_time == 0:
		_schedule_bee()
	return _now() >= next_bee_time

func _schedule_bee() -> void:
	next_bee_time = _now() + randi_range(BEE_RETURN_MIN_SECONDS, BEE_RETURN_MAX_SECONDS)
	save_progress()

func use_bee(i: int) -> void:
	if garden_plots[i]["state"] != PLOT_GROWING or not is_bee_here():
		return
	garden_plots[i]["end"] = int(garden_plots[i]["end"]) - GARDEN_BEE_SECONDS
	_schedule_bee()

# Dorosle roslinki daja roslimonety i znikaja. Zwraca numery tych pol.
func harvest_ready_plots() -> Array:
	var harvested := []
	for i in range(garden_plots.size()):
		if garden_plots[i]["state"] == PLOT_GROWING and plot_seconds_left(i) == 0:
			garden_plots[i] = {"state": PLOT_EMPTY, "end": 0}
			plant_coins += GARDEN_HARVEST_COINS
			if is_shared_garden_on():
				shared_my_harvests += 1
			harvested.append(i)
	if not harvested.is_empty():
		save_progress()
	return harvested

# Poziom jest otwarty, gdy poprzedni zostal ukonczony i gracz odebral
# wszystkie rosliny, ktorych kolka stoja na sciezce tuz przed nim.
func is_level_unlocked(i: int) -> bool:
	if i <= 0:
		return true
	if i - 1 >= completed_levels.size():
		return false
	if not completed_levels[i - 1]:
		return false
	for p_idx in range(PlantData.TYPES.size()):
		if PlantData.TYPES[p_idx].get("unlock_level", 1) == i + 1 and not claimed_plants.has(p_idx):
			return false
	return true

func is_level_completed(i: int) -> bool:
	if i < 0 or i >= completed_levels.size():
		return false
	return completed_levels[i]

func is_plant_unlocked(plant_idx: int) -> bool:
	if plant_idx < 0 or plant_idx >= PlantData.TYPES.size():
		return false
	if PlantData.TYPES[plant_idx].get("unlock_level", 1) <= 1:
		return true
	return claimed_plants.has(plant_idx)

# Kolko rosliny mozna "wejsc" (odebrac), gdy poziom przed nim jest ukonczony.
func is_plant_claimable(plant_idx: int) -> bool:
	if plant_idx < 0 or plant_idx >= PlantData.TYPES.size():
		return false
	if is_plant_unlocked(plant_idx):
		return false
	var unlock_level: int = PlantData.TYPES[plant_idx].get("unlock_level", 1)
	return is_level_completed(unlock_level - 2)

func claim_plant(plant_idx: int) -> void:
	if not is_plant_claimable(plant_idx):
		return
	claimed_plants.append(plant_idx)
	save_progress()

# --- Skrzynie ---
# Numery poziomow, przed ktorymi stoja skrzynie: w co drugiej przerwie miedzy
# roslinami (zaczynajac od tej przed pierwsza), w polowie drogi.
func chest_levels() -> Array:
	var stops := [LEVEL_COUNT]
	for pt in PlantData.TYPES:
		if not stops.has(pt.get("unlock_level", 1)):
			stops.append(pt.get("unlock_level", 1))
	stops.sort()
	var result := []
	for i in range(0, stops.size() - 1, 2):
		result.append(roundi((stops[i] + stops[i + 1]) / 2.0))
	return result

# Skrzynia nie blokuje sciezki: mozna ja otworzyc w dowolnej chwili po
# ukonczeniu poziomu przed nia.
func is_chest_claimable(chest_level: int) -> bool:
	return is_level_completed(chest_level - 2) and not opened_chests.has(chest_level)

# Losuje i od razu zapisuje nagrode. Zwraca {"rubies", "coins"}.
func open_chest(chest_level: int) -> Dictionary:
	if not is_chest_claimable(chest_level):
		return {}
	var reward := {"rubies": _weighted_pick(CHEST_RUBY_WEIGHTS), "coins": _weighted_pick(CHEST_COIN_WEIGHTS)}
	opened_chests.append(chest_level)
	rubies += reward["rubies"]
	plant_coins += reward["coins"]
	save_progress()
	return reward

func _weighted_pick(weights: Dictionary) -> int:
	var total := 0
	for weight in weights.values():
		total += weight
	var roll := randi_range(1, total)
	for value in weights.keys():
		roll -= weights[value]
		if roll <= 0:
			return value
	return weights.keys()[0]

func award_team_win() -> void:
	rubies += TEAM_WIN_RUBIES
	plant_coins += TEAM_WIN_COINS
	save_progress()

# --- Limit nawozow ---
# Cena kolejnego zwiekszenia limitu; -1, gdy limit jest juz najwiekszy.
func next_fertilizer_limit_price() -> int:
	var bought := fertilizer_limit - FERTILIZER_START_LIMIT
	return FERTILIZER_LIMIT_PRICES[bought] if bought < FERTILIZER_LIMIT_PRICES.size() else -1

func buy_fertilizer_limit() -> bool:
	var price := next_fertilizer_limit_price()
	if price < 0 or rubies < price:
		return false
	rubies -= price
	fertilizer_limit += 1
	save_progress()
	return true

func is_icon_unlocked(icon_idx: int) -> bool:
	return PlantData.TYPES[icon_idx].get("unlock_level", 1) <= 1 or unlocked_icons.has(icon_idx)

# Ile krokow kosztuje ikonka - im pozniejsza roslina, tym wiecej.
func icon_steps_required(plant_idx: int) -> int:
	var unlock_level: int = PlantData.TYPES[plant_idx].get("unlock_level", 1)
	if unlock_level <= 11:
		return 2
	return 3 if unlock_level <= 34 else 5

func icon_steps_done(plant_idx: int) -> int:
	return icon_unlock_steps.get(str(plant_idx), 0)

# Zalicza krok; ostatni wymagany odblokowuje ikonke. Ikonki rosliny, ktorej
# gracz jeszcze nie ma, nie da sie odblokowac.
func record_icon_step(plant_idx: int) -> void:
	if not is_plant_unlocked(plant_idx) or is_icon_unlocked(plant_idx):
		return
	var done := icon_steps_done(plant_idx) + 1
	if done >= icon_steps_required(plant_idx):
		unlocked_icons.append(plant_idx)
		icon_unlock_steps.erase(str(plant_idx))
	else:
		icon_unlock_steps[str(plant_idx)] = done
	save_progress()

# Poziom gry zespolowej: najdalszy otwarty poziom zapraszajacego (bez trybu
# nieskonczonego).
func team_level_index() -> int:
	var best := 0
	for i in range(LevelData.LEVELS.size()):
		if is_level_unlocked(i) and not is_endless_level(i):
			best = i
	return best

func unlocked_plant_indices() -> Array:
	var result := []
	for i in range(PlantData.TYPES.size()):
		if is_plant_unlocked(i):
			result.append(i)
	return result

func is_endless_level(i: int) -> bool:
	if i < 0 or i >= LevelData.LEVELS.size():
		return false
	return LevelData.LEVELS[i].get("endless", false)

# Zwraca true, jesli to nowy rekord (i od razu go zapisuje).
func submit_endless_score(kills: int) -> bool:
	if kills <= endless_best:
		return false
	endless_best = kills
	save_progress()
	return true

func complete_level(i: int) -> void:
	if i < 0 or i >= completed_levels.size():
		return
	completed_levels[i] = true
	save_progress()

# Rubin za wygrany poziom - tylko za pierwszym razem. Zwraca true, jesli dany.
func award_level_ruby(i: int) -> bool:
	if i < 0 or i >= ruby_levels.size() or ruby_levels[i]:
		return false
	ruby_levels[i] = true
	rubies += 1
	save_progress()
	return true

# Rubin za tryb nieskonczony - jeden raz, po przekroczeniu ENDLESS_RUBY_KILLS.
func try_award_endless_ruby(kills: int) -> bool:
	if endless_ruby_awarded or kills < ENDLESS_RUBY_KILLS:
		return false
	endless_ruby_awarded = true
	rubies += 1
	save_progress()
	return true

# Zmiana nazwy/ikony wybranego konta. Zwraca false, gdy nazwa jest zajeta
# przez inne konto (wtedy nic sie nie zmienia).
func set_player(new_name: String, icon_idx: int) -> bool:
	if is_profile_name_taken(new_name, current_profile_id):
		return false
	player_name = _clean_name(new_name)
	if is_icon_unlocked(icon_idx):
		player_icon = icon_idx
	for p in profiles:
		if p["id"] == current_profile_id:
			p["name"] = player_name
			p["icon"] = player_icon
	save_profiles()
	return true

func get_loadout(level_i: int) -> Array:
	var raw = loadouts.get(str(level_i), [])
	if not (raw is Array):
		return []
	return raw.duplicate()

func set_loadout(level_i: int, plant_indices: Array) -> void:
	loadouts[str(level_i)] = plant_indices.duplicate()
	save_progress()

# Bez wybranego konta (np. scena gry uruchomiona wprost z edytora) nic nie
# zapisujemy.
func save_progress() -> void:
	if current_profile_id == "":
		return
	var data := {
		"version": SAVE_VERSION,
		"completed_levels": completed_levels,
		"loadouts": loadouts,
		"endless_best": endless_best,
		"rubies": rubies,
		"ruby_levels": ruby_levels,
		"endless_ruby_awarded": endless_ruby_awarded,
		"claimed_plants": claimed_plants,
		"plant_coins": plant_coins,
		"opened_chests": opened_chests,
		"fertilizer_limit": fertilizer_limit,
		"plant_upgrades": plant_upgrades,
		"ad_offer_day": ad_offer_day,
		"event_help_prepaid": event_help_prepaid,
		"event_swap_credits": event_swap_credits,
		"shared_gift_credits": shared_gift_credits,
		"saplings": saplings,
		"garden_plots": garden_plots,
		"next_bee_time": next_bee_time,
		"event_index": event_index,
		"event_started": event_started,
		"event_completed_stages": event_completed_stages,
		"event_stars": event_stars,
		"event_hunt_coins": event_hunt_coins,
		"event_hunt_thresholds": event_hunt_thresholds,
		"shared_choice": shared_choice,
		"shared_my_harvests": shared_my_harvests,
		"shared_friend_harvests": shared_friend_harvests,
		"shared_goal_paid": shared_goal_paid,
		"shared_gift_day": shared_gift_day,
		"event_saved_progress": event_saved_progress,
		"unlocked_icons": unlocked_icons,
		"icon_unlock_steps": icon_unlock_steps,
	}
	var file := FileAccess.open(_save_path(), FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()

func _save_path() -> String:
	return PROFILE_SAVE_PATH % current_profile_id

func load_progress() -> void:
	if not FileAccess.file_exists(_save_path()):
		return
	var file := FileAccess.open(_save_path(), FileAccess.READ)
	if not file:
		return
	var text := file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(text)
	if not (parsed is Dictionary):
		return

	if not parsed.has("version"):
		_migrate_old_save(parsed)
		_migrate_rubies_to_v3()
		_double_levels_to_v4()
		_claim_passed_plants()
		save_progress()
		return

	var loaded_completed = parsed.get("completed_levels", [])
	if loaded_completed is Array:
		for i in range(min(loaded_completed.size(), completed_levels.size())):
			completed_levels[i] = bool(loaded_completed[i])

	var loaded_best = parsed.get("endless_best", 0)
	if typeof(loaded_best) == TYPE_FLOAT or typeof(loaded_best) == TYPE_INT:
		endless_best = max(0, int(loaded_best))

	var version := int(parsed.get("version", 0))
	if version < 3:
		_migrate_rubies_to_v3()
	else:
		_load_v3_fields(parsed)
	if version < 4:
		_double_levels_to_v4()
	if version < 3:
		_claim_passed_plants()

	# Talie wczytujemy na koncu - _sanitize_loadout sprawdza odblokowanie
	# roslin, wiec claimed_plants musi juz byc wczytane.
	var loaded_loadouts = parsed.get("loadouts", {})
	if loaded_loadouts is Dictionary:
		for key in loaded_loadouts.keys():
			var raw = loaded_loadouts[key]
			if not (raw is Array):
				continue
			for new_key in _migrated_loadout_keys(str(key), version):
				loadouts[new_key] = _sanitize_loadout(raw)

	if version < SAVE_VERSION:
		save_progress()

func _loaded_int(parsed: Dictionary, key: String) -> int:
	var value = parsed.get(key, 0)
	return max(0, int(value)) if typeof(value) == TYPE_FLOAT or typeof(value) == TYPE_INT else 0

func _load_v3_fields(parsed: Dictionary) -> void:
	var loaded_rubies = parsed.get("rubies", 0)
	if typeof(loaded_rubies) == TYPE_FLOAT or typeof(loaded_rubies) == TYPE_INT:
		rubies = max(0, int(loaded_rubies))

	var loaded_ruby_levels = parsed.get("ruby_levels", [])
	if loaded_ruby_levels is Array:
		for i in range(min(loaded_ruby_levels.size(), ruby_levels.size())):
			ruby_levels[i] = bool(loaded_ruby_levels[i])

	endless_ruby_awarded = bool(parsed.get("endless_ruby_awarded", false))

	var loaded_coins = parsed.get("plant_coins", 0)
	if typeof(loaded_coins) == TYPE_FLOAT or typeof(loaded_coins) == TYPE_INT:
		plant_coins = max(0, int(loaded_coins))

	var loaded_limit = parsed.get("fertilizer_limit", FERTILIZER_START_LIMIT)
	if typeof(loaded_limit) == TYPE_FLOAT or typeof(loaded_limit) == TYPE_INT:
		fertilizer_limit = clampi(int(loaded_limit), FERTILIZER_START_LIMIT, FERTILIZER_START_LIMIT + FERTILIZER_LIMIT_PRICES.size())

	saplings = _loaded_int(parsed, "saplings")
	next_bee_time = _loaded_int(parsed, "next_bee_time")
	event_index = _loaded_int(parsed, "event_index")
	event_started = _loaded_int(parsed, "event_started")
	event_hunt_coins = _loaded_int(parsed, "event_hunt_coins")
	event_hunt_thresholds = _loaded_int(parsed, "event_hunt_thresholds")
	shared_my_harvests = _loaded_int(parsed, "shared_my_harvests")
	shared_friend_harvests = _loaded_int(parsed, "shared_friend_harvests")
	shared_gift_day = _loaded_int(parsed, "shared_gift_day")
	shared_goal_paid = bool(parsed.get("shared_goal_paid", false))
	shared_choice = str(parsed.get("shared_choice", ""))
	ad_offer_day = _loaded_int(parsed, "ad_offer_day")
	event_help_prepaid = bool(parsed.get("event_help_prepaid", false))
	event_swap_credits = _loaded_int(parsed, "event_swap_credits")
	shared_gift_credits = _loaded_int(parsed, "shared_gift_credits")
	var loaded_upgrades = parsed.get("plant_upgrades", {})
	if loaded_upgrades is Dictionary:
		for key in loaded_upgrades.keys():
			var level = loaded_upgrades[key]
			if typeof(level) == TYPE_FLOAT or typeof(level) == TYPE_INT:
				plant_upgrades[str(key)] = clampi(int(level), 0, PLANT_UPGRADE_MAX_LEVEL)
	var loaded_saved = parsed.get("event_saved_progress", {})
	if loaded_saved is Dictionary:
		for key in loaded_saved.keys():
			if loaded_saved[key] is Dictionary:
				event_saved_progress[str(key)] = loaded_saved[key]
	var loaded_stars = parsed.get("event_stars", {})
	if loaded_stars is Dictionary:
		for key in loaded_stars.keys():
			if typeof(loaded_stars[key]) == TYPE_FLOAT or typeof(loaded_stars[key]) == TYPE_INT:
				event_stars[str(key)] = int(loaded_stars[key])
	var loaded_stages = parsed.get("event_completed_stages", [])
	if loaded_stages is Array:
		for v in loaded_stages:
			if typeof(v) == TYPE_FLOAT or typeof(v) == TYPE_INT:
				event_completed_stages.append(int(v))
	var loaded_plots = parsed.get("garden_plots", [])
	if loaded_plots is Array:
		for i in range(min(loaded_plots.size(), GARDEN_PLOTS)):
			var plot = loaded_plots[i]
			if plot is Dictionary and [PLOT_EMPTY, PLOT_SAPLING, PLOT_GROWING].has(plot.get("state")):
				garden_plots[i] = {"state": plot["state"], "end": int(plot.get("end", 0))}

	var loaded_chests = parsed.get("opened_chests", [])
	if loaded_chests is Array:
		for v in loaded_chests:
			if (typeof(v) == TYPE_FLOAT or typeof(v) == TYPE_INT) and not opened_chests.has(int(v)):
				opened_chests.append(int(v))

	var loaded_claimed = parsed.get("claimed_plants", [])
	if loaded_claimed is Array:
		for v in loaded_claimed:
			if typeof(v) != TYPE_FLOAT and typeof(v) != TYPE_INT:
				continue
			var idx := int(v)
			if idx >= 0 and idx < PlantData.TYPES.size() and not claimed_plants.has(idx):
				claimed_plants.append(idx)

	var loaded_icons = parsed.get("unlocked_icons", [])
	if loaded_icons is Array:
		for v in loaded_icons:
			if typeof(v) != TYPE_FLOAT and typeof(v) != TYPE_INT:
				continue
			var idx := int(v)
			if idx >= 0 and idx < PlantData.TYPES.size() and not unlocked_icons.has(idx):
				unlocked_icons.append(idx)

	var loaded_steps = parsed.get("icon_unlock_steps", {})
	if loaded_steps is Dictionary:
		for key in loaded_steps.keys():
			var count = loaded_steps[key]
			if typeof(count) == TYPE_FLOAT or typeof(count) == TYPE_INT:
				icon_unlock_steps[str(key)] = max(0, int(count))

# Pod jakimi kluczami talia ze starego zapisu trafia do obecnego. Tryb
# nieskonczony przesuwa sie na koniec sciezki.
func _migrated_loadout_keys(key: String, version: int) -> Array:
	if version >= SAVE_VERSION or not key.is_valid_int():
		return [key]
	var level := key.to_int()
	if version < 4:
		if level == OLD_LEVEL_COUNT:
			return [str(LEVEL_COUNT)]
		return [str(level * 2), str(level * 2 + 1)]
	return [str(LEVEL_COUNT)] if level == V4_ENDLESS_INDEX else [key]

# Zapis sprzed wersji 4 mial 28 poziomow, a kazdy z nich dal dwa nowe: postep
# przechodzi na oba, bez nowych rubinow za te, ktore gracz juz dostal.
func _double_levels_to_v4() -> void:
	for i in range(OLD_LEVEL_COUNT - 1, -1, -1):
		completed_levels[i * 2 + 1] = completed_levels[i]
		completed_levels[i * 2] = completed_levels[i]
		ruby_levels[i * 2 + 1] = ruby_levels[i]
		ruby_levels[i * 2] = ruby_levels[i]

# Zapis sprzed wersji 3 nie zna odbierania roslin: rosliny, przed ktorymi poziom
# jest ukonczony, uznajemy za odebrane.
func _claim_passed_plants() -> void:
	for p_idx in range(PlantData.TYPES.size()):
		var unlock_level: int = PlantData.TYPES[p_idx].get("unlock_level", 1)
		if unlock_level > 1 and is_level_completed(unlock_level - 2) and not claimed_plants.has(p_idx):
			claimed_plants.append(p_idx)

# Zapis sprzed wersji 3 nie zna rubinow: za kazdy ukonczony poziom (i rekord
# trybu nieskonczonego) dajemy rubin, ktory by sie nalezal.
func _migrate_rubies_to_v3() -> void:
	for i in range(completed_levels.size()):
		if completed_levels[i] and not ruby_levels[i]:
			ruby_levels[i] = true
			rubies += 1
	if endless_best >= ENDLESS_RUBY_KILLS and not endless_ruby_awarded:
		endless_ruby_awarded = true
		rubies += 1

# Stary format zapisu (sprzed rundy A): {"unlocked_levels": [bool, ...5 pozycji]}.
# unlocked_levels[i + 1] mowilo, ze poziom i (od 0) jest juz odblokowany - co
# odpowiada temu, ze poziom i - 1 zostal ukonczony.
func _migrate_old_save(parsed: Dictionary) -> void:
	if not parsed.has("unlocked_levels"):
		return
	var old = parsed["unlocked_levels"]
	if not (old is Array):
		return
	for i in range(4):
		if i + 1 < old.size():
			completed_levels[i] = bool(old[i + 1])

func _sanitize_loadout(raw: Array) -> Array:
	var result := []
	for v in raw:
		if typeof(v) != TYPE_FLOAT and typeof(v) != TYPE_INT:
			continue
		var idx := int(v)
		if idx < 0 or idx >= PlantData.TYPES.size():
			continue
		if not is_plant_unlocked(idx):
			continue
		if result.has(idx):
			continue
		result.append(idx)
		if result.size() >= MAX_LOADOUT:
			break
	return result
