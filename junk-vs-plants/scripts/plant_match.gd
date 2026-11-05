extends Control

# Roslinne trojki (wydarzenie stale, przycisk u gory sciezki): plansza pelna
# wszystkich roslin, bez smieciostworow. Ruch to zamiana dwoch sasiednich
# roslinek, po ktorej co najmniej 3 takie same stoja w jednym rzedzie albo
# kolumnie. Znika wtedy cala grupa stykajacych sie takich roslinek, a roslina
# dostaje punkty (GameState.match_group_points); 8 punktow to jej darmowe
# ulepszenie. Na puste miejsca spadaja roslinki z gory, a nowe trojki znikaja
# same, bez zuzywania ruchu. Ruchy daja skrzynie i ogrod.

const VIEWPORT_WIDTH := 1280
const VIEWPORT_HEIGHT := 720
const BOARD_POS := Vector2(480, 124)
const CELL := 94.0
const ICON_PAD := 8.0
const COUNTER_POS := Vector2(16, 124)
const COUNTER_SIZE := Vector2(222, 74)
const COUNTER_GAP := Vector2(8, 6)
const COUNTERS_PER_COLUMN := 7
# Przesuniecie palcem o tyle pikseli to juz zamiana, a nie tapniecie.
const SWIPE_MIN := 30.0
const SWAP_TIME := 0.18
const VANISH_TIME := 0.22
const FALL_TIME := 0.28
const BG_COLOR := Color(0.15, 0.25, 0.15)
const CELL_COLOR_A := Color(0.36, 0.5, 0.26)
const CELL_COLOR_B := Color(0.32, 0.45, 0.23)
const COUNTER_COLOR := Color(0.22, 0.32, 0.2)
const SELECT_COLOR := Color(0.98, 0.85, 0.2)
const POINTS_BAR_COLOR := Color(0.98, 0.75, 0.15)
const BTN_COLOR := Color(0.3, 0.45, 0.25)
const NO_MOVES_COLOR := Color(1.0, 0.4, 0.35)

var cols: int = GameState.MATCH_COLS
var rows: int = GameState.MATCH_ROWS
# Indeksy roslin wierszami; -1 = puste pole w trakcie spadania.
var board: Array = []
# Rysunki roslinek na planszy, w tej samej kolejnosci co board.
var nodes: Array = []
var board_area: Control
var select_frame: Panel
var selected := -1
# Trwa animacja - plansza nie reaguje na tapniecia.
var busy := false
var press_cell := -1
var press_pos := Vector2.ZERO
var moves_label: Label
var message_label: Label
# plant_idx -> Panel licznika po lewej.
var counters := {}

func _ready() -> void:
	add_child(UiIcons.screen_background("leaves"))

	add_child(_label(Lang.t("plant_match"), 40, Vector2(0, 10), VIEWPORT_WIDTH))
	message_label = _label(Lang.t("match_hint"), 17, Vector2(BOARD_POS.x, 72), cols * CELL)
	# Dluzsze komunikaty lamia sie na dwie linijki nad plansza.
	message_label.size.y = BOARD_POS.y - 74
	UiIcons.wrap_label(message_label, Vector2(cols * CELL, message_label.size.y))
	message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(message_label)

	var back_btn := Button.new()
	back_btn.text = Lang.t("back")
	back_btn.position = Vector2(20, 16)
	back_btn.size = Vector2(160, 64)
	back_btn.focus_mode = Control.FOCUS_NONE
	back_btn.add_theme_font_size_override("font_size", 24)
	UiIcons.style_button(back_btn, BTN_COLOR, 16)
	back_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/LevelSelect.tscn"))
	add_child(back_btn)

	var move_icon := UiIcons.match_move(56)
	move_icon.position = Vector2(VIEWPORT_WIDTH - 190, 18)
	add_child(move_icon)
	moves_label = _label("", 32, Vector2(VIEWPORT_WIDTH - 126, 22), 110)
	moves_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	add_child(moves_label)

	var order := PlantData.unlock_order()
	for slot in range(order.size()):
		_build_counter(order[slot], slot)
	_build_board_area()

	# Plansza zostaje miedzy wejsciami, zeby nie dalo sie losowac lepszej.
	board = GameState.match_board.duplicate()
	if board.size() != cols * rows or not _find_groups(board).is_empty() or not _has_valid_move(board):
		board = _new_board()
		GameState.save_match_board(board)
	_build_pieces()
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

func _update_moves() -> void:
	moves_label.text = "x %d" % GameState.match_moves

# --- Liczniki po lewej: punkty (0-7) i poziom ulepszenia kazdej rosliny ---
func _build_counter(plant_idx: int, slot: int) -> void:
	var panel := Panel.new()
	var col := int(slot / float(COUNTERS_PER_COLUMN))
	var row := slot % COUNTERS_PER_COLUMN
	panel.position = COUNTER_POS + Vector2(col * (COUNTER_SIZE.x + COUNTER_GAP.x), row * (COUNTER_SIZE.y + COUNTER_GAP.y))
	panel.size = COUNTER_SIZE
	panel.pivot_offset = COUNTER_SIZE / 2.0
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", UiIcons.round_style(COUNTER_COLOR, 12))
	add_child(panel)
	counters[plant_idx] = panel
	_refresh_counter(plant_idx, false)

func _refresh_counter(plant_idx: int, flash: bool) -> void:
	var panel: Panel = counters[plant_idx]
	for child in panel.get_children():
		child.queue_free()
	var icon := UiIcons.plant_icon(plant_idx, 60)
	icon.position = Vector2(6, 7)
	panel.add_child(icon)
	var name_label := _label(PlantData.name_of(plant_idx), 14, Vector2(72, 0), COUNTER_SIZE.x - 78)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	panel.add_child(name_label)

	var level := GameState.plant_upgrade_level(plant_idx)
	if level >= GameState.PLANT_UPGRADE_MAX_LEVEL:
		var max_label := _label(Lang.t("match_full_upgrade"), 14, Vector2(72, 22), COUNTER_SIZE.x - 78)
		max_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		max_label.add_theme_color_override("font_color", POINTS_BAR_COLOR)
		panel.add_child(max_label)
	else:
		var points := GameState.match_points_of(plant_idx)
		var points_bar := UiIcons.segment_bar(Vector2(100, 18), points, GameState.MATCH_POINTS_PER_UPGRADE, POINTS_BAR_COLOR)
		points_bar.position = Vector2(72, 26)
		panel.add_child(points_bar)
		var points_label := _label(str(points), 24, Vector2(176, 14), 40)
		points_label.add_theme_color_override("font_color", POINTS_BAR_COLOR)
		panel.add_child(points_label)
	var upgrade_bar := UiIcons.segment_bar(Vector2(140, 14), level, GameState.PLANT_UPGRADE_MAX_LEVEL)
	upgrade_bar.position = Vector2(72, 52)
	panel.add_child(upgrade_bar)

	if flash:
		var tw := panel.create_tween()
		tw.tween_property(panel, "scale", Vector2(1.08, 1.08), 0.12)
		tw.tween_property(panel, "scale", Vector2.ONE, 0.18)

# --- Plansza ---
func _build_board_area() -> void:
	board_area = Control.new()
	board_area.position = BOARD_POS
	board_area.size = Vector2(cols, rows) * CELL
	# Nowe roslinki spadaja z gory spoza planszy - nie moga byc widoczne nad nia.
	board_area.clip_contents = true
	board_area.gui_input.connect(_on_board_input)
	add_child(board_area)
	for i in range(cols * rows):
		var cell: Control = UiIcons.match_cell(CELL)
		if cell == null:
			var rect := ColorRect.new()
			rect.color = CELL_COLOR_A if (_col(i) + _row(i)) % 2 == 0 else CELL_COLOR_B
			rect.size = Vector2(CELL, CELL)
			rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
			cell = rect
		cell.position = _cell_pos(i)
		board_area.add_child(cell)

	select_frame = Panel.new()
	select_frame.size = Vector2(CELL, CELL)
	select_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := UiIcons.round_style(Color(1, 1, 1, 0.15), 12)
	sb.set_border_width_all(5)
	sb.border_color = SELECT_COLOR
	select_frame.add_theme_stylebox_override("panel", sb)
	select_frame.visible = false
	board_area.add_child(select_frame)

func _col(i: int) -> int:
	return i % cols

func _row(i: int) -> int:
	return int(i / float(cols))

func _cell_pos(i: int) -> Vector2:
	return Vector2(_col(i), _row(i)) * CELL

func _cell_at(pos: Vector2) -> int:
	var col := int(pos.x / CELL)
	var row := int(pos.y / CELL)
	if pos.x < 0 or pos.y < 0 or col >= cols or row >= rows:
		return -1
	return row * cols + col

func _neighbors(i: int) -> Array:
	var result := []
	if _col(i) > 0:
		result.append(i - 1)
	if _col(i) < cols - 1:
		result.append(i + 1)
	if _row(i) > 0:
		result.append(i - cols)
	if _row(i) < rows - 1:
		result.append(i + cols)
	return result

func _build_pieces() -> void:
	for node in nodes:
		if node != null:
			node.queue_free()
	nodes = []
	for i in range(board.size()):
		nodes.append(_make_piece(board[i], _cell_pos(i)))

func _make_piece(plant_idx: int, pos: Vector2) -> Control:
	var icon := UiIcons.plant_icon(plant_idx, CELL - 2.0 * ICON_PAD)
	icon.position = pos + Vector2(ICON_PAD, ICON_PAD)
	icon.pivot_offset = icon.size / 2.0
	board_area.add_child(icon)
	return icon

# --- Sterowanie: tapniecie dwoch sasiednich pol albo przesuniecie palcem ---
func _on_board_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			press_cell = _cell_at(event.position)
			press_pos = event.position
		elif press_cell >= 0:
			var cell := press_cell
			press_cell = -1
			_on_cell_tapped(cell)
	elif event is InputEventMouseMotion and press_cell >= 0:
		var drag: Vector2 = event.position - press_pos
		if drag.length() >= SWIPE_MIN:
			var cell := press_cell
			press_cell = -1
			var target := _neighbor_in_direction(cell, drag)
			if target >= 0:
				_try_swap(cell, target)

func _neighbor_in_direction(i: int, drag: Vector2) -> int:
	var step := Vector2i(signi(int(drag.x)), 0) if absf(drag.x) > absf(drag.y) else Vector2i(0, signi(int(drag.y)))
	var col := _col(i) + step.x
	var row := _row(i) + step.y
	if col < 0 or col >= cols or row < 0 or row >= rows:
		return -1
	return row * cols + col

func _on_cell_tapped(cell: int) -> void:
	if busy:
		return
	if selected < 0:
		_select(cell)
	elif selected == cell:
		_select(-1)
	elif _neighbors(selected).has(cell):
		var first := selected
		_select(-1)
		_try_swap(first, cell)
	else:
		_select(cell)

func _select(cell: int) -> void:
	selected = cell
	select_frame.visible = cell >= 0
	if cell >= 0:
		select_frame.position = _cell_pos(cell)

# Zamiana liczy sie jako ruch tylko wtedy, gdy uklada trojke; inaczej roslinki
# wracaja na swoje miejsca, a ruch zostaje.
func _try_swap(a: int, b: int) -> void:
	if busy:
		return
	_select(-1)
	if GameState.match_moves <= 0:
		message_label.text = Lang.t("match_no_moves")
		var tw := moves_label.create_tween()
		tw.tween_property(moves_label, "modulate", NO_MOVES_COLOR, 0.15)
		tw.tween_property(moves_label, "modulate", Color(1, 1, 1), 0.4)
		return
	busy = true
	_swap_in(board, a, b)
	_swap_in(nodes, a, b)
	await _move_pieces([a, b], SWAP_TIME)
	var groups := _find_groups(board)
	if groups.is_empty():
		_swap_in(board, a, b)
		_swap_in(nodes, a, b)
		await _move_pieces([a, b], SWAP_TIME)
		message_label.text = Lang.t("match_bad_swap")
		busy = false
		return
	GameState.use_match_move()
	_update_moves()
	message_label.text = Lang.t("match_hint")
	await _resolve(groups)
	busy = false

func _swap_in(arr: Array, a: int, b: int) -> void:
	var tmp = arr[a]
	arr[a] = arr[b]
	arr[b] = tmp

func _move_pieces(indices: Array, time: float) -> void:
	if indices.is_empty():
		return
	var tw := create_tween().set_parallel(true)
	for i in indices:
		tw.tween_property(nodes[i], "position", _cell_pos(i) + Vector2(ICON_PAD, ICON_PAD), time).set_trans(Tween.TRANS_SINE)
	await tw.finished

# Usuwa grupy, zrzuca roslinki w dol i dopelnia plansze, az nie bedzie nowych
# trojek. Gdy na koniec nie ma zadnego ruchu, plansza losuje sie od nowa.
func _resolve(groups: Array) -> void:
	while not groups.is_empty():
		var removed := []
		for group in groups:
			_score_group(group)
			removed.append_array(group)
		await _vanish(removed)
		await _drop_and_fill()
		GameState.save_match_board(board)
		groups = _find_groups(board)
	if not _has_valid_move(board):
		message_label.text = Lang.t("match_reshuffle")
		board = _new_board()
		GameState.save_match_board(board)
		await _replace_all_pieces()

func _score_group(group: Array) -> void:
	var plant_idx: int = board[group[0]]
	var center := Vector2.ZERO
	for i in group:
		center += _cell_pos(i)
	center = BOARD_POS + center / group.size() + Vector2(CELL, CELL) / 2.0
	if GameState.plant_upgrade_level(plant_idx) >= GameState.PLANT_UPGRADE_MAX_LEVEL:
		_float_text("MAX", center)
		return
	var points := GameState.match_group_points(group.size())
	var gained := GameState.add_match_points(plant_idx, points)
	_float_text("+%d" % points, center)
	_refresh_counter(plant_idx, true)
	if gained > 0:
		message_label.text = Lang.f("match_upgraded", [PlantData.name_of(plant_idx)])

func _float_text(text: String, center: Vector2) -> void:
	var label := _label(text, 40, center - Vector2(60, 28), 120)
	label.add_theme_color_override("font_color", POINTS_BAR_COLOR)
	label.add_theme_color_override("font_outline_color", Color(0.15, 0.1, 0.05))
	label.add_theme_constant_override("outline_size", 8)
	add_child(label)
	var tw := label.create_tween().set_parallel(true)
	tw.tween_property(label, "position:y", label.position.y - 60, 0.9)
	tw.tween_property(label, "modulate:a", 0.0, 0.9).set_delay(0.3)
	tw.chain().tween_callback(label.queue_free)

func _vanish(removed: Array) -> void:
	var tw := create_tween().set_parallel(true)
	for i in removed:
		tw.tween_property(nodes[i], "scale", Vector2.ZERO, VANISH_TIME).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		_show_pop(i)
	await tw.finished
	for i in removed:
		nodes[i].queue_free()
		nodes[i] = null
		board[i] = -1

func _show_pop(i: int) -> void:
	var pop: Control = UiIcons.match_pop(CELL)
	if pop == null:
		var flash := Panel.new()
		flash.size = Vector2(CELL, CELL)
		flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
		flash.add_theme_stylebox_override("panel", UiIcons.round_style(Color(1.0, 0.95, 0.6, 0.8), int(CELL / 2.0)))
		pop = flash
	pop.position = _cell_pos(i)
	pop.pivot_offset = Vector2(CELL, CELL) / 2.0
	pop.scale = Vector2(0.3, 0.3)
	board_area.add_child(pop)
	var tw := pop.create_tween().set_parallel(true)
	tw.tween_property(pop, "scale", Vector2(1.2, 1.2), 0.35)
	tw.tween_property(pop, "modulate:a", 0.0, 0.35)
	tw.chain().tween_callback(pop.queue_free)

# W kazdej kolumnie roslinki opadaja na puste pola, a z gory wpadaja nowe.
func _drop_and_fill() -> void:
	var moved := []
	for c in range(cols):
		var write_row := rows - 1
		for r in range(rows - 1, -1, -1):
			var i := r * cols + c
			if board[i] < 0:
				continue
			var target := write_row * cols + c
			if target != i:
				board[target] = board[i]
				nodes[target] = nodes[i]
				board[i] = -1
				nodes[i] = null
				moved.append(target)
			write_row -= 1
		for r in range(write_row, -1, -1):
			var i := r * cols + c
			board[i] = -2
	# Nowe roslinki: bez gotowych trojek i tak, zeby wiele rodzajow mialo ruch.
	var fresh := []
	for i in range(board.size()):
		if board[i] == -2:
			var options := range(PlantData.TYPES.size()).filter(func(t):
				board[i] = t
				return not _line_at(board, i))
			board[i] = options.pick_random() if not options.is_empty() else randi() % PlantData.TYPES.size()
			fresh.append(i)
	_add_moves(board, fresh, GameState.MATCH_REFILL_MOVABLE)
	for i in fresh:
		var drop := 0
		while _row(i) + drop + 1 < rows and fresh.has(i + (drop + 1) * cols):
			drop += 1
		nodes[i] = _make_piece(board[i], _cell_pos(i) - Vector2(0, (_row(i) + drop + 1) * CELL))
		moved.append(i)
	await _move_pieces(moved, FALL_TIME)

func _replace_all_pieces() -> void:
	var tw := create_tween().set_parallel(true)
	for node in nodes:
		tw.tween_property(node, "scale", Vector2.ZERO, VANISH_TIME)
	await tw.finished
	_build_pieces()
	var tw_in := create_tween().set_parallel(true)
	for node in nodes:
		node.scale = Vector2.ZERO
		tw_in.tween_property(node, "scale", Vector2.ONE, VANISH_TIME)
	await tw_in.finished

# --- Logika planszy ---
# Grupy do usuniecia: pola w ciagach co najmniej 3 takich samych (w rzedzie albo
# kolumnie) razem ze wszystkimi stykajacymi sie z nimi roslinkami tego rodzaju.
func _find_groups(b: Array) -> Array:
	var in_line := {}
	for i in range(b.size()):
		if b[i] < 0:
			continue
		var c := _col(i)
		var r := _row(i)
		if c == 0 or b[i - 1] != b[i]:
			var run := 1
			while c + run < cols and b[i + run] == b[i]:
				run += 1
			if run >= 3:
				for k in range(run):
					in_line[i + k] = true
		if r == 0 or b[i - cols] != b[i]:
			var run := 1
			while r + run < rows and b[i + run * cols] == b[i]:
				run += 1
			if run >= 3:
				for k in range(run):
					in_line[i + k * cols] = true

	var groups := []
	var seen := {}
	for start in in_line.keys():
		if seen.has(start):
			continue
		var group := []
		var stack := [start]
		seen[start] = true
		while not stack.is_empty():
			var i: int = stack.pop_back()
			group.append(i)
			for n in _neighbors(i):
				if not seen.has(n) and b[n] == b[i]:
					seen[n] = true
					stack.append(n)
		groups.append(group)
	return groups

# Czy na polu i stoi roslina, ktora z sasiadami tworzy co najmniej 3 w rzedzie.
func _line_at(b: Array, i: int) -> bool:
	var t: int = b[i]
	if t < 0:
		return false
	var c := _col(i)
	var r := _row(i)
	var run := 1
	var k := 1
	while c - k >= 0 and b[i - k] == t:
		run += 1
		k += 1
	k = 1
	while c + k < cols and b[i + k] == t:
		run += 1
		k += 1
	if run >= 3:
		return true
	run = 1
	k = 1
	while r - k >= 0 and b[i - k * cols] == t:
		run += 1
		k += 1
	k = 1
	while r + k < rows and b[i + k * cols] == t:
		run += 1
		k += 1
	return run >= 3

# Rodzaje roslin, ktore gracz moze teraz ulozyc w trojke jednym ruchem.
func _movable_types(b: Array) -> Dictionary:
	var types := {}
	for i in range(b.size()):
		for n in [i + 1, i + cols]:
			if n >= b.size() or (n == i + 1 and _col(i) == cols - 1) or b[i] == b[n]:
				continue
			_swap_in(b, i, n)
			if _line_at(b, i):
				types[b[i]] = true
			if _line_at(b, n):
				types[b[n]] = true
			_swap_in(b, i, n)
	return types

func _has_valid_move(b: Array) -> bool:
	return not _movable_types(b).is_empty()

# Czy na planszy nie ma zadnej gotowej trojki.
func _is_calm(b: Array, cells: Array) -> bool:
	for i in cells:
		if _line_at(b, i):
			return false
	return true

# Losowa plansza bez gotowych trojek, na ktorej wiele rodzajow roslin ma ruch -
# gracz sam wybiera, ktora roslinke chce ulepszyc.
func _new_board() -> Array:
	var b := []
	for i in range(cols * rows):
		var options := range(PlantData.TYPES.size()).filter(func(t): return not _makes_line(b, i, t))
		b.append(options.pick_random())
	_add_moves(b, range(b.size()), GameState.MATCH_BOARD_MOVABLE)
	return b

# Zmienia rosliny na wskazanych polach, az ruch bedzie mialo co najmniej "goal"
# rodzajow roslin (albo skoncza sie proby). Plansza nie dostaje gotowych trojek.
func _add_moves(b: Array, cells: Array, goal: int) -> void:
	if cells.is_empty():
		return
	var allowed := {}
	for cell in cells:
		allowed[cell] = true
	var movable := _movable_types(b)
	var tries := 0
	while movable.size() < goal and tries < 300:
		tries += 1
		var missing := range(PlantData.TYPES.size()).filter(func(t): return not movable.has(t))
		var t: int = missing.pick_random()
		# Uklad "prawie trojki": dwie takie same obok siebie i trzecia o jedna
		# zamiane dalej. Gdy sie nie miesci, zmienia sie tylko jedno pole.
		var pattern := _near_match_pattern(cells.pick_random())
		if pattern.is_empty() or not pattern.all(func(c): return allowed.has(c)):
			pattern = [cells.pick_random()]
		var old := pattern.map(func(c): return b[c])
		for c in pattern:
			b[c] = t
		var changed := []
		for c in pattern:
			changed.append(c)
			changed.append_array(_neighbors(c))
		var after := _movable_types(b) if _is_calm(b, changed) else {}
		if after.size() > movable.size():
			movable = after
		else:
			for k in range(pattern.size()):
				b[pattern[k]] = old[k]

# Trzy pola: a i sasiad w jednym kierunku oraz pole, z ktorego jedna zamiana
# dosuwa trzecia roslinke w linie (np. po skosie za para). Pusto, gdy wychodzi
# poza plansze.
func _near_match_pattern(a: int) -> Array:
	var r := _row(a)
	var c := _col(a)
	var options := []
	if c + 2 < cols:
		for dr in [-1, 1]:
			if r + dr >= 0 and r + dr < rows:
				options.append([a, a + 1, (r + dr) * cols + c + 2])
		if c + 3 < cols:
			options.append([a, a + 1, a + 3])
	if r + 2 < rows:
		for dc in [-1, 1]:
			if c + dc >= 0 and c + dc < cols:
				options.append([a, a + cols, (r + 2) * cols + c + dc])
		if r + 3 < rows:
			options.append([a, a + cols, a + 3 * cols])
	return options.pick_random() if not options.is_empty() else []

# Czy roslina t na polu i (wypelnianym po kolei) dalaby trojke z poprzednimi.
func _makes_line(b: Array, i: int, t: int) -> bool:
	if _col(i) >= 2 and b[i - 1] == t and b[i - 2] == t:
		return true
	return _row(i) >= 2 and b[i - cols] == t and b[i - 2 * cols] == t
