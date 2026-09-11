extends Control

const VIEWPORT_WIDTH := 1280
const VIEWPORT_HEIGHT := 720
const COLS := 6
const CELL := 140

func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.15, 0.25, 0.15)
	bg.position = Vector2(0, 0)
	bg.size = Vector2(VIEWPORT_WIDTH, VIEWPORT_HEIGHT)
	add_child(bg)

	var title := Label.new()
	title.text = "Sciezka sukcesow"
	title.position = Vector2(40, 60)
	title.add_theme_font_size_override("font_size", 40)
	add_child(title)

	var hint := Label.new()
	hint.text = "Odblokowane rosliny i miejsca na przyszle nowosci"
	hint.position = Vector2(40, 120)
	hint.add_theme_font_size_override("font_size", 20)
	add_child(hint)

	var start_x := 40
	var start_y := 160
	var index := 0

	for plant in PlantData.TYPES:
		_add_slot(start_x + (index % COLS) * CELL, start_y + int(index / float(COLS)) * CELL,
			load(plant["texture"]), plant["name"], true)
		index += 1

	for i in range(GameState.LOCKED_PLACEHOLDER_COUNT):
		_add_slot(start_x + (index % COLS) * CELL, start_y + int(index / float(COLS)) * CELL,
			load("res://assets/sprites/ui/locked_slot.png"), "???", false)
		index += 1

	var back_btn := Button.new()
	back_btn.text = "Wroc"
	back_btn.position = Vector2(40, 620)
	back_btn.size = Vector2(200, 60)
	back_btn.pressed.connect(_on_back_pressed)
	add_child(back_btn)

func _add_slot(x: int, y: int, texture: Texture2D, label_text: String, unlocked: bool) -> void:
	var frame := ColorRect.new()
	frame.color = Color(0.3, 0.45, 0.25) if unlocked else Color(0.25, 0.25, 0.25)
	frame.position = Vector2(x, y)
	frame.size = Vector2(CELL - 20, CELL - 20)
	add_child(frame)

	var icon := TextureRect.new()
	icon.texture = texture
	icon.position = Vector2(x + 12, y + 6)
	icon.size = Vector2(CELL - 44, CELL - 44)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if not unlocked:
		icon.modulate = Color(0.6, 0.6, 0.6)
	add_child(icon)

	var label := Label.new()
	label.text = label_text
	label.position = Vector2(x, y + CELL - 40)
	label.size = Vector2(CELL - 20, 30)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 16)
	add_child(label)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/LevelSelect.tscn")
