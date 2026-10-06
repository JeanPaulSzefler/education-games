extends Control

# Ekran startowy: wybor lokalnego konta gracza (notatki 2026-10-06, wersja
# lokalna - konta sa tylko na tym urzadzeniu, bez hasla). Przy pierwszym
# uruchomieniu od razu pokazuje sie zakladanie konta; pozniej gracz klika
# swoje konto z zapisanym postepem albo zaklada nowe.

const VIEWPORT_WIDTH := 1280
const VIEWPORT_HEIGHT := 720

const CARD_SIZE := Vector2(170, 210)
const CARD_GAP := 22.0
const CARD_Y := 250.0
const CARD_COLOR := Color(0.3, 0.45, 0.25)
const NEW_CARD_COLOR := Color(0.22, 0.32, 0.2)
const OK_BTN_COLOR := Color(0.25, 0.6, 0.25)
const PANEL_BG_COLOR := Color(0.95, 0.93, 0.85)
const PANEL_TEXT_COLOR := Color(0.15, 0.12, 0.1)
const ERROR_COLOR := Color(0.75, 0.2, 0.15)
const SELECTED_ICON_BORDER := Color(0.95, 0.75, 0.1)

# Wszystko poza tlem i tytulem - czyszczone przy przelaczaniu widokow.
var content: Control

func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.15, 0.25, 0.15)
	bg.size = Vector2(VIEWPORT_WIDTH, VIEWPORT_HEIGHT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var title := Label.new()
	title.text = "Junk vs Plants"
	title.position = Vector2(0, 40)
	title.size = Vector2(VIEWPORT_WIDTH, 70)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 56)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(title)

	if GameState.profiles.is_empty():
		_show_create_form()
	else:
		_show_profile_list()

func _reset_content() -> void:
	if content != null:
		content.queue_free()
	content = Control.new()
	content.size = Vector2(VIEWPORT_WIDTH, VIEWPORT_HEIGHT)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(content)

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

# --- Lista kont: karty z ikona i nazwa + karta "Nowe konto" ---
func _show_profile_list() -> void:
	_reset_content()
	content.add_child(_label("Kliknij swoje konto", 28, Vector2(0, 150), VIEWPORT_WIDTH))

	var cards := GameState.profiles.size() + (1 if GameState.can_create_profile() else 0)
	var start_x := (VIEWPORT_WIDTH - (cards * CARD_SIZE.x + (cards - 1) * CARD_GAP)) / 2.0

	for i in range(GameState.profiles.size()):
		var profile: Dictionary = GameState.profiles[i]
		var card := _card(Vector2(start_x + i * (CARD_SIZE.x + CARD_GAP), CARD_Y), CARD_COLOR)
		var icon := UiIcons.plant_icon(profile["icon"], 120)
		icon.position = Vector2((CARD_SIZE.x - 120) / 2.0, 20)
		card.add_child(icon)
		var name_label := _label(profile["name"], 22, Vector2(6, 150), CARD_SIZE.x - 12)
		name_label.clip_text = true
		card.add_child(name_label)
		var id: String = profile["id"]
		card.pressed.connect(func(): _enter_profile(id))

	if GameState.can_create_profile():
		var x := start_x + GameState.profiles.size() * (CARD_SIZE.x + CARD_GAP)
		var new_card := _card(Vector2(x, CARD_Y), NEW_CARD_COLOR)
		new_card.add_child(_label("+", 80, Vector2(0, 20), CARD_SIZE.x))
		new_card.add_child(_label("Nowe konto", 22, Vector2(0, 150), CARD_SIZE.x))
		new_card.pressed.connect(_show_create_form)

func _card(pos: Vector2, color: Color) -> Button:
	var card := Button.new()
	card.position = pos
	card.size = CARD_SIZE
	card.focus_mode = Control.FOCUS_NONE
	UiIcons.style_button(card, color, 18)
	content.add_child(card)
	return card

func _enter_profile(id: String) -> void:
	GameState.select_profile(id)
	get_tree().change_scene_to_file("res://scenes/LevelSelect.tscn")

# --- Zakladanie konta: nazwa + ikona (do wyboru rosliny startowe) ---
func _show_create_form() -> void:
	_reset_content()

	var panel := Panel.new()
	panel.size = Vector2(720, 470)
	panel.position = Vector2((VIEWPORT_WIDTH - panel.size.x) / 2.0, 150)
	var sb := StyleBoxFlat.new()
	sb.bg_color = PANEL_BG_COLOR
	sb.set_border_width_all(5)
	sb.border_color = Color(0.25, 0.2, 0.15)
	sb.set_corner_radius_all(18)
	panel.add_theme_stylebox_override("panel", sb)
	content.add_child(panel)

	var header := _label("Utworz konto", 34, Vector2(0, 16), panel.size.x)
	header.add_theme_color_override("font_color", PANEL_TEXT_COLOR)
	panel.add_child(header)

	var name_caption := _label("Nazwa:", 22, Vector2(30, 98), 110)
	name_caption.add_theme_color_override("font_color", PANEL_TEXT_COLOR)
	panel.add_child(name_caption)

	var name_edit := LineEdit.new()
	name_edit.placeholder_text = "Wpisz swoje imie"
	name_edit.max_length = GameState.PLAYER_NAME_MAX_LENGTH
	name_edit.position = Vector2(150, 92)
	name_edit.size = Vector2(420, 54)
	name_edit.add_theme_font_size_override("font_size", 24)
	panel.add_child(name_edit)

	var error_label := _label("", 18, Vector2(150, 150), 420)
	error_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	error_label.add_theme_color_override("font_color", ERROR_COLOR)
	panel.add_child(error_label)

	var icon_caption := _label("Ikona:", 22, Vector2(30, 214), 110)
	icon_caption.add_theme_color_override("font_color", PANEL_TEXT_COLOR)
	panel.add_child(icon_caption)

	# Nowe konto ma tylko rosliny startowe, wiec tylko one sa do wyboru.
	var chosen := {"icon": 0}
	var icon_styles := {}
	var x := 150.0
	for p_idx in range(PlantData.TYPES.size()):
		if PlantData.TYPES[p_idx].get("unlock_level", 1) > 1:
			continue
		var btn := Button.new()
		btn.position = Vector2(x, 190)
		btn.size = Vector2(96, 96)
		btn.focus_mode = Control.FOCUS_NONE
		var icon_sb := UiIcons.round_style(Color(0.55, 0.8, 0.4), 14)
		icon_sb.set_border_width_all(5)
		icon_sb.border_color = SELECTED_ICON_BORDER if p_idx == chosen["icon"] else icon_sb.bg_color
		for state in ["normal", "hover", "pressed"]:
			btn.add_theme_stylebox_override(state, icon_sb)
		icon_styles[p_idx] = icon_sb
		var icon := UiIcons.plant_icon(p_idx, 80)
		icon.position = Vector2(8, 8)
		btn.add_child(icon)
		btn.pressed.connect(func():
			chosen["icon"] = p_idx
			for key in icon_styles.keys():
				icon_styles[key].border_color = SELECTED_ICON_BORDER if key == p_idx else icon_styles[key].bg_color)
		panel.add_child(btn)
		x += 112.0

	if not GameState.profiles.is_empty():
		var back_btn := _button("Wroc", CARD_COLOR, Vector2(40, panel.size.y - 100), Vector2(220, 70))
		back_btn.pressed.connect(_show_profile_list)
		panel.add_child(back_btn)

	var create_btn := _button("Utworz konto", OK_BTN_COLOR, Vector2(panel.size.x - 280, panel.size.y - 100), Vector2(240, 70))
	create_btn.pressed.connect(func():
		if name_edit.text.strip_edges().is_empty():
			error_label.text = "Wpisz nazwe konta."
		elif GameState.is_profile_name_taken(name_edit.text):
			error_label.text = "Konto o tej nazwie juz istnieje."
		elif GameState.create_profile(name_edit.text, chosen["icon"]):
			get_tree().change_scene_to_file("res://scenes/LevelSelect.tscn"))
	panel.add_child(create_btn)
