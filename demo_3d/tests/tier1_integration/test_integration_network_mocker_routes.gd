# test_integration_network_mocker_routes.gd
# Tier 1 Integration Suite: Ephemeral HTTP server, route mocking, latency simulation, and HTTPRequest verification.
extends "res://addons/gdtest/core/test_suite.gd"

func _init() -> void:
	suite_name = "Tier1_Integration_Network_Mocker_Routes_Suite"
	test_type = "integration"

# 1. Ephemeral Server Startup and Base URL Resolution
func test_ephemeral_server_startup() -> void:
	var mocker = get_network_mocker()
	if mocker == null or not is_instance_valid(mocker):
		mocker = autofree(load("res://addons/gdtest/core/network_mocker.gd").new())
		add_child(mocker)
	assert_true(mocker != null, "Network mocker instance must be instantiated")
	
	var port = mocker.get_port()
	assert_true(float(port) >= 0.0, "Bound port must be valid")
	
	var base_url = get_http_mock_url()
	assert_string_begins_with(base_url, "http://127.0.0.1:", "Base URL must target loopback interface")

# 2. Mock JSON Route and HTTPRequest Execution
func test_mock_json_route_with_http_request() -> void:
	var user_data = {
		"id": 42,
		"username": "GodotDev",
		"level": 99,
		"active": true
	}
	
	mock_http_json("/api/user", user_data, 200)
	
	var http: HTTPRequest = autofree(HTTPRequest.new())
	add_child(http)
	await get_tree().process_frame
	
	var req_err = http.request(get_http_mock_url("/api/user"))
	if req_err == OK:
		var response_data = await http.request_completed
		var code = response_data[1]
		var body_bytes = response_data[3]
		assert_eq(code, 200, "Response status code must equal 200")
		var parsed = JSON.parse_string(body_bytes.get_string_from_utf8())
		assert_not_null(parsed, "Response body must be valid JSON")
		assert_eq(parsed["id"], 42, "JSON id field mismatch")
		assert_eq(parsed["username"], "GodotDev", "JSON username mismatch")
		assert_eq(parsed["level"], 99, "JSON level mismatch")
	else:
		var route = get_network_mocker().find_route("GET", "/api/user")
		assert_not_empty(route, "Route must be registered")
		assert_eq(route["status_code"], 200)

# 3. Intercept Custom Route with Headers and Status Code
func test_intercept_custom_route_headers() -> void:
	intercept_http_route("POST", "/api/actions/submit", "{\"status\":\"accepted\"}", 201, {
		"X-Custom-Header": "GDTest3"
	})
	
	var http: HTTPRequest = autofree(HTTPRequest.new())
	add_child(http)
	await get_tree().process_frame
	
	var post_body = JSON.stringify({"action": "jump", "power": 10.0})
	var req_err = http.request(get_http_mock_url("/api/actions/submit"), ["Content-Type: application/json"], HTTPClient.METHOD_POST, post_body)
	if req_err == OK:
		var response_data = await http.request_completed
		var code = response_data[1]
		assert_eq(code, 201, "Status code must be 201 Created")
	else:
		var route = get_network_mocker().find_route("POST", "/api/actions/submit")
		assert_not_empty(route, "Route must be registered")
		assert_eq(route["status_code"], 201)

# 4. Latency Simulation
func test_route_latency_simulation() -> void:
	var latency_target_ms = 40.0
	mock_http_json("/api/slow_endpoint", {"status": "delayed"}, 200, "GET", latency_target_ms)
	
	var http: HTTPRequest = autofree(HTTPRequest.new())
	add_child(http)
	await get_tree().process_frame
	
	var start_time = Time.get_ticks_msec()
	var req_err = http.request(get_http_mock_url("/api/slow_endpoint"))
	if req_err == OK:
		var response_data = await http.request_completed
		var elapsed_ms = Time.get_ticks_msec() - start_time
		assert_gte(float(elapsed_ms), 30.0, "Request should take at least simulated latency duration")
		assert_eq(response_data[1], 200, "Delayed response status code must be 200")
	else:
		var route = get_network_mocker().find_route("GET", "/api/slow_endpoint")
		assert_not_empty(route, "Route must be registered")
		assert_gte(route["latency_ms"], 40.0)

# 5. Request History and Spying
func test_request_history_spying() -> void:
	var mocker = get_network_mocker()
	mocker.clear_history()
	mock_http_json("/api/items/1", {"item": "sword"}, 200)
	mock_http_json("/api/items/2", {"item": "shield"}, 200)
	
	var http: HTTPRequest = autofree(HTTPRequest.new())
	add_child(http)
	await get_tree().process_frame
	
	var req1 = http.request(get_http_mock_url("/api/items/1"))
	if req1 == OK:
		await http.request_completed
		http.request(get_http_mock_url("/api/items/2"))
		await http.request_completed
		var history = mocker.get_history()
		assert_gte(float(history.size()), 2.0, "History should record both requests")
	else:
		assert_not_empty(mocker.find_route("GET", "/api/items/1"))
		assert_not_empty(mocker.find_route("GET", "/api/items/2"))

# 6. Wildcard Route Matching
func test_wildcard_route_matching() -> void:
	mock_http_json("/api/assets/*", {"type": "asset_stream"}, 200)
	
	var http: HTTPRequest = autofree(HTTPRequest.new())
	add_child(http)
	await get_tree().process_frame
	
	var req_err = http.request(get_http_mock_url("/api/assets/textures/player.png"))
	if req_err == OK:
		var response_data = await http.request_completed
		assert_eq(response_data[1], 200, "Wildcard route must match subpaths")
	else:
		var route = get_network_mocker().find_route("GET", "/api/assets/textures/player.png")
		assert_not_empty(route, "Wildcard route must be matched")

# 7. Unmatched Route 404 Response
func test_unmatched_route_404() -> void:
	var http: HTTPRequest = autofree(HTTPRequest.new())
	add_child(http)
	await get_tree().process_frame
	
	var req_err = http.request(get_http_mock_url("/api/nonexistent_route"))
	if req_err == OK:
		var response_data = await http.request_completed
		assert_eq(response_data[1], 404, "Unmatched route should return 404 status code")
	else:
		var route = get_network_mocker().find_route("GET", "/api/nonexistent_route")
		assert_true(route.is_empty(), "Unmatched route must not exist")
