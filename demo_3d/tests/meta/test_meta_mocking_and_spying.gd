# test_meta_mocking_and_spying.gd
# Meta Test Suite 5: Dynamic Mocking, Method Stubbing, Invocation Spying & Verifiers.
# Validates dynamic mock generation, fixed/sequential/callable stubs, side-effect hooks,
# argument-specific stub matching, call verifiers (times, never, was_called, was_called_with),
# negative verifier violations using IsolatedMockSuite, and real object spying with delegation.
extends "res://addons/gdtest/core/test_suite.gd"

class IsolatedMockSuite extends GDTestSuite:
	func _init() -> void:
		suite_name = "IsolatedMockSuite"
		test_type = "unit"

class HarnessObserver:
	var pass_count: int = 0
	var fail_count: int = 0
	var failures: Array[String] = []

	func _record_pass() -> void:
		pass_count += 1

	func _record_failure(message: String) -> void:
		fail_count += 1
		failures.append(message)

# Helper dummy classes for mocking/spying tests
class DummyHeroService extends RefCounted:
	var experience: int = 0
	
	func get_hero_name() -> String:
		return "Arthur"
		
	func calculate_damage(base: int, multiplier: int) -> int:
		return base * multiplier
		
	func gain_exp(amount: int) -> void:
		experience += amount

func _init() -> void:
	suite_name = "Meta_Mocking_And_Spying_Suite"
	test_type = "unit"

# ==============================================================================
# 1. DYNAMIC MOCK GENERATION & BASIC RETURN STUBBING
# ==============================================================================

func test_mock_generation_and_fixed_return_stub() -> void:
	# Mock DummyHeroService
	var hero_mock = mock(DummyHeroService)
	assert_not_null(hero_mock, "Mock instance should be created")

	# Stub get_hero_name to return "Lancelot"
	stub(hero_mock, &"get_hero_name").to_return("Lancelot")

	# Dispatch call
	var result = hero_mock.get_hero_name()
	assert_eq(result, "Lancelot", "Mocked method should return configured stub value")

	# Verify invocation count
	verify(hero_mock, &"get_hero_name").times(1)
	verify(hero_mock, &"get_hero_name").was_called()

# ==============================================================================
# 2. SEQUENTIAL RETURN VALUES (to_return_values)
# ==============================================================================

func test_mock_sequential_return_values() -> void:
	var hero_mock = mock(DummyHeroService)
	stub(hero_mock, &"get_hero_name").to_return_values(["FirstCall", "SecondCall", "ThirdCall"])

	assert_eq(hero_mock.get_hero_name(), "FirstCall", "1st invocation returns 1st sequence item")
	assert_eq(hero_mock.get_hero_name(), "SecondCall", "2nd invocation returns 2nd sequence item")
	assert_eq(hero_mock.get_hero_name(), "ThirdCall", "3rd invocation returns 3rd sequence item")
	# Subsequent invocations clamp to last item
	assert_eq(hero_mock.get_hero_name(), "ThirdCall", "4th invocation clamps to last sequence item")

	verify(hero_mock, &"get_hero_name").times(4)

# ==============================================================================
# 3. CUSTOM CALLABLE DELEGATION (to_call) & SIDE EFFECTS (and_do)
# ==============================================================================

func test_mock_custom_callable_and_side_effects() -> void:
	var hero_mock = mock(DummyHeroService)

	# Stub calculate_damage with custom logic
	stub(hero_mock, &"calculate_damage").to_call(func(base: int, mult: int) -> int:
		return (base + 10) * mult
	)

	var damage = hero_mock.calculate_damage(5, 3) # (5 + 10) * 3 = 45
	assert_eq(damage, 45, "Custom callable stub must execute logic")
	verify(hero_mock, &"calculate_damage").was_called_with(5, 3)

	# Side effect hook (and_do)
	var side_effect_data: Array[int] = []
	stub(hero_mock, &"gain_exp").to_return(null).and_do(func(amount: int):
		side_effect_data.append(amount * 2)
	)

	hero_mock.gain_exp(50)
	assert_eq(side_effect_data, [100], "Side effect callable must be triggered on method call")
	verify(hero_mock, &"gain_exp").was_called_with(50)

# ==============================================================================
# 4. ARGUMENT-SPECIFIC STUBBING & PRECEDENCE
# ==============================================================================

func test_mock_argument_specific_stubs_and_precedence() -> void:
	var hero_mock = mock(DummyHeroService)

	# Specific argument stubs
	stub(hero_mock, &"calculate_damage").with_args([10, 2]).to_return(200)
	stub(hero_mock, &"calculate_damage").with_args([10, 5]).to_return(500)
	stub(hero_mock, &"calculate_damage").to_return(0) # Default fallback

	assert_eq(hero_mock.calculate_damage(10, 2), 200, "Matching [10, 2] args returns 200")
	assert_eq(hero_mock.calculate_damage(10, 5), 500, "Matching [10, 5] args returns 500")
	assert_eq(hero_mock.calculate_damage(10, 99), 0, "Unmatched args return default stub 0")

	verify(hero_mock, &"calculate_damage").times(3)

# ==============================================================================
# 5. VERIFIERS: TIMES, NEVER, WAS_CALLED, AT_LEAST, AT_MOST, WAS_CALLED_WITH
# ==============================================================================

func test_mock_verifiers_comprehensive() -> void:
	var hero_mock = mock(DummyHeroService)
	stub(hero_mock, &"calculate_damage").to_return(100)

	# Never called initially
	verify(hero_mock, &"calculate_damage").never()

	# Call 1
	hero_mock.calculate_damage(1, 1)
	verify(hero_mock, &"calculate_damage").was_called()
	verify(hero_mock, &"calculate_damage").times(1)
	verify(hero_mock, &"calculate_damage").at_least(1)
	verify(hero_mock, &"calculate_damage").at_most(1)
	verify(hero_mock, &"calculate_damage").was_called_with(1, 1)
	verify(hero_mock, &"calculate_damage").never_called_with(9, 9)

	# Call 2
	hero_mock.calculate_damage(2, 2)
	verify(hero_mock, &"calculate_damage").times(2)
	verify(hero_mock, &"calculate_damage").at_least(2)
	verify(hero_mock, &"calculate_damage").at_most(3)
	verify(hero_mock, &"calculate_damage").was_called_with(2, 2)

	# Unused method
	verify(hero_mock, &"get_hero_name").never()

# ==============================================================================
# 6. PROXY HISTORY INSPECTION & RESET
# ==============================================================================

func test_mock_proxy_history_and_reset() -> void:
	var hero_mock = mock(DummyHeroService)
	var proxy = MockFactory.get_proxy(hero_mock)
	assert_not_null(proxy, "Proxy must be accessible")

	stub(hero_mock, &"get_hero_name").to_return("Test")
	hero_mock.get_hero_name()
	hero_mock.get_hero_name()

	assert_eq(proxy.get_call_count(&"get_hero_name"), 2)
	var last_call = proxy.get_last_call(&"get_hero_name")
	assert_eq(last_call["method"], &"get_hero_name")
	assert_eq(last_call["return_value"], "Test")

	# Clear history
	proxy.clear_history()
	assert_eq(proxy.get_call_count(&"get_hero_name"), 0, "History should be cleared")

	# Stubs are preserved after clear_history
	assert_eq(hero_mock.get_hero_name(), "Test")

	# Reset mock clears stubs and history
	proxy.reset_mock()
	assert_eq(proxy.get_call_count(), 0)
	assert_empty(proxy.stubs)

# ==============================================================================
# 7. REAL OBJECT SPYING & DELEGATION
# ==============================================================================

func test_real_object_spying_and_delegation() -> void:
	var real_hero = DummyHeroService.new()
	var hero_spy = spy(real_hero)
	assert_not_null(hero_spy, "Spy instance should be created")

	# Unstubbed call delegates to real implementation
	var default_name = hero_spy.get_hero_name()
	assert_eq(default_name, "Arthur", "Unstubbed spy call delegates to real method")
	verify(hero_spy, &"get_hero_name").times(1)

	# Real state mutation
	hero_spy.gain_exp(250)
	verify(hero_spy, &"gain_exp").was_called_with(250)
	# Check real instance was updated
	assert_eq(real_hero.experience, 250, "Spy delegation must mutate real object state")

	# Stubbing a method on a spy overrides delegation
	stub(hero_spy, &"calculate_damage").to_return(9999)
	var spied_dmg = hero_spy.calculate_damage(5, 5)
	assert_eq(spied_dmg, 9999, "Stubbed method on spy overrides real implementation")
	verify(hero_spy, &"calculate_damage").was_called_with(5, 5)

# ==============================================================================
# 8. NEGATIVE VERIFIER VIOLATIONS IN ISOLATED SANDBOX
# ==============================================================================

func test_mock_verifier_negative_violations_in_isolated_sandbox() -> void:
	var mock_suite = IsolatedMockSuite.new()
	autofree(mock_suite)

	var hero_mock = mock(DummyHeroService)
	stub(hero_mock, &"calculate_damage").to_return(50)
	hero_mock.calculate_damage(10, 5)

	# Attach verifier to isolated mock_suite
	var v = MockVerifier.new()
	v.proxy = MockFactory.get_proxy(hero_mock)
	v.suite_ref = mock_suite

	# 1. times mismatch (expected 5, was 1)
	v.target_method = &"calculate_damage"
	var res1 = v.times(5)
	assert_false(res1, "times(5) should fail when called 1 time")
	assert_eq(mock_suite.fail_count, 1)
	assert_string_contains(mock_suite.failures[0]["message"], "to be called 5 times, but was called 1 times")

	# 2. never violation (expected 0, was 1)
	var res2 = v.never()
	assert_false(res2, "never() should fail when called 1 time")
	assert_eq(mock_suite.fail_count, 2)
	assert_string_contains(mock_suite.failures[1]["message"], "never to be called")

	# 3. was_called violation on uncalled method
	v.target_method = &"get_hero_name"
	var res3 = v.was_called()
	assert_false(res3, "was_called() should fail for uncalled method")
	assert_eq(mock_suite.fail_count, 3)
	assert_string_contains(mock_suite.failures[2]["message"], "have been called at least once")

	# 4. was_called_with mismatch
	v.target_method = &"calculate_damage"
	var res4 = v.was_called_with(999, 888)
	assert_false(res4, "was_called_with(999, 888) should fail")
	assert_eq(mock_suite.fail_count, 4)
	assert_string_contains(mock_suite.failures[3]["message"], "called with arguments [999, 888]")

	# 5. never_called_with violation
	var res5 = v.never_called_with(10, 5)
	assert_false(res5, "never_called_with(10, 5) should fail when that call actually occurred")
	assert_eq(mock_suite.fail_count, 5)
	assert_string_contains(mock_suite.failures[4]["message"], "NEVER to have been called with arguments [10, 5]")

	# 6. at_least violation
	var res6 = v.at_least(10)
	assert_false(res6)
	assert_eq(mock_suite.fail_count, 6)

	# 7. at_most violation
	v.target_method = &"calculate_damage"
	var res7 = v.at_most(0)
	assert_false(res7)
	assert_eq(mock_suite.fail_count, 7)

	assert_eq(mock_suite.failures.size(), 7, "All 7 negative verifier violations captured in isolated sandbox")
