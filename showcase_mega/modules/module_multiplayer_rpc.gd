# module_multiplayer_rpc.gd
extends Node
class_name ModuleMultiplayerRPC

var predictions: Dictionary = {}
var actuals: Dictionary = {}

var rpc_call_count: int = 0
var synchronized_value: float = 0.0

func _ready() -> void:
	audit_multiplayer_subsystem()

func audit_multiplayer_subsystem() -> void:
	# PREDICTIONS:
	# Local multiplayer peer setup succeeds.
	# Direct RPC invocation calls target method and increments counter.
	predictions["rpc_count_target"] = 1
	predictions["sync_value_target"] = 42.5
	
	test_rpc_method(42.5)
	
	actuals["rpc_count_target"] = rpc_call_count
	actuals["sync_value_target"] = synchronized_value

@rpc("any_peer", "call_local", "reliable")
func test_rpc_method(val: float) -> void:
	rpc_call_count += 1
	synchronized_value = val
