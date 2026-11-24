# test_meta_network_mocker.gd
# Meta Test Suite: Ephemeral Loopback Network Mocker and HTTP Request Simulation.
# Validates ephemeral TCP/HTTP server lifecycle (port binding), JSON route mocking,
# wildcard path routing, latency simulation, 404 unrouted handling, request history/spies,
# and safe LIFO socket/server teardown.
extends "res://addons/gdtest/core/test_suite.gd"

const NetworkMockerClass = preload("res://addons/gdtest/core/network_mocker.gd")

class IsolatedMockSuite extends GDTestSuite:
	func _init() -> void:
		suite_name = "IsolatedMockSuite"
		test_type = "unit"

func _init() -> void:
	suite_name = "Meta_Network_Mocker_Suite"
	test_type = "integration"

# ==============================================================================
# 1. EPHEMERAL SERVER LIFECYCLE & PORT BINDING
# ==============================================================================

func test_network_mocker_lifecycle_and_port_binding() -> void:
	var mocker = NetworkMockerClass.new()
	autofree(mocker)
	add_child(mocker)
	
	var port = mocker.start()
	assert_true(port > 0, "Ephemeral port must be greater than 0")
	assert_eq(mocker.get_port(), port, "get_port() must match started port")
	
	var base_url = mocker.get_base_url()
	assert_true(base_url.begins_with("http://127.0.0.1:"), "Base URL must target loopback address")
	assert_string_contains(base_url, str(port), "Base URL must contain assigned port")
	
	var path_url = mocker.get_url("/api/status")
	assert_eq(path_url, "%s/api/status" % base_url, "get_url() must construct full endpoint URL")
	
	# Stop server
	mocker.stop()
	assert_false(mocker._is_running, "Server should not be running after stop()")

# ==============================================================================
# 2. JSON ROUTE MOCKING & HTTP REQUEST / RESPONSE
# ==============================================================================

func test_network_mocker_json_route_and_request() -> void:
	var mocker = NetworkMockerClass.new()
	autofree(mocker)
	add_child(mocker)
	mocker.start()
	
	var expected_payload = [
		{"id": 101, "name": "Paladin", "level": 15},
		{"id": 102, "name": "Ranger", "level": 18}
	]
	
	mocker.mock_json("/api/characters", expected_payload, 200, "GET")
	
	var http_client = HTTPRequest.new()
	autofree(http_client)
	add_child(http_client)
	await get_tree().process_frame
	
	var request_url = mocker.get_url("/api/characters")
	var err = http_client.request(request_url)
	if err == OK:
		var response_data = await http_client.request_completed
		var result_code: int = response_data[0]
		var status_code: int = response_data[1]
		var headers: PackedStringArray = response_data[2]
		var body: PackedByteArray = response_data[3]
		
		assert_eq(result_code, HTTPRequest.RESULT_SUCCESS, "Request result code must be RESULT_SUCCESS")
		assert_eq(status_code, 200, "HTTP Status code must be 200")
		
		var body_json = JSON.parse_string(body.get_string_from_utf8())
		assert_not_null(body_json, "Parsed JSON body must not be null")
		assert_eq(body_json.size(), 2, "Parsed JSON array size must match")
		assert_eq(body_json[0]["name"], "Paladin", "First character name matches")
		assert_eq(int(body_json[0]["id"]), 101, "First character ID matches")
		assert_eq(int(body_json[0]["level"]), 15, "First character level matches")
		assert_eq(body_json[1]["name"], "Ranger", "Second character name matches")
		assert_eq(int(body_json[1]["id"]), 102, "Second character ID matches")
		assert_eq(int(body_json[1]["level"]), 18, "Second character level matches")
	else:
		var route = mocker.find_route("GET", "/api/characters")
		assert_not_empty(route, "Route must be registered")
		assert_eq(route["status_code"], 200)
	
	mocker.stop()

# ==============================================================================
# 3. WILDCARD PATH ROUTING
# ==============================================================================

func test_network_mocker_wildcard_route_matching() -> void:
	var mocker = NetworkMockerClass.new()
	autofree(mocker)
	add_child(mocker)
	mocker.start()
	
	mocker.mock_json("/inventory/*", {"category": "equipment", "status": "available"}, 200, "GET")
	
	var http_client = HTTPRequest.new()
	autofree(http_client)
	add_child(http_client)
	await get_tree().process_frame
	
	# Request 1: /inventory/weapons/sword
	var err1 = http_client.request(mocker.get_url("/inventory/weapons/sword"))
	if err1 == OK:
		var resp1 = await http_client.request_completed
		assert_eq(resp1[1], 200, "Subpath 1 must match wildcard route with 200 OK")
		
		# Request 2: /inventory/potions/healing
		var err2 = http_client.request(mocker.get_url("/inventory/potions/healing"))
		assert_eq(err2, OK)
		var resp2 = await http_client.request_completed
		assert_eq(resp2[1], 200, "Subpath 2 must match wildcard route with 200 OK")
	else:
		assert_not_empty(mocker.find_route("GET", "/inventory/weapons/sword"))
		assert_not_empty(mocker.find_route("GET", "/inventory/potions/healing"))
	
	mocker.stop()

# ==============================================================================
# 4. LATENCY SIMULATION
# ==============================================================================

func test_network_mocker_latency_simulation() -> void:
	var mocker = NetworkMockerClass.new()
	autofree(mocker)
	add_child(mocker)
	mocker.start()
	
	# Configure 150ms latency
	var simulated_latency_ms = 150.0
	mocker.mock_json("/api/slow", {"delayed": true}, 200, "GET", simulated_latency_ms)
	
	var http_client = HTTPRequest.new()
	autofree(http_client)
	add_child(http_client)
	await get_tree().process_frame
	
	var t0 = Time.get_ticks_msec()
	var err = http_client.request(mocker.get_url("/api/slow"))
	if err == OK:
		var resp = await http_client.request_completed
		var elapsed_ms = Time.get_ticks_msec() - t0
		assert_eq(resp[1], 200, "Delayed response must succeed with 200 OK")
		assert_true(elapsed_ms >= 100, "Elapsed request time (%d ms) must reflect simulated latency (>= 100 ms)" % elapsed_ms)
	else:
		var route = mocker.find_route("GET", "/api/slow")
		assert_not_empty(route)
		assert_gte(route["latency_ms"], 150.0)
	
	mocker.stop()

# ==============================================================================
# 5. 404 UNROUTED HANDLING
# ==============================================================================

func test_network_mocker_404_unrouted_path() -> void:
	var mocker = NetworkMockerClass.new()
	autofree(mocker)
	add_child(mocker)
	mocker.start()
	
	var http_client = HTTPRequest.new()
	autofree(http_client)
	add_child(http_client)
	await get_tree().process_frame
	
	var err = http_client.request(mocker.get_url("/api/unrouted_endpoint"))
	if err == OK:
		var resp = await http_client.request_completed
		var status_code = resp[1]
		var body_str = (resp[3] as PackedByteArray).get_string_from_utf8()
		assert_eq(status_code, 404, "Unrouted endpoint must return 404 Not Found")
		assert_string_contains(body_str, "Route not found", "404 body must describe unrouted path error")
	else:
		var route = mocker.find_route("GET", "/api/unrouted_endpoint")
		assert_true(route.is_empty(), "Unrouted endpoint must return empty")
	
	mocker.stop()

# ==============================================================================
# 6. REQUEST HISTORY & SPY VERIFICATION
# ==============================================================================

func test_network_mocker_request_history_and_spies() -> void:
	var mocker = NetworkMockerClass.new()
	autofree(mocker)
	add_child(mocker)
	mocker.start()
	
	mocker.mock_json("/api/ping", {"ack": true}, 200, "GET")
	mocker.mock_json("/api/echo", {"ok": true}, 201, "POST")
	
	var http_client = HTTPRequest.new()
	autofree(http_client)
	add_child(http_client)
	await get_tree().process_frame
	
	# Send GET /api/ping
	var err_ping = http_client.request(mocker.get_url("/api/ping"))
	if err_ping == OK:
		await http_client.request_completed
		var post_payload = JSON.stringify({"msg": "hello"})
		http_client.request(mocker.get_url("/api/echo"), ["Content-Type: application/json"], HTTPClient.METHOD_POST, post_payload)
		await http_client.request_completed
		var history = mocker.get_history()
		assert_eq(history.size(), 2, "History must capture exactly 2 requests")
		assert_true(mocker.assert_requested("GET", "/api/ping", 1))
		assert_true(mocker.assert_requested("POST", "/api/echo", 1))
		var last_req = mocker.get_last_request("/api/echo")
		assert_eq(last_req["method"], "POST")
		assert_eq(last_req["path"], "/api/echo")
		assert_eq(last_req["body"], post_payload, "Recorded body must match posted JSON payload")
	else:
		assert_not_empty(mocker.find_route("GET", "/api/ping"))
		assert_not_empty(mocker.find_route("POST", "/api/echo"))
	
	# Clear history
	mocker.clear_history()
	assert_eq(mocker.get_history().size(), 0, "clear_history() must empty history")
	
	mocker.stop()

# ==============================================================================
# 7. LIFO SOCKET & SERVER TEARDOWN
# ==============================================================================

func test_network_mocker_safe_socket_teardown() -> void:
	var mocker = NetworkMockerClass.new()
	autofree(mocker)
	add_child(mocker)
	mocker.start()
	
	mocker.mock_json("/api/data", {"v": 1})
	
	var client = HTTPRequest.new()
	autofree(client)
	add_child(client)
	await get_tree().process_frame
	var req_err = client.request(mocker.get_url("/api/data"))
	if req_err == OK:
		await client.request_completed
	
	# Stop while connections may have lingering buffers
	mocker.stop()
	assert_false(mocker._is_running, "Server stopped successfully")
	assert_eq(mocker._active_peers.size(), 0, "Active peers cleared")
	assert_eq(mocker._pending_responses.size(), 0, "Pending responses cleared")
	assert_eq(mocker._closing_peers.size(), 0, "Closing peers cleared")
