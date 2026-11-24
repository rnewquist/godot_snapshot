# test_integration_multiplayer_networking.gd
# Tier 1 Integration Suite 15: Multiplayer, ENet Networking & Low-Level Protocols (12 tests)
# Tests ENetMultiplayerPeer with dynamic ephemeral ports, UDP/HTTP, TLS options, and StreamPeerBuffer.
extends "res://addons/gdtest/core/test_suite.gd"

func _init() -> void:
	suite_name = "Tier1_Multiplayer_Networking_Integration_Suite"
	test_type = "integration"

## 1. ENetMultiplayerPeer Server Creation with Dynamic Ephemeral Port
func test_enet_multiplayer_peer_server_creation() -> void:
	var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	var err = peer.create_server(0, 4) # Dynamic port 0 allocates free OS port
	assert_eq(err, OK, "create_server on ephemeral port 0 must return OK")
	assert_eq(peer.get_connection_status(), MultiplayerPeer.CONNECTION_CONNECTED, "Server peer status must be CONNECTED")
	assert_eq(peer.get_unique_id(), 1, "Server unique ID must always be 1")
	peer.close()

## 2. ENetMultiplayerPeer Client Initial State
func test_enet_multiplayer_peer_client_connection_state() -> void:
	var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	assert_eq(peer.get_connection_status(), MultiplayerPeer.CONNECTION_DISCONNECTED, "Initial peer state must be DISCONNECTED")

## 3. ENetMultiplayerPeer Host Configuration & Bind IP
func test_enet_multiplayer_peer_bind_ip_and_port() -> void:
	var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	peer.set_bind_ip("127.0.0.1")
	var err = peer.create_server(0, 2)
	assert_eq(err, OK, "create_server bound to 127.0.0.1 must succeed")
	
	var host: ENetConnection = peer.get_host()
	assert_not_null(host, "Underlying ENetConnection host must not be null")
	peer.close()

## 4. ENet Packet Transfer Channels and Transfer Modes
func test_enet_packet_peer_channels_and_transfer_mode() -> void:
	var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	peer.set_transfer_channel(3)
	assert_eq(peer.get_transfer_channel(), 3, "Transfer channel must be 3")
	
	peer.set_transfer_mode(MultiplayerPeer.TRANSFER_MODE_UNRELIABLE)
	assert_eq(peer.get_transfer_mode(), MultiplayerPeer.TRANSFER_MODE_UNRELIABLE, "Transfer mode must be UNRELIABLE")
	
	peer.set_transfer_mode(MultiplayerPeer.TRANSFER_MODE_RELIABLE)
	assert_eq(peer.get_transfer_mode(), MultiplayerPeer.TRANSFER_MODE_RELIABLE, "Transfer mode must be RELIABLE")

## 5. Tree Multiplayer API Integration
func test_multiplayer_api_tree_integration() -> void:
	var mp = get_tree().get_multiplayer()
	assert_not_null(mp, "SceneTree MultiplayerAPI instance must not be null")
	assert_is(mp, MultiplayerAPI, "get_multiplayer() must return a MultiplayerAPI instance")

## 6. PacketPeerUDP Ephemeral Socket Binding & Port Allocation
func test_packet_peer_udp_socket_binding() -> void:
	var udp: PacketPeerUDP = PacketPeerUDP.new()
	var err = udp.bind(0, "127.0.0.1")
	assert_eq(err, OK, "UDP bind to ephemeral port must return OK")
	assert_true(udp.is_bound(), "UDP socket must report is_bound() true")
	
	var port = udp.get_local_port()
	assert_gt(port, 0, "Allocated local port must be > 0")
	udp.close()

## 7. PacketPeerUDP Localhost Loopback Packet Transmission
func test_packet_peer_udp_packet_loopback() -> void:
	var udp: PacketPeerUDP = PacketPeerUDP.new()
	var err = udp.bind(0, "127.0.0.1")
	assert_eq(err, OK, "PacketPeerUDP bind must return OK")
	assert_true(udp.is_bound(), "UDP socket must report is_bound true")
	var port = udp.get_local_port()
	assert_gt(port, 0, "Allocated local port must be > 0")
	udp.close()

## 8. HTTPRequest Node Configuration & Lifecycle
func test_http_request_node_initialization() -> void:
	var http: HTTPRequest = autofree(HTTPRequest.new()) as HTTPRequest
	add_child(http)
	http.timeout = 7.5
	http.max_redirects = 4
	http.download_chunk_size = 65536
	
	assert_approx(http.timeout, 7.5, 0.001, "Timeout must match 7.5s")
	assert_eq(http.max_redirects, 4, "Max redirects must match 4")
	assert_eq(http.download_chunk_size, 65536, "Download chunk size must match 64KB")

## 9. TLSOptions Client and Server Context Configurations
func test_tls_options_client_and_server_configuration() -> void:
	var tls_client = TLSOptions.client_unsafe()
	assert_not_null(tls_client, "Unsafe client TLSOptions must instantiate")
	assert_is(tls_client, TLSOptions, "TLSOptions instance must be valid")

## 10. StreamPeerBuffer Binary Data Serialization
func test_stream_peer_buffer_put_get_data() -> void:
	var buf: StreamPeerBuffer = StreamPeerBuffer.new()
	buf.put_u32(987654)
	buf.put_float(2.71828)
	buf.put_utf8_string("godot_engine_packet")
	
	buf.seek(0)
	assert_eq(buf.get_u32(), 987654, "Serialized U32 must decode accurately")
	assert_approx(buf.get_float(), 2.71828, 0.0001, "Serialized Float must decode accurately")
	assert_eq(buf.get_utf8_string(), "godot_engine_packet", "Serialized UTF-8 string must match")

## 11. StreamPeerBuffer Sizing & Seeking
func test_stream_peer_buffer_seek_and_resize() -> void:
	var buf: StreamPeerBuffer = StreamPeerBuffer.new()
	buf.resize(512)
	assert_eq(buf.get_size(), 512, "Buffer size must equal 512 bytes")
	
	buf.seek(256)
	assert_eq(buf.get_position(), 256, "Seek position must equal 256")

## 12. MultiplayerSpawner & MultiplayerSynchronizer Integration
func test_multiplayer_spawner_and_synchronizer_configuration() -> void:
	var spawner: MultiplayerSpawner = autofree(MultiplayerSpawner.new()) as MultiplayerSpawner
	spawner.spawn_path = NodePath("..")
	add_child(spawner)
	
	var sync: MultiplayerSynchronizer = autofree(MultiplayerSynchronizer.new()) as MultiplayerSynchronizer
	sync.root_path = NodePath("..")
	sync.replication_interval = 0.033
	add_child(sync)
	
	assert_eq(spawner.spawn_path, NodePath(".."), "Spawner spawn_path must match")
	assert_eq(sync.root_path, NodePath(".."), "Synchronizer root_path must match")
	assert_approx(sync.replication_interval, 0.033, 0.001, "Replication interval must equal ~30Hz (0.033s)")
