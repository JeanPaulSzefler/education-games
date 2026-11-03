extends Control

# Labirynt pszczolki (dodatek): gracz prowadzi pszczolke palcem przez zywoplot
# do kwiatka. Krople nektaru skracaja czas o 2 s, a pajeczyna cofa na start.
# Czas daje 1-3 gwiazdki; nagrody liczy GameState.complete_rotation_stage.
# '#' zywoplot, '.' sciezka, 'S' start, 'F' kwiatek, 'n' nektar, 'w' pajeczyna.

const VIEWPORT_WIDTH := 1280
const VIEWPORT_HEIGHT := 720
const CELL := 76.0
const ORIGIN := Vector2(108, 100)
const BEE_RADIUS := 22.0
const BEE_SPEED := 380.0
const NECTAR_BONUS := 2.0
const BACK_COLOR := Color(0.3, 0.45, 0.25)
const OK_BTN_COLOR := Color(0.25, 0.6, 0.25)
const MAZES := [
	["##############",
	 "#S...#......F#",
	 "#.##.#.####..#",
	 "#.#..n.#.....#",
	 "#.#.####.###.#",
	 "#...#n...#...#",
	 "###.....##.n.#",
	 "##############"],
	["##############",
	 "#S.#.....#..F#",
	 "#..#.###.#.###",
	 "#.##...#.#...#",
	 "#....#.#.###.#",
	 "###.##.#.....#",
	 "#n.....###.w.#",
	 "##############"],
	["##############",
	 "#S#....#.....#",
	 "#.#.##.#.###.#",
	 "#...#..w.#F#.#",
	 "###.#.####.#.#",
	 "#n..#......#.#",
	 "#.####.###...#",
	 "##############"],
	["##############",
	 "#S....#.....n#",
	 "####.##.###.##",
	 "#n...#..#...F#",
	 "#.##...##.####",
	 "#..w.#.....w.#",
	 "##.#####.###.#",
	 "##############"],
	["##############",
	 "#S.#...w...#F#",
	 "#..#.#.###.#.#",
	 "##.#.#...#.#.#",
	 "#..#.###.#...#",
	 "#.##...#.###.#",
	 "#....#n#.....#",
	 "##############"],
]
# Czas na 3 i na 2 gwiazdki (w sekundach) dla kolejnych labiryntow.
const STAR_TIMES := [[12.0, 20.0], [14.0, 24.0], [14.0, 24.0], [16.0, 28.0], [20.0, 32.0]]

var kind := GameState.play_kind
var stage := GameState.event_stage
var maze: Array
var bee: Control
var bee_pos := Vector2.ZERO
var start_pos := Vector2.ZERO
var target := Vector2(-1, -1)
var nectars := {}
var elapsed := 0.0
var bonus := 0.0
var running := true
var started := false
var info_label: Label
var message_label: Label

func _ready() -> void:
	maze = MAZES[stage]
	var bg := ColorRect.new()
	bg.color = Color(0.55, 0.8, 0.45)
	bg.size = Vector2(VIEWPORT_WIDTH, VIEWPORT_HEIGHT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	info_label = Label.new()
	info_label.position = Vector2(20, 14)
	info_label.add_theme_font_size_override("font_size", 28)
	info_label.add_theme_color_override("font_color", Color(0.1, 0.2, 0.1))
	add_child(info_label)
	message_label = Label.new()
	message_label.position = Vector2(0, 56)
	message_label.size = Vector2(VIEWPORT_WIDTH, 36)
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.add_theme_font_size_override("font_size", 22)
	message_label.add_theme_color_override("font_color", Color(0.1, 0.2, 0.1))
	message_label.text = Lang.t("maze_hint")
	add_child(message_label)

	var back_btn := Button.new()
	back_btn.text = Lang.t("back")
	back_btn.position = Vector2(VIEWPORT_WIDTH - 180, 10)
	back_btn.size = Vector2(160, 56)
	back_btn.focus_mode = Control.FOCUS_NONE
	UiIcons.style_button(back_btn, BACK_COLOR, 14)
	back_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/Rotation.tscn"))
	add_child(back_btn)

	for row in range(maze.size()):
		for col in range(maze[row].length()):
			var ch: String = maze[row][col]
			var pos := ORIGIN + Vector2(col, row) * CELL
			match ch:
				"#":
					var hedge := ColorRect.new()
					hedge.color = Color(0.15, 0.45, 0.15)
					hedge.position = pos
					hedge.size = Vector2(CELL, CELL)
					hedge.mouse_filter = Control.MOUSE_FILTER_IGNORE
					add_child(hedge)
				"S":
					start_pos = pos + Vector2(CELL, CELL) / 2.0
				"F":
					var flower := UiIcons.plant_icon(11, CELL - 8)
					flower.position = pos + Vector2(4, 4)
					add_child(flower)
				"n":
					var drop := TextureRect.new()
					drop.texture = load("res://assets/sprites/ui/water_drop.png")
					drop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
					drop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
					drop.size = Vector2(CELL, CELL) * 0.5
					drop.position = pos + Vector2(CELL, CELL) * 0.25
					drop.modulate = Color(1.0, 0.8, 0.3)
					drop.mouse_filter = Control.MOUSE_FILTER_IGNORE
					add_child(drop)
					nectars[Vector2i(col, row)] = drop
				"w":
					var web := UiIcons.file_icon("spider_web", CELL)
					if web == null:
						web = _drawn_web()
					web.position = pos
					add_child(web)
	bee = UiIcons.bee(BEE_RADIUS * 2.6)
	add_child(bee)
	bee_pos = start_pos
	_place_bee()
	_update_info()

func _drawn_web() -> Control:
	var c := Control.new()
	c.size = Vector2(CELL, CELL)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for i in range(4):
		var line := Line2D.new()
		var dir := Vector2.from_angle(PI * i / 4.0) * CELL * 0.45
		line.points = PackedVector2Array([Vector2(CELL, CELL) / 2.0 - dir, Vector2(CELL, CELL) / 2.0 + dir])
		line.width = 2
		line.default_color = Color(0.95, 0.95, 0.95)
		c.add_child(line)
	return c

func _place_bee() -> void:
	bee.position = bee_pos - bee.size / 2.0

func _cell_at(pos: Vector2) -> Vector2i:
	var local := (pos - ORIGIN) / CELL
	return Vector2i(int(floor(local.x)), int(floor(local.y)))

func _char_at(cell: Vector2i) -> String:
	if cell.y < 0 or cell.y >= maze.size() or cell.x < 0 or cell.x >= maze[cell.y].length():
		return "#"
	return maze[cell.y][cell.x]

# Czy pszczolka w tym miejscu zachodzi na zywoplot.
func _blocked(pos: Vector2) -> bool:
	for offset in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		if _char_at(_cell_at(pos + offset * BEE_RADIUS * 0.8)) == "#":
			return true
	return false

func _input(event: InputEvent) -> void:
	if not running:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		target = event.position if event.pressed else Vector2(-1, -1)
	elif event is InputEventMouseMotion and target.x >= 0.0:
		target = event.position

func _process(delta: float) -> void:
	if not running:
		return
	if target.x >= 0.0 and bee_pos.distance_to(target) > 4.0:
		if not started:
			started = true
			message_label.text = ""
		var step := (target - bee_pos).normalized() * minf(BEE_SPEED * delta, bee_pos.distance_to(target))
		# Ruch osobno w poziomie i w pionie, zeby pszczolka slizgala sie po zywoplocie.
		if not _blocked(bee_pos + Vector2(step.x, 0)):
			bee_pos.x += step.x
		if not _blocked(bee_pos + Vector2(0, step.y)):
			bee_pos.y += step.y
		_place_bee()
	if started:
		elapsed += delta
	var cell := _cell_at(bee_pos)
	match _char_at(cell):
		"w":
			bee_pos = start_pos
			target = Vector2(-1, -1)
			_place_bee()
			message_label.text = Lang.t("maze_web")
		"n":
			if nectars.has(cell):
				nectars[cell].queue_free()
				nectars.erase(cell)
				bonus += NECTAR_BONUS
				message_label.text = Lang.t("maze_nectar")
		"F":
			_finish()
	_update_info()

func _time() -> float:
	return maxf(0.0, elapsed - bonus)

func _update_info() -> void:
	info_label.text = Lang.f("maze_info", [stage + 1, snappedf(_time(), 0.1)])

func _finish() -> void:
	running = false
	var times: Array = STAR_TIMES[stage]
	var stars := 1
	if _time() <= times[0]:
		stars = 3
	elif _time() <= times[1]:
		stars = 2
	var reward := GameState.complete_rotation_stage(kind, stage, stars)
	var panel := Panel.new()
	panel.size = Vector2(620, 300)
	panel.position = (Vector2(VIEWPORT_WIDTH, VIEWPORT_HEIGHT) - panel.size) / 2.0
	var sb := UiIcons.round_style(Color(0.95, 0.93, 0.85), 18)
	sb.set_border_width_all(5)
	sb.border_color = Color(0.25, 0.2, 0.15)
	panel.add_theme_stylebox_override("panel", sb)
	add_child(panel)
	var text := Label.new()
	text.text = Lang.f("maze_result", [snappedf(_time(), 0.1), stars])
	if reward["saplings"] > 0:
		text.text += "\n" + Lang.f("saplings_won", [reward["saplings"]])
	if reward["moves"] > 0:
		text.text += "\n" + Lang.f("moves_won", [reward["moves"]])
	text.position = Vector2(20, 30)
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiIcons.wrap_label(text, Vector2(580, 140))
	text.add_theme_font_size_override("font_size", 26)
	text.add_theme_color_override("font_color", Color(0.15, 0.12, 0.1))
	panel.add_child(text)
	var again := Button.new()
	again.text = Lang.t("play_again")
	again.position = Vector2(40, 200)
	again.size = Vector2(250, 70)
	again.focus_mode = Control.FOCUS_NONE
	UiIcons.style_button(again, OK_BTN_COLOR, 14)
	again.pressed.connect(func(): get_tree().reload_current_scene())
	panel.add_child(again)
	var back := Button.new()
	back.text = Lang.t("back")
	back.position = Vector2(330, 200)
	back.size = Vector2(250, 70)
	back.focus_mode = Control.FOCUS_NONE
	UiIcons.style_button(back, BACK_COLOR, 14)
	back.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/Rotation.tscn"))
	panel.add_child(back)
