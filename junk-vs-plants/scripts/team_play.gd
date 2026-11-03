extends Control

# Gra z innym graczem (notatki 2026-10-30 i 2026-11-03): gracz najpierw wybiera
# wspolprace (jedna plansza) albo rywalizacje (pojedynek), potem znajomego z
# listy osob w poblizu, a znajomy musi potwierdzic gre na swoim koncie. Obaj
# musza miec ten ekran otwarty i byc w tej samej sieci Wi-Fi (albo na hotspocie
# jednego z nich). Ten sam ekran laczy tez do sadzenia razem i wymiany naklejek.

const VIEWPORT_WIDTH := 1280
const VIEWPORT_HEIGHT := 720

const CARD_SIZE := Vector2(170, 210)
const CARD_GAP := 22.0
const CARD_Y := 250.0
const MAX_CARDS := 6
const MODE_CARD_SIZE := Vector2(440, 330)
const CARD_COLOR := Color(0.3, 0.45, 0.25)
const DUEL_COLOR := Color(0.6, 0.3, 0.2)
const OK_BTN_COLOR := Color(0.25, 0.6, 0.25)
const NO_BTN_COLOR := Color(0.75, 0.18, 0.15)
const POPUP_BG_COLOR := Color(0.95, 0.93, 0.85)
const POPUP_TEXT_COLOR := Color(0.15, 0.12, 0.1)
const NO_WIFI_CHECK_INTERVAL := 2.0

var cards: Control
var status_label: Label
var title_label: Label
var hint_labels: Array = []
var mode_layer: Control
var popup: Control
var wifi_timer := 0.0
# Wybrano juz tryb i trwa szukanie znajomych.
var searching := false

func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.15, 0.25, 0.15)
	bg.size = Vector2(VIEWPORT_WIDTH, VIEWPORT_HEIGHT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	var picture := UiIcons.background(Vector2(VIEWPORT_WIDTH, VIEWPORT_HEIGHT))
	if picture != null:
		picture.modulate = Color(0.55, 0.55, 0.55)
		add_child(picture)

	title_label = _label("", 44, Vector2(0, 30), VIEWPORT_WIDTH)
	add_child(title_label)
	for i in range(2):
		var hint := _label("", 22, Vector2(0, 100 + i * 36), VIEWPORT_WIDTH)
		hint_labels.append(hint)
		add_child(hint)

	status_label = _label("", 24, Vector2(0, 490), VIEWPORT_WIDTH)
	add_child(status_label)

	cards = Control.new()
	cards.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(cards)

	var back_btn := _button(Lang.t("back"), CARD_COLOR, Vector2(40, 620), Vector2(220, 70))
	back_btn.pressed.connect(_on_back_pressed)
	add_child(back_btn)

	NetSession.players_changed.connect(_rebuild_cards)
	NetSession.invite_received.connect(_show_incoming_invite)
	NetSession.invite_cancelled.connect(_on_invite_cancelled)
	NetSession.invite_failed.connect(_on_invite_failed)
	NetSession.session_started.connect(_on_session_started)
	NetSession.album_received.connect(_on_album_received)

	# Zaproszenia od znajomych dochodza od razu, takze przy wyborze trybu.
	if not NetSession.start_discovery():
		status_label.text = Lang.t("mp_no_discovery")
		return
	if NetSession.mode == NetSession.MODE_GARDEN or NetSession.mode == NetSession.MODE_ALBUM or NetSession.mode_chosen:
		NetSession.mode_chosen = false
		_start_search()
	else:
		_show_mode_choice()

func _process(delta: float) -> void:
	if not searching:
		return
	wifi_timer -= delta
	if wifi_timer <= 0.0:
		wifi_timer = NO_WIFI_CHECK_INTERVAL
		if popup == null and NetSession.players.is_empty():
			_update_empty_status()

func _update_empty_status() -> void:
	if NetSession.local_addresses().is_empty():
		status_label.text = Lang.t("mp_no_network")
	else:
		status_label.text = Lang.t("mp_searching")

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

func _mode_title(mode: String) -> String:
	return Lang.t("mp_title_" + mode)

# --- Wybor: wspolpraca albo rywalizacja ---
func _show_mode_choice() -> void:
	title_label.text = Lang.t("mp_title")
	hint_labels[0].text = Lang.t("mp_choose_mode")
	mode_layer = Control.new()
	add_child(mode_layer)
	var gap := 60.0
	var start_x := (VIEWPORT_WIDTH - 2 * MODE_CARD_SIZE.x - gap) / 2.0
	var modes := [NetSession.MODE_GAME, NetSession.MODE_DUEL]
	for i in range(modes.size()):
		var mode: String = modes[i]
		var card := _button("", CARD_COLOR if i == 0 else DUEL_COLOR, Vector2(start_x + i * (MODE_CARD_SIZE.x + gap), 170), MODE_CARD_SIZE)
		mode_layer.add_child(card)
		var icon := UiIcons.multiplayer_icon(130, mode == NetSession.MODE_DUEL)
		icon.position = Vector2((MODE_CARD_SIZE.x - 130) / 2.0, 20)
		card.add_child(icon)
		card.add_child(_label(_mode_title(mode), 32, Vector2(10, 160), MODE_CARD_SIZE.x - 20))
		var desc := _label(Lang.t("mp_desc_" + mode), 18, Vector2(24, 210), MODE_CARD_SIZE.x - 48)
		desc.size.y = 110
		UiIcons.wrap_label(desc, Vector2(MODE_CARD_SIZE.x - 48, desc.size.y))
		card.add_child(desc)
		card.pressed.connect(func():
			NetSession.mode = mode
			mode_layer.queue_free()
			_start_search())

func _start_search() -> void:
	searching = true
	title_label.text = _mode_title(NetSession.mode)
	hint_labels[0].text = Lang.t("mp_hint_network")
	hint_labels[1].text = Lang.t("mp_hint_screen")
	_rebuild_cards()

func _rebuild_cards() -> void:
	if not searching:
		return
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
		status_label.text = Lang.t("mp_invite_failed")
		return
	var panel := _open_popup(Lang.f("mp_waiting_for", [friend_name]))
	var cancel_btn := _button(Lang.t("cancel"), NO_BTN_COLOR, Vector2((panel.size.x - 220) / 2.0, 170), Vector2(220, 70))
	cancel_btn.pressed.connect(func():
		NetSession.cancel_invite()
		_close_popup())
	panel.add_child(cancel_btn)

func _show_incoming_invite(from_name: String) -> void:
	var panel := _open_popup(Lang.f("mp_invite_" + NetSession.incoming_mode(), [from_name]))
	var no_btn := _button(Lang.t("not_now"), NO_BTN_COLOR, Vector2(50, 170), Vector2(240, 70))
	no_btn.pressed.connect(func():
		NetSession.decline_invite()
		_close_popup())
	panel.add_child(no_btn)
	var yes_btn := _button(Lang.t("play"), OK_BTN_COLOR, Vector2(panel.size.x - 290, 170), Vector2(240, 70))
	yes_btn.pressed.connect(func():
		_close_popup()
		status_label.text = Lang.t("mp_connecting")
		NetSession.accept_invite())
	panel.add_child(yes_btn)

func _on_invite_cancelled() -> void:
	_close_popup()
	status_label.text = Lang.t("mp_invite_withdrawn")

func _on_invite_failed(reason: String) -> void:
	_close_popup()
	status_label.text = reason

func _on_session_started() -> void:
	match NetSession.mode:
		NetSession.MODE_GARDEN:
			get_tree().change_scene_to_file("res://scenes/SharedGarden.tscn")
		NetSession.MODE_ALBUM:
			if mode_layer != null and is_instance_valid(mode_layer):
				mode_layer.queue_free()
			_open_popup(Lang.t("album_trading"))
			NetSession.send_album(GameState.album)
		_:
			get_tree().change_scene_to_file("res://scenes/PlantSelect.tscn")

# Wymiana naklejek: obie strony licza te same pary i od razu je zapisuja.
func _on_album_received(owned: Dictionary) -> void:
	var trades := NetSession.album_trades(GameState.album, owned)
	for trade in trades:
		GameState.trade_sticker(trade[0], trade[1])
	# Chwila zwloki, zeby nasz album zdazyl dojsc do znajomego przed rozlaczeniem.
	get_tree().create_timer(1.5).timeout.connect(NetSession.end_session)
	var panel := _open_popup(Lang.f("album_traded", [trades.size()]) if not trades.is_empty() else Lang.t("album_nothing_to_trade"))
	var ok_btn := _button(Lang.t("ok"), OK_BTN_COLOR, Vector2((panel.size.x - 220) / 2.0, 170), Vector2(220, 70))
	ok_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/Rotation.tscn"))
	panel.add_child(ok_btn)

func _on_back_pressed() -> void:
	var target := "res://scenes/LevelSelect.tscn"
	if NetSession.mode == NetSession.MODE_GARDEN:
		target = "res://scenes/Garden.tscn"
	elif NetSession.mode == NetSession.MODE_ALBUM:
		target = "res://scenes/Rotation.tscn"
	NetSession.cancel_invite()
	NetSession.end_session()
	get_tree().change_scene_to_file(target)

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
	UiIcons.wrap_label(label, Vector2(panel.size.x - 60, label.size.y))
	label.add_theme_color_override("font_color", POPUP_TEXT_COLOR)
	panel.add_child(label)
	return panel

func _close_popup() -> void:
	if popup != null:
		popup.queue_free()
		popup = null
