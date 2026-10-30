extends Control

# Ekran biezacego wydarzenia: etapy po kolei, czas do konca i nagrody.

const VIEWPORT_WIDTH := 1280
const VIEWPORT_HEIGHT := 720
const CARD_SIZE := Vector2(170, 210)
const CARD_GAP := 22.0
const CARD_Y := 280.0
const DONE_COLOR := Color(0.25, 0.7, 0.3)
const OPEN_COLOR := Color(0.85, 0.75, 0.2)
const LOCKED_COLOR := Color(0.4, 0.4, 0.4)
const BACK_COLOR := Color(0.3, 0.45, 0.25)

func _ready() -> void:
	GameState.clear_event_game()
	GameState.refresh_event()

	var bg := ColorRect.new()
	bg.color = Color(0.15, 0.25, 0.15)
	bg.size = Vector2(VIEWPORT_WIDTH, VIEWPORT_HEIGHT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var back_btn := Button.new()
	back_btn.text = "Wroc"
	back_btn.position = Vector2(40, 620)
	back_btn.size = Vector2(220, 70)
	back_btn.focus_mode = Control.FOCUS_NONE
	back_btn.add_theme_font_size_override("font_size", 24)
	UiIcons.style_button(back_btn, BACK_COLOR, 16)
	back_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/LevelSelect.tscn"))
	add_child(back_btn)

	var event := GameState.current_event()
	if event.is_empty():
		add_child(_label("Wydarzenia", 44, Vector2(0, 40)))
		add_child(_label("Nowe wydarzenie pojawi sie wkrotce.", 26, Vector2(0, 300)))
		return

	add_child(_label(event["name"], 44, Vector2(0, 40)))
	var description := _label(event["description"], 22, Vector2(140, 110))
	description.size = Vector2(VIEWPORT_WIDTH - 280, 70)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(description)
	add_child(_label(_time_left_text(), 22, Vector2(0, 200)))
	_build_stages(event)

func _label(text: String, font_size: int, pos: Vector2) -> Label:
	var label := Label.new()
	label.text = text
	label.position = pos
	label.size = Vector2(VIEWPORT_WIDTH, font_size + 16)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func _time_left_text() -> String:
	var left := GameState.event_seconds_left()
	return "Do konca: %d dni %d godz. Potem wydarzenie znika razem z postepami." % [left / 86400, (left % 86400) / 3600]

func _build_stages(event: Dictionary) -> void:
	var stages: Array = event["stages"]
	var start_x := (VIEWPORT_WIDTH - (stages.size() * CARD_SIZE.x + (stages.size() - 1) * CARD_GAP)) / 2.0
	for i in range(stages.size()):
		var done: bool = GameState.event_completed_stages.has(i)
		var open := GameState.is_event_stage_open(i)
		var card := Button.new()
		card.position = Vector2(start_x + i * (CARD_SIZE.x + CARD_GAP), CARD_Y)
		card.size = CARD_SIZE
		card.focus_mode = Control.FOCUS_NONE
		card.disabled = not open
		var color := LOCKED_COLOR
		if done:
			color = DONE_COLOR
		elif open:
			color = OPEN_COLOR
		UiIcons.style_button(card, color, 18)
		add_child(card)

		var number := _label(str(i + 1), 60, Vector2(0, 24))
		number.size.x = CARD_SIZE.x
		card.add_child(number)

		var saplings: int = EventData.REPLAY_SAPLINGS if done else stages[i]["saplings"]
		var reward := _label("+%d" % saplings, 26, Vector2(0, 140))
		reward.size.x = CARD_SIZE.x - 60
		card.add_child(reward)
		var icon := UiIcons.sapling(44)
		icon.position = Vector2(CARD_SIZE.x - 76, 136)
		card.add_child(icon)

		var stage := i
		card.pressed.connect(func():
			GameState.start_event_game(stage)
			get_tree().change_scene_to_file("res://scenes/Main.tscn"))
