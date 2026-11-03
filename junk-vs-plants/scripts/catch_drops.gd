extends Control

# Lapanie kropli (dodatek): z nieba spadaja krople, nawozy i smieci. Gracz
# przesuwa konewke palcem. Kropla to punkty, nawoz podwaja punkty do konca
# rundy, a zlapany smiec zabiera serce. Runda trwa 60 s albo do utraty 3 serc
# i z czasem przyspiesza. Progi wyniku (AddonData.CATCH_THRESHOLDS) daja sadzonki.

const VIEWPORT_WIDTH := 1280
const VIEWPORT_HEIGHT := 720
const ROUND_TIME := 60.0
const HEARTS := 3
const DROP_POINTS := 5
const CAN_Y := 600.0
const CAN_SIZE := Vector2(130, 90)
const ITEM_SIZE := 56.0
const START_FALL := 180.0
const FALL_PER_SECOND := 4.0
const START_SPAWN := 0.9
const MIN_SPAWN := 0.35
const TRASH_TEXTURES := ["res://assets/sprites/enemies/bottle.png", "res://assets/sprites/enemies/can.png"]
const BACK_COLOR := Color(0.3, 0.45, 0.25)
const OK_BTN_COLOR := Color(0.25, 0.6, 0.25)

var kind := GameState.play_kind
var can: Control
var items: Array = []
var time_left := ROUND_TIME
var spawn_timer := 0.5
var score := 0
var hearts := HEARTS
var multiplier := 1
var running := true
var info_label: Label

func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.55, 0.78, 0.95)
	bg.size = Vector2(VIEWPORT_WIDTH, VIEWPORT_HEIGHT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	var grass := ColorRect.new()
	grass.color = Color(0.3, 0.6, 0.25)
	grass.position = Vector2(0, CAN_Y + CAN_SIZE.y - 10)
	grass.size = Vector2(VIEWPORT_WIDTH, VIEWPORT_HEIGHT)
	grass.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(grass)

	info_label = Label.new()
	info_label.position = Vector2(20, 12)
	info_label.add_theme_font_size_override("font_size", 28)
	info_label.add_theme_color_override("font_color", Color(0.1, 0.15, 0.3))
	add_child(info_label)

	var back_btn := Button.new()
	back_btn.text = Lang.t("back")
	back_btn.position = Vector2(VIEWPORT_WIDTH - 180, 10)
	back_btn.size = Vector2(160, 56)
	back_btn.focus_mode = Control.FOCUS_NONE
	UiIcons.style_button(back_btn, BACK_COLOR, 14)
	back_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/Rotation.tscn"))
	add_child(back_btn)

	can = UiIcons.file_icon("watering_can", CAN_SIZE.x)
	if can == null:
		can = _drawn_can()
	can.position = Vector2((VIEWPORT_WIDTH - CAN_SIZE.x) / 2.0, CAN_Y)
	add_child(can)
	_update_info()

# Konewka z kodu, dopoki nie ma grafiki.
func _drawn_can() -> Control:
	var c := Control.new()
	c.size = CAN_SIZE
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var body := ColorRect.new()
	body.color = Color(0.3, 0.55, 0.85)
	body.position = Vector2(20, 20)
	body.size = Vector2(90, 70)
	c.add_child(body)
	var spout := ColorRect.new()
	spout.color = Color(0.25, 0.45, 0.75)
	spout.position = Vector2(100, 30)
	spout.size = Vector2(30, 12)
	c.add_child(spout)
	return c

func _input(event: InputEvent) -> void:
	if not running:
		return
	var x := -1.0
	if event is InputEventMouseMotion or event is InputEventMouseButton:
		x = event.position.x
	elif event is InputEventScreenDrag or event is InputEventScreenTouch:
		x = event.position.x
	if x >= 0.0:
		can.position.x = clampf(x - CAN_SIZE.x / 2.0, 0.0, VIEWPORT_WIDTH - CAN_SIZE.x)

func _process(delta: float) -> void:
	if not running:
		return
	time_left -= delta
	var elapsed := ROUND_TIME - time_left
	spawn_timer -= delta
	if spawn_timer <= 0.0:
		spawn_timer = maxf(MIN_SPAWN, START_SPAWN - elapsed * 0.01)
		_spawn_item()
	var fall := START_FALL + elapsed * FALL_PER_SECOND
	var catch_rect := Rect2(can.position + Vector2(10, 10), Vector2(CAN_SIZE.x - 20, 40))
	for item in items.duplicate():
		var node: Control = item["node"]
		node.position.y += fall * delta
		var center := node.position + Vector2(ITEM_SIZE, ITEM_SIZE) / 2.0
		if catch_rect.has_point(center):
			_catch(item)
		elif node.position.y > VIEWPORT_HEIGHT:
			node.queue_free()
			items.erase(item)
	if time_left <= 0.0 or hearts <= 0:
		_finish()
	_update_info()

func _spawn_item() -> void:
	var roll := randf()
	var kind_name := "drop"
	if roll < 0.06:
		kind_name = "fertilizer"
	elif roll < 0.36:
		kind_name = "trash"
	var node: Control
	match kind_name:
		"drop":
			node = _sprite("res://assets/sprites/ui/water_drop.png")
		"fertilizer":
			node = _sprite("res://assets/sprites/ui/fertilizer.png")
		_:
			node = _sprite(TRASH_TEXTURES.pick_random())
	node.position = Vector2(randf_range(20, VIEWPORT_WIDTH - 20 - ITEM_SIZE), -ITEM_SIZE)
	add_child(node)
	items.append({"node": node, "kind": kind_name})

func _sprite(path: String) -> TextureRect:
	var tex := TextureRect.new()
	tex.texture = load(path)
	tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex.size = Vector2(ITEM_SIZE, ITEM_SIZE)
	tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return tex

func _catch(item: Dictionary) -> void:
	items.erase(item)
	item["node"].queue_free()
	match item["kind"]:
		"drop":
			score += DROP_POINTS * multiplier
		"fertilizer":
			multiplier = 2
		_:
			hearts -= 1
			var tw := can.create_tween()
			tw.tween_property(can, "modulate", Color(1, 0.4, 0.4), 0.1)
			tw.tween_property(can, "modulate", Color(1, 1, 1), 0.3)

func _update_info() -> void:
	info_label.text = Lang.f("catch_info", [score, "♥".repeat(maxi(hearts, 0)), ceili(maxf(time_left, 0.0))]) + ("   x2" if multiplier > 1 else "")

func _finish() -> void:
	running = false
	for item in items:
		item["node"].queue_free()
	items.clear()
	var saplings := GameState.claim_score_thresholds(kind, AddonData.CATCH_THRESHOLDS, score)
	GameState.record_bingo("addon_game")
	var panel := Panel.new()
	panel.size = Vector2(620, 300)
	panel.position = (Vector2(VIEWPORT_WIDTH, VIEWPORT_HEIGHT) - panel.size) / 2.0
	var sb := UiIcons.round_style(Color(0.95, 0.93, 0.85), 18)
	sb.set_border_width_all(5)
	sb.border_color = Color(0.25, 0.2, 0.15)
	panel.add_theme_stylebox_override("panel", sb)
	add_child(panel)
	var text := Label.new()
	text.text = Lang.f("catch_result", [score]) + ("\n" + Lang.f("saplings_won", [saplings]) if saplings > 0 else "")
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
