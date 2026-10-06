extends Node

# Konta graczy sa lokalne (na tym urzadzeniu, bez hasla): lista kont w
# PROFILES_PATH, a postep kazdego konta w osobnym pliku save_<id>.json.
# Zapis sprzed kont (LEGACY_SAVE_PATH) staje sie pierwszym kontem.
const PROFILES_PATH := "user://profiles.json"
const PROFILE_SAVE_PATH := "user://save_%s.json"
const LEGACY_SAVE_PATH := "user://savegame.json"
const MAX_PROFILES := 6
const SAVE_VERSION := 3
const LEVEL_COUNT := 28
const MAX_LOADOUT := 6

# Tryb nieskonczony daje rubin (jeden raz), gdy gracz pokona w jednej grze
# co najmniej tylu wrogow ("umowiona ilosc punktow" z notatek 2026-10-06).
const ENDLESS_RUBY_KILLS := 50
const DEFAULT_PLAYER_NAME := "Gracz"
const PLAYER_NAME_MAX_LENGTH := 14

var current_level_index := 0

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

# Rosliny, w ktorych kolko na sciezce gracz juz "wszedl" (indeksy w PlantData.TYPES).
# Rosliny z unlock_level 1 sa dostepne od startu i nie trzeba ich odbierac.
var claimed_plants: Array = []

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
	claimed_plants = []
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
			return

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
	if is_plant_unlocked(icon_idx):
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
		_migrate_to_v3()
		save_progress()
		return

	var loaded_completed = parsed.get("completed_levels", [])
	if loaded_completed is Array:
		for i in range(min(loaded_completed.size(), completed_levels.size())):
			completed_levels[i] = bool(loaded_completed[i])

	var loaded_best = parsed.get("endless_best", 0)
	if typeof(loaded_best) == TYPE_FLOAT or typeof(loaded_best) == TYPE_INT:
		endless_best = max(0, int(loaded_best))

	if int(parsed.get("version", 0)) < 3:
		_migrate_to_v3()
	else:
		_load_v3_fields(parsed)

	# Talie wczytujemy na koncu - _sanitize_loadout sprawdza odblokowanie
	# roslin, wiec claimed_plants musi juz byc wczytane.
	var loaded_loadouts = parsed.get("loadouts", {})
	if loaded_loadouts is Dictionary:
		for key in loaded_loadouts.keys():
			var raw = loaded_loadouts[key]
			if raw is Array:
				loadouts[str(key)] = _sanitize_loadout(raw)

	if int(parsed.get("version", 0)) < 3:
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

	var loaded_claimed = parsed.get("claimed_plants", [])
	if loaded_claimed is Array:
		for v in loaded_claimed:
			if typeof(v) != TYPE_FLOAT and typeof(v) != TYPE_INT:
				continue
			var idx := int(v)
			if idx >= 0 and idx < PlantData.TYPES.size() and not claimed_plants.has(idx):
				claimed_plants.append(idx)

# Zapis sprzed wersji 3 nie zna rubinow ani odbierania roslin: rosliny, ktore
# wg starej zasady byly juz odblokowane (poziom przed nimi ukonczony), uznajemy
# za odebrane, a za kazdy ukonczony poziom (i rekord trybu nieskonczonego)
# dajemy rubin, ktory by sie nalezal.
func _migrate_to_v3() -> void:
	for p_idx in range(PlantData.TYPES.size()):
		var unlock_level: int = PlantData.TYPES[p_idx].get("unlock_level", 1)
		if unlock_level > 1 and is_level_completed(unlock_level - 2) and not claimed_plants.has(p_idx):
			claimed_plants.append(p_idx)
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
