extends Control

# Ekran biezacego wydarzenia: etapy, czas do konca, nagrody i pomoc kupowana
# za roslimonety przed etapem.

const VIEWPORT_WIDTH := 1280
const VIEWPORT_HEIGHT := 720
const CARD_SIZE := Vector2(170, 210)
const CARD_GAP := 22.0
const CARD_Y := 280.0
const DONE_COLOR := Color(0.25, 0.7, 0.3)
const OPEN_COLOR := Color(0.85, 0.75, 0.2)
const LOCKED_COLOR := Color(0.4, 0.4, 0.4)
const BACK_COLOR := Color(0.3, 0.45, 0.25)
const OK_BTN_COLOR := Color(0.25, 0.6, 0.25)
const HELP_BTN_COLOR := Color(0.3, 0.5, 0.75)
const POPUP_BG_COLOR := Color(0.95, 0.93, 0.85)
const POPUP_TEXT_COLOR := Color(0.15, 0.12, 0.1)

var popup: Control

func _ready() -> void:
	GameState.clear_event_game()
	GameState.refresh_event()

	var bg := ColorRect.new()
	bg.color = Color(0.15, 0.25, 0.15)
	bg.size = Vector2(VIEWPORT_WIDTH, VIEWPORT_HEIGHT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var back_btn := _button("Wroc", BACK_COLOR, Vector2(40, 620), Vector2(220, 70))
	back_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/LevelSelect.tscn"))
	add_child(back_btn)

	var coin_icon := UiIcons.plant_coin(40)
	coin_icon.position = Vector2(1080, 640)
	add_child(coin_icon)
	var coin_label := _label(str(GameState.plant_coins), 30, Vector2(1126, 636))
	coin_label.size.x = 130
	coin_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	add_child(coin_label)

	var event := GameState.current_event()
	if event.is_empty():
		add_child(_label("Wydarzenia", 44, Vector2(0, 40)))
		add_child(_label("Nowe wydarzenie pojawi sie wkrotce.", 26, Vector2(0, 300)))
		return

	add_child(_label(event["name"], 44, Vector2(0, 30)))
	var description := _label(event["description"], 22, Vector2(120, 96))
	description.size = Vector2(VIEWPORT_WIDTH - 240, 70)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(description)
	add_child(_label(_time_left_text(), 22, Vector2(0, 182)))
	if event.get("coin_hunt", false):
		add_child(_label(_hunt_progress_text(), 24, Vector2(0, 226)))
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

func _button(text: String, color: Color, pos: Vector2, btn_size: Vector2) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.position = pos
	btn.size = btn_size
	btn.focus_mode = Control.FOCUS_NONE
	btn.add_theme_font_size_override("font_size", 24)
	UiIcons.style_button(btn, color, 16)
	return btn

func _time_left_text() -> String:
	var left := GameState.event_seconds_left()
	return "Do konca: %d dni %d godz. Potem wydarzenie znika razem z postepami." % [left / 86400, (left % 86400) / 3600]

func _hunt_progress_text() -> String:
	var reached := GameState.event_hunt_thresholds
	var thresholds: Array = EventData.HUNT_THRESHOLDS
	if reached >= thresholds.size():
		return "Monety z tygodnia: %d. Wszystkie progi zdobyte!" % GameState.event_hunt_coins
	var next: Dictionary = thresholds[reached]
	return "Monety z tygodnia: %d. Nastepny prog: %d monet, +%d sadzonek" % [GameState.event_hunt_coins, next["coins"], next["saplings"]]

func _build_stages(event: Dictionary) -> void:
	var count: int = EventData.STAGES.size()
	var start_x := (VIEWPORT_WIDTH - (count * CARD_SIZE.x + (count - 1) * CARD_GAP)) / 2.0
	for i in range(count):
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
		_add_card_reward(card, event, i, done)

		var stage := i
		card.pressed.connect(func(): _on_stage_pressed(event, stage))

func _add_card_reward(card: Button, event: Dictionary, stage: int, done: bool) -> void:
	var text := ""
	if event.get("coin_hunt", false):
		return
	if event.get("time_race", false):
		text = "%d / 3 *" % event_stars(stage)
	else:
		text = "+%d" % (EventData.REPLAY_SAPLINGS if done else EventData.STAGES[stage]["saplings"])
	var reward := _label(text, 26, Vector2(0, 140))
	reward.size.x = CARD_SIZE.x - 60
	card.add_child(reward)
	var icon := UiIcons.sapling(44)
	icon.position = Vector2(CARD_SIZE.x - 76, 136)
	card.add_child(icon)

func event_stars(stage: int) -> int:
	return GameState.event_stars.get(str(stage), 0)

# Gdy wydarzenie ma pomoc, gracz wybiera przed etapem, czy ja kupic.
func _on_stage_pressed(event: Dictionary, stage: int) -> void:
	if not event.has("help"):
		_start_stage(event, stage, false)
		return
	var help: Dictionary = event["help"]
	popup = Control.new()
	popup.size = Vector2(VIEWPORT_WIDTH, VIEWPORT_HEIGHT)
	add_child(popup)
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.6)
	shade.size = popup.size
	popup.add_child(shade)

	var panel := Panel.new()
	panel.size = Vector2(700, 300)
	panel.position = (popup.size - panel.size) / 2.0
	var sb := UiIcons.round_style(POPUP_BG_COLOR, 18)
	sb.set_border_width_all(5)
	sb.border_color = Color(0.25, 0.2, 0.15)
	panel.add_theme_stylebox_override("panel", sb)
	popup.add_child(panel)

	var question := _label("Pomoc na ten etap: %s" % help["text"], 26, Vector2(20, 40))
	question.size = Vector2(panel.size.x - 40, 90)
	question.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	question.add_theme_color_override("font_color", POPUP_TEXT_COLOR)
	panel.add_child(question)

	var play_btn := _button("Zagraj bez pomocy", OK_BTN_COLOR, Vector2(30, 170), Vector2(300, 80))
	play_btn.pressed.connect(func(): _start_stage(event, stage, false))
	panel.add_child(play_btn)

	var help_btn := _button("Kup za %d i zagraj" % help["cost"], HELP_BTN_COLOR, Vector2(370, 170), Vector2(300, 80))
	help_btn.disabled = GameState.plant_coins < help["cost"]
	help_btn.pressed.connect(func(): _start_stage(event, stage, true))
	panel.add_child(help_btn)

# Sadzenie z tasmy od razu idzie na plansze, a standardowe przez wybor talii.
func _start_stage(event: Dictionary, stage: int, with_help: bool) -> void:
	if not GameState.start_event_game(stage, with_help):
		return
	var scene := "res://scenes/Main.tscn" if event["planting"] == "belt" else "res://scenes/PlantSelect.tscn"
	get_tree().change_scene_to_file(scene)
