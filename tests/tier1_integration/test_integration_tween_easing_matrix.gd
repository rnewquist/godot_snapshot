# test_integration_tween_easing_matrix.gd
# Tier 1 Integration Suite 9: Full 33-Equation Tween Transition & Easing Matrix.
extends "res://addons/gdtest/core/test_suite.gd"

var test_scene_2d: Node2D

func _init() -> void:
	suite_name = "Tier1_Integration_Tween_Easing_Matrix"
	test_type = "integration"

func before_each() -> void:
	test_scene_2d = autofree(Node2D.new()) as Node2D
	add_child(test_scene_2d)

func _run_tween_matrix_test(trans: Tween.TransitionType, ease_mode: Tween.EaseType, tag: String) -> void:
	var dummy: Node2D = autofree(Node2D.new()) as Node2D
	dummy.position = Vector2(0, 0)
	test_scene_2d.add_child(dummy)
	
	var tween: Tween = create_tween()
	tween.set_trans(trans)
	tween.set_ease(ease_mode)
	tween.tween_property(dummy, "position:x", 100.0, 0.02)
	
	await tween.finished
	assert_approx(dummy.position.x, 100.0, 0.5, "Tween %s must reach final target 100.0" % tag)

# ==============================================================================
# 1. TRANS_LINEAR (3 EASING MODES)
# ==============================================================================

func test_tween_trans_linear_ease_in() -> void:
	await _run_tween_matrix_test(Tween.TRANS_LINEAR, Tween.EASE_IN, "TRANS_LINEAR + EASE_IN")

func test_tween_trans_linear_ease_out() -> void:
	await _run_tween_matrix_test(Tween.TRANS_LINEAR, Tween.EASE_OUT, "TRANS_LINEAR + EASE_OUT")

func test_tween_trans_linear_ease_in_out() -> void:
	await _run_tween_matrix_test(Tween.TRANS_LINEAR, Tween.EASE_IN_OUT, "TRANS_LINEAR + EASE_IN_OUT")

# ==============================================================================
# 2. TRANS_SINE (3 EASING MODES)
# ==============================================================================

func test_tween_trans_sine_ease_in() -> void:
	await _run_tween_matrix_test(Tween.TRANS_SINE, Tween.EASE_IN, "TRANS_SINE + EASE_IN")

func test_tween_trans_sine_ease_out() -> void:
	await _run_tween_matrix_test(Tween.TRANS_SINE, Tween.EASE_OUT, "TRANS_SINE + EASE_OUT")

func test_tween_trans_sine_ease_in_out() -> void:
	await _run_tween_matrix_test(Tween.TRANS_SINE, Tween.EASE_IN_OUT, "TRANS_SINE + EASE_IN_OUT")

# ==============================================================================
# 3. TRANS_QUINT (3 EASING MODES)
# ==============================================================================

func test_tween_trans_quint_ease_in() -> void:
	await _run_tween_matrix_test(Tween.TRANS_QUINT, Tween.EASE_IN, "TRANS_QUINT + EASE_IN")

func test_tween_trans_quint_ease_out() -> void:
	await _run_tween_matrix_test(Tween.TRANS_QUINT, Tween.EASE_OUT, "TRANS_QUINT + EASE_OUT")

func test_tween_trans_quint_ease_in_out() -> void:
	await _run_tween_matrix_test(Tween.TRANS_QUINT, Tween.EASE_IN_OUT, "TRANS_QUINT + EASE_IN_OUT")

# ==============================================================================
# 4. TRANS_QUART (3 EASING MODES)
# ==============================================================================

func test_tween_trans_quart_ease_in() -> void:
	await _run_tween_matrix_test(Tween.TRANS_QUART, Tween.EASE_IN, "TRANS_QUART + EASE_IN")

func test_tween_trans_quart_ease_out() -> void:
	await _run_tween_matrix_test(Tween.TRANS_QUART, Tween.EASE_OUT, "TRANS_QUART + EASE_OUT")

func test_tween_trans_quart_ease_in_out() -> void:
	await _run_tween_matrix_test(Tween.TRANS_QUART, Tween.EASE_IN_OUT, "TRANS_QUART + EASE_IN_OUT")

# ==============================================================================
# 5. TRANS_QUAD (3 EASING MODES)
# ==============================================================================

func test_tween_trans_quad_ease_in() -> void:
	await _run_tween_matrix_test(Tween.TRANS_QUAD, Tween.EASE_IN, "TRANS_QUAD + EASE_IN")

func test_tween_trans_quad_ease_out() -> void:
	await _run_tween_matrix_test(Tween.TRANS_QUAD, Tween.EASE_OUT, "TRANS_QUAD + EASE_OUT")

func test_tween_trans_quad_ease_in_out() -> void:
	await _run_tween_matrix_test(Tween.TRANS_QUAD, Tween.EASE_IN_OUT, "TRANS_QUAD + EASE_IN_OUT")

# ==============================================================================
# 6. TRANS_EXPO (3 EASING MODES)
# ==============================================================================

func test_tween_trans_expo_ease_in() -> void:
	await _run_tween_matrix_test(Tween.TRANS_EXPO, Tween.EASE_IN, "TRANS_EXPO + EASE_IN")

func test_tween_trans_expo_ease_out() -> void:
	await _run_tween_matrix_test(Tween.TRANS_EXPO, Tween.EASE_OUT, "TRANS_EXPO + EASE_OUT")

func test_tween_trans_expo_ease_in_out() -> void:
	await _run_tween_matrix_test(Tween.TRANS_EXPO, Tween.EASE_IN_OUT, "TRANS_EXPO + EASE_IN_OUT")

# ==============================================================================
# 7. TRANS_ELASTIC (3 EASING MODES)
# ==============================================================================

func test_tween_trans_elastic_ease_in() -> void:
	await _run_tween_matrix_test(Tween.TRANS_ELASTIC, Tween.EASE_IN, "TRANS_ELASTIC + EASE_IN")

func test_tween_trans_elastic_ease_out() -> void:
	await _run_tween_matrix_test(Tween.TRANS_ELASTIC, Tween.EASE_OUT, "TRANS_ELASTIC + EASE_OUT")

func test_tween_trans_elastic_ease_in_out() -> void:
	await _run_tween_matrix_test(Tween.TRANS_ELASTIC, Tween.EASE_IN_OUT, "TRANS_ELASTIC + EASE_IN_OUT")

# ==============================================================================
# 8. TRANS_CUBIC (3 EASING MODES)
# ==============================================================================

func test_tween_trans_cubic_ease_in() -> void:
	await _run_tween_matrix_test(Tween.TRANS_CUBIC, Tween.EASE_IN, "TRANS_CUBIC + EASE_IN")

func test_tween_trans_cubic_ease_out() -> void:
	await _run_tween_matrix_test(Tween.TRANS_CUBIC, Tween.EASE_OUT, "TRANS_CUBIC + EASE_OUT")

func test_tween_trans_cubic_ease_in_out() -> void:
	await _run_tween_matrix_test(Tween.TRANS_CUBIC, Tween.EASE_IN_OUT, "TRANS_CUBIC + EASE_IN_OUT")

# ==============================================================================
# 9. TRANS_CIRC (3 EASING MODES)
# ==============================================================================

func test_tween_trans_circ_ease_in() -> void:
	await _run_tween_matrix_test(Tween.TRANS_CIRC, Tween.EASE_IN, "TRANS_CIRC + EASE_IN")

func test_tween_trans_circ_ease_out() -> void:
	await _run_tween_matrix_test(Tween.TRANS_CIRC, Tween.EASE_OUT, "TRANS_CIRC + EASE_OUT")

func test_tween_trans_circ_ease_in_out() -> void:
	await _run_tween_matrix_test(Tween.TRANS_CIRC, Tween.EASE_IN_OUT, "TRANS_CIRC + EASE_IN_OUT")

# ==============================================================================
# 10. TRANS_BOUNCE (3 EASING MODES)
# ==============================================================================

func test_tween_trans_bounce_ease_in() -> void:
	await _run_tween_matrix_test(Tween.TRANS_BOUNCE, Tween.EASE_IN, "TRANS_BOUNCE + EASE_IN")

func test_tween_trans_bounce_ease_out() -> void:
	await _run_tween_matrix_test(Tween.TRANS_BOUNCE, Tween.EASE_OUT, "TRANS_BOUNCE + EASE_OUT")

func test_tween_trans_bounce_ease_in_out() -> void:
	await _run_tween_matrix_test(Tween.TRANS_BOUNCE, Tween.EASE_IN_OUT, "TRANS_BOUNCE + EASE_IN_OUT")

# ==============================================================================
# 11. TRANS_BACK (3 EASING MODES)
# ==============================================================================

func test_tween_trans_back_ease_in() -> void:
	await _run_tween_matrix_test(Tween.TRANS_BACK, Tween.EASE_IN, "TRANS_BACK + EASE_IN")

func test_tween_trans_back_ease_out() -> void:
	await _run_tween_matrix_test(Tween.TRANS_BACK, Tween.EASE_OUT, "TRANS_BACK + EASE_OUT")

func test_tween_trans_back_ease_in_out() -> void:
	await _run_tween_matrix_test(Tween.TRANS_BACK, Tween.EASE_IN_OUT, "TRANS_BACK + EASE_IN_OUT")
