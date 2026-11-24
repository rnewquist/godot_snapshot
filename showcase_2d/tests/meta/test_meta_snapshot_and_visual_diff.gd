# test_meta_snapshot_and_visual_diff.gd
# Meta Test Suite: Deterministic State Snapshot Engine and Quantitative Visual Diffing.
# Validates float quantization (4 decimals), volatile ID and pointer stripping, JSON drift failures,
# visual diff Manhattan color distance, pixel mismatch ratio, Rect2i exclusion masks, and #FF00FF neon magenta heatmaps.
extends "res://addons/gdtest/core/test_suite.gd"

const SnapshotEngineClass = preload("res://addons/gdtest/core/snapshot_engine.gd")
const VisualDiffEngineClass = preload("res://addons/gdtest/core/visual_diff_engine.gd")

class IsolatedMockSuite extends GDTestSuite:
	func _init() -> void:
		suite_name = "IsolatedMockSuite"
		test_type = "unit"

func _init() -> void:
	suite_name = "Meta_Snapshot_And_Visual_Diff_Suite"
	test_type = "unit"

# ==============================================================================
# 1. FLOAT QUANTIZATION & SANITIZATION (4 Decimal Precision & Near-Zero Suppression)
# ==============================================================================

func test_snapshot_float_quantization() -> void:
	# 1. Scalar float
	var raw_float = 3.1415926535
	var sanitized_float = SnapshotEngineClass.sanitize(raw_float)
	assert_eq(sanitized_float, 3.1416, "Float must be quantized to 4 decimals (3.1416)")
	
	# 2. Near-zero suppression (< 0.00005 -> 0.0)
	var near_zero_pos = 0.00003
	var near_zero_neg = -0.00002
	assert_eq(SnapshotEngineClass.sanitize(near_zero_pos), 0.0, "Near-zero positive float must be snapped to 0.0")
	assert_eq(SnapshotEngineClass.sanitize(near_zero_neg), 0.0, "Near-zero negative float must avoid -0.0 artifacts and snap to 0.0")
	
	# 3. Vector2 & Vector3 quantization
	var v2 = Vector2(1.23456, 7.89012)
	var san_v2 = SnapshotEngineClass.sanitize(v2)
	assert_approx(san_v2["x"], 1.2346, 0.0001, "Vector2.x quantized")
	assert_approx(san_v2["y"], 7.8901, 0.0001, "Vector2.y quantized")
	
	var v3 = Vector3(0.11111, 0.22222, 0.33333)
	var san_v3 = SnapshotEngineClass.sanitize(v3)
	assert_approx(san_v3["x"], 0.1111, 0.0001)
	assert_approx(san_v3["y"], 0.2222, 0.0001)
	assert_approx(san_v3["z"], 0.3333, 0.0001)
	
	# 4. Color & Quaternion quantization
	var col = Color(0.12345, 0.67891, 0.99999, 1.0)
	var san_col = SnapshotEngineClass.sanitize(col)
	assert_approx(san_col["r"], 0.1235, 0.0001)
	assert_approx(san_col["g"], 0.6789, 0.0001)
	assert_approx(san_col["b"], 1.0, 0.0001)
	assert_approx(san_col["a"], 1.0, 0.0001)

# ==============================================================================
# 2. VOLATILE ID STRIPPING & DETERMINISTIC SORTING
# ==============================================================================

func test_snapshot_volatile_id_and_pointer_stripping() -> void:
	# 1. Stripping @Node@1234 auto-generated suffix
	var volatile_node_name = "@CharacterBody2D@10452"
	var clean_node_name = SnapshotEngineClass._sanitize_string(volatile_node_name)
	assert_eq(clean_node_name, "@CharacterBody2D", "Trailing numeric instance ID suffix must be stripped")
	
	# 2. Stripping pointer memory address <Resource#45892>
	var volatile_ptr = "<MyResource#847291>"
	var clean_ptr = SnapshotEngineClass._sanitize_string(volatile_ptr)
	assert_eq(clean_ptr, "<MyResource>", "Memory pointer address must be stripped to prevent snapshot churn")
	
	# 3. Deterministic dictionary key sorting
	var unsorted_dict = {
		"zeta": 1,
		"alpha": 2,
		"beta": 3,
		"gamma": 4
	}
	var san_dict: Dictionary = SnapshotEngineClass.sanitize(unsorted_dict)
	var keys = san_dict.keys()
	assert_eq(keys, ["alpha", "beta", "gamma", "zeta"], "Dictionary keys must be sorted alphabetically")

func test_snapshot_node_tree_serialization() -> void:
	var root = Node2D.new()
	root.name = "RootNode"
	root.position = Vector2(50.12345, 100.67891)
	root.rotation = 0.5
	root.modulate = Color(1.0, 0.5, 0.25, 1.0)
	autofree(root)
	
	var child = Control.new()
	child.name = "ChildControl"
	child.size = Vector2(200.0, 100.0)
	root.add_child(child)
	
	var serialized = SnapshotEngineClass.serialize_node(root, true)
	
	assert_eq(serialized["name"], "RootNode")
	assert_eq(serialized["type"], "Node2D")
	assert_eq(serialized["position"]["x"], 50.1235)
	assert_eq(serialized["position"]["y"], 100.6789)
	assert_eq(serialized["children"].size(), 1, "Child node must be serialized")
	assert_eq(serialized["children"][0]["name"], "ChildControl")
	assert_eq(serialized["children"][0]["type"], "Control")

# ==============================================================================
# 3. STRUCTURAL JSON DIFF CALCULATION & DRIFT FAILURES (IsolatedMockSuite)
# ==============================================================================

func test_snapshot_structural_diff_calculation() -> void:
	var expected = {
		"player": {
			"health": 100,
			"mana": 50,
			"items": ["sword", "shield"]
		},
		"version": 1
	}
	
	var actual = {
		"player": {
			"health": 85,       # Modified value
			"items": ["sword", "potion", "ring"], # Modified array
			"buff": "haste"     # Extra key
			# mana is missing
		},
		"version": 1
	}
	
	var diffs = SnapshotEngineClass.compute_diff(expected, actual)
	assert_true(diffs.size() >= 3, "Diff calculation must identify health change, missing mana, and extra buff")
	
	var diff_text = "\n".join(diffs)
	assert_string_contains(diff_text, "health", "Diff must report health mismatch")
	assert_string_contains(diff_text, "mana", "Diff must report missing mana")
	assert_string_contains(diff_text, "buff", "Diff must report extra buff key")

func test_snapshot_drift_failure_in_isolated_mock_suite() -> void:
	var mock_suite = IsolatedMockSuite.new()
	autofree(mock_suite)
	
	# Compute diff on mismatched data
	var golden_data = {"score": 100, "level": 1}
	var drift_data = {"score": 250, "level": 1}
	
	var diff_lines = SnapshotEngineClass.compute_diff(golden_data, drift_data)
	assert_false(diff_lines.is_empty(), "compute_diff must detect score difference")
	
	# Simulate snapshot failure on mock suite
	mock_suite._record_failure("Snapshot mismatch: score expected 100, got 250")
	
	assert_eq(mock_suite.fail_count, 1, "Mock suite isolated failure recorded")
	assert_eq(mock_suite.failures.size(), 1)
	assert_string_contains(mock_suite.failures[0]["message"], "score expected 100")

# ==============================================================================
# 4. VISUAL DIFF MANHATTAN COLOR DISTANCE & PIXEL MATCHING
# ==============================================================================

func test_visual_diff_manhattan_color_distance() -> void:
	# 1. Identical colors
	var dist_zero = VisualDiffEngineClass._calculate_color_difference(Color.RED, Color.RED)
	assert_approx(dist_zero, 0.0, 0.0001, "Distance between identical colors must be 0.0")
	
	# 2. Black (0,0,0,1) vs White (1,1,1,1) -> dr=1, dg=1, db=1, da=0 -> sum=3 / 4.0 = 0.75
	var dist_bw = VisualDiffEngineClass._calculate_color_difference(Color.BLACK, Color.WHITE)
	assert_approx(dist_bw, 0.75, 0.001, "Manhattan distance between Black and White must be 0.75")
	
	# 3. Transparent Black (0,0,0,0) vs Opaque White (1,1,1,1) -> dr=1, dg=1, db=1, da=1 -> sum=4 / 4.0 = 1.0
	var dist_max = VisualDiffEngineClass._calculate_color_difference(Color(0, 0, 0, 0), Color(1, 1, 1, 1))
	assert_approx(dist_max, 1.0, 0.001, "Maximum Manhattan distance across all 4 channels must be 1.0")
	
	# 4. Small delta under tolerance
	var c1 = Color(0.5, 0.5, 0.5, 1.0)
	var c2 = Color(0.51, 0.51, 0.51, 1.0)
	var dist_small = VisualDiffEngineClass._calculate_color_difference(c1, c2)
	assert_true(dist_small < 0.02, "Distance must be under default color tolerance 0.02")

func test_visual_diff_image_comparison_identical_and_mismatch() -> void:
	# 1. Identical 16x16 images
	var img1 = Image.create(16, 16, false, Image.FORMAT_RGBA8)
	img1.fill(Color(0.2, 0.4, 0.6, 1.0))
	var img2 = Image.create(16, 16, false, Image.FORMAT_RGBA8)
	img2.fill(Color(0.2, 0.4, 0.6, 1.0))
	
	var pass_result = VisualDiffEngineClass.compare_images(img1, img2, 0.02, 0.0)
	assert_true(pass_result["passed"], "Identical images must pass visual diff")
	assert_eq(pass_result["mismatched_pixels"], 0, "Mismatched pixels must be 0")
	assert_approx(pass_result["mismatch_ratio"], 0.0, 0.0001)
	
	# 2. Modified image with 10 mismatched pixels
	var img_modified = img2.duplicate()
	for i in range(10):
		img_modified.set_pixel(i, 0, Color.RED)
		
	var fail_result = VisualDiffEngineClass.compare_images(img_modified, img1, 0.02, 0.0)
	assert_false(fail_result["passed"], "Modified image must fail with 0 allowed mismatch ratio")
	assert_eq(fail_result["mismatched_pixels"], 10, "Mismatched pixels must equal 10")
	var expected_ratio = 10.0 / 256.0 # 16*16 = 256
	assert_approx(fail_result["mismatch_ratio"], expected_ratio, 0.001)

func test_visual_diff_dimension_mismatch() -> void:
	var img_a = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	var img_b = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	
	var dim_result = VisualDiffEngineClass.compare_images(img_a, img_b)
	assert_false(dim_result["passed"], "Dimension mismatch must fail comparison")
	assert_string_contains(dim_result["error"], "Dimension mismatch", "Error message must state dimension mismatch")

# ==============================================================================
# 5. RECT2I EXCLUSION MASKS & #FF00FF NEON MAGENTA HEATMAPS
# ==============================================================================

func test_visual_diff_rect2i_exclusion_masks() -> void:
	var w = 20
	var h = 20
	var baseline = Image.create(w, h, false, Image.FORMAT_RGBA8)
	baseline.fill(Color.BLACK)
	
	var actual = Image.create(w, h, false, Image.FORMAT_RGBA8)
	actual.fill(Color.BLACK)
	
	# Modify 4 pixels in top-left region (0,0) to (1,1)
	actual.set_pixel(0, 0, Color.WHITE)
	actual.set_pixel(0, 1, Color.WHITE)
	actual.set_pixel(1, 0, Color.WHITE)
	actual.set_pixel(1, 1, Color.WHITE)
	
	# Mask the 4x4 area containing the modified pixels
	var mask_rect = Rect2i(0, 0, 4, 4) # 16 pixels masked
	var result = VisualDiffEngineClass.compare_images(actual, baseline, 0.02, 0.0, [mask_rect])
	
	assert_eq(result["masked_pixels"], 16, "Exclusion mask must cover exactly 16 pixels")
	assert_eq(result["active_pixels"], 400 - 16, "Active pixels must equal 384")
	assert_eq(result["mismatched_pixels"], 0, "Modified pixels inside exclusion mask must be ignored")
	assert_true(result["passed"], "Comparison must pass because diffs are masked")

func test_visual_diff_neon_magenta_heatmap_generation() -> void:
	var w = 8
	var h = 8
	var baseline = Image.create(w, h, false, Image.FORMAT_RGBA8)
	baseline.fill(Color.BLUE)
	
	var actual = Image.create(w, h, false, Image.FORMAT_RGBA8)
	actual.fill(Color.BLUE)
	
	# Set pixel (3, 3) to RED (mismatch)
	actual.set_pixel(3, 3, Color.RED)
	
	var res = VisualDiffEngineClass.compare_images(actual, baseline, 0.02, 0.0)
	var diff_img: Image = res["diff_image"]
	
	assert_not_null(diff_img, "Diff image must be generated")
	assert_eq(diff_img.get_width(), w)
	assert_eq(diff_img.get_height(), h)
	
	# Verify mismatched pixel is marked with Neon Magenta #FF00FF (Color(1.0, 0.0, 1.0, 1.0))
	var diff_pixel = diff_img.get_pixel(3, 3)
	assert_color_approx(diff_pixel, VisualDiffEngineClass.NEON_MAGENTA, 0.001, "Mismatched pixel must be marked with #FF00FF Neon Magenta")
	
	# Verify matching pixel is marked with dimmed grayscale
	var match_pixel = diff_img.get_pixel(0, 0)
	assert_approx(match_pixel.r, match_pixel.g, 0.01, "Matching pixel must be grayscale (r == g)")
	assert_approx(match_pixel.g, match_pixel.b, 0.01, "Matching pixel must be grayscale (g == b)")
