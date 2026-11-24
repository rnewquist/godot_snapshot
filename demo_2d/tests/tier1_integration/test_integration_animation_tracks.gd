# test_integration_animation_tracks.gd
# Tier 1 Integration Suite 10: Animation Tracks & State Machines (7 tests)
# Tests Value, 3D Transform, Method, Bezier, Audio tracks, BlendSpace1D, and StateMachine transitions.
extends "res://addons/gdtest/core/test_suite.gd"

func _init() -> void:
	suite_name = "Tier1_Animation_Tracks_Integration_Suite"
	test_type = "integration"

## 1. Value Track Interpolation and Update Mode
func test_value_track_interpolation_and_update() -> void:
	var node: Node2D = autofree(Node2D.new()) as Node2D
	add_child(node)
	node.position = Vector2(0, 0)
	
	var anim: Animation = Animation.new()
	anim.length = 1.0
	var track_idx = anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(track_idx, NodePath(str(node.name) + ":position"))
	anim.track_set_interpolation_type(track_idx, Animation.INTERPOLATION_LINEAR)
	anim.value_track_set_update_mode(track_idx, Animation.UPDATE_CONTINUOUS)
	
	anim.track_insert_key(track_idx, 0.0, Vector2(0, 0))
	anim.track_insert_key(track_idx, 1.0, Vector2(100, 200))
	
	var interp_val = anim.value_track_interpolate(track_idx, 0.5)
	assert_vector2_approx(interp_val, Vector2(50, 100), 0.01, "Linear interpolation at t=0.5 must be midpoint")
	assert_eq(anim.track_get_interpolation_type(track_idx), Animation.INTERPOLATION_LINEAR, "Interpolation type must be LINEAR")
	assert_eq(anim.value_track_get_update_mode(track_idx), Animation.UPDATE_CONTINUOUS, "Update mode must be UPDATE_CONTINUOUS")

## 2. 3D Transform Track (Position, Rotation, Scale)
func test_3d_transform_track_position_rotation_scale() -> void:
	var anim: Animation = Animation.new()
	anim.length = 2.0
	
	# Position 3D Track
	var pos_track = anim.add_track(Animation.TYPE_POSITION_3D)
	anim.track_set_path(pos_track, NodePath("Bone:."))
	anim.position_track_insert_key(pos_track, 0.0, Vector3(0, 0, 0))
	anim.position_track_insert_key(pos_track, 2.0, Vector3(10, 20, 30))
	var interp_pos = anim.position_track_interpolate(pos_track, 1.0)
	assert_vector3_approx(interp_pos, Vector3(5, 10, 15), 0.01, "3D Position track must interpolate linearly")
	
	# Rotation 3D Track
	var rot_track = anim.add_track(Animation.TYPE_ROTATION_3D)
	anim.track_set_path(rot_track, NodePath("Bone:."))
	var q_start = Quaternion.IDENTITY
	var q_end = Quaternion(Vector3.UP, PI / 2.0)
	anim.rotation_track_insert_key(rot_track, 0.0, q_start)
	anim.rotation_track_insert_key(rot_track, 2.0, q_end)
	var interp_rot = anim.rotation_track_interpolate(rot_track, 2.0)
	assert_quaternion_approx(interp_rot, q_end, 0.01, "3D Rotation track at t=2.0 must match end quaternion")
	
	# Scale 3D Track
	var scale_track = anim.add_track(Animation.TYPE_SCALE_3D)
	anim.track_set_path(scale_track, NodePath("Bone:."))
	anim.scale_track_insert_key(scale_track, 0.0, Vector3(1, 1, 1))
	anim.scale_track_insert_key(scale_track, 2.0, Vector3(3, 3, 3))
	var interp_scale = anim.scale_track_interpolate(scale_track, 1.0)
	assert_vector3_approx(interp_scale, Vector3(2, 2, 2), 0.01, "3D Scale track must interpolate to midpoint")

## 3. Method Call Track Dispatch
func test_method_call_track_dispatch() -> void:
	var anim: Animation = Animation.new()
	anim.length = 1.0
	var track_idx = anim.add_track(Animation.TYPE_METHOD)
	anim.track_set_path(track_idx, NodePath("ReceiverNode"))
	
	var args: Array = ["event_payload", 42]
	anim.track_insert_key(track_idx, 0.5, {"method": "on_animation_event", "args": args})
	
	assert_eq(anim.track_get_key_count(track_idx), 1, "Method track should have 1 keyframe")
	assert_eq(anim.method_track_get_name(track_idx, 0), &"on_animation_event", "Method name must match")
	var retrieved_params = anim.method_track_get_params(track_idx, 0)
	assert_eq(retrieved_params.size(), 2, "Method params count must be 2")
	assert_eq(retrieved_params[0], "event_payload", "First arg must match")
	assert_eq(retrieved_params[1], 42, "Second arg must match")

## 4. Bezier Track Curves and Evaluation
func test_bezier_track_curves_and_evaluation() -> void:
	var anim: Animation = Animation.new()
	anim.length = 1.0
	var track_idx = anim.add_track(Animation.TYPE_BEZIER)
	anim.track_set_path(track_idx, NodePath("Node2D:position:x"))
	
	# Bezier key: in_handle, out_handle
	anim.bezier_track_insert_key(track_idx, 0.0, 0.0, Vector2(-0.25, 0), Vector2(0.25, 0))
	anim.bezier_track_insert_key(track_idx, 1.0, 100.0, Vector2(-0.25, 0), Vector2(0.25, 0))
	
	assert_eq(anim.track_get_key_count(track_idx), 2, "Bezier track must contain 2 keys")
	var eval_mid = anim.bezier_track_interpolate(track_idx, 0.5)
	assert_approx(eval_mid, 50.0, 5.0, "Bezier interpolation at midpoint should evaluate to approx 50.0")

## 5. Audio Track Stream Triggering
func test_audio_track_stream_trigger() -> void:
	var anim: Animation = Animation.new()
	anim.length = 2.0
	var track_idx = anim.add_track(Animation.TYPE_AUDIO)
	anim.track_set_path(track_idx, NodePath("AudioStreamPlayer"))
	
	var stream: AudioStreamGenerator = AudioStreamGenerator.new()
	anim.audio_track_insert_key(track_idx, 0.25, stream, 0.0, 1.5)
	
	assert_eq(anim.track_get_type(track_idx), Animation.TYPE_AUDIO, "Track type must be AUDIO")
	assert_eq(anim.audio_track_get_key_stream(track_idx, 0), stream, "Audio stream reference must match")
	assert_approx(anim.audio_track_get_key_start_offset(track_idx, 0), 0.0, 0.001, "Start offset must match")
	assert_approx(anim.audio_track_get_key_end_offset(track_idx, 0), 1.5, 0.001, "End offset must match")

## 6. AnimationNodeBlendSpace1D Blending Configuration
func test_animation_node_blend_space_1d_blending() -> void:
	var blend_space: AnimationNodeBlendSpace1D = AnimationNodeBlendSpace1D.new()
	blend_space.min_space = -1.0
	blend_space.max_space = 1.0
	blend_space.snap = 0.1
	
	var anim_idle: AnimationRootNode = AnimationNodeAnimation.new()
	(anim_idle as AnimationNodeAnimation).animation = &"idle"
	var anim_run: AnimationRootNode = AnimationNodeAnimation.new()
	(anim_run as AnimationNodeAnimation).animation = &"run"
	
	blend_space.add_blend_point(anim_idle, 0.0)
	blend_space.add_blend_point(anim_run, 1.0)
	
	assert_eq(blend_space.get_blend_point_count(), 2, "BlendSpace1D should have 2 blend points")
	assert_approx(blend_space.get_blend_point_position(0), 0.0, 0.001, "Blend point 0 position must be 0.0")
	assert_approx(blend_space.get_blend_point_position(1), 1.0, 0.001, "Blend point 1 position must be 1.0")
	assert_approx(blend_space.min_space, -1.0, 0.001, "Min space must be -1.0")
	assert_approx(blend_space.max_space, 1.0, 0.001, "Max space must be 1.0")

## 7. AnimationNodeStateMachine Transitions & State Architecture
func test_animation_node_state_machine_transitions() -> void:
	var state_machine: AnimationNodeStateMachine = AnimationNodeStateMachine.new()
	
	var idle_node: AnimationNodeAnimation = AnimationNodeAnimation.new()
	idle_node.animation = &"idle"
	var walk_node: AnimationNodeAnimation = AnimationNodeAnimation.new()
	walk_node.animation = &"walk"
	var jump_node: AnimationNodeAnimation = AnimationNodeAnimation.new()
	jump_node.animation = &"jump"
	
	state_machine.add_node(&"idle", idle_node)
	state_machine.add_node(&"walk", walk_node)
	state_machine.add_node(&"jump", jump_node)
	
	assert_true(state_machine.has_node(&"idle"), "State machine must contain 'idle' state")
	assert_true(state_machine.has_node(&"walk"), "State machine must contain 'walk' state")
	assert_true(state_machine.has_node(&"jump"), "State machine must contain 'jump' state")
	
	var trans_idle_walk: AnimationNodeStateMachineTransition = AnimationNodeStateMachineTransition.new()
	trans_idle_walk.xfade_time = 0.2
	trans_idle_walk.advance_mode = AnimationNodeStateMachineTransition.ADVANCE_MODE_AUTO
	state_machine.add_transition(&"idle", &"walk", trans_idle_walk)
	
	assert_true(state_machine.has_transition(&"idle", &"walk"), "Transition idle -> walk must exist")
	var fetched_trans = state_machine.get_transition(0)
	assert_approx(fetched_trans.xfade_time, 0.2, 0.001, "Cross-fade time must equal 0.2s")
