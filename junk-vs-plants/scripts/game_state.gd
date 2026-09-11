extends Node

const SAVE_PATH := "user://savegame.json"
const LEVEL_COUNT := 5

var current_level_index := 0
var unlocked_levels := [true, false, false, false, false]

# Rosliny juz zaimplementowane w grze - wszystkie dostepne od poczatku.
# Kolejne (locked) sloty na sciezce sukcesow beda dodawane w przyszlych aktualizacjach.
const LOCKED_PLACEHOLDER_COUNT := 4

func _ready() -> void:
	load_progress()

func complete_level(index: int) -> void:
	if index + 1 < unlocked_levels.size():
		unlocked_levels[index + 1] = true
	save_progress()

func save_progress() -> void:
	var data := {"unlocked_levels": unlocked_levels}
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
	if parsed is Dictionary and parsed.has("unlocked_levels"):
		var loaded: Array = parsed["unlocked_levels"]
		for i in range(min(loaded.size(), unlocked_levels.size())):
			unlocked_levels[i] = loaded[i]
