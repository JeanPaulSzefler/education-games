extends Control

# Gra zespolowa (notatki 2026-10-30): gracz wybiera znajomego z listy osob w
# poblizu, a znajomy musi potwierdzic gre na swoim koncie. Obaj musza miec ten
# ekran otwarty i byc w tej samej sieci Wi-Fi (albo na hotspocie jednego z nich).

const VIEWPORT_WIDTH := 1280
const VIEWPORT_HEIGHT := 720

const CARD_SIZE := Vector2(170, 210)
const CARD_GAP := 22.0
const CARD_Y := 250.0
const MAX_CARDS := 6
const CARD_COLOR := Color(0.3, 0.45, 0.25)
const OK_BTN_COLOR := Color(0.25, 0.6, 0.25)
const NO_BTN_COLOR := Color(0.75, 0.18, 0.15)
const POPUP_BG_COLOR := Color(0.95, 0.93, 0.85)
const POPUP_TEXT_COLOR := Color(0.15, 0.12, 0.1)
const NO_WIFI_CHECK_INTERVAL := 2.0

var cards: Control
var status_label: Label
var popup: Control
var wifi_timer := 0.0

func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.15, 0.25, 0.15)
	bg.size = Vector2(VIEWPORT_WIDTH, VIEWPORT_HEIGHT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var garden := NetSession.mode == NetSession.MODE_GARDEN
	var title := _label("Sadzimy razem" if garden else "Gra zespolowa", 44, Vector2(0, 30), VIEWPORT_WIDTH)
	add_child(title)
	add_child(_label("Wybierz znajomego. Musicie byc w tej samej sieci Wi-Fi albo na hotspocie jednego z telefonow.", 22, Vector2(0, 100), VIEWPORT_WIDTH))
	add_child(_label("Znajomy tez musi miec otwarty ten ekran na swoim koncie.", 22, Vector2(0, 136), VIEWPORT_WIDTH))

	status_label = _label("", 24, Vector2(0, 490), VIEWPORT_WIDTH)
	add_child(status_label)

	cards = Control.new()
	cards.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(cards)

	var back_btn := _button("Wroc", CARD_COLOR, Vector2(40, 620), Vector2(220, 70))
	back_btn.pressed.connect(_on_back_pressed)
	add_child(back_btn)

	NetSession.players_changed.connect(_rebuild_cards)
	NetSession.invite_received.connect(_show_incoming_invite)
	NetSession.invite_cancelled.connect(_on_invite_cancelled)
	NetSession.invite_failed.connect(_on_invite_failed)
	NetSession.session_started.connect(_on_session_started)

	if not NetSession.start_discovery():
		status_label.text = "Nie udalo sie wlaczyc szukania znajomych."
		return
	_rebuild_cards()

func _process(delta: float) -> void:
	wifi_timer -= delta
	if wifi_timer <= 0.0:
		wifi_timer = NO_WIFI_CHECK_INTERVAL
		if popup == null and NetSession.players.is_empty():
			_update_empty_status()

func _update_empty_status() -> void:
	if NetSession.local_addresses().is_empty():
		status_label.text = "Brak sieci - polacz telefon z Wi-Fi albo wlacz hotspot."
	else:
		status_label.text = "Szukam znajomych w poblizu..."

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

func _rebuild_cards() -> void:
	for card in cards.get_children():
		card.queue_free()
	var ids: Array = NetSession.players.keys().slice(0, MAX_CARDS)
	if ids.is_empty():
		_update_empty_status()
		return
	status_label.text = ""
	var start_x := (VIEWPORT_WIDTH - (ids.size() * CARD_SIZE.x + (ids.size() - 1) * CARD_GAP)) / 2.0
	for i in range(ids.size()):
		var id: String = ids[i]
		var player: Dictionary = NetSession.players[id]
		var card := Button.new()
		card.position = Vector2(start_x + i * (CARD_SIZE.x + CARD_GAP), CARD_Y)
		card.size = CARD_SIZE
		card.focus_mode = Control.FOCUS_NONE
		UiIcons.style_button(card, CARD_COLOR, 18)
		cards.add_child(card)
		var icon := UiIcons.plant_icon(player["icon"], 120)
		icon.position = Vector2((CARD_SIZE.x - 120) / 2.0, 20)
		card.add_child(icon)
		var name_label := _label(player["name"], 22, Vector2(6, 150), CARD_SIZE.x - 12)
		name_label.clip_text = true
		card.add_child(name_label)
		card.pressed.connect(func(): _invite(id))

func _invite(id: String) -> void:
	var friend_name: String = NetSession.players[id]["name"]
	if not NetSession.send_invite(id):
		status_label.text = "Nie udalo sie wyslac zaproszenia."
		return
	var panel := _open_popup("Czekam, az %s potwierdzi gre..." % friend_name)
	var cancel_btn := _button("ANULUJ", NO_BTN_COLOR, Vector2((panel.size.x - 220) / 2.0, 170), Vector2(220, 70))
	cancel_btn.pressed.connect(func():
		NetSession.cancel_invite()
		_close_popup())
	panel.add_child(cancel_btn)

func _show_incoming_invite(from_name: String) -> void:
	var panel := _open_popup("%s zaprasza Cie do gry zespolowej!" % from_name)
	var no_btn := _button("NIE TERAZ", NO_BTN_COLOR, Vector2(50, 170), Vector2(240, 70))
	no_btn.pressed.connect(func():
		NetSession.decline_invite()
		_close_popup())
	panel.add_child(no_btn)
	var yes_btn := _button("ZAGRAJ", OK_BTN_COLOR, Vector2(panel.size.x - 290, 170), Vector2(240, 70))
	yes_btn.pressed.connect(func():
		_close_popup()
		status_label.text = "Lacze ze znajomym..."
		NetSession.accept_invite())
	panel.add_child(yes_btn)

func _on_invite_cancelled() -> void:
	_close_popup()
	status_label.text = "Znajomy wycofal zaproszenie."

func _on_invite_failed(reason: String) -> void:
	_close_popup()
	status_label.text = reason

func _on_session_started() -> void:
	var garden := NetSession.mode == NetSession.MODE_GARDEN
	get_tree().change_scene_to_file("res://scenes/SharedGarden.tscn" if garden else "res://scenes/PlantSelect.tscn")

func _on_back_pressed() -> void:
	var garden := NetSession.mode == NetSession.MODE_GARDEN
	NetSession.cancel_invite()
	NetSession.end_session()
	get_tree().change_scene_to_file("res://scenes/Garden.tscn" if garden else "res://scenes/LevelSelect.tscn")

func _open_popup(text: String) -> Panel:
	_close_popup()
	popup = Control.new()
	popup.size = Vector2(VIEWPORT_WIDTH, VIEWPORT_HEIGHT)
	add_child(popup)

	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.6)
	shade.size = popup.size
	popup.add_child(shade)

	var panel := Panel.new()
	panel.size = Vector2(620, 280)
	panel.position = (popup.size - panel.size) / 2.0
	var sb := StyleBoxFlat.new()
	sb.bg_color = POPUP_BG_COLOR
	sb.set_border_width_all(5)
	sb.border_color = Color(0.25, 0.2, 0.15)
	sb.set_corner_radius_all(18)
	panel.add_theme_stylebox_override("panel", sb)
	popup.add_child(panel)

	var label := _label(text, 28, Vector2(30, 40), panel.size.x - 60)
	label.size.y = 110
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", POPUP_TEXT_COLOR)
	panel.add_child(label)
	return panel

func _close_popup() -> void:
	if popup != null:
		popup.queue_free()
		popup = null
