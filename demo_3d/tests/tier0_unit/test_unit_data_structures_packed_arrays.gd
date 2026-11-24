# test_unit_data_structures_packed_arrays.gd
# Tier 0 Pure Unit Suite: Typed Arrays, Dictionary merge modes, and all 9 Godot PackedArray types.
extends "res://addons/gdtest/core/test_suite.gd"

func _init() -> void:
	suite_name = "Tier0_Unit_Data_Structures_Packed_Arrays_Suite"
	test_type = "unit"

# 1. Typed Array Type Safety Int
func test_typed_array_type_safety_int() -> void:
	var arr: Array[int] = [1, 2, 3]
	assert_true(arr.is_typed(), "Array[int] must be typed")
	assert_eq(arr.get_typed_builtin(), TYPE_INT, "Typed array builtin must equal TYPE_INT")
	arr.append(4)
	assert_size(arr, 4, "Array size must be 4 after append")
	assert_eq(arr[3], 4, "Appended integer mismatch")

# 2. Typed Array Type Safety String
func test_typed_array_type_safety_string() -> void:
	var arr: Array[String] = ["alpha", "beta", "gamma"]
	assert_true(arr.is_typed(), "Array[String] must be typed")
	assert_eq(arr.get_typed_builtin(), TYPE_STRING, "Typed array builtin must equal TYPE_STRING")
	arr.append("delta")
	assert_true(arr.has("beta"), "Typed string array must contain 'beta'")
	assert_size(arr, 4, "Typed string array size mismatch")

# 3. Typed Array Object Hierarchy
func test_typed_array_object_hierarchy() -> void:
	var nodes: Array[Node] = []
	assert_true(nodes.is_typed(), "Array[Node] must be typed")
	var n1: Node = autofree(Node.new())
	var n2: Node = autofree(Node2D.new())
	nodes.append(n1)
	nodes.append(n2)
	assert_size(nodes, 2, "Array[Node] size mismatch")
	assert_eq(nodes[0], n1, "First node element mismatch")
	assert_eq(nodes[1], n2, "Derived Node2D element mismatch")

# 4. Typed Array Sorting & Searching
func test_typed_array_sorting_and_searching() -> void:
	var numbers: Array[int] = [45, 12, 89, 3, 27]
	numbers.sort()
	assert_array_eq(numbers, [3, 12, 27, 45, 89], "Array sort mismatch")
	var idx_27: int = numbers.bsearch(27)
	assert_eq(idx_27, 2, "Binary search index mismatch")
	var found_idx: int = numbers.find(89)
	assert_eq(found_idx, 4, "Find index mismatch")

# 5. Typed Array Functional Operations
func test_typed_array_functional_ops() -> void:
	var vals: Array[int] = [1, 2, 3, 4, 5]
	var doubled: Array = vals.map(func(x: int) -> int: return x * 2)
	assert_array_eq(doubled, [2, 4, 6, 8, 10], "map() doubling mismatch")
	
	var evens: Array = vals.filter(func(x: int) -> bool: return x % 2 == 0)
	assert_array_eq(evens, [2, 4], "filter() evens mismatch")
	
	var sum_val: int = vals.reduce(func(acc: int, x: int) -> int: return acc + x, 0)
	assert_eq(sum_val, 15, "reduce() sum mismatch")
	
	assert_true(vals.any(func(x: int) -> bool: return x > 4), "any() condition mismatch")
	assert_true(vals.all(func(x: int) -> bool: return x > 0), "all() condition mismatch")

# 6. Dictionary Merge Overwrite False
func test_dictionary_merge_overwrite_false() -> void:
	var target: Dictionary = {"hp": 100, "attack": 25}
	var source: Dictionary = {"attack": 50, "defense": 30}
	target.merge(source, false) # Overwrite = false (keep target's attack)
	assert_eq(target["hp"], 100, "Target HP must remain 100")
	assert_eq(target["attack"], 25, "Target attack must not be overwritten when overwrite=false")
	assert_eq(target["defense"], 30, "Source defense must be added")

# 7. Dictionary Merge Overwrite True
func test_dictionary_merge_overwrite_true() -> void:
	var target: Dictionary = {"hp": 100, "attack": 25}
	var source: Dictionary = {"attack": 50, "defense": 30}
	target.merge(source, true) # Overwrite = true (overwrite target's attack)
	assert_eq(target["hp"], 100, "Target HP must remain 100")
	assert_eq(target["attack"], 50, "Target attack must be overwritten when overwrite=true")
	assert_eq(target["defense"], 30, "Source defense must be added")

# 8. Dictionary Keys, Values & Iteration
func test_dictionary_keys_values_and_iteration() -> void:
	var dict: Dictionary = {"name": "Warrior", "level": 10, "gold": 500}
	assert_dict_has_key(dict, "name", "Dictionary must have key 'name'")
	assert_eq(dict.get("level", 1), 10, "Dictionary get existing key mismatch")
	assert_eq(dict.get("xp", 0), 0, "Dictionary get default value mismatch")
	dict.erase("gold")
	assert_dict_not_has_key(dict, "gold", "Dictionary must not have erased key")
	assert_size(dict.keys(), 2, "Dictionary keys count after erase mismatch")

# 9. Dictionary Duplicate Shallow vs Deep
func test_dictionary_duplicate_shallow_and_deep() -> void:
	var nested: Dictionary = {"stats": {"hp": 100}}
	var shallow_copy: Dictionary = nested.duplicate(false)
	var deep_copy: Dictionary = nested.duplicate(true)
	
	nested["stats"]["hp"] = 50
	assert_eq(shallow_copy["stats"]["hp"], 50, "Shallow copy must reflect nested mutation")
	assert_eq(deep_copy["stats"]["hp"], 100, "Deep copy must isolate nested mutation")

# 10. PackedByteArray Operations
func test_packed_byte_array_ops() -> void:
	var pba: PackedByteArray = PackedByteArray([0x47, 0x6F, 0x64, 0x6F, 0x74]) # "Godot"
	assert_size(pba, 5, "PackedByteArray size mismatch")
	assert_eq(pba.get_string_from_utf8(), "Godot", "UTF-8 decode mismatch")
	assert_eq(pba.hex_encode(), "476f646f74", "Hex encode mismatch")
	pba.append(0x21) # '!'
	assert_eq(pba.get_string_from_utf8(), "Godot!", "Appended byte mismatch")

# 11. PackedInt32Array Operations
func test_packed_int32_array_ops() -> void:
	var pia: PackedInt32Array = PackedInt32Array([10, 20, 30])
	pia.append(40)
	assert_size(pia, 4, "PackedInt32Array size mismatch")
	assert_eq(pia[1], 20, "PackedInt32Array index 1 mismatch")
	assert_true(pia.has(30), "PackedInt32Array must contain 30")
	var bytes: PackedByteArray = pia.to_byte_array()
	assert_eq(bytes.size(), 16, "PackedInt32Array of 4 ints must convert to 16 bytes")

# 12. PackedInt64Array Operations
func test_packed_int64_array_ops() -> void:
	var pi64: PackedInt64Array = PackedInt64Array([9223372036854775800, -9223372036854775800])
	assert_size(pi64, 2, "PackedInt64Array size mismatch")
	assert_eq(pi64[0], 9223372036854775800, "PackedInt64Array int64 max value mismatch")
	pi64.append(42)
	assert_size(pi64, 3, "PackedInt64Array size after append mismatch")

# 13. PackedFloat32Array Operations
func test_packed_float32_array_ops() -> void:
	var pfa: PackedFloat32Array = PackedFloat32Array([3.5, 1.2, 8.9])
	pfa.sort()
	assert_approx(pfa[0], 1.2, 0.001, "Sorted PackedFloat32Array element 0 mismatch")
	assert_approx(pfa[2], 8.9, 0.001, "Sorted PackedFloat32Array element 2 mismatch")
	var bytes: PackedByteArray = pfa.to_byte_array()
	assert_eq(bytes.size(), 12, "3 float32 elements must serialize to 12 bytes")

# 14. PackedFloat64Array Operations
func test_packed_float64_array_ops() -> void:
	var pf64: PackedFloat64Array = PackedFloat64Array([1.123456789012345, 2.718281828459045])
	assert_size(pf64, 2, "PackedFloat64Array size mismatch")
	assert_approx(pf64[0], 1.123456789012345, 0.00000001, "PackedFloat64Array double precision mismatch")
	var bytes: PackedByteArray = pf64.to_byte_array()
	assert_eq(bytes.size(), 16, "2 float64 elements must serialize to 16 bytes")

# 15. PackedStringArray Operations
func test_packed_string_array_ops() -> void:
	var psa: PackedStringArray = PackedStringArray(["godot", "engine", "tier0"])
	assert_size(psa, 3, "PackedStringArray size mismatch")
	assert_eq("_".join(psa), "godot_engine_tier0", "PackedStringArray join mismatch")
	assert_true(psa.has("engine"), "PackedStringArray must have 'engine'")

# 16. PackedVector2Array Operations
func test_packed_vector2_array_ops() -> void:
	var pva2: PackedVector2Array = PackedVector2Array([
		Vector2(0.0, 0.0),
		Vector2(10.0, 0.0),
		Vector2(10.0, 10.0),
		Vector2(0.0, 10.0)
	])
	assert_size(pva2, 4, "PackedVector2Array size mismatch")
	assert_vector2_approx(pva2[2], Vector2(10.0, 10.0), 0.001, "PackedVector2Array element 2 mismatch")
	var bytes: PackedByteArray = pva2.to_byte_array()
	assert_eq(bytes.size(), 32, "4 Vector2 elements (8 floats) must serialize to 32 bytes")

# 17. PackedVector3Array Operations
func test_packed_vector3_array_ops() -> void:
	var pva3: PackedVector3Array = PackedVector3Array([
		Vector3(1.0, 2.0, 3.0),
		Vector3(4.0, 5.0, 6.0)
	])
	assert_size(pva3, 2, "PackedVector3Array size mismatch")
	assert_vector3_approx(pva3[1], Vector3(4.0, 5.0, 6.0), 0.001, "PackedVector3Array element 1 mismatch")
	var bytes: PackedByteArray = pva3.to_byte_array()
	assert_eq(bytes.size(), 24, "2 Vector3 elements (6 floats) must serialize to 24 bytes")

# 18. PackedColorArray Operations
func test_packed_color_array_ops() -> void:
	var pca: PackedColorArray = PackedColorArray([Color.RED, Color.GREEN, Color.BLUE])
	assert_size(pca, 3, "PackedColorArray size mismatch")
	assert_color_approx(pca[0], Color.RED, 0.001, "PackedColorArray element 0 mismatch")
	var bytes: PackedByteArray = pca.to_byte_array()
	assert_eq(bytes.size(), 48, "3 Color elements (12 floats) must serialize to 48 bytes")
