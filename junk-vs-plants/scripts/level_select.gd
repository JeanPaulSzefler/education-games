extends Control

const VIEWPORT_WIDTH := 1280
const VIEWPORT_HEIGHT := 720
const COLS_PER_ROW := 3
const BTN_SIZE := Vector2(380, 90)
const BTN_GAP := Vector2(20, 20)
const GRID_START := Vector2(40, 130)

const LEVEL_NAMES := [
	"Poziom 1 - Podworko", "Poziom 2 - Park", "Poziom 3 - Wysypisko",
	"Poziom 4 - Sortownia Odpadow", "Poziom 5 - Skladowisko",
]

func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.15, 0.25, 0.15)
	bg.position = Vector2(0, 0)
	bg.size = Vector2(VIEWPORT_WIDTH, VIEWPORT_HEIGHT)
	add_child(bg)

	var title := Label.new()
	title.text = "Junk vs Plants"
	title.position = Vector2(40, 20)
	title.add_theme_font_size_override("font_size", 40)
	add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Wybierz poziom"
	subtitle.position = Vector2(40, 72)
	subtitle.add_theme_font_size_override("font_size", 22)
	add_child(subtitle)

	for i in range(GameState.LEVEL_COUNT):
		var unlocked: bool = GameState.unlocked_levels[i]
		var col := i % COLS_PER_ROW
		var row := int(i / float(COLS_PER_ROW))
		var btn := Button.new()
		btn.text = LEVEL_NAMES[i] if unlocked else "%s (zablokowany)" % LEVEL_NAMES[i]
		btn.position = GRID_START + Vector2(col * (BTN_SIZE.x + BTN_GAP.x), row * (BTN_SIZE.y + BTN_GAP.y))
		btn.size = BTN_SIZE
		btn.disabled = not unlocked
		btn.pressed.connect(_on_level_pressed.bind(i))
		add_child(btn)

	var rows_used := ceili(GameState.LEVEL_COUNT / float(COLS_PER_ROW))
	var path_btn_size := Vector2(400, 70)
	var path_btn := Button.new()
	path_btn.text = "Sciezka sukcesow (rosliny)"
	path_btn.position = Vector2(
		(VIEWPORT_WIDTH - path_btn_size.x) / 2,
		GRID_START.y + rows_used * (BTN_SIZE.y + BTN_GAP.y) + 10,
	)
	path_btn.size = path_btn_size
	path_btn.pressed.connect(_on_progress_path_pressed)
	add_child(path_btn)

func _on_level_pressed(index: int) -> void:
	GameState.current_level_index = index
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _on_progress_path_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ProgressPath.tscn")
