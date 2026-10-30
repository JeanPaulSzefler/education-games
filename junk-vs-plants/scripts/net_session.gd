extends Node

# Gra zespolowa bez serwera (notatki 2026-10-30): telefony lacza sie ze soba
# bezposrednio w tej samej sieci Wi-Fi albo przez hotspot jednego z nich.
#
# 1. Ekran TeamPlay rozglasza po UDP "jestem tu" i zbiera graczy w poblizu.
# 2. Zapraszajacy (host) otwiera port gry i wysyla zaproszenie z losowym kodem.
# 3. Znajomy potwierdza na swoim koncie: laczy sie (ENet) i odsyla kod. Odmowa
#    albo brak odpowiedzi = gracze nie graja zespolowo.
# 4. W grze symulacje liczy tylko host: gosc wysyla swoje akcje i dostaje stan
#    planszy (patrz sekcja "Gra zespolowa" w main.gd).
#
# Wszystkie RPC ida przez ten autoload, bo istnieje on po obu stronach przez
# caly czas, niezaleznie od tego, jaka scena jest akurat wczytana.

const DISCOVERY_PORT := 47810
const GAME_PORT := 47811
# Podnosic przy kazdej zmianie protokolu - rozne wersje gry sie nie widza.
const PROTOCOL_VERSION := 2
const ANNOUNCE_INTERVAL := 1.0
const PLAYER_TIMEOUT := 3.5
const INVITE_RESEND_INTERVAL := 1.0
const INVITE_TIMEOUT := 30.0
const INCOMING_INVITE_TIMEOUT := 4.0
const MAX_PACKET_SIZE := 512
# Telefon, ktory zniknal, wykrywamy po kilku sekundach, a nie po domyslnych 30.
const PEER_TIMEOUT_MS := 8000

signal players_changed
signal invite_received(from_name: String)
signal invite_cancelled
signal invite_failed(reason: String)
signal session_started
signal game_starting
signal session_lost
signal snapshot_received(data: Dictionary)
signal event_received(kind: String, args: Array)
signal action_received(kind: String, args: Array)
signal action_error_received(text: String)
signal place_confirmed(plant_idx: int)
signal game_over_received(won: bool, enemy_texture: String)

# Trwa gra zespolowa (obaj gracze polaczeni).
var active := false
var is_host := false
# Host: gosc jest juz na scenie gry i symulacja moze ruszyc.
var guest_in_game := false
# Nawozy sa w grze wspolne, wiec liczy sie wiekszy limit z obu kont.
var team_fertilizer_limit := GameState.FERTILIZER_START_LIMIT
# Komunikat do pokazania na sciezce po przerwaniu gry.
var notice := ""

var players := {}  # id -> {"name", "icon", "ip", "seen"}

var my_id := ""
var udp: PacketPeerUDP
var announce_timer := 0.0
var clock := 0.0
var outgoing_invite := {}  # {"id", "ip", "token", "deadline", "next_send"}
var incoming_invite := {}  # {"id", "name", "ip", "token", "seen"}
var declined_tokens := []
var enet: ENetMultiplayerPeer
var guest_peer_id := 0
var host_ready := false
var guest_ready := false

func _ready() -> void:
	my_id = "%08x%08x" % [randi(), randi()]
	multiplayer.peer_connected.connect(_on_peer_connected)
	# Deferred: te reakcje zamykaja polaczenie, czego nie wolno robic w trakcie
	# obslugi jego zdarzen.
	multiplayer.peer_disconnected.connect(_on_peer_disconnected, CONNECT_DEFERRED)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed, CONNECT_DEFERRED)
	multiplayer.server_disconnected.connect(_on_connection_lost, CONNECT_DEFERRED)

func _process(delta: float) -> void:
	if udp == null:
		return
	clock += delta
	_read_packets()
	announce_timer -= delta
	if announce_timer <= 0.0:
		announce_timer = ANNOUNCE_INTERVAL
		_announce()
		_forget_silent_players()
	_update_invites()

# --- Szukanie graczy w poblizu ---
# Zwraca false, gdy port jest zajety.
func start_discovery() -> bool:
	stop_discovery()
	players.clear()
	udp = PacketPeerUDP.new()
	udp.set_broadcast_enabled(true)
	if udp.bind(DISCOVERY_PORT) != OK:
		udp = null
		return false
	announce_timer = 0.0
	return true

func stop_discovery() -> void:
	if udp != null:
		udp.close()
		udp = null
	incoming_invite = {}
	declined_tokens.clear()

# Adresy IPv4 tego telefonu w sieciach lokalnych. Pusta lista = brak Wi-Fi.
func local_addresses() -> Array:
	var result := []
	for address in IP.get_local_addresses():
		if address.begins_with("10.") or address.begins_with("192.168."):
			result.append(address)
		elif address.begins_with("172."):
			var second := address.get_slice(".", 1).to_int()
			if second >= 16 and second <= 31:
				result.append(address)
	return result

func _announce() -> void:
	var packet := {"t": "hello", "name": GameState.player_name, "icon": GameState.player_icon}
	_send(packet, "255.255.255.255")
	# Na hotspocie ogolny broadcast czesto idzie do sieci komorkowej, wiec
	# wysylamy tez na adres rozgloszeniowy kazdej sieci lokalnej.
	for address in local_addresses():
		var parts: PackedStringArray = address.split(".")
		_send(packet, "%s.%s.%s.255" % [parts[0], parts[1], parts[2]])

func _send(packet: Dictionary, ip: String) -> void:
	var data := packet.duplicate()
	data["v"] = PROTOCOL_VERSION
	data["id"] = my_id
	udp.set_dest_address(ip, DISCOVERY_PORT)
	udp.put_packet(JSON.stringify(data).to_utf8_buffer())

func _read_packets() -> void:
	while udp.get_available_packet_count() > 0:
		var raw := udp.get_packet()
		var ip := udp.get_packet_ip()
		if raw.size() > MAX_PACKET_SIZE:
			continue
		var json := JSON.new()
		if json.parse(raw.get_string_from_utf8()) != OK or not (json.data is Dictionary):
			continue
		var packet: Dictionary = json.data
		if packet.get("v") != float(PROTOCOL_VERSION) or not (packet.get("id") is String) or packet["id"] == my_id:
			continue
		_handle_packet(packet, ip)

func _handle_packet(packet: Dictionary, ip: String) -> void:
	var sender: String = packet["id"]
	match packet.get("t"):
		"hello":
			_on_hello(packet, sender, ip)
		"invite":
			_on_invite(packet, sender, ip)
		"cancel":
			if not incoming_invite.is_empty() and incoming_invite["id"] == sender:
				incoming_invite = {}
				invite_cancelled.emit()
		"decline":
			if not outgoing_invite.is_empty() and outgoing_invite["id"] == sender:
				_abort_invite("Znajomy nie moze teraz zagrac.")

func _on_hello(packet: Dictionary, sender: String, ip: String) -> void:
	var icon = packet.get("icon")
	if not (packet.get("name") is String) or not (icon is float or icon is int):
		return
	var known := players.has(sender)
	players[sender] = {
		"name": str(packet["name"]).left(GameState.PLAYER_NAME_MAX_LENGTH),
		"icon": clampi(int(icon), 0, PlantData.TYPES.size() - 1),
		"ip": ip,
		"seen": clock,
	}
	if not known:
		# Odpowiedz wprost - rozgloszenia nie zawsze dochodza w obie strony.
		if not packet.get("reply", false):
			_send({"t": "hello", "name": GameState.player_name, "icon": GameState.player_icon, "reply": true}, ip)
		players_changed.emit()

func _forget_silent_players() -> void:
	var changed := false
	for id in players.keys():
		if clock - players[id]["seen"] > PLAYER_TIMEOUT:
			players.erase(id)
			changed = true
	if changed:
		players_changed.emit()

# --- Zaproszenia ---
# Zwraca false, gdy nie da sie otworzyc portu gry.
func send_invite(player_id: String) -> bool:
	if not players.has(player_id):
		return false
	enet = ENetMultiplayerPeer.new()
	if enet.create_server(GAME_PORT, 1) != OK:
		enet = null
		return false
	multiplayer.multiplayer_peer = enet
	outgoing_invite = {
		"id": player_id,
		"ip": players[player_id]["ip"],
		"token": "%08x%08x" % [randi(), randi()],
		"deadline": clock + INVITE_TIMEOUT,
		"next_send": clock,
	}
	return true

func cancel_invite() -> void:
	if outgoing_invite.is_empty():
		return
	_send({"t": "cancel"}, outgoing_invite["ip"])
	outgoing_invite = {}
	_close_peer()

func _abort_invite(reason: String) -> void:
	outgoing_invite = {}
	_close_peer()
	invite_failed.emit(reason)

func _update_invites() -> void:
	if not outgoing_invite.is_empty():
		if clock >= outgoing_invite["deadline"]:
			_abort_invite("Znajomy nie potwierdzil gry.")
		elif clock >= outgoing_invite["next_send"]:
			outgoing_invite["next_send"] = clock + INVITE_RESEND_INTERVAL
			_send({"t": "invite", "name": GameState.player_name, "token": outgoing_invite["token"]}, outgoing_invite["ip"])
	# Zaproszenie przestalo przychodzic - zapraszajacy zniknal.
	if not incoming_invite.is_empty() and enet == null and clock - incoming_invite["seen"] > INCOMING_INVITE_TIMEOUT:
		incoming_invite = {}
		invite_cancelled.emit()

func _on_invite(packet: Dictionary, sender: String, ip: String) -> void:
	if not (packet.get("name") is String) or not (packet.get("token") is String):
		return
	var token: String = packet["token"]
	if declined_tokens.has(token):
		_send({"t": "decline"}, ip)
		return
	if not incoming_invite.is_empty():
		if incoming_invite["token"] == token:
			incoming_invite["seen"] = clock
		else:
			_send({"t": "decline"}, ip)
		return
	# Sami kogos zapraszamy albo laczymy sie - teraz nie mozemy.
	if enet != null:
		_send({"t": "decline"}, ip)
		return
	var from_name := str(packet["name"]).left(GameState.PLAYER_NAME_MAX_LENGTH)
	incoming_invite = {"id": sender, "name": from_name, "ip": ip, "token": token, "seen": clock}
	invite_received.emit(from_name)

func accept_invite() -> void:
	if incoming_invite.is_empty():
		return
	enet = ENetMultiplayerPeer.new()
	if enet.create_client(incoming_invite["ip"], GAME_PORT) != OK:
		enet = null
		incoming_invite = {}
		invite_failed.emit("Nie udalo sie polaczyc ze znajomym.")
		return
	multiplayer.multiplayer_peer = enet

func decline_invite() -> void:
	if incoming_invite.is_empty():
		return
	declined_tokens.append(incoming_invite["token"])
	_send({"t": "decline"}, incoming_invite["ip"])
	incoming_invite = {}

# --- Polaczenie ---
func _on_peer_connected(id: int) -> void:
	if enet != null and enet.get_unique_id() == 1:
		_set_peer_timeout(id)

func _on_connected_to_server() -> void:
	_set_peer_timeout(1)
	_rpc_join.rpc_id(1, incoming_invite.get("token", ""), GameState.team_level_index(), GameState.fertilizer_limit)

func _on_connection_failed() -> void:
	incoming_invite = {}
	_close_peer()
	invite_failed.emit("Nie udalo sie polaczyc ze znajomym.")

func _on_peer_disconnected(id: int) -> void:
	if active and id == guest_peer_id:
		_on_connection_lost()

func _on_connection_lost() -> void:
	if not active:
		incoming_invite = {}
		_close_peer()
		invite_failed.emit("Nie udalo sie polaczyc ze znajomym.")
		return
	notice = "Polaczenie ze znajomym zostalo przerwane."
	end_session()
	session_lost.emit()

func _set_peer_timeout(id: int) -> void:
	var peer := enet.get_peer(id)
	if peer != null:
		peer.set_timeout(0, PEER_TIMEOUT_MS / 2, PEER_TIMEOUT_MS)

func _close_peer() -> void:
	if enet != null:
		enet.close()
		enet = null
	multiplayer.multiplayer_peer = null

func end_session() -> void:
	active = false
	is_host = false
	guest_in_game = false
	host_ready = false
	guest_ready = false
	guest_peer_id = 0
	outgoing_invite = {}
	GameState.team_level = {}
	_close_peer()
	stop_discovery()

func _begin_session(host: bool) -> void:
	active = true
	is_host = host
	outgoing_invite = {}
	incoming_invite = {}
	stop_discovery()
	session_started.emit()

# Gosc odsyla kod z zaproszenia. Kto inny w tej sieci nie dolaczy do gry.
@rpc("any_peer", "call_remote", "reliable")
func _rpc_join(token: String, guest_level: int, guest_fertilizer_limit: int) -> void:
	var sender := multiplayer.get_remote_sender_id()
	if outgoing_invite.is_empty() or token != outgoing_invite["token"]:
		enet.disconnect_peer(sender)
		return
	guest_peer_id = sender
	var level := clampi(guest_level, 0, GameState.LEVEL_COUNT - 1)
	var difficulty := LevelData.team_difficulty(GameState.team_level_index(), level)
	var boss := LevelData.random_team_boss(difficulty)
	var limit: int = max(GameState.fertilizer_limit, guest_fertilizer_limit)
	_rpc_welcome.rpc_id(sender, difficulty, boss, limit)
	_setup_team_game(difficulty, boss, limit)
	_begin_session(true)

@rpc("authority", "call_remote", "reliable")
func _rpc_welcome(difficulty: int, boss: int, fertilizer_limit: int) -> void:
	_setup_team_game(difficulty, boss, fertilizer_limit)
	_begin_session(false)

func _setup_team_game(difficulty: int, boss: int, fertilizer_limit: int) -> void:
	GameState.current_level_index = difficulty
	GameState.team_level = LevelData.team_level(difficulty, boss)
	team_fertilizer_limit = fertilizer_limit

# --- Start gry: czekamy, az obaj wybiora rosliny, a potem, az gosc wczyta plansze ---
func mark_ready() -> void:
	if is_host:
		host_ready = true
		_start_if_both_ready()
	else:
		_rpc_guest_ready.rpc_id(1)

@rpc("any_peer", "call_remote", "reliable")
func _rpc_guest_ready() -> void:
	if multiplayer.get_remote_sender_id() != guest_peer_id:
		return
	guest_ready = true
	_start_if_both_ready()

func _start_if_both_ready() -> void:
	if host_ready and guest_ready:
		_rpc_begin_game.rpc_id(guest_peer_id)
		game_starting.emit()

@rpc("authority", "call_remote", "reliable")
func _rpc_begin_game() -> void:
	game_starting.emit()

func notify_guest_in_game() -> void:
	_rpc_guest_in_game.rpc_id(1)

@rpc("any_peer", "call_remote", "reliable")
func _rpc_guest_in_game() -> void:
	if multiplayer.get_remote_sender_id() == guest_peer_id:
		guest_in_game = true

# --- W trakcie gry ---
func send_snapshot(data: Dictionary) -> void:
	_rpc_snapshot.rpc_id(guest_peer_id, data)

@rpc("authority", "call_remote", "unreliable_ordered")
func _rpc_snapshot(data: Dictionary) -> void:
	snapshot_received.emit(data)

func send_event(kind: String, args: Array) -> void:
	_rpc_event.rpc_id(guest_peer_id, kind, args)

@rpc("authority", "call_remote", "reliable")
func _rpc_event(kind: String, args: Array) -> void:
	event_received.emit(kind, args)

func send_action(kind: String, args: Array) -> void:
	_rpc_action.rpc_id(1, kind, args)

@rpc("any_peer", "call_remote", "reliable")
func _rpc_action(kind: String, args: Array) -> void:
	if multiplayer.get_remote_sender_id() == guest_peer_id:
		action_received.emit(kind, args)

func send_action_error(text: String) -> void:
	_rpc_action_error.rpc_id(guest_peer_id, text)

@rpc("authority", "call_remote", "reliable")
func _rpc_action_error(text: String) -> void:
	action_error_received.emit(text)

func send_place_confirmed(plant_idx: int) -> void:
	_rpc_place_confirmed.rpc_id(guest_peer_id, plant_idx)

@rpc("authority", "call_remote", "reliable")
func _rpc_place_confirmed(plant_idx: int) -> void:
	place_confirmed.emit(plant_idx)

func send_game_over(won: bool, enemy_texture: String) -> void:
	_rpc_game_over.rpc_id(guest_peer_id, won, enemy_texture)

@rpc("authority", "call_remote", "reliable")
func _rpc_game_over(won: bool, enemy_texture: String) -> void:
	game_over_received.emit(won, enemy_texture)
