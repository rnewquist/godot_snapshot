# test_unit_signals_spies_lifecycle.gd
# Tier 0 Pure Unit Suite: Signal spying, emission history, parameter payloads, and lifecycle memory safety.
extends "res://addons/gdtest/core/test_suite.gd"

class MockEmitter extends Node:
	signal value_changed(new_val: int)
	signal complex_event(id: int, label: String, pos: Vector2)
	signal empty_event()

func _init() -> void:
	suite_name = "Tier0_Unit_Signals_Spies_Lifecycle_Suite"
	test_type = "unit"

# 1. Watch Signal & Assert Emitted
func test_watch_signal_and_assert_emitted() -> void:
	var emitter: MockEmitter = autofree(MockEmitter.new())
	watch_signal(emitter, &"value_changed")
	emitter.value_changed.emit(42)
	assert_signal_emitted(emitter, &"value_changed", "Signal must be recorded as emitted")

# 2. Assert Signal Not Emitted
func test_assert_signal_not_emitted() -> void:
	var emitter: MockEmitter = autofree(MockEmitter.new())
	watch_signal(emitter, &"empty_event")
	assert_signal_not_emitted(emitter, &"empty_event", "Un-emitted signal must not be recorded")

# 3. Assert Signal Count Multiple Emissions
func test_assert_signal_count_multiple_emissions() -> void:
	var emitter: MockEmitter = autofree(MockEmitter.new())
	watch_signal(emitter, &"value_changed")
	emitter.value_changed.emit(1)
	emitter.value_changed.emit(2)
	emitter.value_changed.emit(3)
	emitter.value_changed.emit(4)
	assert_signal_count(emitter, &"value_changed", 4, "Signal emission count must equal 4")

# 4. Signal Emissions Payload History
func test_signal_emissions_payload_history() -> void:
	var emitter: MockEmitter = autofree(MockEmitter.new())
	watch_signal(emitter, &"value_changed")
	emitter.value_changed.emit(10)
	emitter.value_changed.emit(20)
	emitter.value_changed.emit(30)
	
	var history: Array = get_signal_emissions(emitter, &"value_changed")
	assert_size(history, 3, "Emissions history size mismatch")
	assert_eq(history[0][0], 10, "First emission argument mismatch")
	assert_eq(history[1][0], 20, "Second emission argument mismatch")
	assert_eq(history[2][0], 30, "Third emission argument mismatch")

# 5. Get Last Signal Emission
func test_get_last_signal_emission() -> void:
	var emitter: MockEmitter = autofree(MockEmitter.new())
	watch_signal(emitter, &"value_changed")
	emitter.value_changed.emit(100)
	emitter.value_changed.emit(200)
	var last_payload: Array = get_last_signal_emission(emitter, &"value_changed")
	assert_size(last_payload, 1, "Payload argument count mismatch")
	assert_eq(last_payload[0], 200, "Last emission value mismatch")

# 6. Signal With Multiple Parameters
func test_signal_with_multiple_parameters() -> void:
	var emitter: MockEmitter = autofree(MockEmitter.new())
	watch_signal(emitter, &"complex_event")
	emitter.complex_event.emit(77, "checkpoint", Vector2(150.0, 300.0))
	var last_args: Array = get_last_signal_emission(emitter, &"complex_event")
	assert_size(last_args, 3, "Multi-parameter payload size mismatch")
	assert_eq(last_args[0], 77, "Argument 0 int mismatch")
	assert_eq(last_args[1], "checkpoint", "Argument 1 string mismatch")
	assert_vector2_approx(last_args[2], Vector2(150.0, 300.0), 0.001, "Argument 2 Vector2 mismatch")

# 7. Signal Spies Multiple Objects and Signals
func test_signal_spies_multiple_objects_and_signals() -> void:
	var emitter_a: MockEmitter = autofree(MockEmitter.new())
	var emitter_b: MockEmitter = autofree(MockEmitter.new())
	watch_signal(emitter_a, &"value_changed")
	watch_signal(emitter_b, &"empty_event")
	
	emitter_a.value_changed.emit(999)
	assert_signal_count(emitter_a, &"value_changed", 1, "Emitter A count mismatch")
	assert_signal_not_emitted(emitter_b, &"empty_event", "Emitter B should not have emitted")
	
	emitter_b.empty_event.emit()
	assert_signal_count(emitter_b, &"empty_event", 1, "Emitter B count mismatch")
	assert_signal_count(emitter_a, &"value_changed", 1, "Emitter A count must remain 1")

# 8. Signal Connection Lifecycle Disconnect
func test_signal_connection_lifecycle_disconnect() -> void:
	var emitter: MockEmitter = autofree(MockEmitter.new())
	var call_counter: Array[int] = [0]
	var cb = func(_val: int): call_counter[0] += 1
	
	emitter.value_changed.connect(cb)
	emitter.value_changed.emit(10)
	assert_eq(call_counter[0], 1, "Connected callback must be invoked on emit")
	
	emitter.value_changed.disconnect(cb)
	emitter.value_changed.emit(20)
	assert_eq(call_counter[0], 1, "Disconnected callback must not be invoked on subsequent emit")

# 9. Signal One Shot Connection
func test_signal_one_shot_connection() -> void:
	var emitter: MockEmitter = autofree(MockEmitter.new())
	var call_count: Array[int] = [0]
	emitter.empty_event.connect(func(): call_count[0] += 1, CONNECT_ONE_SHOT)
	emitter.empty_event.emit()
	emitter.empty_event.emit()
	assert_eq(call_count[0], 1, "CONNECT_ONE_SHOT signal must only trigger callback once")

# 10. Autofree and Signal Teardown Isolation
func test_autofree_and_signal_teardown_isolation() -> void:
	var emitter: MockEmitter = autofree(MockEmitter.new())
	watch_signal(emitter, &"value_changed")
	emitter.value_changed.emit(555)
	assert_signal_emitted(emitter, &"value_changed", "Watched signal on autofreed node must record emission")
	assert_true(is_instance_valid(emitter), "Autofreed node remains valid during test execution")
