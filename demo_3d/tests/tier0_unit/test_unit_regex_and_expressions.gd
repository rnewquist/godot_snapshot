# test_unit_regex_and_expressions.gd
# Tier 0 Pure Unit Suite: RegEx capture groups/substitutions, Expression variables, math, and instance method execution.
extends "res://addons/gdtest/core/test_suite.gd"

func _init() -> void:
	suite_name = "Tier0_Unit_Regex_And_Expressions_Suite"
	test_type = "unit"

func get_unit_multiplier() -> float:
	return 3.5

# 1. RegEx Compile Valid and Invalid Pattern
func test_regex_compile_valid_and_invalid_pattern() -> void:
	var regex_valid: RegEx = RegEx.new()
	var err: Error = regex_valid.compile(r"^\d{3}-\d{4}$")
	assert_eq(err, OK, "Valid regex pattern must compile with OK")
	assert_true(regex_valid.is_valid(), "Compiled regex must be valid")
	
	var regex_invalid: RegEx = RegEx.new()
	var err_invalid: Error = regex_invalid.compile(r"[unclosed-bracket", false)
	assert_ne(err_invalid, OK, "Invalid regex pattern must not return OK")
	assert_false(regex_invalid.is_valid(), "Invalid regex must report is_valid = false")

# 2. RegEx Search & Indexed Match Groups
func test_regex_search_and_match_groups() -> void:
	var regex: RegEx = RegEx.new()
	regex.compile(r"(\w+):(\d+)")
	var result: RegExMatch = regex.search("server_port:8080")
	assert_not_null(result, "Regex match result must not be null")
	if result:
		assert_eq(result.get_string(0), "server_port:8080", "Group 0 full match mismatch")
		assert_eq(result.get_string(1), "server_port", "Group 1 identifier mismatch")
		assert_eq(result.get_string(2), "8080", "Group 2 digits mismatch")

# 3. RegEx Named Capture Groups
func test_regex_named_capture_groups() -> void:
	var regex: RegEx = RegEx.new()
	regex.compile(r"(?<proto>https?)://(?<domain>[a-zA-Z0-9.-]+)")
	var result: RegExMatch = regex.search("Connecting to https://godotengine.org/api")
	assert_not_null(result, "Named regex match must not be null")
	if result:
		assert_eq(result.get_string("proto"), "https", "Named group 'proto' mismatch")
		assert_eq(result.get_string("domain"), "godotengine.org", "Named group 'domain' mismatch")

# 4. RegEx Search All Multiple Matches
func test_regex_search_all_multiple_matches() -> void:
	var regex: RegEx = RegEx.new()
	regex.compile(r"\b[A-Z]{3}\b")
	var text: String = "Codes: USA, GBR, JPN, DEU are valid country codes"
	var matches: Array[RegExMatch] = regex.search_all(text)
	assert_size(matches, 4, "Matches count mismatch")
	assert_eq(matches[0].get_string(), "USA", "Match 0 mismatch")
	assert_eq(matches[1].get_string(), "GBR", "Match 1 mismatch")
	assert_eq(matches[2].get_string(), "JPN", "Match 2 mismatch")
	assert_eq(matches[3].get_string(), "DEU", "Match 3 mismatch")

# 5. RegEx Sub Substitutions
func test_regex_sub_substitution() -> void:
	var regex: RegEx = RegEx.new()
	regex.compile(r"\d+")
	var text: String = "User 101 has 500 gold"
	var sub_all: String = regex.sub(text, "###", true)
	assert_eq(sub_all, "User ### has ### gold", "Global regex substitution mismatch")
	var sub_one: String = regex.sub(text, "###", false)
	assert_eq(sub_one, "User ### has 500 gold", "Single regex substitution mismatch")

# 6. RegEx Dynamic Pattern Creation
func test_regex_dynamic_pattern_creation() -> void:
	var regex: RegEx = RegEx.create_from_string(r"\$([0-9]+\.[0-9]{2})")
	assert_true(regex.is_valid(), "RegEx created from string must be valid")
	var result: RegExMatch = regex.search("The Price: $19.99 (USD) today")
	assert_not_null(result, "RegEx search must find price")
	if result:
		assert_eq(result.get_string(1), "19.99", "Captured group must match price string")

# 7. Expression Simple Math Evaluation
func test_expression_simple_math_evaluation() -> void:
	var expr: Expression = Expression.new()
	var err: Error = expr.parse("10 + 20 * 3 - (15 / 5)")
	assert_eq(err, OK, "Expression parse math must return OK")
	var result: Variant = expr.execute()
	assert_false(expr.has_execute_failed(), "Expression execution must not fail")
	assert_eq(result, 67, "Math expression (10 + 60 - 3 = 67) mismatch")

# 8. Expression Variables and Inputs
func test_expression_variables_and_inputs() -> void:
	var expr: Expression = Expression.new()
	var input_names: PackedStringArray = PackedStringArray(["base_dmg", "crit_mult", "armor"])
	var err: Error = expr.parse("(base_dmg * crit_mult) - armor", input_names)
	assert_eq(err, OK, "Expression parse variables must return OK")
	var result: Variant = expr.execute([100.0, 1.5, 20.0])
	assert_false(expr.has_execute_failed(), "Expression execution must succeed")
	assert_approx(float(result), 130.0, 0.001, "Expression calculated value mismatch")

# 9. Expression Built-in Math Functions
func test_expression_built_in_math_functions() -> void:
	var expr: Expression = Expression.new()
	var err: Error = expr.parse("sqrt(val_a) + pow(val_b, 3) + abs(val_c)", PackedStringArray(["val_a", "val_b", "val_c"]))
	assert_eq(err, OK, "Expression built-in math parse must return OK")
	var result: Variant = expr.execute([16.0, 2.0, -10.0])
	# 4 + 8 + 10 = 22
	assert_approx(float(result), 22.0, 0.001, "Expression built-in math mismatch")

# 10. Expression String Manipulation
func test_expression_string_manipulation() -> void:
	var expr: Expression = Expression.new()
	var err: Error = expr.parse("greeting + ' ' + target.to_upper()", PackedStringArray(["greeting", "target"]))
	assert_eq(err, OK, "Expression string parse must return OK")
	var result: Variant = expr.execute(["Hello", "world"])
	assert_eq(result, "Hello WORLD", "Expression string operation mismatch")

# 11. Expression Custom Instance Methods
func test_expression_custom_instance_methods() -> void:
	var expr: Expression = Expression.new()
	var err: Error = expr.parse("get_unit_multiplier() * 2.0")
	assert_eq(err, OK, "Expression method call parse must return OK")
	var result: Variant = expr.execute([], self)
	assert_false(expr.has_execute_failed(), "Instance method execution must succeed")
	assert_approx(float(result), 7.0, 0.001, "Instance method result (3.5 * 2.0 = 7.0) mismatch")

# 12. Expression Parse Error Handling
func test_expression_parse_error_handling() -> void:
	var expr: Expression = Expression.new()
	var err: Error = expr.parse("2 + * / 5")
	assert_ne(err, OK, "Malformed expression parse must fail")
	assert_not_empty(expr.get_error_text(), "Expression error text must be populated")
