# test_meta_idling_and_benchmarks.gd
# Meta Test Suite: Deterministic Idling Registry and Statistical Micro-Benchmark Engine.
# Validates quiescent settling checks (Tweens, 2D/3D physics, tokens), consecutive idle frames,
# non-settled timeout diagnostic reporting, micro-benchmark statistical metrics (min, max, mean,
# median, p90, p95, p99, stddev, ops/sec, memory tracking), and statistical invariant assertions.
extends "res://addons/gdtest/core/test_suite.gd"

const IdlingRegistryClass = preload("res://addons/gdtest/core/idling_registry.gd")
const BenchmarkEngineClass = preload("res://addons/gdtest/core/benchmark_engine.gd")

class IsolatedMockSuite extends GDTestSuite:
	func _init() -> void:
		suite_name = "IsolatedMockSuite"
		test_type = "unit"

func _init() -> void:
	suite_name = "Meta_Idling_And_Benchmarks_Suite"
	test_type = "unit"

# ==============================================================================
# 1. IDLING REGISTRY (Custom Tokens, Quiescent State)
# ==============================================================================

func test_idling_registry_custom_tokens() -> void:
	var registry = IdlingRegistryClass.new()
	
	assert_true(registry.get_active_tokens().is_empty(), "Initial tokens must be empty")
	assert_false(registry.has_token("asset_loader"), "Should not have asset_loader token initially")
	
	registry.acquire_token("asset_loader", {"resource": "player.tscn"})
	registry.acquire_token("vfx_particle_burst")
	
	assert_true(registry.has_token("asset_loader"), "Should track acquired asset_loader token")
	assert_true(registry.has_token("vfx_particle_burst"), "Should track acquired vfx token")
	assert_eq(registry.get_active_tokens().size(), 2, "Active tokens count should equal 2")
	
	# Release single token
	registry.release_token("asset_loader")
	assert_false(registry.has_token("asset_loader"), "Released token must not be active")
	assert_true(registry.has_token("vfx_particle_burst"), "Other tokens must remain active")
	assert_eq(registry.get_active_tokens().size(), 1)
	
	# Clear tokens
	registry.clear_tokens()
	assert_true(registry.get_active_tokens().is_empty(), "clear_tokens() must empty all tokens")

func test_idling_registry_active_tweens_detection() -> void:
	var registry = IdlingRegistryClass.new()
	
	# Create a running SceneTree Tween
	var dummy_node = Node2D.new()
	autofree(dummy_node)
	add_child(dummy_node)
	
	var tween = create_tween()
	tween.tween_property(dummy_node, "position", Vector2(100.0, 100.0), 2.0)
	
	var active_tweens = registry.get_active_tweens(get_tree())
	assert_true(active_tweens.size() >= 1, "Registry must detect active running Tween")
	
	var non_settled = registry.get_non_settled_resources(get_tree(), self)
	assert_false(non_settled["is_idle"], "is_idle must be false while Tween is running")
	assert_true(non_settled["tweens"].size() >= 1, "Non-settled tweens list must not be empty")
	
	# Kill tween and verify idle
	tween.kill()
	await step_frames(1)
	
	var post_kill_tweens = registry.get_active_tweens(get_tree())
	assert_eq(post_kill_tweens.size(), 0, "Killed tween should not be reported as active")

func test_idling_registry_moving_physics_bodies() -> void:
	var registry = IdlingRegistryClass.new()
	var root_container = Node2D.new()
	autofree(root_container)
	add_child(root_container)
	
	# 1. 2D CharacterBody with velocity
	var cb2d = CharacterBody2D.new()
	cb2d.name = "MovingHero2D"
	cb2d.velocity = Vector2(120.0, 0.0)
	root_container.add_child(cb2d)
	
	# 2. 2D RigidBody with linear velocity
	var rb2d = RigidBody2D.new()
	rb2d.name = "MovingCrate2D"
	rb2d.linear_velocity = Vector2(45.0, 10.0)
	rb2d.sleeping = false
	root_container.add_child(rb2d)
	
	var moving_bodies = registry.get_moving_physics_bodies(root_container, 0.01)
	assert_eq(moving_bodies.size(), 2, "Registry must detect both moving 2D bodies")
	
	# Stop motion & put to sleep
	cb2d.velocity = Vector2.ZERO
	rb2d.linear_velocity = Vector2.ZERO
	rb2d.angular_velocity = 0.0
	rb2d.sleeping = true
	
	var settled_bodies = registry.get_moving_physics_bodies(root_container, 0.01)
	assert_eq(settled_bodies.size(), 0, "Settled bodies with zero velocity must not be reported")

# ==============================================================================
# 2. CONSECUTIVE IDLE FRAMES & SETTLING (wait_until_idle)
# ==============================================================================

func test_idling_registry_wait_until_idle_success() -> void:
	var registry = IdlingRegistryClass.new()
	var container = Node.new()
	autofree(container)
	add_child(container)
	
	# When no active tweens, bodies, or tokens exist, wait_until_idle must settle cleanly
	var result = await registry.wait_until_idle(get_tree(), container, 2.0, 0.01, 2)
	assert_true(result["settled"], "wait_until_idle must return settled = true when quiescent")
	assert_true(result["elapsed_seconds"] >= 0.0, "Elapsed seconds must be non-negative")
	assert_true(result["pending"].is_empty(), "Pending resources must be empty on success")

# ==============================================================================
# 3. TIMEOUT NON-SETTLED RESOURCE DIAGNOSTIC REPORTING
# ==============================================================================

func test_idling_registry_format_non_settled_report() -> void:
	var registry = IdlingRegistryClass.new()
	
	var mock_non_settled = {
		"is_idle": false,
		"tweens": [{"instance_id": 1234, "is_running": true}],
		"physics_bodies": [
			{"path": "/root/Level/Player", "type": "CharacterBody2D", "velocity": "linear=150.0000"}
		],
		"tokens": ["network_sync_token"]
	}
	
	var report = registry.format_non_settled_report(mock_non_settled, 3.5)
	
	assert_string_contains(report, "Idling timeout after 3.50s", "Report must contain timeout duration")
	assert_string_contains(report, "1 active Tween(s)", "Report must state active Tween count")
	assert_string_contains(report, "1 moving physics body/bodies", "Report must state moving bodies count")
	assert_string_contains(report, "/root/Level/Player", "Report must include node path")
	assert_string_contains(report, "network_sync_token", "Report must list active token name")

# ==============================================================================
# 4. MICRO-BENCHMARK STATISTICAL METRICS & MEMORY TRACKING
# ==============================================================================

func test_benchmark_engine_synchronous_metrics() -> void:
	var counter = [0]
	var stats = BenchmarkEngineClass.benchmark(
		"ArrayAppendAndSum",
		func():
			var arr: Array[int] = []
			for j in range(100):
				arr.append(j)
			var sum = 0
			for val in arr:
				sum += val
			counter[0] += sum,
		500, # 500 iterations
		20,  # 20 warmup iterations
		1    # batch size
	)
	
	assert_eq(stats["name"], "ArrayAppendAndSum", "Stats name must match")
	assert_eq(stats["iterations"], 500, "Iterations must match 500")
	assert_eq(stats["warmup_iterations"], 20, "Warmup iterations must match 20")
	assert_true(stats.has("min_usec"), "Must contain min_usec")
	assert_true(stats.has("max_usec"), "Must contain max_usec")
	assert_true(stats.has("mean_usec"), "Must contain mean_usec")
	assert_true(stats.has("median_usec"), "Must contain median_usec")
	assert_true(stats.has("p90_usec"), "Must contain p90_usec")
	assert_true(stats.has("p95_usec"), "Must contain p95_usec")
	assert_true(stats.has("p99_usec"), "Must contain p99_usec")
	assert_true(stats.has("stddev_usec"), "Must contain stddev_usec")
	assert_true(stats.has("variance_usec"), "Must contain variance_usec")
	assert_true(stats.has("ops_per_sec"), "Must contain ops_per_sec")
	assert_true(stats.has("memory_bytes_before"), "Must track memory before")
	assert_true(stats.has("memory_bytes_after"), "Must track memory after")
	assert_true(stats.has("memory_bytes_delta"), "Must track memory delta")

func test_benchmark_engine_async_metrics() -> void:
	var stats = await BenchmarkEngineClass.benchmark_async(
		"AsyncProcessFrameStep",
		func():
			await get_tree().process_frame,
		5, # 5 iterations
		1  # 1 warmup iteration
	)
	
	assert_eq(stats["name"], "AsyncProcessFrameStep")
	assert_eq(stats["iterations"], 5)
	assert_true(stats["mean_usec"] > 0.0, "Async mean duration must be > 0")
	assert_true(stats["ops_per_sec"] > 0.0, "Async ops per sec must be > 0")

# ==============================================================================
# 5. STATISTICAL INVARIANT ASSERTIONS
# ==============================================================================

func test_benchmark_statistical_invariants() -> void:
	var stats = BenchmarkEngineClass.benchmark(
		"StatisticalInvariantsCheck",
		func():
			var x = sin(1.234) * cos(5.678),
		300,
		20
	)
	
	var min_u = stats["min_usec"]
	var median_u = stats["median_usec"]
	var max_u = stats["max_usec"]
	var p90_u = stats["p90_usec"]
	var p95_u = stats["p95_usec"]
	var p99_u = stats["p99_usec"]
	var stddev_u = stats["stddev_usec"]
	var variance_u = stats["variance_usec"]
	var ops_sec = stats["ops_per_sec"]
	
	# Invariant 1: min <= median <= max
	assert_true(min_u <= median_u, "min_usec (%f) must be <= median_usec (%f)" % [min_u, median_u])
	assert_true(median_u <= max_u, "median_usec (%f) must be <= max_u (%f)" % [median_u, max_u])
	
	# Invariant 2: Percentile monotonicity: p90 <= p95 <= p99 <= max
	assert_true(p90_u <= p95_u, "p90 (%f) must be <= p95 (%f)" % [p90_u, p95_u])
	assert_true(p95_u <= p99_u, "p95 (%f) must be <= p99 (%f)" % [p95_u, p99_u])
	assert_true(p99_u <= max_u, "p99 (%f) must be <= max (%f)" % [p99_u, max_u])
	
	# Invariant 3: Dispersion metrics non-negative
	assert_true(stddev_u >= 0.0, "stddev must be non-negative")
	assert_true(variance_u >= 0.0, "variance must be non-negative")
	assert_true(ops_sec > 0.0, "ops_per_sec must be positive")

func test_benchmark_table_formatters() -> void:
	var stats1 = BenchmarkEngineClass.benchmark("VectorMath", func(): var _v = Vector2(1, 2).dot(Vector2(3, 4)), 100, 10)
	var stats2 = BenchmarkEngineClass.benchmark("ColorLerp", func(): var _c = Color.RED.lerp(Color.BLUE, 0.5), 100, 10)
	
	# ASCII Table formatting
	var ascii_table = BenchmarkEngineClass.format_table([stats1, stats2])
	assert_string_contains(ascii_table, "VectorMath", "ASCII table must contain benchmark name")
	assert_string_contains(ascii_table, "ColorLerp", "ASCII table must contain second benchmark name")
	assert_string_contains(ascii_table, "Ops / Sec", "ASCII table must contain Ops header")
	
	# Markdown Table formatting
	var md_table = BenchmarkEngineClass.format_markdown_table([stats1, stats2])
	assert_string_contains(md_table, "| Benchmark | Iters | Mean |", "Markdown table must contain header line")
	assert_string_contains(md_table, "| :--- | ---: |", "Markdown table must contain alignment row")
	assert_string_contains(md_table, "| VectorMath |", "Markdown table must contain data row")

func test_benchmark_assertion_failure_in_isolated_mock_suite() -> void:
	var mock_suite = IsolatedMockSuite.new()
	autofree(mock_suite)
	
	# Deliberately assert benchmark mean time is under an impossibly tiny limit (0.00001 µs)
	# This should fail inside the mock_suite sandbox
	var failed_res = mock_suite.assert_benchmark_under(func():
		var arr: Array[int] = []
		for i in range(500):
			arr.append(i)
	, 0.0000001, 50, "Deliberate benchmark threshold failure")
	
	assert_false(failed_res, "assert_benchmark_under must return false when threshold is exceeded")
	assert_eq(mock_suite.fail_count, 1, "Mock suite must record exactly 1 failure")
	assert_eq(mock_suite.failures.size(), 1, "Mock suite failures list size must be 1")
	assert_string_contains(mock_suite.failures[0]["message"], "Deliberate benchmark threshold failure", "Failure message must describe benchmark error")
