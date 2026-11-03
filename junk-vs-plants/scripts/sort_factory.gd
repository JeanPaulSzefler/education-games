extends Control

# Sortownia (gra edukacyjna): tasma wiezie smieci od lewej do prawej, a gracz
# przeciaga kazdy do wlasciwego pojemnika. Pomylka albo smiec, ktory spadnie z
# tasmy, to blad - 3 bledy albo koniec czasu koncza runde. Tasma przyspiesza.
# Progi wyniku (AddonData.SORT_THRESHOLDS) daja sadzonki.

const VIEWPORT_WIDTH := 1280
const VIEWPORT_HEIGHT := 720
const ROUND_TIME := 90.0
const MISTAKES := 3
const BELT_Y := 170.0
const BELT_HEIGHT := 150.0
const ITEM_SIZE := Vector2(170, 110)
const BIN_SIZE := Vector2(220, 170)
const BIN_GAP := 18.0
const BIN_Y := 450.0
const START_SPEED := 70.0
const SPEED_PER_SECOND := 1.6
const START_SPAWN := 3.2
const MIN_SPAWN := 1.3
const BACK_COLOR := Color(0.3, 0.45, 0.25)
const OK_BTN_COLOR := Color(0.25, 0.6, 0.25)

var kind := GameState.play_kind
var items: Array = []
var bins: Array = []
var held: Dictionary = {}
var held_offset := Vector2.ZERO
var time_left := ROUND_TIME
var spawn_timer := 0.5
var score := 0
var mistakes := 0
var running := true
var info_label: Label
var feedback_label: Label

func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.13, 0.22, 0.3)
	bg.size = Vector2(VIEWPORT_WIDTH, VIEWPORT_HEIGHT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	var belt := ColorRect.new()
	belt.color = Color(0.3, 0.3, 0.33)
	belt.position = Vector2(0, BELT_Y)
	belt.size = Vector2(VIEWPORT_WIDTH, BELT_HEIGHT)
	belt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(belt)

	var title := Label.new()
	title.text = Lang.t("addon_sort_game")
	title.position = Vector2(20, 10)
	title.add_theme_font_size_override("font_size", 34)
	add_child(title)
	info_label = Label.new()
	info_label.position = Vector2(20, 64)
	info_label.add_theme_font_size_override("font_size", 24)
	add_child(info_label)
	feedback_label = Label.new()
	feedback_label.position = Vector2(0, 360)
	feedback_label.size = Vector2(VIEWPORT_WIDTH, 60)
	feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	feedback_label.add_theme_font_size_override("font_size", 24)
	add_child(feedback_label)

	var back_btn := Button.new()
	back_btn.text = Lang.t("back")
	back_btn.position = Vector2(VIEWPORT_WIDTH - 180, 10)
	back_btn.size = Vector2(160, 56)
	back_btn.focus_mode = Control.FOCUS_NONE
	UiIcons.style_button(back_btn, BACK_COLOR, 14)
	back_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/Rotation.tscn"))
	add_child(back_btn)

	var start_x := (VIEWPORT_WIDTH - (AddonData.BINS.size() * BIN_SIZE.x + (AddonData.BINS.size() - 1) * BIN_GAP)) / 2.0
	for i in range(AddonData.BINS.size()):
		var bin: String = AddonData.BINS[i]
		var rect := Panel.new()
		rect.position = Vector2(start_x + i * (BIN_SIZE.x + BIN_GAP), BIN_Y)
		rect.size = BIN_SIZE
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rect.add_theme_stylebox_override("panel", UiIcons.round_style(AddonData.BIN_COLORS[bin], 16))
		add_child(rect)
		var text := Label.new()
		text.text = Lang.t("bin_" + bin)
		text.position = Vector2(10, 10)
		text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		UiIcons.wrap_label(text, BIN_SIZE - Vector2(20, 20))
		text.add_theme_font_size_override("font_size", 20)
		text.add_theme_color_override("font_color", Color(0.1, 0.1, 0.1) if bin == "yellow" else Color(1, 1, 1))
		rect.add_child(text)
		bins.append({"bin": bin, "rect": rect})
	_update_info()

func _process(delta: float) -> void:
	if not running:
		return
	time_left -= delta
	var elapsed := ROUND_TIME - time_left
	spawn_timer -= delta
	if spawn_timer <= 0.0:
		spawn_timer = maxf(MIN_SPAWN, START_SPAWN - elapsed * 0.025)
		_spawn_item()
	var speed := START_SPEED + elapsed * SPEED_PER_SECOND
	for item in items.duplicate():
		if item == held:
			continue
		var node: Control = item["node"]
		node.position.x += speed * delta
		if node.position.x > VIEWPORT_WIDTH:
			_mistake(Lang.f("sort_fell", [Lang.t("trash_" + item["id"])]))
			node.queue_free()
			items.erase(item)
	if time_left <= 0.0 or mistakes >= MISTAKES:
		_finish()
	_update_info()

func _spawn_item() -> void:
	var data: Array = AddonData.TRASH_ITEMS.pick_random()
	var card := Panel.new()
	card.size = ITEM_SIZE
	card.position = Vector2(-ITEM_SIZE.x, BELT_Y + (BELT_HEIGHT - ITEM_SIZE.y) / 2.0)
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_theme_stylebox_override("panel", UiIcons.round_style(Color(0.97, 0.95, 0.88), 12))
	add_child(card)
	var icon := UiIcons.file_icon("trash_" + data[0], 60)
	var text_y := 10.0
	if icon != null:
		icon.position = Vector2((ITEM_SIZE.x - 60) / 2.0, 4)
		card.add_child(icon)
		text_y = 64.0
	var text := Label.new()
	text.text = Lang.t("trash_" + data[0])
	text.position = Vector2(6, text_y)
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UiIcons.wrap_label(text, Vector2(ITEM_SIZE.x - 12, ITEM_SIZE.y - text_y - 4))
	text.add_theme_font_size_override("font_size", 18 if icon == null else 14)
	text.add_theme_color_override("font_color", Color(0.15, 0.12, 0.1))
	card.add_child(text)
	items.append({"node": card, "id": data[0], "bin": data[1]})

func _input(event: InputEvent) -> void:
	if not running:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_grab(event.position)
		elif not held.is_empty():
			_drop(event.position)
	elif event is InputEventMouseMotion and not held.is_empty():
		held["node"].position = event.position - held_offset

func _grab(pos: Vector2) -> void:
	for item in items:
		if Rect2(item["node"].position, ITEM_SIZE).has_point(pos):
			held = item
			held_offset = pos - item["node"].position
			move_child(item["node"], get_child_count() - 1)
			return

func _drop(pos: Vector2) -> void:
	var item := held
	held = {}
	for entry in bins:
		var rect: Panel = entry["rect"]
		if Rect2(rect.position, rect.size).has_point(pos):
			items.erase(item)
			item["node"].queue_free()
			if entry["bin"] == item["bin"]:
				score += 1
				feedback_label.text = Lang.t("quiz_right")
			else:
				_mistake(Lang.f("quiz_wrong", [Lang.t("trash_" + item["id"]), Lang.t("bin_" + item["bin"])]))
			return
	# Puszczony poza pojemnikiem - wraca na tasme.
	item["node"].position.y = BELT_Y + (BELT_HEIGHT - ITEM_SIZE.y) / 2.0

func _mistake(text: String) -> void:
	mistakes += 1
	feedback_label.text = text

func _update_info() -> void:
	info_label.text = Lang.f("sort_info", [score, MISTAKES - mistakes, ceili(maxf(time_left, 0.0))])

func _finish() -> void:
	running = false
	held = {}
	for item in items:
		item["node"].queue_free()
	items.clear()
	var saplings := GameState.claim_score_thresholds(kind, AddonData.SORT_THRESHOLDS, score)
	var panel := Panel.new()
	panel.size = Vector2(620, 300)
	panel.position = (Vector2(VIEWPORT_WIDTH, VIEWPORT_HEIGHT) - panel.size) / 2.0
	var sb := UiIcons.round_style(Color(0.95, 0.93, 0.85), 18)
	sb.set_border_width_all(5)
	sb.border_color = Color(0.25, 0.2, 0.15)
	panel.add_theme_stylebox_override("panel", sb)
	add_child(panel)
	var text := Label.new()
	text.text = Lang.f("sort_result", [score]) + ("\n" + Lang.f("saplings_won", [saplings]) if saplings > 0 else "")
	text.position = Vector2(20, 40)
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiIcons.wrap_label(text, Vector2(580, 110))
	text.add_theme_font_size_override("font_size", 28)
	text.add_theme_color_override("font_color", Color(0.15, 0.12, 0.1))
	panel.add_child(text)
	var again := Button.new()
	again.text = Lang.t("play_again")
	again.position = Vector2(40, 190)
	again.size = Vector2(250, 70)
	again.focus_mode = Control.FOCUS_NONE
	UiIcons.style_button(again, OK_BTN_COLOR, 14)
	again.pressed.connect(func(): get_tree().reload_current_scene())
	panel.add_child(again)
	var back := Button.new()
	back.text = Lang.t("back")
	back.position = Vector2(330, 190)
	back.size = Vector2(250, 70)
	back.focus_mode = Control.FOCUS_NONE
	UiIcons.style_button(back, BACK_COLOR, 14)
	back.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/Rotation.tscn"))
	panel.add_child(back)
