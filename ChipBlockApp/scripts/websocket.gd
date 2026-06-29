extends Node

signal mood_changed(mood: String)
signal tracker_data_updated(url: String, trackers: Array, fingerprinters: Array)

var tcp_server = TCPServer.new()
var peers: Array = []

func _ready():
	tcp_server.listen(8765)

func _process(_delta):
	if tcp_server.is_connection_available():
		var conn = tcp_server.take_connection()
		var ws = WebSocketPeer.new()
		ws.accept_stream(conn)
		peers.append(ws)
		print("Client connected")

	for peer in peers:
		peer.poll()
		if peer.get_ready_state() == WebSocketPeer.STATE_OPEN:
			while peer.get_available_packet_count() > 0:
				var message = peer.get_packet().get_string_from_utf8()
				print("Received: ", message)
				var data = JSON.parse_string(message)
				if data and data.get("type") == "tracker_update":
					handle_tracker_data(data)
				elif data and data.get("type") == "socialTimerExpired":
					mood_changed.emit("social")
				elif data and data.get("type") == "news_site":
					mood_changed.emit("news")

	peers = peers.filter(func(p): return p.get_ready_state() != WebSocketPeer.STATE_CLOSED)


func handle_tracker_data(data):
	var url = data.get("url", "")
	var trackers = data.get("trackers", [])
	var fingerprinters = data.get("fingerprinters", [])
	tracker_data_updated.emit(url, trackers, fingerprinters)

	print("Trackers: ", data.get("trackers", []).size(), " Fingerprinters: ", data.get("fingerprinters", []).size())
	
	
	if trackers.size() > 10 || fingerprinters.size() > 2:
		mood_changed.emit("panic")
	elif trackers.size() > 5 || fingerprinters.size() > 1:
		mood_changed.emit("scared")
	elif trackers.size() > 0 || fingerprinters.size() > 0:
		mood_changed.emit("nervous")
	else:
		mood_changed.emit("happy")
