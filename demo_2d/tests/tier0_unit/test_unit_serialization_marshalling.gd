# test_unit_serialization_marshalling.gd
# Tier 0 Pure Unit Suite: JSON serialization/deserialization, var_to_bytes/bytes_to_var marshalling, and ConfigFile parsing.
extends "res://addons/gdtest/core/test_suite.gd"

func _init() -> void:
	suite_name = "Tier0_Unit_Serialization_Marshalling_Suite"
	test_type = "unit"

# 1. JSON Stringify Primitives & Arrays
func test_json_stringify_primitives_and_arrays() -> void:
	var data: Array = [1, "two", true, 4.5]
	var json_str: String = JSON.stringify(data)
	assert_string_contains(json_str, "two", "JSON stringify must contain string literal")
	var parsed: Variant = JSON.parse_string(json_str)
	assert_eq(parsed.size(), 4, "Parsed array size mismatch")
	assert_eq(parsed[0], 1, "Parsed element 0 mismatch")
	assert_eq(parsed[1], "two", "Parsed element 1 mismatch")
	assert_eq(parsed[2], true, "Parsed element 2 mismatch")

# 2. JSON Stringify & Parse Nested Dictionaries
func test_json_stringify_and_parse_nested_dictionaries() -> void:
	var dict: Dictionary = {
		"user": {
			"id": 101,
			"roles": ["admin", "tester"],
			"active": true
		}
	}
	var encoded: String = JSON.stringify(dict, "\t")
	var decoded: Variant = JSON.parse_string(encoded)
	assert_dict_has_key(decoded, "user", "Decoded dict must have 'user'")
	assert_eq(decoded["user"]["id"], 101, "Decoded user ID mismatch")
	assert_array_eq(decoded["user"]["roles"], ["admin", "tester"], "Decoded user roles mismatch")

# 3. JSON Parse Error Handling
func test_json_parse_error_handling() -> void:
	var malformed_json: String = '{"key": "value", bad_syntax}'
	var json_parser: JSON = JSON.new()
	var err: Error = json_parser.parse(malformed_json)
	assert_ne(err, OK, "Malformed JSON must return non-OK error code")
	assert_gte(json_parser.get_error_line(), 0, "Error line must be non-negative")
	assert_not_empty(json_parser.get_error_message(), "Error message must not be empty")

# 4. JSON Type Preservation
func test_json_type_preservation() -> void:
	var payload: Dictionary = {
		"null_val": null,
		"bool_val": false,
		"int_val": 42,
		"float_val": 3.14159,
		"str_val": "Godot"
	}
	var json_str: String = JSON.stringify(payload)
	var recovered: Dictionary = JSON.parse_string(json_str)
	assert_null(recovered["null_val"], "JSON null value mismatch")
	assert_false(recovered["bool_val"], "JSON bool value mismatch")
	assert_eq(recovered["int_val"], 42, "JSON int value mismatch")
	assert_approx(recovered["float_val"], 3.14159, 0.0001, "JSON float value mismatch")
	assert_eq(recovered["str_val"], "Godot", "JSON string value mismatch")

# 5. var_to_bytes and bytes_to_var Primitives
func test_var_to_bytes_and_bytes_to_var_primitives() -> void:
	var int_val: int = 12345678
	var bytes_int: PackedByteArray = var_to_bytes(int_val)
	assert_eq(bytes_to_var(bytes_int), int_val, "Int marshalling roundtrip mismatch")
	
	var str_val: String = "GDScript Tier 0 Unit"
	var bytes_str: PackedByteArray = var_to_bytes(str_val)
	assert_eq(bytes_to_var(bytes_str), str_val, "String marshalling roundtrip mismatch")

# 6. var_to_bytes and bytes_to_var Math Types
func test_var_to_bytes_and_bytes_to_var_vectors_and_transforms() -> void:
	var v3: Vector3 = Vector3(1.23, 4.56, 7.89)
	var bytes_v3: PackedByteArray = var_to_bytes(v3)
	var rec_v3: Vector3 = bytes_to_var(bytes_v3)
	assert_vector3_approx(rec_v3, v3, 0.001, "Vector3 bytes roundtrip mismatch")
	
	var t3: Transform3D = Transform3D(Basis(Quaternion(Vector3.UP, PI / 4.0)), Vector3(10.0, 20.0, 30.0))
	var bytes_t3: PackedByteArray = var_to_bytes(t3)
	var rec_t3: Transform3D = bytes_to_var(bytes_t3)
	assert_transform3d_approx(rec_t3, t3, 0.001, "Transform3D bytes roundtrip mismatch")

# 7. var_to_bytes and bytes_to_var Object Flag Safety
func test_var_to_bytes_and_bytes_to_var_objects_flag() -> void:
	var simple_data: Array = [1, 2, 3]
	var bytes_no_obj: PackedByteArray = var_to_bytes(simple_data)
	var bytes_with_obj: PackedByteArray = var_to_bytes_with_objects(simple_data)
	assert_array_eq(bytes_to_var(bytes_no_obj), simple_data, "bytes_to_var mismatch")
	assert_array_eq(bytes_to_var_with_objects(bytes_with_obj), simple_data, "bytes_to_var_with_objects mismatch")

# 8. var_to_str and str_to_var Roundtrip
func test_var_to_str_and_str_to_var_roundtrip() -> void:
	var data: Dictionary = {
		"vec": Vector2(10.0, 20.0),
		"color": Color.RED,
		"tags": ["unit", "test"]
	}
	var text_rep: String = var_to_str(data)
	assert_string_contains(text_rep, "Vector2", "var_to_str must represent Vector2")
	var reconstructed: Dictionary = str_to_var(text_rep)
	assert_vector2_approx(reconstructed["vec"], Vector2(10.0, 20.0), 0.001, "Reconstructed Vector2 mismatch")
	assert_color_approx(reconstructed["color"], Color.RED, 0.001, "Reconstructed Color mismatch")

# 9. ConfigFile Set & Get Values
func test_config_file_set_and_get_values() -> void:
	var config: ConfigFile = ConfigFile.new()
	config.set_value("audio", "master_volume", 0.75)
	config.set_value("graphics", "fullscreen", true)
	config.set_value("graphics", "resolution", Vector2i(1920, 1080))
	
	assert_approx(config.get_value("audio", "master_volume", 1.0), 0.75, 0.001, "ConfigFile float get mismatch")
	assert_true(config.get_value("graphics", "fullscreen", false), "ConfigFile bool get mismatch")
	assert_eq(config.get_value("graphics", "resolution", Vector2i.ZERO), Vector2i(1920, 1080), "ConfigFile vector get mismatch")
	assert_eq(config.get_value("missing", "key", "default_val"), "default_val", "ConfigFile default fallback mismatch")

# 10. ConfigFile Sections & Keys
func test_config_file_sections_and_keys() -> void:
	var config: ConfigFile = ConfigFile.new()
	config.set_value("section_a", "k1", 1)
	config.set_value("section_a", "k2", 2)
	config.set_value("section_b", "k3", 3)
	
	assert_true(config.has_section("section_a"), "ConfigFile must have section_a")
	assert_true(config.has_section_key("section_a", "k1"), "ConfigFile must have section_a:k1")
	assert_false(config.has_section("section_c"), "ConfigFile must not have section_c")
	
	var sections: PackedStringArray = config.get_sections()
	assert_size(sections, 2, "ConfigFile sections count mismatch")
	var keys_a: PackedStringArray = config.get_section_keys("section_a")
	assert_size(keys_a, 2, "ConfigFile keys count mismatch")

# 11. ConfigFile Erase & Clear
func test_config_file_erase_and_clear() -> void:
	var config: ConfigFile = ConfigFile.new()
	config.set_value("game", "score", 1000)
	config.set_value("game", "lives", 3)
	config.erase_section_key("game", "lives")
	assert_false(config.has_section_key("game", "lives"), "Erased key must not exist")
	assert_true(config.has_section_key("game", "score"), "Non-erased key must exist")
	
	config.clear()
	assert_empty(config.get_sections(), "Cleared ConfigFile must have 0 sections")

# 12. ConfigFile Encode & Parse Text
func test_config_file_encode_and_parse_string() -> void:
	var config: ConfigFile = ConfigFile.new()
	config.set_value("player", "name", "Hero")
	config.set_value("player", "level", 99)
	var text_data: String = config.encode_to_text()
	
	var config2: ConfigFile = ConfigFile.new()
	var err: Error = config2.parse(text_data)
	assert_eq(err, OK, "ConfigFile parse must return OK")
	assert_eq(config2.get_value("player", "name"), "Hero", "Parsed ConfigFile player name mismatch")
	assert_eq(config2.get_value("player", "level"), 99, "Parsed ConfigFile player level mismatch")
