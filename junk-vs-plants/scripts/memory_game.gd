extends Control

# Pamiec ogrodnika (dodatek): 20 zakrytych kart, czyli 10 par roslinek. Odkrycie
# drugiej karty kosztuje ruch z Roslinnych trojek; para oddaje ruch i daje
# roslinie punkt do ulepszenia (8 punktow = ulepszenie). Plansza zostaje do konca
# dodatku, a po odkryciu wszystkich par losuje sie nowa.

const VIEWPORT_WIDTH := 1280
const VIEWPORT_HEIGHT := 720
const COLS := 5
const ROWS := 4
const CARD := 116.0
const GAP := 12.0
const BOARD_TOP := 130.0
const PAIRS := 10
const PREVIEW_TIME := 3.0
const MISMATCH_TIME := 1.0
const BACK_COLOR := Color(0.3, 0.45, 0.25)
const CARD_BACK_COLOR := Color(0.35, 0.6, 0.3)
const CARD_FACE_COLOR := Color(0.95, 0.93, 0.85)
const HELP_BTN_COLOR := Color(0.3, 0.5, 0.75)

var kind := GameState.play_kind
var board: Array = []
var opened: Array = []
var buttons: Array = []
var first := -1
var busy := false
var moves_label: Label
var message_label: Label

func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.15, 0.25, 0.15)
	bg.size = Vector2(VIEWPORT_WIDTH, VIEWPORT_HEIGHT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	add_child(_label(Lang.t("addon_memory"), 40, Vector2(0, 14), VIEWPORT_WIDTH))
	message_label = _label(Lang.t("memory_hint"), 20, Vector2(0, 76), VIEWPORT_WIDTH)
	add_child(message_label)

	var back_btn := _button(Lang.t("back"), BACK_COLOR, Vector2(30, 620), Vector2(200, 70))
	back_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/Rotation.tscn"))
	add_child(back_btn)

	var move_icon := UiIcons.match_move(56)
	move_icon.position = Vector2(1060, 20)
	add_child(move_icon)
	moves_label = _label("", 32, Vector2(1124, 24), 120)
	moves_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	add_child(moves_label)

	var preview_btn := _button(Lang.f("memory_preview", [GameState.rotation_entry(kind)["help"]["cost"]]), HELP_BTN_COLOR, Vector2(1010, 620), Vector2(240, 70))
	preview_btn.add_theme_font_size_override("font_size", 20)
	preview_btn.pressed.connect(_on_preview_pressed)
	add_child(preview_btn)

	_load_board()
	_build_cards()
	_update_moves()

func _label(text: String, font_size: int, pos: Vector2, width: float) -> Label:
	var label := Label.new()
	label.text = text
	label.position = pos
	label.size = Vector2(width, font_size + 16)
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

func _update_moves() -> void:
	moves_label.text = "x %d" % GameState.match_moves

# Plansza zapisana w danych dodatku (liczby z JSON wracaja jako float).
func _load_board() -> void:
	var data := GameState.rotation_data(kind)
	if data.has("memory_board") and data["memory_board"].size() == COLS * ROWS:
		board = data["memory_board"].map(func(v): return int(v))
		opened = data["memory_open"].map(func(v): return bool(v))
		if not opened.has(false):
			_new_board()
	else:
		_new_board()

func _new_board() -> void:
	var plants := range(PlantData.TYPES.size())
	plants.shuffle()
	board = []
	for k in range(PAIRS):
		board.append(plants[k])
		board.append(plants[k])
	board.shuffle()
	opened = []
	for i in range(board.size()):
		opened.append(false)
	_save()

func _save() -> void:
	var data := GameState.rotation_data(kind)
	data["memory_board"] = board
	data["memory_open"] = opened
	GameState.save_progress()

func _build_cards() -> void:
	for btn in buttons:
		btn.queue_free()
	buttons = []
	var start_x := (VIEWPORT_WIDTH - (COLS * CARD + (COLS - 1) * GAP)) / 2.0
	for i in range(board.size()):
		var btn := Button.new()
		btn.position = Vector2(start_x + (i % COLS) * (CARD + GAP), BOARD_TOP + int(i / float(COLS)) * (CARD + GAP))
		btn.size = Vector2(CARD, CARD)
		btn.focus_mode = Control.FOCUS_NONE
		btn.pressed.connect(_on_card_pressed.bind(i))
		add_child(btn)
		buttons.append(btn)
		_show_card(i, opened[i])

func _show_card(i: int, face_up: bool) -> void:
	var btn: Button = buttons[i]
	for child in btn.get_children():
		child.queue_free()
	UiIcons.style_button(btn, CARD_FACE_COLOR if face_up else CARD_BACK_COLOR, 14)
	if face_up:
		var icon := UiIcons.plant_icon(board[i], CARD - 16)
		icon.position = Vector2(8, 8)
		btn.add_child(icon)
	else:
		var leaf := UiIcons.sapling(CARD * 0.5)
		leaf.position = Vector2(CARD * 0.25, CARD * 0.25)
		leaf.modulate = Color(1, 1, 1, 0.5)
		btn.add_child(leaf)

func _on_card_pressed(i: int) -> void:
	if busy or opened[i] or i == first:
		return
	if GameState.match_moves <= 0:
		message_label.text = Lang.t("memory_no_moves")
		return
	_show_card(i, true)
	if first < 0:
		first = i
		return
	var a := first
	first = -1
	GameState.use_match_move()
	if board[a] == board[i]:
		# Para: ruch wraca, a roslina dostaje punkt.
		GameState.match_moves += 1
		opened[a] = true
		opened[i] = true
		var upgraded := GameState.add_match_points(board[i], 1)
		message_label.text = Lang.f("memory_pair_upgrade" if upgraded > 0 else "memory_pair", [PlantData.name_of(board[i])])
		_save()
		_update_moves()
		if not opened.has(false):
			message_label.text = Lang.t("memory_board_done")
			busy = true
			await get_tree().create_timer(1.5).timeout
			busy = false
			_new_board()
			_build_cards()
		return
	_update_moves()
	busy = true
	await get_tree().create_timer(MISMATCH_TIME).timeout
	busy = false
	_show_card(a, false)
	_show_card(i, false)

# Pomoc: za roslimonety wszystkie karty odkrywaja sie na 3 sekundy.
func _on_preview_pressed() -> void:
	if busy:
		return
	if not GameState.spend_coins(GameState.rotation_entry(kind)["help"]["cost"]):
		message_label.text = Lang.t("too_few_coins")
		return
	busy = true
	first = -1
	for i in range(board.size()):
		_show_card(i, true)
	await get_tree().create_timer(PREVIEW_TIME).timeout
	busy = false
	for i in range(board.size()):
		_show_card(i, opened[i])
