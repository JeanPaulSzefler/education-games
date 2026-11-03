extends Control

# Quiz ekologiczny (gra edukacyjna): raz dziennie 5 pytan "do ktorego pojemnika
# wyrzucisz...?". Kazda dobra odpowiedz to roslimonety, a komplet 5/5 - sadzonka.
# Po kazdej odpowiedzi gra pokazuje, gdzie naprawde trafia ten smiec.

const VIEWPORT_WIDTH := 1280
const VIEWPORT_HEIGHT := 720
const BIN_SIZE := Vector2(220, 150)
const BIN_GAP := 18.0
const BIN_Y := 420.0
const NEXT_DELAY := 2.0
const BACK_COLOR := Color(0.3, 0.45, 0.25)
const OK_BTN_COLOR := Color(0.25, 0.6, 0.25)

var questions: Array = []
var current := 0
var correct := 0
var answered := false
var item_label: Label
var item_icon_holder: Control
var feedback_label: Label
var progress_label: Label
var bin_buttons: Array = []

func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.13, 0.22, 0.3)
	bg.size = Vector2(VIEWPORT_WIDTH, VIEWPORT_HEIGHT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	add_child(_label(Lang.t("addon_quiz"), 38, Vector2(0, 14)))
	progress_label = _label("", 22, Vector2(0, 70))
	add_child(progress_label)
	add_child(_label(Lang.t("quiz_question"), 26, Vector2(0, 120)))
	item_icon_holder = Control.new()
	item_icon_holder.position = Vector2((VIEWPORT_WIDTH - 110) / 2.0, 170)
	add_child(item_icon_holder)
	item_label = _label("", 40, Vector2(0, 285))
	add_child(item_label)
	feedback_label = _label("", 24, Vector2(0, 600))
	add_child(feedback_label)

	var back_btn := _button(Lang.t("back"), BACK_COLOR, Vector2(30, 630), Vector2(180, 64))
	back_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/Rotation.tscn"))
	add_child(back_btn)

	var start_x := (VIEWPORT_WIDTH - (AddonData.BINS.size() * BIN_SIZE.x + (AddonData.BINS.size() - 1) * BIN_GAP)) / 2.0
	for i in range(AddonData.BINS.size()):
		var bin: String = AddonData.BINS[i]
		var btn := _bin_button(bin, Vector2(start_x + i * (BIN_SIZE.x + BIN_GAP), BIN_Y))
		btn.pressed.connect(func(): _answer(bin))
		add_child(btn)
		bin_buttons.append(btn)

	if not GameState.is_quiz_ready():
		item_label.text = Lang.t("quiz_tomorrow")
		for btn in bin_buttons:
			btn.disabled = true
		return
	var items: Array = AddonData.TRASH_ITEMS.duplicate()
	items.shuffle()
	questions = items.slice(0, AddonData.QUIZ_QUESTIONS)
	_show_question()

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
	btn.add_theme_font_size_override("font_size", 22)
	UiIcons.style_button(btn, color, 16)
	return btn

# Pojemnik w swoim kolorze z nazwa, np. "Zolty: metale i plastik".
func _bin_button(bin: String, pos: Vector2) -> Button:
	var color: Color = AddonData.BIN_COLORS[bin]
	var btn := _button("", color, pos, BIN_SIZE)
	var text := Label.new()
	text.text = Lang.t("bin_" + bin)
	text.position = Vector2(10, 10)
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UiIcons.wrap_label(text, BIN_SIZE - Vector2(20, 20))
	text.add_theme_font_size_override("font_size", 20)
	text.add_theme_color_override("font_color", Color(0.1, 0.1, 0.1) if bin == "yellow" else Color(1, 1, 1))
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(text)
	return btn

static func trash_icon(item_id: String, size: float) -> Control:
	return UiIcons.file_icon("trash_" + item_id, size)

func _show_question() -> void:
	answered = false
	var item: Array = questions[current]
	progress_label.text = Lang.f("quiz_progress", [current + 1, questions.size(), correct])
	item_label.text = Lang.t("trash_" + item[0])
	feedback_label.text = ""
	for child in item_icon_holder.get_children():
		child.queue_free()
	var icon := trash_icon(item[0], 110)
	if icon != null:
		item_icon_holder.add_child(icon)
	for btn in bin_buttons:
		btn.modulate = Color(1, 1, 1)

func _answer(bin: String) -> void:
	if answered or questions.is_empty():
		return
	answered = true
	var item: Array = questions[current]
	var right: String = item[1]
	if bin == right:
		correct += 1
		feedback_label.text = Lang.t("quiz_right")
	else:
		feedback_label.text = Lang.f("quiz_wrong", [Lang.t("trash_" + item[0]), Lang.t("bin_" + right)])
	for i in range(AddonData.BINS.size()):
		bin_buttons[i].modulate = Color(1, 1, 1) if AddonData.BINS[i] == right else Color(0.45, 0.45, 0.45)
	await get_tree().create_timer(NEXT_DELAY).timeout
	current += 1
	if current < questions.size():
		_show_question()
	else:
		_finish()

func _finish() -> void:
	var reward := GameState.finish_quiz(correct)
	for btn in bin_buttons:
		btn.disabled = true
	item_label.text = Lang.f("quiz_result", [correct, questions.size()])
	progress_label.text = ""
	feedback_label.text = Lang.f("quiz_reward", [reward["coins"]]) + (" " + Lang.f("saplings_won", [reward["saplings"]]) if reward["saplings"] > 0 else "")
	var ok := _button(Lang.t("ok"), OK_BTN_COLOR, Vector2((VIEWPORT_WIDTH - 220) / 2.0, 630), Vector2(220, 64))
	ok.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/Rotation.tscn"))
	add_child(ok)
