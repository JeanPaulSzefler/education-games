extends Control

# Ekran biezacego dodatku albo gry edukacyjnej (GameState.rotation_view):
# nazwa, opis, czas do zmiany, a dalej - zaleznie od rodzaju - etapy, przycisk
# mini-gry, album naklejek, karta bingo albo pojedynek.

const VIEWPORT_WIDTH := 1280
const VIEWPORT_HEIGHT := 720
const CARD_SIZE := Vector2(170, 210)
const CARD_GAP := 22.0
const CARD_Y := 300.0
const DONE_COLOR := Color(0.25, 0.7, 0.3)
const OPEN_COLOR := Color(0.85, 0.75, 0.2)
const LOCKED_COLOR := Color(0.4, 0.4, 0.4)
const BACK_COLOR := Color(0.3, 0.45, 0.25)
const OK_BTN_COLOR := Color(0.25, 0.6, 0.25)
const HELP_BTN_COLOR := Color(0.3, 0.5, 0.75)
const POPUP_BG_COLOR := Color(0.95, 0.93, 0.85)
const POPUP_TEXT_COLOR := Color(0.15, 0.12, 0.1)
const BINGO_CELL := Vector2(250, 84)

# Sceny mini-gier dla rodzaju wpisu.
const SCENES := {
	"memory": "res://scenes/MemoryGame.tscn",
	"catch": "res://scenes/CatchDrops.tscn",
	"quiz": "res://scenes/EcoQuiz.tscn",
	"sort_game": "res://scenes/SortFactory.tscn",
	"maze": "res://scenes/BeeMaze.tscn",
	"path": "res://scenes/PathDefense.tscn",
}

var kind := GameState.rotation_view
var entry: Dictionary
var popup: Control
var content: Control
var coin_label: Label

func _ready() -> void:
	GameState.clear_event_game()
	GameState.refresh_rotation(kind)
	NetSession.notice = ""
	entry = GameState.rotation_entry(kind)

	add_child(UiIcons.screen_background("menu"))

	var back_btn := _button(Lang.t("back"), BACK_COLOR, Vector2(40, 620), Vector2(220, 70))
	back_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/LevelSelect.tscn"))
	add_child(back_btn)

	var coin_icon := UiIcons.plant_coin(40)
	coin_icon.position = Vector2(1080, 640)
	add_child(coin_icon)
	coin_label = _label(str(GameState.plant_coins), 30, Vector2(1126, 636))
	coin_label.size.x = 130
	coin_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	add_child(coin_label)

	var header := Lang.t("addons_title") if kind == AddonData.KIND_ADDON else Lang.t("edu_title")
	add_child(_label(header, 24, Vector2(0, 12)))
	add_child(_label(AddonData.title(entry), 42, Vector2(0, 40)))
	var description := _label(AddonData.description(entry), 20, Vector2(110, 100))
	UiIcons.wrap_label(description, Vector2(VIEWPORT_WIDTH - 220, 96))
	add_child(description)
	add_child(_label(_time_left_text(), 20, Vector2(0, 200)))

	content = Control.new()
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(content)
	_build_content()

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
	var left := GameState.rotation_seconds_left(kind)
	var next: Dictionary = AddonData.entries(kind)[(int(GameState.rotations[kind]["index"]) + 1) % AddonData.entries(kind).size()]
	return Lang.f("rotation_time_left", [left / 86400, (left % 86400) / 3600, AddonData.title(next)])

func _build_content() -> void:
	for child in content.get_children():
		child.queue_free()
	match entry["kind"]:
		"combat", "path", "maze":
			_build_stages()
		"album":
			_build_album()
		"bingo":
			_build_bingo()
		"duel":
			_build_duel()
		_:
			_build_minigame()

# --- Etapy ---
func _build_stages() -> void:
	var count: int = EventData.STAGES.size()
	var start_x := (VIEWPORT_WIDTH - (count * CARD_SIZE.x + (count - 1) * CARD_GAP)) / 2.0
	var done_list := GameState.rotation_stages(kind)
	for i in range(count):
		var done: bool = done_list.has(i)
		var open := GameState.is_rotation_stage_open(kind, i)
		var card := _button("", DONE_COLOR if done else (OPEN_COLOR if open else LOCKED_COLOR), Vector2(start_x + i * (CARD_SIZE.x + CARD_GAP), CARD_Y), CARD_SIZE)
		card.disabled = not open
		content.add_child(card)
		var number := _label(str(i + 1), 60, Vector2(0, 20))
		number.size.x = CARD_SIZE.x
		card.add_child(number)
		_add_stage_reward(card, i, done)
		var stage := i
		card.pressed.connect(func(): _on_stage_pressed(stage))

func _add_stage_reward(card: Button, stage: int, done: bool) -> void:
	var row := HBoxContainer.new()
	row.position = Vector2(8, 120)
	row.size = Vector2(CARD_SIZE.x - 16, 70)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(row)
	if entry["kind"] == "maze":
		var stars := GameState.rotation_stars(kind, stage)
		row.add_child(_small_label("%d / 3" % stars))
		row.add_child(UiIcons.star(36))
		return
	if done:
		row.add_child(_small_label("+%d" % AddonData.REPLAY_COINS))
		row.add_child(UiIcons.plant_coin(34))
		return
	var reward: Dictionary = AddonData.STAGE_REWARDS[stage]
	for key in ["saplings", "moves", "rubies"]:
		if reward.get(key, 0) > 0:
			row.add_child(_small_label("+%d" % reward[key]))
			match key:
				"saplings":
					row.add_child(UiIcons.sapling(34))
				"moves":
					row.add_child(UiIcons.match_move(34))
				_:
					row.add_child(UiIcons.ruby(34))

func _small_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 22)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func _on_stage_pressed(stage: int) -> void:
	if not entry.has("help"):
		_start_stage(stage, false)
		return
	var panel := _open_popup(Vector2(700, 300), Lang.f("help_for_stage", [AddonData.help_text(entry)]))
	var play_btn := _button(Lang.t("play_without_help"), OK_BTN_COLOR, Vector2(30, 170), Vector2(300, 80))
	play_btn.pressed.connect(func(): _start_stage(stage, false))
	panel.add_child(play_btn)
	var cost: int = entry["help"]["cost"]
	var help_btn := _button(Lang.f("help_buy", [cost]), HELP_BTN_COLOR, Vector2(370, 170), Vector2(300, 80))
	help_btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	help_btn.add_theme_font_size_override("font_size", 20)
	help_btn.disabled = GameState.plant_coins < cost
	help_btn.pressed.connect(func(): _start_stage(stage, true))
	panel.add_child(help_btn)

func _start_stage(stage: int, with_help: bool) -> void:
	if entry["kind"] != "combat":
		if not GameState.start_rotation_minigame(kind, stage, with_help):
			get_tree().reload_current_scene()
			return
		get_tree().change_scene_to_file(SCENES[entry["kind"]])
		return
	if not GameState.start_rotation_game(kind, stage, with_help):
		get_tree().reload_current_scene()
		return
	get_tree().change_scene_to_file("res://scenes/Main.tscn" if entry["planting"] == "puzzle" else "res://scenes/PlantSelect.tscn")

# --- Mini-gry bez etapow ---
func _build_minigame() -> void:
	var data := GameState.rotation_data(kind)
	var info := ""
	var can_play := true
	match entry["kind"]:
		"memory":
			info = Lang.f("memory_info", [GameState.match_moves])
		"catch":
			info = _thresholds_text(AddonData.CATCH_THRESHOLDS, data)
		"sort_game":
			info = _thresholds_text(AddonData.SORT_THRESHOLDS, data)
		"quiz":
			can_play = GameState.is_quiz_ready()
			info = Lang.t("quiz_ready") if can_play else Lang.t("quiz_tomorrow")
	var info_label := _label(info, 24, Vector2(0, 290))
	content.add_child(info_label)
	var play_btn := _button(Lang.t("play_excl"), OK_BTN_COLOR, Vector2((VIEWPORT_WIDTH - 320) / 2.0, 380), Vector2(320, 100))
	play_btn.add_theme_font_size_override("font_size", 36)
	play_btn.disabled = not can_play
	play_btn.pressed.connect(func():
		GameState.start_rotation_minigame(kind, 0, false)
		get_tree().change_scene_to_file(SCENES[entry["kind"]]))
	content.add_child(play_btn)

func _thresholds_text(thresholds: Array, data: Dictionary) -> String:
	var reached: int = int(data.get("thresholds", 0))
	var best: int = int(data.get("best", 0))
	if reached >= thresholds.size():
		return Lang.f("score_all_done", [best])
	var next: Dictionary = thresholds[reached]
	return Lang.f("score_next", [best, next["score"], next["saplings"]])

# --- Album naklejek ---
func _build_album() -> void:
	var stickers := AddonData.album_stickers()
	var size := 64.0
	var gap := 10.0
	var per_row := AddonData.ALBUM_PAGE_SIZE
	var start_x := (VIEWPORT_WIDTH - (per_row * size + (per_row - 1) * gap)) / 2.0
	for i in range(stickers.size()):
		var row := int(i / float(per_row))
		var pos := Vector2(start_x + (i % per_row) * (size + gap), 240 + row * (size + 30))
		var count := int(GameState.album.get(stickers[i], 0))
		var icon: Control = Stickers.icon(stickers[i], size)
		if count <= 0:
			icon.modulate = Color(0.25, 0.25, 0.25, 0.6)
		icon.position = pos
		content.add_child(icon)
		if count > 1:
			var dup := _small_label("x%d" % count)
			dup.position = pos + Vector2(size - 22, size - 6)
			content.add_child(dup)
		if i % per_row == 0:
			var paid: bool = GameState.album_pages_paid.has(row)
			var page := _small_label(Lang.f("album_page", [row + 1]) + (" ✓" if paid else ""))
			page.position = Vector2(start_x - 150, pos.y + 18)
			content.add_child(page)
	var info := _label(Lang.f("album_info", [AddonData.ALBUM_PAGE_RUBIES]), 18, Vector2(0, 520))
	content.add_child(info)
	var trade_btn := _button(Lang.t("album_trade"), HELP_BTN_COLOR, Vector2((VIEWPORT_WIDTH - 420) / 2.0, 560), Vector2(420, 60))
	trade_btn.disabled = GameState.album_duplicates().is_empty()
	trade_btn.pressed.connect(func():
		NetSession.mode = NetSession.MODE_ALBUM
		get_tree().change_scene_to_file("res://scenes/TeamPlay.tscn"))
	content.add_child(trade_btn)

# --- Bingo ---
func _build_bingo() -> void:
	var card := GameState.bingo_card()
	var n := AddonData.BINGO_SIZE
	var start := Vector2((VIEWPORT_WIDTH - n * BINGO_CELL.x - (n - 1) * 8) / 2.0, 236)
	for i in range(card.size()):
		var task_idx: int = card[i]
		var task: Dictionary = AddonData.BINGO_TASKS[task_idx]
		var done := GameState.is_bingo_task_done(task_idx)
		var cell := _button("", DONE_COLOR if done else Color(0.95, 0.93, 0.85), start + Vector2((i % n) * (BINGO_CELL.x + 8), int(i / float(n)) * (BINGO_CELL.y + 8)), BINGO_CELL)
		content.add_child(cell)
		var text := _label(Lang.f("bingo_" + task["id"], [task["goal"]]), 16, Vector2(6, 4))
		UiIcons.wrap_label(text, Vector2(BINGO_CELL.x - 12, 50))
		text.add_theme_color_override("font_color", Color(1, 1, 1) if done else POPUP_TEXT_COLOR)
		cell.add_child(text)
		var progress := _label("%d / %d" % [min(GameState.bingo_count(task_idx), task["goal"]), task["goal"]], 16, Vector2(6, 56))
		progress.size.x = BINGO_CELL.x - 12
		progress.add_theme_color_override("font_color", Color(1, 1, 1) if done else Color(0.4, 0.35, 0.3))
		cell.add_child(progress)
		var cell_idx := i
		if not done:
			cell.pressed.connect(func(): _offer_bingo_swap(cell_idx))
	content.add_child(_label(Lang.f("bingo_info", [AddonData.BINGO_CARD_RUBIES]), 18, Vector2(0, 600)))

func _offer_bingo_swap(cell: int) -> void:
	var cost: int = entry["help"]["cost"]
	var panel := _open_popup(Vector2(700, 300), Lang.f("bingo_swap_question", [cost]))
	var no_btn := _button(Lang.t("back"), BACK_COLOR, Vector2(30, 170), Vector2(300, 80))
	no_btn.pressed.connect(_close_popup)
	panel.add_child(no_btn)
	var yes_btn := _button(Lang.f("help_buy_only", [cost]), HELP_BTN_COLOR, Vector2(370, 170), Vector2(300, 80))
	yes_btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	yes_btn.add_theme_font_size_override("font_size", 20)
	yes_btn.disabled = GameState.plant_coins < cost
	yes_btn.pressed.connect(func():
		GameState.swap_bingo_task(cell)
		get_tree().reload_current_scene())
	panel.add_child(yes_btn)

# --- Pojedynek ---
func _build_duel() -> void:
	content.add_child(_label(Lang.f("duel_week_info", [AddonData.DUEL_WEEK_RUBIES, AddonData.DUEL_WEEK_COINS]), 22, Vector2(0, 290)))
	var icon := UiIcons.multiplayer_icon(120, true)
	icon.position = Vector2((VIEWPORT_WIDTH - 120) / 2.0, 340)
	content.add_child(icon)
	var play_btn := _button(Lang.t("duel_play"), OK_BTN_COLOR, Vector2((VIEWPORT_WIDTH - 360) / 2.0, 480), Vector2(360, 90))
	play_btn.pressed.connect(func():
		NetSession.mode = NetSession.MODE_DUEL
		NetSession.mode_chosen = true
		get_tree().change_scene_to_file("res://scenes/TeamPlay.tscn"))
	content.add_child(play_btn)

# --- Okienka ---
func _open_popup(panel_size: Vector2, text: String) -> Panel:
	_close_popup()
	popup = Control.new()
	popup.size = Vector2(VIEWPORT_WIDTH, VIEWPORT_HEIGHT)
	add_child(popup)
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.6)
	shade.size = popup.size
	shade.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed:
			_close_popup())
	popup.add_child(shade)
	var panel := Panel.new()
	panel.size = panel_size
	panel.position = (popup.size - panel_size) / 2.0
	var sb := UiIcons.round_style(POPUP_BG_COLOR, 18)
	sb.set_border_width_all(5)
	sb.border_color = Color(0.25, 0.2, 0.15)
	panel.add_theme_stylebox_override("panel", sb)
	popup.add_child(panel)
	var question := _label(text, 24, Vector2(20, 30))
	UiIcons.wrap_label(question, Vector2(panel_size.x - 40, 120))
	question.add_theme_color_override("font_color", POPUP_TEXT_COLOR)
	panel.add_child(question)
	return panel

func _close_popup() -> void:
	if popup != null:
		popup.queue_free()
		popup = null
