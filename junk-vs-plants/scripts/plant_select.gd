extends Control

# Ekran wyboru talii - pokazuje sie zawsze przed poziomem (takze gdy gracz ma
# tylko 2 rosliny, jako przypomnienie "oto twoje rosliny").

const VIEWPORT_WIDTH := 1280
const VIEWPORT_HEIGHT := 720

const CARD_SIZE := Vector2(260, 220)
const CARD_GAP := Vector2(20, 20)
const CARDS_PER_ROW := 4
const GRID_TOP := 160.0

var selected: Array = []
# plant_idx -> {"border_sb": StyleBoxFlat, "mark": Panel albo null}
var card_refs: Dictionary = {}

var counter_label: Label
var message_label: Label
var play_button: Button

func _ready() -> void:
	var level: Dictionary = LevelData.LEVELS[GameState.current_level_index]

	var bg := ColorRect.new()
	bg.color = Color(0.15, 0.25, 0.15)
	bg.position = Vector2(0, 0)
	bg.size = Vector2(VIEWPORT_WIDTH, VIEWPORT_HEIGHT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var title := Label.new()
	title.text = level["name"]
	title.position = Vector2(40, 16)
	title.add_theme_font_size_override("font_size", 30)
	add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Wybierz rosliny do tej gry (najwyzej 6)"
	subtitle.position = Vector2(40, 58)
	subtitle.add_theme_font_size_override("font_size", 18)
	add_child(subtitle)

	counter_label = Label.new()
	counter_label.position = Vector2(40, 84)
	counter_label.add_theme_font_size_override("font_size", 16)
	add_child(counter_label)

	var boss_idx: int = level.get("boss", -1)
	if boss_idx >= 0:
		var boss_icon := TextureRect.new()
		boss_icon.texture = load(BossData.TYPES[boss_idx]["texture"])
		boss_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		boss_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		boss_icon.size = Vector2(28, 28)
		boss_icon.position = Vector2(230, 82)
		add_child(boss_icon)

		var boss_label := Label.new()
		boss_label.text = "Na koncu: %s" % BossData.TYPES[boss_idx]["name"]
		boss_label.position = Vector2(264, 84)
		boss_label.add_theme_font_size_override("font_size", 16)
		add_child(boss_label)

	message_label = Label.new()
	message_label.position = Vector2(40, 110)
	message_label.add_theme_font_size_override("font_size", 16)
	message_label.add_theme_color_override("font_color", Color(0.9, 0.35, 0.25))
	add_child(message_label)

	var loadout := GameState.get_loadout(GameState.current_level_index)
	if loadout.is_empty():
		var unlocked := GameState.unlocked_plant_indices()
		loadout = unlocked.slice(0, min(GameState.MAX_LOADOUT, unlocked.size()))
	selected = loadout.duplicate()

	_build_grid()
	_update_counter()

	var back_btn := Button.new()
	back_btn.text = "Wroc"
	back_btn.position = Vector2(40, 640)
	back_btn.size = Vector2(220, 60)
	back_btn.pressed.connect(_on_back_pressed)
	add_child(back_btn)

	play_button = Button.new()
	play_button.text = "Graj!"
	play_button.position = Vector2(1020, 640)
	play_button.size = Vector2(220, 60)
	play_button.pressed.connect(_on_play_pressed)
	add_child(play_button)
	play_button.disabled = selected.is_empty()

func _build_grid() -> void:
	card_refs.clear()
	var total_width := CARDS_PER_ROW * CARD_SIZE.x + (CARDS_PER_ROW - 1) * CARD_GAP.x
	var start_x := (VIEWPORT_WIDTH - total_width) / 2.0
	for plant_idx in range(PlantData.TYPES.size()):
		var col := plant_idx % CARDS_PER_ROW
		var row := int(plant_idx / float(CARDS_PER_ROW))
		var x := start_x + col * (CARD_SIZE.x + CARD_GAP.x)
		var y := GRID_TOP + row * (CARD_SIZE.y + CARD_GAP.y)
		_build_card(plant_idx, x, y)

func _build_card(plant_idx: int, x: float, y: float) -> void:
	var pt: Dictionary = PlantData.TYPES[plant_idx]
	var unlocked := GameState.is_plant_unlocked(plant_idx)
	var is_selected := selected.has(plant_idx)

	var card := Button.new()
	card.position = Vector2(x, y)
	card.size = CARD_SIZE
	card.flat = true
	card.focus_mode = Control.FOCUS_NONE
	card.disabled = not unlocked
	if unlocked:
		card.pressed.connect(_on_card_pressed.bind(plant_idx))

	var border_sb := StyleBoxFlat.new()
	border_sb.bg_color = Color(0.22, 0.3, 0.2)
	border_sb.border_width_left = 4
	border_sb.border_width_right = 4
	border_sb.border_width_top = 4
	border_sb.border_width_bottom = 4
	border_sb.border_color = Color(0.15, 0.75, 0.2) if is_selected else Color(0.4, 0.4, 0.35)
	border_sb.corner_radius_top_left = 14
	border_sb.corner_radius_top_right = 14
	border_sb.corner_radius_bottom_left = 14
	border_sb.corner_radius_bottom_right = 14
	for state in ["normal", "hover", "pressed", "disabled"]:
		card.add_theme_stylebox_override(state, border_sb)

	add_child(card)

	var icon := TextureRect.new()
	icon.texture = load(pt["texture"])
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size = Vector2(110, 110)
	icon.position = Vector2((CARD_SIZE.x - 110) / 2.0, 14)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not unlocked:
		icon.modulate = Color(0.15, 0.15, 0.15)
	card.add_child(icon)

	var name_label := Label.new()
	name_label.text = pt["name"]
	name_label.position = Vector2(8, 130)
	name_label.size = Vector2(CARD_SIZE.x - 16, 24)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(name_label)

	var mark: Panel = null
	if unlocked:
		var cost_drop := TextureRect.new()
		cost_drop.texture = load("res://assets/sprites/ui/water_drop.png")
		cost_drop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		cost_drop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		cost_drop.size = Vector2(22, 22)
		cost_drop.position = Vector2(CARD_SIZE.x / 2.0 - 30, 158)
		cost_drop.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(cost_drop)

		var cost_label := Label.new()
		cost_label.text = str(pt["cost"])
		cost_label.position = Vector2(CARD_SIZE.x / 2.0 - 2, 156)
		cost_label.size = Vector2(48, 24)
		cost_label.add_theme_font_size_override("font_size", 16)
		cost_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(cost_label)

		mark = Panel.new()
		mark.size = Vector2(26, 26)
		mark.position = Vector2(CARD_SIZE.x - 34, 8)
		mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
		mark.visible = is_selected
		var mark_sb := StyleBoxFlat.new()
		mark_sb.bg_color = Color(0.15, 0.75, 0.2)
		mark_sb.corner_radius_top_left = 13
		mark_sb.corner_radius_top_right = 13
		mark_sb.corner_radius_bottom_left = 13
		mark_sb.corner_radius_bottom_right = 13
		mark.add_theme_stylebox_override("panel", mark_sb)
		card.add_child(mark)
	else:
		var lock_label := Label.new()
		lock_label.text = "od poziomu %d" % pt.get("unlock_level", 1)
		lock_label.position = Vector2(8, 158)
		lock_label.size = Vector2(CARD_SIZE.x - 16, 24)
		lock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lock_label.add_theme_font_size_override("font_size", 14)
		lock_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(lock_label)

	card_refs[plant_idx] = {"border_sb": border_sb, "mark": mark}

func _on_card_pressed(plant_idx: int) -> void:
	if selected.has(plant_idx):
		selected.erase(plant_idx)
	else:
		if selected.size() >= GameState.MAX_LOADOUT:
			message_label.text = "Mozesz wybrac najwyzej 6 roslin"
			return
		selected.append(plant_idx)
	message_label.text = ""
	_update_card_visual(plant_idx)
	_update_counter()

func _update_card_visual(plant_idx: int) -> void:
	var refs: Dictionary = card_refs[plant_idx]
	var is_selected: bool = selected.has(plant_idx)
	refs["border_sb"].border_color = Color(0.15, 0.75, 0.2) if is_selected else Color(0.4, 0.4, 0.35)
	if refs["mark"] != null:
		refs["mark"].visible = is_selected

func _update_counter() -> void:
	counter_label.text = "Wybrane: %d / %d" % [selected.size(), GameState.MAX_LOADOUT]
	if play_button:
		play_button.disabled = selected.is_empty()

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/LevelSelect.tscn")

func _on_play_pressed() -> void:
	if selected.is_empty():
		return
	var ordered := []
	for i in range(PlantData.TYPES.size()):
		if selected.has(i):
			ordered.append(i)
	GameState.current_loadout = ordered
	GameState.set_loadout(GameState.current_level_index, ordered)
	get_tree().change_scene_to_file("res://scenes/Main.tscn")
