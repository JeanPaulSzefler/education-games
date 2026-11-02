extends Control

# Ogrod (wydarzenie stale): 8 pol z ziemia. Gracz sadzi sadzonke, podlewa ja i
# czeka 15 godzin, a sadzonka powoli zmienia sie w dorosla roslinke. Gotowa
# roslinka swieci na teczowo i czeka, az gracz ja tapnie: wtedy daje 50
# roslimonet i ruch do Roslinnych trojek, i znika. Czas przyspiesza 15 rubinow
# albo pszczolka. Stan pol i czasy trzyma GameState.

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
const GROWN_SIZE := 130.0
# Wysokosc roslinki z ziemia: od sadzonki sprzed podlania do doroslej (GROWN_SIZE).
const SAPLING_HEIGHT := 72.0
# Jaka czesc wysokosci obrazka zajmuje roslinka z ziemia na etapach 1 i 2
# (kwadratowe obrazki z ziemia przy dolnej krawedzi, GRAFIKI_PROMPTY_6.md).
const GARDEN_STAGE_FILLS := [0.6, 0.85]
const GLOW_SIZE := 180.0
const REWARD_ICON_SIZE := 36.0
const BEE_SIZE := 80.0
const BEE_Y := 500.0
const BEE_FLIGHT_TIME := 1.2
const BEE_SIT_SWINGS := 3
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
var moves_label: Label
# Etykiety licznikow: indeks pola -> Label.
var timer_labels := {}
# Etapy wzrostu na rosnacych polach: indeks pola -> Array
# {"node", "fill" (czesc wysokosci obrazka z roslinka), "gap" (pusty pasek pod nia)}.
var growth_views := {}
var bee: Button
var bee_tween: Tween
var popup: Control
var tick := 0.0

func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.2, 0.36, 0.18)
	bg.size = Vector2(VIEWPORT_WIDTH, VIEWPORT_HEIGHT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	add_child(_label("Ogrod", 44, Vector2(0, 24), VIEWPORT_WIDTH))

	var move_icon := UiIcons.match_move(40)
	move_icon.position = Vector2(810, 34)
	add_child(move_icon)
	moves_label = _label("", 30, Vector2(856, 30), 90)
	moves_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	add_child(moves_label)

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
	_check_ready_plots()
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
	_check_ready_plots()
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
	moves_label.text = str(GameState.match_moves)
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
	growth_views.clear()
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
				_build_growth(btn, i)
				var timer := _label("", 22, Vector2(0, PLOT_SIZE.y - 38), PLOT_SIZE.x)
				btn.add_child(timer)
				timer_labels[i] = timer
			GameState.PLOT_READY:
				_build_ready_plant(btn)
		btn.pressed.connect(_on_plot_pressed.bind(i))
		plots_layer.add_child(btn)

# Wzrost: sadzonka powoli przechodzi w kolejne etapy (GRAFIKI_PROMPTY_6.md),
# az do doroslej roslinki, i przy tym rosnie. Bez grafik etapow sadzonka
# przenika sie wprost z dorosla roslinka.
func _build_growth(btn: Button, i: int) -> void:
	var stages := [_growth_layer(UiIcons.sapling(GROWN_SIZE))]
	for k in range(UiIcons.GARDEN_STAGE_TEXTURES.size()):
		var path: String = UiIcons.GARDEN_STAGE_TEXTURES[k]
		if ResourceLoader.exists(path):
			stages.append({"node": UiIcons.texture_from(path, GROWN_SIZE), "fill": GARDEN_STAGE_FILLS[k], "gap": 0.0})
	stages.append(_growth_layer(UiIcons.plant_icon_tinted(GROWN_PLANT_IDX, GROWN_SIZE, GROWN_TINT)))
	for stage in stages:
		var node: Control = stage["node"]
		# Roslinka rosnie od ziemi w gore.
		node.pivot_offset = Vector2(GROWN_SIZE / 2.0, GROWN_SIZE)
		btn.add_child(node)
	growth_views[i] = stages
	_update_growth(i)

# Obrazek przyciety do tresci wypelnia kwadrat na szerokosc albo wysokosc. Szeroki
# (np. sadzonka) stoi na srodku kwadratu, wiec pod roslinka zostaje pusty pasek.
func _growth_layer(node: Control) -> Dictionary:
	if node is TextureRect and node.texture != null:
		var tex_size: Vector2 = node.texture.get_size()
		if tex_size.x > tex_size.y:
			var fill := tex_size.y / tex_size.x
			return {"node": node, "fill": fill, "gap": (1.0 - fill) / 2.0}
	return {"node": node, "fill": 1.0, "gap": 0.0}

# Wszystkie etapy maja te sama, rosnaca wysokosc roslinki z ziemia, a ziemia stoi
# w tym samym miejscu, wiec przenikanie etapow nie skacze.
func _update_growth(i: int) -> void:
	var stages: Array = growth_views[i]
	var growth := GameState.plot_growth(i)
	var height := lerpf(SAPLING_HEIGHT, GROWN_SIZE, growth)
	var progress := growth * (stages.size() - 1)
	var current := mini(int(progress), stages.size() - 2)
	var blend := progress - current
	for s in range(stages.size()):
		var alpha := 0.0
		if s == current:
			alpha = 1.0 - blend
		elif s == current + 1:
			alpha = blend
		var node: Control = stages[s]["node"]
		var scale_factor: float = height / (GROWN_SIZE * stages[s]["fill"])
		node.modulate.a = alpha
		node.scale = Vector2.ONE * scale_factor
		node.position = Vector2((PLOT_SIZE.x - GROWN_SIZE) / 2.0,
			PLOT_SIZE.y - GROWN_SIZE - 34 + stages[s]["gap"] * GROWN_SIZE * scale_factor)

# Gotowa roslinka: teczowa poswiata i nagrody, ktore gracz zbiera tapnieciem.
func _build_ready_plant(btn: Button) -> void:
	var glow := UiIcons.rainbow_glow(Vector2(GLOW_SIZE, GLOW_SIZE))
	glow.position = Vector2((PLOT_SIZE.x - GLOW_SIZE) / 2.0, -14)
	glow.pivot_offset = glow.size / 2.0
	btn.add_child(glow)
	var tw := glow.create_tween().set_loops()
	tw.tween_property(glow, "scale", Vector2(1.08, 1.08), 0.6).set_trans(Tween.TRANS_SINE)
	tw.tween_property(glow, "scale", Vector2.ONE, 0.6).set_trans(Tween.TRANS_SINE)

	var plant := UiIcons.plant_icon_tinted(GROWN_PLANT_IDX, GROWN_SIZE, GROWN_TINT)
	plant.position = Vector2((PLOT_SIZE.x - GROWN_SIZE) / 2.0, 0)
	btn.add_child(plant)

	var reward_y := PLOT_SIZE.y - REWARD_ICON_SIZE - 6
	var coin := UiIcons.plant_coin(REWARD_ICON_SIZE)
	coin.position = Vector2(12, reward_y)
	btn.add_child(coin)
	var coin_text := _label("+%d" % GameState.GARDEN_HARVEST_COINS, 22, Vector2(12 + REWARD_ICON_SIZE, reward_y - 2), 60)
	coin_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.add_child(coin_text)
	var move := UiIcons.match_move(REWARD_ICON_SIZE)
	move.position = Vector2(110, reward_y)
	btn.add_child(move)
	var move_text := _label("+%d" % GameState.GARDEN_HARVEST_MOVES, 22, Vector2(110 + REWARD_ICON_SIZE, reward_y - 2), 40)
	move_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.add_child(move_text)

func _plot_position(i: int) -> Vector2:
	return Vector2(
		PLOTS_X + (i % PLOTS_PER_ROW) * (PLOT_SIZE.x + PLOT_GAP),
		PLOTS_Y + int(i / float(PLOTS_PER_ROW)) * (PLOT_SIZE.y + PLOT_GAP)
	)

func _update_timers() -> void:
	for i in timer_labels.keys():
		var left := GameState.plot_seconds_left(i)
		timer_labels[i].text = "%02d:%02d:%02d" % [left / 3600, (left % 3600) / 60, left % 60]
	for i in growth_views.keys():
		_update_growth(i)

func _on_plot_pressed(i: int) -> void:
	var state: String = GameState.garden_plots[i]["state"]
	# Nagrody z gotowej roslinki zbiera sie tapnieciem, niezaleznie od narzedzia.
	if state == GameState.PLOT_READY:
		_collect(i)
		return
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
	bee.pivot_offset = bee.size / 2.0
	bee.add_child(UiIcons.bee(BEE_SIZE))
	bee.pressed.connect(func(): _select_tool(TOOL_BEE))
	add_child(bee)
	bee_tween = bee.create_tween()
	bee_tween.set_loops()
	bee_tween.tween_property(bee, "position:x", PLOTS_X + 3.0 * PLOT_SIZE.x, 6.0).set_trans(Tween.TRANS_SINE)
	bee_tween.tween_property(bee, "position:x", PLOTS_X, 6.0).set_trans(Tween.TRANS_SINE)

# Przyspieszenie liczy sie od razu, a pszczolka podlatuje do roslinki, siada na
# niej i dopiero potem odlatuje. Do jej powrotu nie mozna jej znowu uzyc.
func _use_bee(i: int, state: String) -> void:
	if state != GameState.PLOT_GROWING:
		message_label.text = "Pszczolka pomaga tylko rosnacym roslinkom."
		return
	GameState.use_bee(i)
	tool = TOOL_NONE
	message_label.text = "Pszczolka leci do roslinki..."
	_build_tools()
	_fly_bee_to_plot(i)

func _fly_bee_to_plot(i: int) -> void:
	var visiting := bee
	bee = null
	visiting.disabled = true
	bee_tween.kill()
	var seat := _plot_position(i) + Vector2((PLOT_SIZE.x - BEE_SIZE) / 2.0, 10)
	var tw := visiting.create_tween()
	tw.tween_property(visiting, "position", seat, BEE_FLIGHT_TIME).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(func():
		message_label.text = "Pszczolka przyspieszyla roslinke o 3 godziny!"
		_refresh()
		_check_ready_plots())
	for _swing in range(BEE_SIT_SWINGS):
		tw.tween_property(visiting, "rotation", 0.15, 0.35).set_trans(Tween.TRANS_SINE)
		tw.tween_property(visiting, "rotation", -0.15, 0.35).set_trans(Tween.TRANS_SINE)
	tw.tween_property(visiting, "rotation", 0.0, 0.2)
	tw.tween_property(visiting, "position", Vector2(VIEWPORT_WIDTH + BEE_SIZE, -BEE_SIZE), BEE_FLIGHT_TIME)
	tw.tween_callback(visiting.queue_free)

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
			_check_ready_plots())
	panel.add_child(yes_btn)

func _close_popup() -> void:
	if popup != null:
		popup.queue_free()
		popup = null

# --- Zbior: gotowa roslinka czeka na tapniecie, a potem daje nagrody i znika ---
func _check_ready_plots() -> void:
	if GameState.mark_ready_plots().is_empty():
		return
	message_label.text = "Roslinka wyrosla! Tapnij ja, zeby zebrac nagrody."
	_refresh()

func _collect(i: int) -> void:
	if not GameState.collect_plot(i):
		return
	var origin := _plot_position(i)
	message_label.text = "+%d roslimonet i +%d ruch do Roslinnych trojek!" % [GameState.GARDEN_HARVEST_COINS, GameState.GARDEN_HARVEST_MOVES]

	# Roslinka maleje i znika, a nagrody leca do licznikow u gory.
	var plant := UiIcons.plant_icon_tinted(GROWN_PLANT_IDX, GROWN_SIZE, GROWN_TINT)
	plant.position = origin + Vector2((PLOT_SIZE.x - GROWN_SIZE) / 2.0, 0)
	plant.pivot_offset = Vector2(GROWN_SIZE / 2.0, GROWN_SIZE)
	add_child(plant)
	var tw := plant.create_tween().set_parallel(true)
	tw.tween_property(plant, "scale", Vector2(0.2, 0.2), 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tw.tween_property(plant, "modulate:a", 0.0, 0.5)
	tw.chain().tween_callback(plant.queue_free)

	var reward_y := PLOT_SIZE.y - REWARD_ICON_SIZE - 6
	_fly_reward(UiIcons.plant_coin(REWARD_ICON_SIZE), origin + Vector2(12, reward_y), Vector2(962, 36))
	_fly_reward(UiIcons.match_move(REWARD_ICON_SIZE), origin + Vector2(110, reward_y), Vector2(812, 36))
	_refresh()

func _fly_reward(icon: Control, from: Vector2, to: Vector2) -> void:
	icon.position = from
	add_child(icon)
	var tw := icon.create_tween()
	tw.tween_property(icon, "position", to, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.tween_callback(icon.queue_free)
