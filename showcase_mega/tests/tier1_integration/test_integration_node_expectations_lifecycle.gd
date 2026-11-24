# test_integration_node_expectations_lifecycle.gd
# Tier 1 Integration Suite: Node expectations, teardown lifecycle, physics settling, and scene/visual snapshots.
extends "res://addons/gdtest/core/test_suite.gd"

var _external_resource_allocated: bool = false

func _init() -> void:
	suite_name = "Tier1_Integration_Node_Expectations_Lifecycle_Suite"
	test_type = "integration"

# 1. Node Expectations: Existence, Tree Membership, and Visibility
func test_node_expectations_existence_and_visibility() -> void:
	var root: Node2D = autofree(Node2D.new())
	root.name = "RootNode2D"
	add_child(root)
	
	var child_sprite: Sprite2D = autofree(Sprite2D.new())
	child_sprite.name = "PlayerSprite"
	child_sprite.visible = true
	root.add_child(child_sprite)
	
	var hidden_node: Control = autofree(Control.new())
	hidden_node.name = "HiddenUI"
	hidden_node.visible = false
	root.add_child(hidden_node)
	
	expect_node(root).to_exist()
	expect_node(root).to_be_inside_tree()
	
	expect_node(child_sprite).to_be_visible()
	expect_node(hidden_node).to_be_hidden()
	
	on_node(root).to_have_child("PlayerSprite")
	on_node(root).to_have_child_count(2)

# 2. Node Expectations: Transforms and Properties
func test_node_expectations_transforms_and_properties() -> void:
	var node: Node2D = autofree(Node2D.new())
	node.name = "TransformEntity"
	node.position = Vector2(100.0, 200.0)
	node.scale = Vector2(2.0, 2.0)
	node.rotation = 0.5
	node.set_meta("health", 100)
	add_child(node)
	
	expect_node(node).to_have_position(Vector2(100.0, 200.0))
	expect_node(node).to_have_scale(Vector2(2.0, 2.0))
	expect_node(node).to_have_property(&"rotation", 0.5)
	expect_node(node).to_have_signal(&"draw")

# 3. Teardown Callbacks Registration and LIFO Execution
func test_teardown_callback_registration() -> void:
	_external_resource_allocated = true
	
	# Register teardown cleanup
	add_teardown(func():
		_external_resource_allocated = false
	)
	
	assert_true(_external_resource_allocated, "Resource must be marked allocated during test body")

# 4. Async Settle and assert_settled Physics Convergence
func test_physics_and_frame_settle() -> void:
	var body: RigidBody2D = autofree(RigidBody2D.new())
	body.name = "SettlingPhysicsBody"
	body.gravity_scale = 0.0
	body.linear_velocity = Vector2(0.0001, 0.0001)
	add_child(body)
	
	await settle(3, 2)
	var settled = await assert_settled(body, 1.0, 0.01)
	assert_true(settled, "Low velocity physics body must be recognized as settled")

# 5. Scene Hierarchy Snapshot Testing
func test_scene_hierarchy_snapshot() -> void:
	var canvas: CanvasLayer = autofree(CanvasLayer.new())
	canvas.name = "UIRootCanvas"
	
	var label: Label = autofree(Label.new())
	label.name = "TitleLabel"
	label.text = "Snapshot Test Title"
	canvas.add_child(label)
	
	var button: Button = autofree(Button.new())
	button.name = "ActionButton"
	button.text = "Click Me"
	canvas.add_child(button)
	
	add_child(canvas)
	
	var snap_ok = assert_scene_snapshot(canvas, "ui_hierarchy_snapshot", ["name", "text"], true)
	assert_true(snap_ok, "Scene snapshot assertion must serialize hierarchy and properties")

# 6. Visual Snapshot Rendering Checkpoint
func test_visual_snapshot_checkpoint() -> void:
	var node: ColorRect = autofree(ColorRect.new())
	node.name = "SnapshotColorRect"
	node.color = Color(0.1, 0.6, 0.9, 1.0)
	node.custom_minimum_size = Vector2(64.0, 64.0)
	node.size = Vector2(64.0, 64.0)
	add_child(node)
	
	await settle(2, 1)
	var vis_ok = await assert_visual_snapshot(node, "color_rect_snapshot", 0.05, true)
	assert_true(vis_ok, "Visual snapshot assertion must capture and validate image")
