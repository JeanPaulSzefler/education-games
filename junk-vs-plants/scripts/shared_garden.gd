extends Control

# Sadzenie razem: polaczeni znajomi widza wspolny cel tygodnia (zbiory obojga)
# i moga wysylac sobie sadzonki. Dziala przez NetSession, bez serwera.

const VIEWPORT_WIDTH := 1280
const VIEWPORT_HEIGHT := 720
const OK_BTN_COLOR := Color(0.25, 0.6, 0.25)
const BACK_COLOR := Color(0.3, 0.45, 0.25)

var progress_label: Label
var message_label: Label
var saplings_label: Label
var gift_btn: Button

func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.2, 0.36, 0.18)
	bg.size = Vector2(VIEWPORT_WIDTH, VIEWPORT_HEIGHT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	add_child(_label("Sadzimy razem", 44, Vector2(0, 40)))
	progress_label = _label("", 30, Vector2(0, 160))
	add_child(progress_label)
	saplings_label = _label("", 26, Vector2(0, 230))
	add_child(saplings_label)
	message_label = _label("", 24, Vector2(0, 470))
	add_child(message_label)

	gift_btn = _button("", OK_BTN_COLOR, Vector2((VIEWPORT_WIDTH - 480) / 2.0, 330), Vector2(480, 90))
	gift_btn.pressed.connect(_on_gift_pressed)
	add_child(gift_btn)

	var back_btn := _button("Zakoncz", BACK_COLOR, Vector2(40, 620), Vector2(220, 70))
	back_btn.pressed.connect(_leave)
	add_child(back_btn)

	NetSession.garden_harvests_received.connect(_on_friend_harvests)
	NetSession.garden_gift_received.connect(_on_gift_received)
	NetSession.session_lost.connect(_leave)
	NetSession.send_garden_harvests(GameState.shared_my_harvests)
	_refresh()

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
	btn.add_theme_font_size_override("font_size", 26)
	UiIcons.style_button(btn, color, 16)
	return btn

func _refresh() -> void:
	var goal := EventData.SHARED_GOAL_HARVESTS
	var total: int = min(GameState.shared_total_harvests(), goal)
	progress_label.text = "Wspolny cel: %d / %d zebranych roslinek" % [total, goal]
	saplings_label.text = "Twoje sadzonki: %d" % GameState.saplings
	if GameState.is_free_gift_ready():
		gift_btn.text = "Wyslij sadzonke za darmo"
		gift_btn.disabled = false
	else:
		gift_btn.text = "Wyslij sadzonke za %d roslimonet" % EventData.GIFT_COST
		gift_btn.disabled = GameState.plant_coins < EventData.GIFT_COST

func _on_gift_pressed() -> void:
	if GameState.pay_for_gift():
		NetSession.send_garden_gift()
		message_label.text = "Sadzonka wyslana do znajomego!"
		_refresh()

func _on_gift_received() -> void:
	GameState.receive_gift()
	message_label.text = "Znajomy przyslal Ci sadzonke!"
	_refresh()

func _on_friend_harvests(count: int) -> void:
	GameState.set_friend_harvests(count)
	if GameState.try_pay_shared_goal():
		message_label.text = "Wspolny cel zdobyty: +%d sadzonki dla kazdego!" % EventData.SHARED_REWARD_SAPLINGS
	_refresh()

func _leave() -> void:
	NetSession.end_session()
	NetSession.notice = ""
	get_tree().change_scene_to_file("res://scenes/Garden.tscn")
