extends Control

# Ekran wyboru talii - pokazuje sie zawsze przed poziomem (takze gdy gracz ma
# tylko 2 rosliny, jako przypomnienie "oto twoje rosliny"). Rosliny sa w
# kolejnosci, w jakiej gracz je odblokowuje.

const VIEWPORT_WIDTH := 1280
const VIEWPORT_HEIGHT := 720

const CARD_SIZE := Vector2(152, 220)
const CARD_GAP := Vector2(14, 20)
const CARDS_PER_ROW := 7
const GRID_TOP := 160.0
const TEAM_LOADOUT_KEY := -1
const EVENT_LOADOUT_KEY := -2

var selected: Array = []
# Wydarzenia: role niedostepne w talii, rosliny narzucone i limit talii.
var banned_roles: Array = []
var forced_plants: Array = []
var max_plants := GameState.MAX_LOADOUT
# Siodme miejsce wypozyczone na te gre (tylko na sciezce); rubiny pobiera "Graj!".
var rent_slot := false
# plant_idx -> {"border_sb": StyleBoxFlat, "mark": Panel albo null}
var card_refs: Dictionary = {}
var cards_layer: Control

var counter_label: Label
var message_label: Label
var subtitle: Label
var play_button: Button
var rent_button: Button

func _ready() -> void:
	var level: Dictionary = GameState.current_level()

	add_child(UiIcons.screen_background("yard"))

	var title := Label.new()
	title.text = LevelData.title(level)
	title.position = Vector2(40, 16)
	title.add_theme_font_size_override("font_size", 30)
	add_child(title)

	subtitle = Label.new()
	subtitle.text = Lang.f("select_max", [GameState.MAX_LOADOUT])
	subtitle.position = Vector2(40, 58)
	subtitle.add_theme_font_size_override("font_size", 18)
	add_child(subtitle)

	counter_label = Label.new()
	counter_label.position = Vector2(40, 84)
	counter_label.add_theme_font_size_override("font_size", 16)
	add_child(counter_label)

	if level.get("endless", false):
		var endless_label := Label.new()
		endless_label.text = Lang.f("select_endless", [GameState.endless_best])
		endless_label.position = Vector2(230, 84)
		endless_label.add_theme_font_size_override("font_size", 16)
		add_child(endless_label)

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
		boss_label.text = Lang.f("select_boss", [BossData.name_of(boss_idx)])
		boss_label.position = Vector2(264, 84)
		boss_label.add_theme_font_size_override("font_size", 16)
		add_child(boss_label)

	message_label = Label.new()
	message_label.position = Vector2(40, 110)
	message_label.add_theme_font_size_override("font_size", 16)
	message_label.add_theme_color_override("font_color", Color(0.9, 0.35, 0.25))
	add_child(message_label)

	var event: Dictionary = GameState.playing_event()
	banned_roles = event.get("banned_roles", [])
	if event.get("forced_deck", false):
		forced_plants = GameState.event_forced_plants
		var extra: bool = GameState.event_help_active and not event.get("single_plant", false)
		max_plants = forced_plants.size() + (1 if extra else 0)
		subtitle.text = Lang.t("select_forced") + (" " + Lang.t("select_forced_extra") if extra else "")
		selected = forced_plants.duplicate()
		# Jedna roslinka: kupiona pomoc pozwala raz wylosowac inna rosline.
		if event.get("single_plant", false) and GameState.event_help_active:
			_build_reroll_button()
	else:
		var loadout := GameState.get_loadout(_loadout_key())
		if loadout.is_empty():
			var unlocked := GameState.unlocked_plant_indices()
			loadout = unlocked.slice(0, min(GameState.MAX_LOADOUT, unlocked.size()))
		# Talia z wypozyczonym miejscem wraca do 6 roslin - miejsce bylo na jedna gre.
		selected = loadout.filter(_is_plant_allowed).slice(0, max_plants)

	cards_layer = Control.new()
	cards_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(cards_layer)
	_build_grid()
	_update_counter()

	var back_btn := Button.new()
	back_btn.text = Lang.t("back")
	back_btn.position = Vector2(40, 640)
	back_btn.size = Vector2(220, 60)
	back_btn.pressed.connect(_on_back_pressed)
	add_child(back_btn)

	play_button = Button.new()
	play_button.text = Lang.t("play_excl")
	play_button.position = Vector2(1020, 640)
	play_button.size = Vector2(220, 60)
	play_button.pressed.connect(_on_play_pressed)
	add_child(play_button)
	play_button.disabled = selected.is_empty()
	_build_rent_button()

	if NetSession.active:
		NetSession.game_starting.connect(_start_game)
		NetSession.session_lost.connect(_on_back_pressed)

func _build_reroll_button() -> void:
	var btn := Button.new()
	btn.text = Lang.t("select_reroll")
	btn.position = Vector2(400, 640)
	btn.size = Vector2(480, 60)
	btn.focus_mode = Control.FOCUS_NONE
	btn.add_theme_font_size_override("font_size", 20)
	btn.pressed.connect(func():
		var old: Array = GameState.event_forced_plants
		var deck: Array = old
		while deck == old:
			deck = GameState._random_single_plant_deck()
		GameState.event_forced_plants = deck
		forced_plants = deck
		selected = deck.duplicate()
		btn.queue_free()
		for child in cards_layer.get_children():
			child.queue_free()
		_build_grid()
		_update_counter())
	add_child(btn)

# Siodme miejsce za rubiny: tylko na sciezce i tylko, gdy gracz ma wiecej roslin,
# niz miesci sie w zwyklej talii.
func _build_rent_button() -> void:
	if GameState.is_event_game() or NetSession.active:
		return
	if GameState.unlocked_plant_indices().size() <= GameState.MAX_LOADOUT:
		return
	rent_button = Button.new()
	rent_button.position = Vector2(400, 640)
	rent_button.size = Vector2(480, 60)
	rent_button.focus_mode = Control.FOCUS_NONE
	rent_button.add_theme_font_size_override("font_size", 17)
	rent_button.pressed.connect(_on_rent_pressed)
	add_child(rent_button)
	var key := UiIcons.rent_slot(44)
	key.position = Vector2(10, 8)
	rent_button.add_child(key)
	var ruby := UiIcons.ruby(36)
	ruby.position = Vector2(rent_button.size.x - 46, 12)
	rent_button.add_child(ruby)
	_update_rent_button()

func _update_rent_button() -> void:
	if rent_button == null:
		return
	if rent_slot:
		rent_button.text = Lang.t("rent_cancel")
	else:
		rent_button.text = Lang.f("rent_offer", [GameState.RENT_SLOT_RUBIES])
	rent_button.disabled = not rent_slot and GameState.rubies < GameState.RENT_SLOT_RUBIES

func _on_rent_pressed() -> void:
	rent_slot = not rent_slot
	max_plants = GameState.MAX_LOADOUT + (1 if rent_slot else 0)
	subtitle.text = Lang.f("select_max", [max_plants])
	if rent_slot:
		message_label.text = Lang.t("rent_pay_later")
	else:
		message_label.text = ""
		while selected.size() > max_plants:
			var removed: int = selected.pop_back()
			_update_card_visual(removed)
	_update_rent_button()
	_update_counter()

func _build_grid() -> void:
	card_refs.clear()
	var total_width := CARDS_PER_ROW * CARD_SIZE.x + (CARDS_PER_ROW - 1) * CARD_GAP.x
	var start_x := (VIEWPORT_WIDTH - total_width) / 2.0
	var order := PlantData.unlock_order()
	for k in range(order.size()):
		var col := k % CARDS_PER_ROW
		var row := int(k / float(CARDS_PER_ROW))
		var x := start_x + col * (CARD_SIZE.x + CARD_GAP.x)
		var y := GRID_TOP + row * (CARD_SIZE.y + CARD_GAP.y)
		_build_card(order[k], x, y)

func _build_card(plant_idx: int, x: float, y: float) -> void:
	var pt: Dictionary = PlantData.TYPES[plant_idx]
	var unlocked := _is_plant_allowed(plant_idx)
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
	border_sb.set_border_width_all(4)
	border_sb.border_color = Color(0.15, 0.75, 0.2) if is_selected else Color(0.4, 0.4, 0.35)
	border_sb.set_corner_radius_all(14)
	for state in ["normal", "hover", "pressed", "disabled"]:
		card.add_theme_stylebox_override(state, border_sb)

	cards_layer.add_child(card)

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
	name_label.text = PlantData.name_of(plant_idx)
	name_label.position = Vector2(8, 130)
	name_label.size = Vector2(CARD_SIZE.x - 16, 24)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.clip_text = true
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
		mark.add_theme_stylebox_override("panel", UiIcons.round_style(Color(0.15, 0.75, 0.2), 13))
		card.add_child(mark)
	else:
		var lock_label := Label.new()
		lock_label.text = Lang.t("select_unavailable") if GameState.is_event_game() else Lang.f("select_from_level", [pt.get("unlock_level", 1)])
		lock_label.position = Vector2(8, 158)
		lock_label.size = Vector2(CARD_SIZE.x - 16, 24)
		lock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lock_label.add_theme_font_size_override("font_size", 14)
		lock_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(lock_label)

	card_refs[plant_idx] = {"border_sb": border_sb, "mark": mark}

# Czy roslina moze trafic do talii na tej planszy.
func _is_plant_allowed(plant_idx: int) -> bool:
	if forced_plants.has(plant_idx):
		return true
	if banned_roles.has(PlantData.TYPES[plant_idx]["role"]):
		return false
	# Narzucona talia: czwarta roslina moze byc dowolna, takze nieodblokowana,
	# zeby nowy gracz nie zaplacil za pomoc, ktorej nie ma jak uzyc.
	if not forced_plants.is_empty():
		return max_plants > forced_plants.size()
	return GameState.is_plant_unlocked(plant_idx)

func _on_card_pressed(plant_idx: int) -> void:
	if forced_plants.has(plant_idx):
		message_label.text = Lang.t("select_forced_locked")
		return
	if selected.has(plant_idx):
		selected.erase(plant_idx)
	else:
		if selected.size() >= max_plants:
			message_label.text = Lang.f("select_too_many", [max_plants])
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
	counter_label.text = Lang.f("select_count", [selected.size(), max_plants])
	if play_button:
		play_button.disabled = selected.is_empty()

func _on_back_pressed() -> void:
	NetSession.end_session()
	get_tree().change_scene_to_file(GameState.play_screen() if GameState.is_event_game() else "res://scenes/LevelSelect.tscn")

func _on_play_pressed() -> void:
	if selected.is_empty():
		return
	if selected.size() > GameState.MAX_LOADOUT and not GameState.rent_extra_slot():
		message_label.text = Lang.t("rent_no_rubies")
		return
	var ordered := []
	for i in range(PlantData.TYPES.size()):
		if selected.has(i):
			ordered.append(i)
	GameState.current_loadout = ordered
	GameState.set_loadout(_loadout_key(), ordered)
	if NetSession.active:
		# Gra z innym graczem rusza dopiero, gdy obaj gracze wybiora rosliny.
		play_button.disabled = true
		message_label.text = Lang.t("waiting_for_friend")
		NetSession.mark_ready()
		return
	_start_game()

# Gra z innym graczem i wydarzenia maja wlasne talie, niezalezne od poziomow sciezki.
func _loadout_key() -> int:
	if GameState.is_event_game():
		return EVENT_LOADOUT_KEY
	return TEAM_LOADOUT_KEY if NetSession.active else GameState.current_level_index

func _start_game() -> void:
	get_tree().change_scene_to_file("res://scenes/Main.tscn")
