# test_negative_multiplayer_networking.gd
# Tier 1 Negative Boundary Suite: Connection Refused, HTTP Timeouts, Malformed JSON, Port Collisions & Buffer EOF.
extends "res://addons/gdtest/core/test_suite.gd"

func _init() -> void:
	suite_name = "Tier1_Negative_Multiplayer_Networking"
	test_type = "integration"

# ==============================================================================
# 1. CLOSED PORT CONNECTION AND PEER TEARDOWN
# ==============================================================================

func test_enet_connection_closed_port_handling() -> void:
	var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	# Connect to local port 59998 where no server is listening
	var err: Error = peer.create_client("127.0.0.1", 59998)
	assert_eq(err, OK, "create_client returns OK on initiating connection attempt")
	
	var status: int = peer.get_connection_status()
	assert_true(
		status == MultiplayerPeer.CONNECTION_CONNECTING or status == MultiplayerPeer.CONNECTION_DISCONNECTED,
		"Client peer status is CONNECTING or DISCONNECTED"
	)
	
	# Clean peer shutdown
	peer.close()
	assert_eq(peer.get_connection_status(), MultiplayerPeer.CONNECTION_DISCONNECTED, "Status after close is DISCONNECTED")

# ==============================================================================
# 2. HTTP TIMEOUT CONFIGURATION AND RESULT ENUMS
# ==============================================================================

func test_http_request_timeout_configuration_and_result_enum() -> void:
	var http: HTTPRequest = autofree(HTTPRequest.new()) as HTTPRequest
	add_child(http)
	
	http.timeout = 0.05
	assert_approx(http.timeout, 0.05, 0.001, "HTTPRequest timeout configured to 50ms")
	
	# Verify standard Godot HTTPRequest.Result enum constants
	assert_eq(HTTPRequest.RESULT_SUCCESS, 0, "RESULT_SUCCESS is 0")
	assert_eq(HTTPRequest.RESULT_TIMEOUT, 13, "RESULT_TIMEOUT is 13")
	assert_eq(HTTPRequest.RESULT_CANT_CONNECT, 2, "RESULT_CANT_CONNECT is 2")
	
	# Safe cancel of unstarted or active request
	http.cancel_request()
	assert_eq(http.get_http_client_status(), HTTPClient.STATUS_DISCONNECTED, "HTTP client status is DISCONNECTED")

# ==============================================================================
# 3. MALFORMED NON-JSON RESPONSES & PARSER RESILIENCE
# ==============================================================================

func test_json_parsing_malformed_non_json_strings() -> void:
	var malformed_payloads: Array[String] = [
		"{ invalid_key_missing_quotes: 123 }",
		"<html><head><title>500 Internal Server Error</title></head><body><h1>Server Error</h1></body></html>",
		"['unterminated array string",
		"{ \"key\": ",
		"undefined",
		"NaN",
		"<<< XML PACKET >>>"
	]
	
	for payload: String in malformed_payloads:
		# Static JSON parse string must return null on error without throwing
		var parsed: Variant = JSON.parse_string(payload)
		assert_null(parsed, "Malformed payload must parse to null: '%s'" % payload.substr(0, 25))
		
		# Instance-based parser inspection
		var json_obj: JSON = JSON.new()
		var err: Error = json_obj.parse(payload)
		assert_ne(err, OK, "Instance parse must return an error code for malformed payload")
		assert_gt(json_obj.get_error_message().length(), 0, "Error message must be populated")

# ==============================================================================
# 4. DUPLICATE PORT COLLISIONS
# ==============================================================================

func test_duplicate_port_collision_error_handling() -> void:
	var peer1: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	var peer2: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	
	# Bind peer1 to dynamic ephemeral port
	var err1: Error = peer1.create_server(0, 2)
	assert_eq(err1, OK, "Peer1 server creation must succeed")
	
	var host: ENetConnection = peer1.get_host()
	assert_not_null(host, "Host must be allocated")
	var bound_port: int = host.get_local_port()
	assert_gt(bound_port, 0, "Bound port must be > 0")
	
	# Attempt to bind peer2 to the exact same port (must fail with collision error)
	var err2: Error = peer2.create_server(bound_port, 2)
	assert_ne(err2, OK, "Peer2 must fail to bind to already occupied port %d" % bound_port)
	
	# Clean release
	peer1.close()
	peer2.close()

# ==============================================================================
# 5. STREAM PEER BUFFER EOF READS AND UNDERFLOW
# ==============================================================================

func test_stream_peer_buffer_eof_reads_and_underflow() -> void:
	var buffer: StreamPeerBuffer = StreamPeerBuffer.new()
	buffer.put_u32(0xCAFEBABE)
	buffer.seek(0)
	
	var val: int = buffer.get_u32()
	assert_eq(val, 0xCAFEBABE, "Read valid u32 value from buffer")
	assert_eq(buffer.get_position(), 4, "Buffer position at 4")
	assert_eq(buffer.get_size(), 4, "Buffer size is 4")
	
	# Read beyond EOF safely without crashing
	var eof_val_u32: int = buffer.get_u32()
	assert_true(typeof(eof_val_u32) == TYPE_INT, "Reading u32 beyond EOF returns int safely")
	
	var eof_val_float: float = buffer.get_float()
	assert_true(typeof(eof_val_float) == TYPE_FLOAT, "Reading float beyond EOF returns float safely")
	
	var data_result: Array = buffer.get_data(100)
	assert_ne(data_result[0], OK, "get_data beyond buffer size returns non-OK error code")
	
	# Empty buffer initialization
	var empty_buf: StreamPeerBuffer = StreamPeerBuffer.new()
	assert_eq(empty_buf.get_size(), 0, "Empty buffer size is 0")
	assert_eq(empty_buf.get_u8(), 0, "Reading u8 on empty buffer returns 0")
