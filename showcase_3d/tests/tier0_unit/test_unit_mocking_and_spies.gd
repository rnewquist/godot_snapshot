# test_unit_mocking_and_spies.gd
# Tier 0 Unit Suite: GDTest 3.0 Mocking, Stubs, Verifiers, and Spies.
extends "res://addons/gdtest/core/test_suite.gd"

class CalculatorService extends RefCounted:
	func add(a: int, b: int) -> int:
		return a + b
		
	func multiply(a: int, b: int) -> int:
		return a * b
		
	func divide(a: float, b: float) -> float:
		if b == 0.0:
			return 0.0
		return a / b
		
	func get_service_name() -> String:
		return "CalculatorService"
		
	func complex_operation(label: String, values: Array) -> Dictionary:
		return {"label": label, "count": values.size()}

func _init() -> void:
	suite_name = "Tier0_Unit_Mocking_And_Spies_Suite"
	test_type = "unit"

# 1. Mock method returning fixed value via stub
func test_mock_stub_to_return() -> void:
	var mock_calc = mock(CalculatorService)
	stub(mock_calc, &"add").to_return(100)
	
	var result = mock_calc.add(2, 3)
	assert_eq(result, 100, "Stubbed add method must return configured return value")
	
	var unconfigured = mock_calc.multiply(4, 5)
	assert_null(unconfigured, "Unstubbed mock method should return null by default")

# 2. Mock method returning sequential values
func test_mock_stub_sequence_returns() -> void:
	var mock_calc = mock(CalculatorService)
	stub(mock_calc, &"get_service_name").to_return_values(["Primary", "Secondary", "Tertiary"])
	
	assert_eq(mock_calc.get_service_name(), "Primary", "First call should return first sequence item")
	assert_eq(mock_calc.get_service_name(), "Secondary", "Second call should return second sequence item")
	assert_eq(mock_calc.get_service_name(), "Tertiary", "Third call should return third sequence item")
	assert_eq(mock_calc.get_service_name(), "Tertiary", "Subsequent calls should return last sequence item")

# 3. Mock method with custom callable
func test_mock_stub_to_call() -> void:
	var mock_calc = mock(CalculatorService)
	stub(mock_calc, &"multiply").to_call(func(a: int, b: int) -> int:
		return (a * b) + 10
	)
	
	var result = mock_calc.multiply(5, 5)
	assert_eq(result, 35, "Custom callable stub should compute and return result")

# 4. Mock side-effect execution with and_do
func test_mock_stub_side_effect() -> void:
	var mock_calc = mock(CalculatorService)
	var side_effect_called: Array[int] = [0]
	
	stub(mock_calc, &"add").to_return(42).and_do(func(a, b):
		side_effect_called[0] += 1
	)
	
	var res = mock_calc.add(1, 2)
	assert_eq(res, 42, "Return value must be preserved")
	assert_eq(side_effect_called[0], 1, "Side effect callable must be executed")

# 5. Argument matching in stubs
func test_mock_stub_argument_matching() -> void:
	var mock_calc = mock(CalculatorService)
	stub(mock_calc, &"add").with_args([10, 20]).to_return(300)
	stub(mock_calc, &"add").with_args([1, 2]).to_return(3)
	
	assert_eq(mock_calc.add(10, 20), 300, "Matching specific args [10, 20] must return 300")
	assert_eq(mock_calc.add(1, 2), 3, "Matching specific args [1, 2] must return 3")
	assert_null(mock_calc.add(99, 99), "Non-matching args should return null default")

# 6. Verification of call counts (times, never, was_called, at_least, at_most)
func test_mock_verification_call_counts() -> void:
	var mock_calc = mock(CalculatorService)
	stub(mock_calc, &"add").to_return(0)
	
	verify(mock_calc, &"add").never()
	
	mock_calc.add(1, 1)
	mock_calc.add(2, 2)
	mock_calc.add(3, 3)
	
	verify(mock_calc, &"add").times(3)
	verify(mock_calc, &"add").was_called()
	verify(mock_calc, &"add").at_least(2)
	verify(mock_calc, &"add").at_most(4)
	verify(mock_calc, &"multiply").never()

# 7. Verification of argument payloads
func test_mock_verification_arguments() -> void:
	var mock_calc = mock(CalculatorService)
	mock_calc.complex_operation("physics_step", [1, 2, 3])
	mock_calc.complex_operation("render_step", [4, 5])
	
	verify(mock_calc, &"complex_operation").was_called_with("physics_step", [1, 2, 3])
	verify(mock_calc, &"complex_operation").was_called_with("render_step", [4, 5])
	verify(mock_calc, &"complex_operation").never_called_with("unknown_step", [])

# 8. Spy on real object: delegates to real implementation while tracking calls
func test_spy_delegates_to_real_implementation() -> void:
	var real_calc = CalculatorService.new()
	var spied_calc = spy(real_calc)
	
	# Execute real methods via spy
	var sum = spied_calc.add(15, 25)
	assert_eq(sum, 40, "Spy must delegate to real object implementation")
	
	var prod = spied_calc.multiply(6, 7)
	assert_eq(prod, 42, "Spy must execute real multiplication")
	
	# Verify recorded invocations
	verify(spied_calc, &"add").times(1)
	verify(spied_calc, &"add").was_called_with(15, 25)
	verify(spied_calc, &"multiply").times(1)
	verify(spied_calc, &"multiply").was_called_with(6, 7)

# 9. Spy with method stub override
func test_spy_with_stub_override() -> void:
	var real_calc = CalculatorService.new()
	var spied_calc = spy(real_calc)
	
	# Stub only 'divide' while leaving 'add' real
	stub(spied_calc, &"divide").to_return(999.9)
	
	var real_sum = spied_calc.add(5, 5)
	assert_eq(real_sum, 10, "Unstubbed method on spy must run real logic")
	
	var stubbed_div = spied_calc.divide(100.0, 2.0)
	assert_approx(stubbed_div, 999.9, 0.001, "Stubbed method on spy must return stubbed value")
	
	verify(spied_calc, &"add").was_called()
	verify(spied_calc, &"divide").was_called_with(100.0, 2.0)
