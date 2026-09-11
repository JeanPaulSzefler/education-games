extends Control

const LEVEL_NAMES := [
	"Poziom 1 - Podworko", "Poziom 2 - Park", "Poziom 3 - Wysypisko",
	"Poziom 4 - Sortownia Odpadow", "Poziom 5 - Skladowisko",
]

func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.15, 0.25, 0.15)
	bg.position = Vector2(0, 0)
	bg.size = Vector2(720, 1280)
	add_child(bg)

	var title := Label.new()
	title.text = "Junk vs Plants"
	title.position = Vector2(40, 60)
	title.add_theme_font_size_override("font_size", 48)
	add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Wybierz poziom"
	subtitle.position = Vector2(40, 130)
	subtitle.add_theme_font_size_override("font_size", 28)
	add_child(subtitle)

	for i in range(GameState.LEVEL_COUNT):
		var unlocked: bool = GameState.unlocked_levels[i]
		var btn := Button.new()
		btn.text = LEVEL_NAMES[i] if unlocked else "%s (zablokowany)" % LEVEL_NAMES[i]
		btn.position = Vector2(40, 220 + i * 100)
		btn.size = Vector2(640, 80)
		btn.disabled = not unlocked
		btn.pressed.connect(_on_level_pressed.bind(i))
		add_child(btn)

	var path_btn := Button.new()
	path_btn.text = "Sciezka sukcesow (rosliny)"
	path_btn.position = Vector2(40, 220 + GameState.LEVEL_COUNT * 100 + 40)
	path_btn.size = Vector2(640, 80)
	path_btn.pressed.connect(_on_progress_path_pressed)
	add_child(path_btn)

func _on_level_pressed(index: int) -> void:
	GameState.current_level_index = index
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _on_progress_path_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ProgressPath.tscn")
