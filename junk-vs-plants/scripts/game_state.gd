extends Node

# Konta graczy sa lokalne (na tym urzadzeniu, bez hasla): lista kont w
# PROFILES_PATH, a postep kazdego konta w osobnym pliku save_<id>.json.
# Zapis sprzed kont (LEGACY_SAVE_PATH) staje sie pierwszym kontem.
const PROFILES_PATH := "user://profiles.json"
const PROFILE_SAVE_PATH := "user://save_%s.json"
const LEGACY_SAVE_PATH := "user://savegame.json"
const MAX_PROFILES := 6
const SAVE_VERSION := 4
const LEVEL_COUNT := 56
const MAX_LOADOUT := 6
# Poziomy z zapisow sprzed wersji 4 (kazdy dal potem dwa nowe poziomy).
const OLD_LEVEL_COUNT := 28

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

# Tryb nieskonczony daje rubin (jeden raz), gdy gracz pokona w jednej grze
# co najmniej tylu wrogow ("umowiona ilosc punktow" z notatek 2026-10-06).
const ENDLESS_RUBY_KILLS := 50
const DEFAULT_PLAYER_NAME := "Gracz"
const PLAYER_NAME_MAX_LENGTH := 14

var current_level_index := 0
# Plansza gry zespolowej (pusta poza gra zespolowa) - patrz current_level().
var team_level := {}

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
		file.store_string(JSON.stringify({"next_id": next_profile_id, "profiles": profiles}))
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
			return

func current_level() -> Dictionary:
	return team_level if not team_level.is_empty() else LevelData.LEVELS[current_level_index]

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
# Numery poziomow, przed ktorymi stoja skrzynie: po jednej miedzy kolejnymi
# roslinami (i przed pierwsza), w polowie drogi.
func chest_levels() -> Array:
	var stops := [LEVEL_COUNT]
	for pt in PlantData.TYPES:
		if not stops.has(pt.get("unlock_level", 1)):
			stops.append(pt.get("unlock_level", 1))
	stops.sort()
	var result := []
	for i in range(stops.size() - 1):
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
			if version < 4 and str(key).is_valid_int():
				var old_level := str(key).to_int()
				loadouts[str(old_level * 2)] = _sanitize_loadout(raw)
				loadouts[str(old_level * 2 + 1)] = _sanitize_loadout(raw)
			else:
				loadouts[str(key)] = _sanitize_loadout(raw)

	if version < 4:
		save_progress()

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
