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
# Ruchy do Roslinnych trojek: najczesciej skrzynia nie daje zadnego.
const CHEST_MOVE_WEIGHTS := {0: 60, 1: 30, 2: 10}

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

# Roslinne trojki (wydarzenie stale): plansza COLS x ROWS ze wszystkimi roslinami,
# a 8 punktow przy roslinie zamienia sie w jedno jej ulepszenie.
const MATCH_COLS := 8
const MATCH_ROWS := 6
const MATCH_POINTS_PER_UPGRADE := 8
# Ile rodzajow roslin ma miec mozliwy ruch: na nowej planszy i po dopelnieniu.
const MATCH_BOARD_MOVABLE := 10
const MATCH_REFILL_MOVABLE := 8

# Siodme miejsce w talii na jedna gre na sciezce, wypozyczane za rubiny.
const RENT_SLOT_RUBIES := 3
# Kosiarka (jak w Plants vs Zombies): kupuje sie ja w trakcie poziomu, osobno dla
# kazdego rzedu, i dziala tylko do konca tej gry.
const MOWER_RUBIES := 5

# Kod testowy pozwala raz zmienic wydarzenie. W kodzie gry jest tylko jego skrot.
const TEST_CODE_SHA256 := "e0277cd898e021d443fe6817322b8f98623cb9a0a366e5daa39e03c47bf79959"
const TEST_CODE_MAX_FAILURES := 3
const TEST_CODE_LOCK_SECONDS := 10 * 60

# Ogrod: 8 pol, roslinka rosnie 15 godzin i daje 50 roslimonet i ruch do
# Roslinnych trojek. Przyspieszenie kosztuje 15 rubinow, a pszczolka zabiera
# 3 godziny i wraca po 15-30 minutach.
const GARDEN_PLOTS := 8
const GARDEN_GROW_SECONDS := 15 * 3600
const GARDEN_HARVEST_COINS := 50
const GARDEN_HARVEST_MOVES := 1
# Roslinki odblokowane od tego poziomu daja czasem 2 ruchy zamiast jednego.
const GARDEN_BONUS_MIN_LEVEL := 20
const GARDEN_BONUS_CHANCE := 0.35
const GARDEN_DEFAULT_PLANT := 3
const GARDEN_RUSH_RUBIES := 15
const GARDEN_BEE_SECONDS := 3 * 3600
const BEE_RETURN_MIN_SECONDS := 15 * 60
const BEE_RETURN_MAX_SECONDS := 30 * 60
const PLOT_EMPTY := "empty"
const PLOT_SAPLING := "sapling"
const PLOT_GROWING := "growing"
# Dorosla roslinka czeka, az gracz zbierze nagrody.
const PLOT_READY := "ready"

# Tryb nieskonczony (notatki 2026-11-03): pierwsza przegrana daje rubin i ruch,
# a kazda nastepna tylko wtedy, gdy gracz pobije kolejny prog pokonanych wrogow:
# 100, 150, 200... (kazdy prog raz).
const ENDLESS_FIRST_THRESHOLD := 100
const ENDLESS_THRESHOLD_STEP := 50
# Gra z innym graczem daje ruch, najwyzej tyle razy dziennie.
const MP_MOVES_PER_DAY := 3
const DUEL_WIN_COINS := 20
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

# Rubiny: 1 za pierwsze wygranie kazdego poziomu (ruby_levels[i] = juz dany).
# endless_ruby_awarded: nagroda za pierwsza gre w trybie nieskonczonym juz dana;
# endless_steps: ile progow pokonanych wrogow juz nagrodzono.
var rubies := 0
var ruby_levels: Array = []
var endless_ruby_awarded := false
var endless_steps := 0

# Roslimonety: ze skrzyn i z wygranych gier zespolowych.
var plant_coins := 0
# Otwarte skrzynie: numery poziomow, przed ktorymi stoja na sciezce.
var opened_chests: Array = []
var fertilizer_limit := FERTILIZER_START_LIMIT
# Ulepszenia roslin: String(indeks rosliny) -> poziom.
var plant_upgrades: Dictionary = {}
# Dzien (Unix), w ktorym gracz ostatnio wzial rubiny z oferty "za reklame".
var ad_offer_day := 0
# Roslinne trojki: ruchy, punkty przy roslinach (String(indeks) -> 0-7) i
# plansza (indeksy roslin wierszami; pusta = do wylosowania).
var match_moves := 0
var match_points: Dictionary = {}
var match_board: Array = []

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

# Rotacje dodatkow i gier edukacyjnych (AddonData): rodzaj -> {"index", "started",
# "stages", "stars", "replays", "data"}. "data" trzyma stan mini-gier i wydarzen
# meta (plansza Pamieci, karta bingo, zdobyte progi...).
var rotations: Dictionary = {}
# Co teraz gra gracz na planszy: "" (sciezka), "weekly", "addon" albo "edu".
var play_kind := ""
# Album naklejek zostaje miedzy tygodniami albumu: id naklejki -> liczba.
var album: Dictionary = {}
var album_pages_paid: Array = []
var album_frame := false
var duel_reward_day := 0
# Ruchy z gier z innym graczem: dzien (Unix) i ile ich juz dzis dano.
var mp_moves_day := 0
var mp_moves_today := 0
# Jezyk konta ("" = jezyk telefonu) i obejrzane kroki przewodnika (GuideData).
var language := ""
var guide_seen: Array = []

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
	Lang.set_code(last_language if last_language != "" else Lang.device_code())

# Jezyk ostatnio uzytego konta - ekran wyboru kont pokazuje sie w nim, zanim
# ktores konto zostanie wybrane.
var last_language := ""

# --- Jezyk konta ---
func apply_language() -> void:
	Lang.set_code(language if language != "" else Lang.device_code())

func set_language(lang_code: String) -> void:
	language = lang_code
	last_language = lang_code
	apply_language()
	save_progress()
	save_profiles()

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
	endless_steps = 0
	rotations = {}
	play_kind = ""
	album = {}
	album_pages_paid = []
	album_frame = false
	duel_reward_day = 0
	mp_moves_day = 0
	mp_moves_today = 0
	language = ""
	guide_seen = []
	plant_coins = 0
	opened_chests = []
	fertilizer_limit = FERTILIZER_START_LIMIT
	plant_upgrades = {}
	ad_offer_day = 0
	match_moves = 0
	match_points = {}
	match_board = []
	saplings = 0
	garden_plots = []
	for i in range(GARDEN_PLOTS):
		garden_plots.append(empty_plot())
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
	last_language = str(parsed.get("last_language", ""))
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
			"last_language": last_language,
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
	# Nowe konto zaczyna w jezyku, w ktorym gracz ostatnio gral.
	language = last_language
	apply_language()
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
			apply_language()
			refresh_event()
			for kind in [AddonData.KIND_ADDON, AddonData.KIND_EDU]:
				refresh_rotation(kind)
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
	play_kind = "weekly"
	current_level_index = EventData.STAGES[stage]["level_idx"]
	current_loadout = []
	event_level = LevelData.event_level(event, stage, "event_" + event["id"])
	if event.get("forced_deck", false):
		event_forced_plants = _random_forced_deck(stage)
	return true

# Zasady tego, co gracz teraz gra na planszy (wydarzenie tygodnia, dodatek albo
# gra edukacyjna); pusty slownik poza nimi.
func playing_event() -> Dictionary:
	if event_level.is_empty():
		return {}
	if play_kind == "weekly":
		return current_event()
	return rotation_entry(play_kind)

func playing_seconds_left() -> int:
	return event_seconds_left() if play_kind == "weekly" else rotation_seconds_left(play_kind)

# Ekran, na ktory wraca gracz z etapu.
func play_screen() -> String:
	return "res://scenes/Events.tscn" if play_kind == "weekly" else "res://scenes/Rotation.tscn"

# --- Rotacje dodatkow i gier edukacyjnych ---
# Ekran rotacji pokazuje te, ktora wybral gracz na sciezce.
var rotation_view := AddonData.KIND_ADDON

func _rotation(kind: String) -> Dictionary:
	if not rotations.has(kind):
		rotations[kind] = {"index": 0, "started": 0, "stages": [], "stars": {}, "replays": 0, "data": {}}
	return rotations[kind]

# Po uplywie 5 dni przychodzi nastepny wpis, a po ostatnim rotacja wraca do poczatku.
func refresh_rotation(kind: String) -> void:
	var rot := _rotation(kind)
	var changed := false
	var length := AddonData.DURATION_DAYS * 86400
	if rot["started"] > 0 and _now() - rot["started"] >= length:
		var passed := int((_now() - rot["started"]) / length)
		rot["index"] = (rot["index"] + passed) % AddonData.entries(kind).size()
		rot["started"] += passed * length
		_reset_rotation_progress(rot)
		changed = true
	if rot["started"] == 0:
		rot["started"] = _now()
		changed = true
	if changed:
		save_progress()

func _reset_rotation_progress(rot: Dictionary) -> void:
	rot["stages"] = []
	rot["stars"] = {}
	rot["replays"] = 0
	rot["data"] = {}

func rotation_entry(kind: String) -> Dictionary:
	var list: Array = AddonData.entries(kind)
	return list[int(_rotation(kind)["index"]) % list.size()]

func rotation_seconds_left(kind: String) -> int:
	return max(0, AddonData.DURATION_DAYS * 86400 - (_now() - int(_rotation(kind)["started"])))

# Stan mini-gier i wydarzen meta biezacego wpisu (znika razem z nim).
func rotation_data(kind: String) -> Dictionary:
	return _rotation(kind)["data"]

func rotation_stages(kind: String) -> Array:
	return _rotation(kind)["stages"]

func rotation_stars(kind: String, stage: int) -> int:
	return int(_rotation(kind)["stars"].get(str(stage), 0))

func is_rotation_stage_open(kind: String, stage: int) -> bool:
	return stage == 0 or rotation_stages(kind).has(stage - 1)

# Kod testowy: od razu przechodzi na wybrany wpis rotacji, z pelnymi 5 dniami.
func switch_rotation(kind: String, idx: int) -> void:
	var rot := _rotation(kind)
	rot["index"] = idx
	rot["started"] = _now()
	_reset_rotation_progress(rot)
	save_progress()

# Przygotowuje etap dodatku albo gry edukacyjnej na planszy (main.gd). Pomoc
# pobiera roslimonety. Zwraca false, gdy wpis wlasnie sie zmienil albo brak monet.
func start_rotation_game(kind: String, stage: int, with_help := false) -> bool:
	var before := rotation_entry(kind)
	refresh_rotation(kind)
	var entry := rotation_entry(kind)
	if entry["id"] != before["id"]:
		return false
	if with_help and not spend_coins(entry["help"]["cost"]):
		return false
	event_help_active = with_help
	event_stage = stage
	play_kind = kind
	current_level_index = EventData.STAGES[stage]["level_idx"]
	current_loadout = []
	event_level = LevelData.event_level(entry, stage, "addon_" + entry["id"])
	if entry.get("single_plant", false):
		event_forced_plants = _random_single_plant_deck()
	# Zagadka obronna ma gotowa talie, bez ekranu wyboru roslin.
	if entry.get("puzzle", false):
		current_loadout = AddonData.PUZZLES[stage]["deck"].duplicate()
	return true

# Mini-gra z rotacji (bez planszy main.gd): zapamietuje etap i kupiona pomoc.
func start_rotation_minigame(kind: String, stage: int, with_help: bool) -> bool:
	var before := rotation_entry(kind)
	refresh_rotation(kind)
	var entry := rotation_entry(kind)
	if entry["id"] != before["id"]:
		return false
	if with_help and not spend_coins(entry["help"]["cost"]):
		return false
	event_level = {}
	event_help_active = with_help
	event_stage = stage
	play_kind = kind
	return true

# Jedna roslinka: Kaktus i jedna losowa roslina, ktora nie daje wody (bez Pnaczy).
func _random_single_plant_deck() -> Array:
	var pool := []
	for i in range(PlantData.TYPES.size()):
		var role: String = PlantData.TYPES[i]["role"]
		if role != "generator" and role != "vines":
			pool.append(i)
	var deck := [PlantData.cactus_index(), pool.pick_random()]
	deck.sort()
	return deck

# Nagroda za wygrany etap rotacji (takze Budowanie sciezki i Labirynt). Zwraca
# {"saplings", "rubies", "moves", "coins"}.
func complete_rotation_stage(kind: String, stage: int, stars := 0) -> Dictionary:
	var rot := _rotation(kind)
	var reward := {"saplings": 0, "rubies": 0, "moves": 0, "coins": 0}
	var first_win: bool = not rot["stages"].has(stage)
	var best := rotation_stars(kind, stage)
	if stars > 0:
		rot["stars"][str(stage)] = max(best, stars)
	if rotation_entry(kind)["kind"] == "maze":
		# Labirynt: sadzonka za kazda nowa gwiazdke i ruch za ostatni labirynt.
		if first_win:
			rot["stages"].append(stage)
		reward["saplings"] = max(0, stars - best)
		if first_win and stage == EventData.STAGES.size() - 1:
			reward["moves"] = 1
		_give(reward)
		record_bingo("addon_game")
		return reward
	if first_win:
		rot["stages"].append(stage)
		var stage_reward: Dictionary = AddonData.STAGE_REWARDS[stage]
		for key in stage_reward.keys():
			reward[key] += stage_reward[key]
		if stage == EventData.STAGES.size() - 1:
			reward["rubies"] += rotation_entry(kind).get("final_rubies", 0)
	else:
		rot["replays"] += 1
		reward["coins"] = AddonData.REPLAY_COINS
		if rot["replays"] % AddonData.REPLAY_SAPLING_EVERY == 0:
			reward["saplings"] = 1
	_give(reward)
	record_bingo("addon_game")
	return reward

# Dopisuje nagrode do konta i zapisuje.
func _give(reward: Dictionary) -> void:
	saplings += reward.get("saplings", 0)
	rubies += reward.get("rubies", 0)
	match_moves += reward.get("moves", 0)
	plant_coins += reward.get("coins", 0)
	save_progress()

# Prog wyniku w mini-grze (Lapanie kropli, Sortownia): kazdy prog nagradza raz.
# Zwraca liczbe sadzonek za nowe progi.
func claim_score_thresholds(kind: String, thresholds: Array, score: int) -> int:
	var data := rotation_data(kind)
	var reached: int = data.get("thresholds", 0)
	var gained := 0
	while reached < thresholds.size() and score >= thresholds[reached]["score"]:
		gained += thresholds[reached]["saplings"]
		reached += 1
	data["thresholds"] = reached
	data["best"] = max(int(data.get("best", 0)), score)
	_give({"saplings": gained})
	return gained

# --- Quiz: raz dziennie ---
func is_quiz_ready() -> bool:
	return int(rotation_data(AddonData.KIND_EDU).get("quiz_day", -1)) != _today()

func finish_quiz(correct: int) -> Dictionary:
	var data := rotation_data(AddonData.KIND_EDU)
	data["quiz_day"] = _today()
	var reward := {"coins": correct * AddonData.QUIZ_COINS_PER_ANSWER,
		"saplings": 1 if correct >= AddonData.QUIZ_QUESTIONS else 0}
	_give(reward)
	return reward

# --- Album naklejek ---
func is_album_week() -> bool:
	return rotation_entry(AddonData.KIND_ADDON)["kind"] == "album"

# W tygodniu albumu wygrane i zbiory daja losowa naklejke. Zwraca jej id albo "".
func drop_sticker() -> String:
	if not is_album_week():
		return ""
	var sticker: String = AddonData.album_stickers().pick_random()
	album[sticker] = int(album.get(sticker, 0)) + 1
	_pay_album_pages()
	save_progress()
	return sticker

func _pay_album_pages() -> void:
	var stickers := AddonData.album_stickers()
	var pages := int(ceil(stickers.size() / float(AddonData.ALBUM_PAGE_SIZE)))
	for page in range(pages):
		if album_pages_paid.has(page):
			continue
		var full := true
		for k in range(page * AddonData.ALBUM_PAGE_SIZE, min((page + 1) * AddonData.ALBUM_PAGE_SIZE, stickers.size())):
			if int(album.get(stickers[k], 0)) <= 0:
				full = false
				break
		if full:
			album_pages_paid.append(page)
			rubies += AddonData.ALBUM_PAGE_RUBIES
	if album_pages_paid.size() >= pages:
		album_frame = true

# Wymiana ze znajomym: dostajemy naklejke, a jedna nasza powtorka odchodzi.
func trade_sticker(given: String, received: String) -> void:
	if int(album.get(given, 0)) > 1:
		album[given] = int(album[given]) - 1
	album[received] = int(album.get(received, 0)) + 1
	_pay_album_pages()
	save_progress()

func album_duplicates() -> Array:
	var result := []
	for key in album.keys():
		if int(album[key]) > 1:
			result.append(key)
	return result

# --- Bingo ---
func is_bingo_week() -> bool:
	return rotation_entry(AddonData.KIND_ADDON)["kind"] == "bingo"

# Karta: 16 zadan wylosowanych na tydzien (indeksy w AddonData.BINGO_TASKS).
func bingo_card() -> Array:
	var data := rotation_data(AddonData.KIND_ADDON)
	if not data.has("card"):
		var ids := range(AddonData.BINGO_TASKS.size())
		ids.shuffle()
		data["card"] = ids.slice(0, AddonData.BINGO_SIZE * AddonData.BINGO_SIZE)
		data["counts"] = {}
		data["lines"] = []
		data["full_paid"] = false
		save_progress()
	# Po wczytaniu z JSON liczby sa typu float.
	if not data["card"].all(func(v): return v is int):
		data["card"] = data["card"].map(func(v): return int(v))
		data["lines"] = data["lines"].map(func(v): return int(v))
	return data["card"]

func bingo_count(task_idx: int) -> int:
	return int(rotation_data(AddonData.KIND_ADDON).get("counts", {}).get(str(task_idx), 0))

func is_bingo_task_done(task_idx: int) -> bool:
	return bingo_count(task_idx) >= AddonData.BINGO_TASKS[task_idx]["goal"]

# Licznik zadania (np. "plant_corn") idzie w gore tylko w tygodniu bingo.
func record_bingo(task_id: String, amount := 1) -> void:
	if not is_bingo_week() or amount <= 0:
		return
	var card := bingo_card()
	var data := rotation_data(AddonData.KIND_ADDON)
	var changed := false
	for task_idx in card:
		if AddonData.BINGO_TASKS[task_idx]["id"] == task_id and not is_bingo_task_done(task_idx):
			data["counts"][str(task_idx)] = bingo_count(task_idx) + amount
			changed = true
	if changed:
		_pay_bingo_lines()
		save_progress()

# Kazda pelna linia daje na zmiane sadzonke i ruch, a cala karta rubiny.
func _pay_bingo_lines() -> void:
	var card := bingo_card()
	var data := rotation_data(AddonData.KIND_ADDON)
	var n := AddonData.BINGO_SIZE
	var lines := []
	for r in range(n):
		lines.append(range(n).map(func(c): return r * n + c))
	for c in range(n):
		lines.append(range(n).map(func(r): return r * n + c))
	lines.append(range(n).map(func(k): return k * n + k))
	lines.append(range(n).map(func(k): return k * n + (n - 1 - k)))
	for li in range(lines.size()):
		if data["lines"].has(li):
			continue
		if lines[li].all(func(cell): return is_bingo_task_done(card[cell])):
			data["lines"].append(li)
			if data["lines"].size() % 2 == 1:
				saplings += 1
			else:
				match_moves += 1
	if not data["full_paid"] and card.all(func(task_idx): return is_bingo_task_done(task_idx)):
		data["full_paid"] = true
		rubies += AddonData.BINGO_CARD_RUBIES

# Pomoc: zamiana niezrobionego zadania na inne, spoza karty.
func swap_bingo_task(cell: int) -> bool:
	var card := bingo_card()
	if is_bingo_task_done(card[cell]):
		return false
	var spare := range(AddonData.BINGO_TASKS.size()).filter(func(t): return not card.has(t))
	if spare.is_empty() or not spend_coins(rotation_entry(AddonData.KIND_ADDON)["help"]["cost"]):
		return false
	card[cell] = spare.pick_random()
	save_progress()
	return true

# --- Pojedynek (tydzien pojedynkow daje dodatkowa nagrode raz dziennie) ---
func is_duel_week() -> bool:
	return rotation_entry(AddonData.KIND_ADDON)["kind"] == "duel"

# --- Gry z innym graczem: ruch za kazda skonczona gre, najwyzej 3 dziennie ---
func award_multiplayer_game(duel: bool, won: bool) -> Dictionary:
	var reward := {"rubies": 0, "coins": 0, "moves": 0}
	if mp_moves_day != _today():
		mp_moves_day = _today()
		mp_moves_today = 0
	if mp_moves_today < MP_MOVES_PER_DAY:
		mp_moves_today += 1
		reward["moves"] = 1
	if won and not duel:
		reward["rubies"] = TEAM_WIN_RUBIES
		reward["coins"] = TEAM_WIN_COINS
	elif won and duel:
		reward["coins"] = DUEL_WIN_COINS
		if is_duel_week() and duel_reward_day != _today():
			duel_reward_day = _today()
			reward["rubies"] += AddonData.DUEL_WEEK_RUBIES
			reward["coins"] += AddonData.DUEL_WEEK_COINS
	_give(reward)
	return reward

# --- Tryb nieskonczony ---
func endless_next_threshold() -> int:
	return ENDLESS_FIRST_THRESHOLD + endless_steps * ENDLESS_THRESHOLD_STEP

# Koniec gry w trybie nieskonczonym. Zwraca {"rubies", "moves"}.
func finish_endless_game(kills: int) -> Dictionary:
	var reward := {"rubies": 0, "moves": 0}
	if not endless_ruby_awarded:
		endless_ruby_awarded = true
		reward = {"rubies": 1, "moves": 1}
	while kills >= endless_next_threshold():
		endless_steps += 1
		reward["rubies"] += 1
		reward["moves"] += 1
	_give(reward)
	return reward

# --- Przewodnik ---
func is_guide_seen(step_id: String) -> bool:
	return guide_seen.has(step_id)

func mark_guide_seen(step_id: String) -> void:
	if not guide_seen.has(step_id):
		guide_seen.append(step_id)
		save_progress()

# Ile poziomow sciezki gracz ma juz za soba (do odblokowywania funkcji).
func completed_level_count() -> int:
	var count := 0
	for i in range(LEVEL_COUNT):
		if completed_levels[i]:
			count = i + 1
	return count

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
	play_kind = ""

# Wygrany etap: nagroda zalezna od wydarzenia. Zwraca {"saplings", "rubies",
# "moves", "coins"}. stars: gwiazdki z Wyscigu (0 w innych wydarzeniach).
func complete_event_stage(stars := 0) -> Dictionary:
	if play_kind != "weekly":
		return complete_rotation_stage(play_kind, event_stage, stars)
	var event := current_event()
	var first_win: bool = not event_completed_stages.has(event_stage)
	var reward := {"saplings": 0, "rubies": 0, "moves": 0, "coins": 0}
	record_bingo("event_stage")
	if first_win:
		event_completed_stages.append(event_stage)
		# Ruch do Roslinnych trojek za niektore etapy (notatki 2026-11-03).
		reward["moves"] = EventData.STAGES[event_stage].get("moves", 0)
		match_moves += reward["moves"]
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
	if price < 0 or rubies < price:
		return false
	rubies -= price
	plant_upgrades[str(plant_idx)] = plant_upgrade_level(plant_idx) + 1
	record_bingo("upgrade")
	save_progress()
	return true

# --- Roslinne trojki ---
# Punkty za jedna grupe: 3-4 roslinki to 1 punkt, 5-6 to 2, 7-8 to 3 itd.
static func match_group_points(group_size: int) -> int:
	return 1 + int((group_size - 3) / 2.0)

func match_points_of(plant_idx: int) -> int:
	return match_points.get(str(plant_idx), 0)

func use_match_move() -> bool:
	if match_moves <= 0:
		return false
	match_moves -= 1
	record_bingo("match_move")
	save_progress()
	return true

# Dopisuje punkty roslinie; kazde 8 punktow to darmowe ulepszenie. W pelni
# ulepszona roslina nie zbiera juz punktow. Zwraca liczbe nowych ulepszen.
func add_match_points(plant_idx: int, points: int) -> int:
	var total := match_points_of(plant_idx) + points
	var gained := 0
	while total >= MATCH_POINTS_PER_UPGRADE and plant_upgrade_level(plant_idx) < PLANT_UPGRADE_MAX_LEVEL:
		total -= MATCH_POINTS_PER_UPGRADE
		plant_upgrades[str(plant_idx)] = plant_upgrade_level(plant_idx) + 1
		gained += 1
	if plant_upgrade_level(plant_idx) >= PLANT_UPGRADE_MAX_LEVEL:
		total = 0
	match_points[str(plant_idx)] = total
	save_progress()
	return gained

func save_match_board(board: Array) -> void:
	match_board = board.duplicate()
	save_progress()

# --- Siodme miejsce w talii ---
# Placi za jedna gre na sciezce; zwraca false, gdy brakuje rubinow. Talia z 7
# roslinami w current_loadout oznacza, ze miejsce jest oplacone na te gre.
func rent_extra_slot() -> bool:
	if rubies < RENT_SLOT_RUBIES:
		return false
	rubies -= RENT_SLOT_RUBIES
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
func empty_plot() -> Dictionary:
	return {"state": PLOT_EMPTY, "end": 0, "plant": GARDEN_DEFAULT_PLANT, "moves": GARDEN_HARVEST_MOVES}

# Sadzonka wyrasta na losowa z odblokowanych roslin; te z pozniejszych poziomow
# daja czasem 2 ruchy do Roslinnych trojek.
func _roll_plot_plant(i: int) -> void:
	var unlocked := unlocked_plant_indices()
	var p_idx: int = unlocked[randi() % unlocked.size()] if not unlocked.is_empty() else GARDEN_DEFAULT_PLANT
	var moves := GARDEN_HARVEST_MOVES
	if PlantData.TYPES[p_idx].get("unlock_level", 1) >= GARDEN_BONUS_MIN_LEVEL and randf() < GARDEN_BONUS_CHANCE:
		moves = 2
	garden_plots[i]["plant"] = p_idx
	garden_plots[i]["moves"] = moves

func plant_sapling(i: int) -> void:
	if saplings > 0 and garden_plots[i]["state"] == PLOT_EMPTY:
		saplings -= 1
		garden_plots[i]["state"] = PLOT_SAPLING
		_roll_plot_plant(i)
		save_progress()

func water_plot(i: int) -> void:
	if garden_plots[i]["state"] == PLOT_SAPLING:
		garden_plots[i]["state"] = PLOT_GROWING
		garden_plots[i]["end"] = _now() + GARDEN_GROW_SECONDS
		record_bingo("garden_water")
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

# Roslinki, ktore skonczyly rosnac, czekaja na zebranie nagrod. Zwraca numery
# pol, ktore wlasnie staly sie gotowe.
func mark_ready_plots() -> Array:
	var newly_ready := []
	for i in range(garden_plots.size()):
		if garden_plots[i]["state"] == PLOT_GROWING and plot_seconds_left(i) == 0:
			garden_plots[i]["state"] = PLOT_READY
			newly_ready.append(i)
	if not newly_ready.is_empty():
		save_progress()
	return newly_ready

# Zebranie nagrod z doroslej roslinki: roslimonety i ruch, a pole sie zwalnia.
func collect_plot(i: int) -> bool:
	if garden_plots[i]["state"] != PLOT_READY:
		return false
	var moves: int = garden_plots[i].get("moves", GARDEN_HARVEST_MOVES)
	garden_plots[i] = empty_plot()
	plant_coins += GARDEN_HARVEST_COINS
	match_moves += moves
	if is_shared_garden_on():
		shared_my_harvests += 1
	record_bingo("garden_collect")
	drop_sticker()
	save_progress()
	return true

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

# Losuje i od razu zapisuje nagrode. Zwraca {"rubies", "coins", "moves"}.
func open_chest(chest_level: int) -> Dictionary:
	if not is_chest_claimable(chest_level):
		return {}
	var reward := {"rubies": _weighted_pick(CHEST_RUBY_WEIGHTS), "coins": _weighted_pick(CHEST_COIN_WEIGHTS),
		"moves": _weighted_pick(CHEST_MOVE_WEIGHTS)}
	opened_chests.append(chest_level)
	rubies += reward["rubies"]
	plant_coins += reward["coins"]
	match_moves += reward["moves"]
	record_bingo("chest_or_shop")
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

# --- Limit nawozow ---
# Cena kolejnego zwiekszenia limitu; -1, gdy limit jest juz najwiekszy.
func next_fertilizer_limit_price() -> int:
	var bought := fertilizer_limit - FERTILIZER_START_LIMIT
	return FERTILIZER_LIMIT_PRICES[bought] if bought < FERTILIZER_LIMIT_PRICES.size() else -1

func buy_mower() -> bool:
	if rubies < MOWER_RUBIES:
		return false
	rubies -= MOWER_RUBIES
	record_bingo("chest_or_shop")
	save_progress()
	return true

func buy_fertilizer_limit() -> bool:
	var price := next_fertilizer_limit_price()
	if price < 0 or rubies < price:
		return false
	rubies -= price
	fertilizer_limit += 1
	record_bingo("chest_or_shop")
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
# Pierwsze wygranie poziomu z bossem daje tez ruch do Roslinnych trojek.
# Zwraca {"rubies", "moves"} albo pusty slownik przy powtorce.
func award_level_ruby(i: int) -> Dictionary:
	if i < 0 or i >= ruby_levels.size() or ruby_levels[i]:
		return {}
	ruby_levels[i] = true
	var reward := {"rubies": 1, "moves": 0}
	if LevelData.LEVELS[i].get("boss", -1) >= 0:
		reward["moves"] = 1
	_give(reward)
	return reward

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
		"match_moves": match_moves,
		"match_points": match_points,
		"match_board": match_board,
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
		"endless_steps": endless_steps,
		"rotations": rotations,
		"album": album,
		"album_pages_paid": album_pages_paid,
		"album_frame": album_frame,
		"duel_reward_day": duel_reward_day,
		"mp_moves_day": mp_moves_day,
		"mp_moves_today": mp_moves_today,
		"language": language,
		"guide_seen": guide_seen,
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
	match_moves = _loaded_int(parsed, "match_moves")
	var loaded_points = parsed.get("match_points", {})
	if loaded_points is Dictionary:
		for key in loaded_points.keys():
			var points = loaded_points[key]
			if typeof(points) == TYPE_FLOAT or typeof(points) == TYPE_INT:
				match_points[str(key)] = clampi(int(points), 0, MATCH_POINTS_PER_UPGRADE - 1)
	var loaded_board = parsed.get("match_board", [])
	if loaded_board is Array and loaded_board.size() == MATCH_COLS * MATCH_ROWS:
		for v in loaded_board:
			if (typeof(v) != TYPE_FLOAT and typeof(v) != TYPE_INT) or int(v) < 0 or int(v) >= PlantData.TYPES.size():
				match_board = []
				break
			match_board.append(int(v))
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
			if plot is Dictionary and [PLOT_EMPTY, PLOT_SAPLING, PLOT_GROWING, PLOT_READY].has(plot.get("state")):
				var saved_plant := int(plot.get("plant", GARDEN_DEFAULT_PLANT))
				if saved_plant < 0 or saved_plant >= PlantData.TYPES.size():
					saved_plant = GARDEN_DEFAULT_PLANT
				garden_plots[i] = {"state": plot["state"], "end": int(plot.get("end", 0)), "plant": saved_plant, "moves": clampi(int(plot.get("moves", GARDEN_HARVEST_MOVES)), 1, 2)}

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

	endless_steps = _loaded_int(parsed, "endless_steps")
	duel_reward_day = _loaded_int(parsed, "duel_reward_day")
	mp_moves_day = _loaded_int(parsed, "mp_moves_day")
	mp_moves_today = _loaded_int(parsed, "mp_moves_today")
	album_frame = bool(parsed.get("album_frame", false))
	language = str(parsed.get("language", ""))
	var loaded_rotations = parsed.get("rotations", {})
	if loaded_rotations is Dictionary:
		for kind in [AddonData.KIND_ADDON, AddonData.KIND_EDU]:
			var raw = loaded_rotations.get(kind)
			if raw is Dictionary:
				var rot := _rotation(kind)
				rot["index"] = _loaded_int(raw, "index")
				rot["started"] = _loaded_int(raw, "started")
				rot["replays"] = _loaded_int(raw, "replays")
				for stage in raw.get("stages", []):
					rot["stages"].append(int(stage))
				var stars = raw.get("stars", {})
				if stars is Dictionary:
					for key in stars.keys():
						rot["stars"][str(key)] = int(stars[key])
				# Stan mini-gier wraca z JSON z liczbami jako float - kazda gra
				# czyta go przez int(), wiec wystarczy go przepisac.
				if raw.get("data") is Dictionary:
					rot["data"] = raw["data"]
	var loaded_album = parsed.get("album", {})
	if loaded_album is Dictionary:
		for key in loaded_album.keys():
			album[str(key)] = int(loaded_album[key])
	for page in parsed.get("album_pages_paid", []):
		album_pages_paid.append(int(page))
	for step in parsed.get("guide_seen", []):
		guide_seen.append(str(step))

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
	if endless_best >= 50 and not endless_ruby_awarded:
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
