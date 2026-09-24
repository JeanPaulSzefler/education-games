extends Node

const SAVE_PATH := "user://savegame.json"
const SAVE_VERSION := 2
const LEVEL_COUNT := 17
const MAX_LOADOUT := 6

var current_level_index := 0

# Talia na biezaca gre - ustawiana przez ekran wyboru talii (PlantSelect),
# odczytywana przez main.gd przy budowie paska roslin.
var current_loadout: Array = []

var completed_levels: Array = []

# Talia zapamietana per poziom: klucz to String(indeks poziomu od 0), wartosc
# to Array indeksow w PlantData.TYPES. Klucze trzymamy jako String, bo tak
# i tak wychodza z JSON.
var loadouts: Dictionary = {}

func _ready() -> void:
	completed_levels = []
	for i in range(LEVEL_COUNT):
		completed_levels.append(false)
	load_progress()

func is_level_unlocked(i: int) -> bool:
	if i <= 0:
		return true
	if i - 1 >= completed_levels.size():
		return false
	return completed_levels[i - 1]

func is_level_completed(i: int) -> bool:
	if i < 0 or i >= completed_levels.size():
		return false
	return completed_levels[i]

func is_plant_unlocked(plant_idx: int) -> bool:
	if plant_idx < 0 or plant_idx >= PlantData.TYPES.size():
		return false
	var unlock_level: int = PlantData.TYPES[plant_idx].get("unlock_level", 1)
	return is_level_unlocked(unlock_level - 1)

func unlocked_plant_indices() -> Array:
	var result := []
	for i in range(PlantData.TYPES.size()):
		if is_plant_unlocked(i):
			result.append(i)
	return result

func complete_level(i: int) -> void:
	if i < 0 or i >= completed_levels.size():
		return
	completed_levels[i] = true
	save_progress()

func get_loadout(level_i: int) -> Array:
	var raw = loadouts.get(str(level_i), [])
	if not (raw is Array):
		return []
	return raw.duplicate()

func set_loadout(level_i: int, plant_indices: Array) -> void:
	loadouts[str(level_i)] = plant_indices.duplicate()
	save_progress()

func save_progress() -> void:
	var data := {
		"version": SAVE_VERSION,
		"completed_levels": completed_levels,
		"loadouts": loadouts,
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()

func load_progress() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return
	var text := file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(text)
	if not (parsed is Dictionary):
		return

	if not parsed.has("version"):
		_migrate_old_save(parsed)
		save_progress()
		return

	var loaded_completed = parsed.get("completed_levels", [])
	if loaded_completed is Array:
		for i in range(min(loaded_completed.size(), completed_levels.size())):
			completed_levels[i] = bool(loaded_completed[i])

	var loaded_loadouts = parsed.get("loadouts", {})
	if loaded_loadouts is Dictionary:
		for key in loaded_loadouts.keys():
			var raw = loaded_loadouts[key]
			if raw is Array:
				loadouts[str(key)] = _sanitize_loadout(raw)

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
