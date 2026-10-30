extends Control

# Ogrod (wydarzenie stale): 8 pol z ziemia. Gracz sadzi sadzonke, podlewa ja i
# czeka 15 godzin; dorosla roslinka daje 50 roslimonet i znika. Czas przyspiesza
# 15 rubinow albo pszczolka. Stan pol i czasy trzyma GameState.

const VIEWPORT_WIDTH := 1280
const VIEWPORT_HEIGHT := 720
const PLOT_SIZE := Vector2(190, 170)
const PLOT_GAP := 20.0
const PLOTS_X := 290.0
const PLOTS_Y := 110.0
const PLOTS_PER_ROW := 4
const TOOL_SIZE := Vector2(210, 110)
const TOOL_X := 40.0
const SOIL_COLOR := Color(0.36, 0.24, 0.13)
const TOOL_COLOR := Color(0.3, 0.45, 0.25)
const TOOL_ACTIVE_COLOR := Color(0.85, 0.7, 0.15)
const OK_BTN_COLOR := Color(0.25, 0.6, 0.25)
const POPUP_BG_COLOR := Color(0.95, 0.93, 0.85)
const POPUP_TEXT_COLOR := Color(0.15, 0.12, 0.1)
# Ten sam rysunek co Pokrzywa, ale jasnofioletowy.
const GROWN_PLANT_IDX := 3
const GROWN_TINT := Color(0.85, 0.7, 1.0)
const BEE_SIZE := 80.0
const BEE_Y := 500.0
const TOOL_NONE := ""
const TOOL_SAPLING := "sapling"
const TOOL_WATER := "water"
const TOOL_BEE := "bee"

var tool := TOOL_NONE
var plots_layer: Control
var tools_layer: Control
var message_label: Label
var coin_label: Label
var ruby_label: Label
# Etykiety licznikow: indeks pola -> Label.
var timer_labels := {}
var bee: Button
var popup: Control
var tick := 0.0

func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.2, 0.36, 0.18)
	bg.size = Vector2(VIEWPORT_WIDTH, VIEWPORT_HEIGHT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	add_child(_label("Ogrod", 44, Vector2(0, 24), VIEWPORT_WIDTH))

	var coin_icon := UiIcons.plant_coin(40)
	coin_icon.position = Vector2(960, 34)
	add_child(coin_icon)
	coin_label = _label("", 30, Vector2(1006, 30), 90)
	coin_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	add_child(coin_label)
	var ruby_icon := UiIcons.ruby(40)
	ruby_icon.position = Vector2(1110, 34)
	add_child(ruby_icon)
	ruby_label = _label("", 30, Vector2(1156, 30), 90)
	ruby_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	add_child(ruby_label)

	tools_layer = Control.new()
	tools_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(tools_layer)
	plots_layer = Control.new()
	plots_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(plots_layer)

	message_label = _label("", 24, Vector2(0, 590), VIEWPORT_WIDTH)
	add_child(message_label)

	var back_btn := _button("Wroc", TOOL_COLOR, Vector2(40, 620), Vector2(210, 70))
	back_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/LevelSelect.tscn"))
	add_child(back_btn)

	_refresh()
	_harvest_ready_plots()
	_build_shared_controls()

# Tydzien Low: gracz wybiera, czy sadzi razem ze znajomym. Gdy tak, na ekranie
# jest przycisk polaczenia ze znajomym.
func _build_shared_controls() -> void:
	if not GameState.is_shared_garden_offered():
		return
	if GameState.shared_choice == "":
		_show_shared_question()
		return
	if not GameState.is_shared_garden_on():
		return
	var btn := _button("Sadzimy razem", OK_BTN_COLOR, Vector2(TOOL_X, PLOTS_Y + 2.0 * (TOOL_SIZE.y + PLOT_GAP)), TOOL_SIZE)
	btn.pressed.connect(func():
		NetSession.mode = NetSession.MODE_GARDEN
		get_tree().change_scene_to_file("res://scenes/TeamPlay.tscn"))
	add_child(btn)
	GameState.try_pay_shared_goal()

func _show_shared_question() -> void:
	var panel := _open_popup_panel("W tym tygodniu mozesz sadzic razem ze znajomym: wspolny cel, wymiana sadzonek i 2 razy wieksza nagroda. Zatwierdzasz?")
	var no_btn := _button("Nie", TOOL_COLOR, Vector2(50, 190), Vector2(240, 70))
	no_btn.pressed.connect(func():
		GameState.set_shared_choice(false)
		_close_popup())
	panel.add_child(no_btn)
	var yes_btn := _button("Zatwierdzam", OK_BTN_COLOR, Vector2(panel.size.x - 290, 190), Vector2(240, 70))
	yes_btn.pressed.connect(func():
		GameState.set_shared_choice(true)
		_close_popup()
		_build_shared_controls())
	panel.add_child(yes_btn)

func _open_popup_panel(text: String) -> Panel:
	popup = Control.new()
	popup.size = Vector2(VIEWPORT_WIDTH, VIEWPORT_HEIGHT)
	add_child(popup)
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.6)
	shade.size = popup.size
	popup.add_child(shade)

	var panel := Panel.new()
	panel.size = Vector2(620, 290)
	panel.position = (popup.size - panel.size) / 2.0
	var sb := UiIcons.round_style(POPUP_BG_COLOR, 18)
	sb.set_border_width_all(5)
	sb.border_color = Color(0.25, 0.2, 0.15)
	panel.add_theme_stylebox_override("panel", sb)
	popup.add_child(panel)

	var question := _label(text, 24, Vector2(20, 30), panel.size.x - 40)
	question.size.y = 150
	question.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	question.add_theme_color_override("font_color", POPUP_TEXT_COLOR)
	panel.add_child(question)
	return panel

func _process(delta: float) -> void:
	tick -= delta
	if tick > 0.0:
		return
	tick = 1.0
	_harvest_ready_plots()
	_update_timers()
	if bee == null and GameState.is_bee_here():
		_spawn_bee()

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

func _refresh() -> void:
	coin_label.text = str(GameState.plant_coins)
	ruby_label.text = str(GameState.rubies)
	_build_tools()
	_build_plots()
	_update_timers()

# --- Narzedzia po lewej: sadzonki i kropelka ---
func _build_tools() -> void:
	for child in tools_layer.get_children():
		child.queue_free()
	var sapling_btn := _button("", TOOL_ACTIVE_COLOR if tool == TOOL_SAPLING else TOOL_COLOR, Vector2(TOOL_X, PLOTS_Y), TOOL_SIZE)
	var sapling_icon := UiIcons.sapling(86)
	sapling_icon.position = Vector2(12, 12)
	sapling_btn.add_child(sapling_icon)
	sapling_btn.add_child(_label("x %d" % GameState.saplings, 30, Vector2(104, 34), 96))
	sapling_btn.pressed.connect(func(): _select_tool(TOOL_SAPLING))
	tools_layer.add_child(sapling_btn)

	var water_btn := _button("", TOOL_ACTIVE_COLOR if tool == TOOL_WATER else TOOL_COLOR, Vector2(TOOL_X, PLOTS_Y + TOOL_SIZE.y + PLOT_GAP), TOOL_SIZE)
	var drop := TextureRect.new()
	drop.texture = load("res://assets/sprites/ui/water_drop.png")
	drop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	drop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	drop.size = Vector2(86, 86)
	drop.position = Vector2((TOOL_SIZE.x - 86) / 2.0, 12)
	drop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	water_btn.add_child(drop)
	water_btn.pressed.connect(func(): _select_tool(TOOL_WATER))
	tools_layer.add_child(water_btn)

func _select_tool(new_tool: String) -> void:
	tool = TOOL_NONE if tool == new_tool else new_tool
	if tool == TOOL_SAPLING and GameState.saplings <= 0:
		tool = TOOL_NONE
		message_label.text = "Nie masz sadzonek - zdobedziesz je w wydarzeniach."
	elif tool == TOOL_SAPLING:
		message_label.text = "Tapnij puste pole, zeby posadzic sadzonke."
	elif tool == TOOL_WATER:
		message_label.text = "Tapnij sadzonke, zeby ja podlac."
	elif tool == TOOL_BEE:
		message_label.text = "Tapnij rosnaca roslinke, zeby posadzic na niej pszczolke."
	else:
		message_label.text = ""
	_build_tools()

# --- Pola ---
func _build_plots() -> void:
	for child in plots_layer.get_children():
		child.queue_free()
	timer_labels.clear()
	for i in range(GameState.GARDEN_PLOTS):
		var btn := _button("", SOIL_COLOR, _plot_position(i), PLOT_SIZE)
		var soil := UiIcons.soil_plot(PLOT_SIZE)
		if soil != null:
			btn.add_child(soil)
		var plot: Dictionary = GameState.garden_plots[i]
		match plot["state"]:
			GameState.PLOT_SAPLING:
				var sapling := UiIcons.sapling(90)
				sapling.position = (PLOT_SIZE - sapling.size) / 2.0
				btn.add_child(sapling)
			GameState.PLOT_GROWING:
				var plant_size := lerpf(70.0, 120.0, GameState.plot_growth(i))
				var plant := UiIcons.plant_icon_tinted(GROWN_PLANT_IDX, plant_size, GROWN_TINT)
				plant.position = Vector2((PLOT_SIZE.x - plant_size) / 2.0, PLOT_SIZE.y - plant_size - 34)
				btn.add_child(plant)
				var timer := _label("", 22, Vector2(0, PLOT_SIZE.y - 38), PLOT_SIZE.x)
				btn.add_child(timer)
				timer_labels[i] = timer
		btn.pressed.connect(_on_plot_pressed.bind(i))
		plots_layer.add_child(btn)

func _plot_position(i: int) -> Vector2:
	return Vector2(
		PLOTS_X + (i % PLOTS_PER_ROW) * (PLOT_SIZE.x + PLOT_GAP),
		PLOTS_Y + int(i / float(PLOTS_PER_ROW)) * (PLOT_SIZE.y + PLOT_GAP)
	)

func _update_timers() -> void:
	for i in timer_labels.keys():
		var left := GameState.plot_seconds_left(i)
		timer_labels[i].text = "%02d:%02d:%02d" % [left / 3600, (left % 3600) / 60, left % 60]

func _on_plot_pressed(i: int) -> void:
	var state: String = GameState.garden_plots[i]["state"]
	match tool:
		TOOL_SAPLING:
			if state != GameState.PLOT_EMPTY:
				message_label.text = "To pole jest zajete."
				return
			GameState.plant_sapling(i)
			if GameState.saplings <= 0:
				tool = TOOL_NONE
			message_label.text = "Teraz wybierz kropelke i podlej sadzonke."
			_refresh()
		TOOL_WATER:
			if state != GameState.PLOT_SAPLING:
				message_label.text = "Tu nie ma sadzonki do podlania."
				return
			GameState.water_plot(i)
			message_label.text = "Roslinka rosnie!"
			_refresh()
		TOOL_BEE:
			_use_bee(i, state)
		_:
			if state == GameState.PLOT_GROWING:
				_show_rush_popup(i)
			elif state == GameState.PLOT_SAPLING:
				message_label.text = "Wybierz kropelke, zeby podlac sadzonke."
			else:
				message_label.text = "Wybierz sadzonke, zeby ja tu posadzic."

# --- Pszczolka ---
func _spawn_bee() -> void:
	bee = Button.new()
	bee.flat = true
	bee.size = Vector2(BEE_SIZE, BEE_SIZE)
	bee.position = Vector2(PLOTS_X, BEE_Y)
	bee.focus_mode = Control.FOCUS_NONE
	bee.add_child(UiIcons.bee(BEE_SIZE))
	bee.pressed.connect(func(): _select_tool(TOOL_BEE))
	add_child(bee)
	var tw := bee.create_tween()
	tw.set_loops()
	tw.tween_property(bee, "position:x", PLOTS_X + 3.0 * PLOT_SIZE.x, 6.0).set_trans(Tween.TRANS_SINE)
	tw.tween_property(bee, "position:x", PLOTS_X, 6.0).set_trans(Tween.TRANS_SINE)

func _use_bee(i: int, state: String) -> void:
	if state != GameState.PLOT_GROWING:
		message_label.text = "Pszczolka pomaga tylko rosnacym roslinkom."
		return
	GameState.use_bee(i)
	tool = TOOL_NONE
	message_label.text = "Pszczolka przyspieszyla roslinke o 3 godziny!"
	_fly_bee_away()
	_refresh()
	_harvest_ready_plots()

func _fly_bee_away() -> void:
	var leaving := bee
	bee = null
	leaving.disabled = true
	var tw := leaving.create_tween()
	tw.tween_property(leaving, "position", Vector2(VIEWPORT_WIDTH + BEE_SIZE, -BEE_SIZE), 1.0)
	tw.tween_callback(leaving.queue_free)

# --- Przyspieszanie za rubiny ---
func _show_rush_popup(i: int) -> void:
	var panel := _open_popup_panel("Przyspieszyc te roslinke za %d rubinow?" % GameState.GARDEN_RUSH_RUBIES)

	var no_btn := _button("Wroc", TOOL_COLOR, Vector2(50, 190), Vector2(240, 70))
	no_btn.pressed.connect(_close_popup)
	panel.add_child(no_btn)

	var yes_btn := _button("Przyspiesz", OK_BTN_COLOR, Vector2(panel.size.x - 290, 190), Vector2(240, 70))
	yes_btn.disabled = GameState.rubies < GameState.GARDEN_RUSH_RUBIES
	yes_btn.pressed.connect(func():
		_close_popup()
		if GameState.rush_plot(i):
			_refresh()
			_harvest_ready_plots())
	panel.add_child(yes_btn)

func _close_popup() -> void:
	if popup != null:
		popup.queue_free()
		popup = null

# --- Zbior: dorosla roslinka pokazuje sie, daje roslimonety i znika ---
func _harvest_ready_plots() -> void:
	var ready_plots := GameState.harvest_ready_plots()
	if ready_plots.is_empty():
		return
	for i in ready_plots:
		_show_harvest(i)
	message_label.text = "Roslinka wyrosla! +%d roslimonet" % (GameState.GARDEN_HARVEST_COINS * ready_plots.size())
	_refresh()

func _show_harvest(i: int) -> void:
	var box := Control.new()
	box.size = PLOT_SIZE
	box.position = _plot_position(i)
	box.pivot_offset = PLOT_SIZE / 2.0
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(box)
	var plant := UiIcons.plant_icon_tinted(GROWN_PLANT_IDX, 130, GROWN_TINT)
	plant.position = Vector2((PLOT_SIZE.x - 130) / 2.0, 0)
	box.add_child(plant)
	box.add_child(_label("+%d" % GameState.GARDEN_HARVEST_COINS, 28, Vector2(10, PLOT_SIZE.y - 44), 100))
	var coin := UiIcons.plant_coin(40)
	coin.position = Vector2(114, PLOT_SIZE.y - 44)
	box.add_child(coin)
	box.scale = Vector2(0.2, 0.2)
	var tw := box.create_tween()
	tw.tween_property(box, "scale", Vector2(1, 1), 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(1.5)
	tw.tween_property(box, "modulate:a", 0.0, 0.5)
	tw.tween_callback(box.queue_free)
