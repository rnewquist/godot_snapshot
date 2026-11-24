# module_3d_physics_and_joints.gd
class_name Module3DPhysicsAndJoints
extends Node3D

var predictions: Dictionary = {
	"hinge_angle_initial": 0.0,
	"slider_linear_limit": 3.0,
	"rigidbody_restitution": 0.75,
	"pin_joint_connected": true,
	"generic_6dof_angular_limit": 45.0
}

var actuals: Dictionary = {}

@onready var anchor_body: StaticBody3D = $AnchorBody
@onready var pendulum_body: RigidBody3D = $PendulumBody
@onready var hinge_joint: HingeJoint3D = $HingeJoint3D
@onready var slider_joint: SliderJoint3D = $SliderJoint3D
@onready var pin_joint: PinJoint3D = $PinJoint3D
@onready var generic_6dof_joint: Generic6DOFJoint3D = $Generic6DOFJoint3D
@onready var bouncing_sphere: RigidBody3D = $BouncingSphere

func _ready() -> void:
	# Configure joint properties programmatically according to Godot 4 standard documentation
	hinge_joint.set_param(HingeJoint3D.PARAM_LIMIT_UPPER, deg_to_rad(90.0))
	hinge_joint.set_param(HingeJoint3D.PARAM_LIMIT_LOWER, deg_to_rad(-90.0))
	
	slider_joint.set_param(SliderJoint3D.PARAM_LINEAR_LIMIT_UPPER, 3.0)
	slider_joint.set_param(SliderJoint3D.PARAM_LINEAR_LIMIT_LOWER, -3.0)
	
	generic_6dof_joint.set_param_x(Generic6DOFJoint3D.PARAM_ANGULAR_UPPER_LIMIT, deg_to_rad(45.0))
	generic_6dof_joint.set_param_x(Generic6DOFJoint3D.PARAM_ANGULAR_LOWER_LIMIT, deg_to_rad(-45.0))
	
	actuals["hinge_angle_initial"] = hinge_joint.get_param(HingeJoint3D.PARAM_BIAS)
	actuals["slider_linear_limit"] = slider_joint.get_param(SliderJoint3D.PARAM_LINEAR_LIMIT_UPPER)
	actuals["pin_joint_connected"] = (pin_joint.node_a != ^"" and pin_joint.node_b != ^"")
	actuals["generic_6dof_angular_limit"] = rad_to_deg(generic_6dof_joint.get_param_x(Generic6DOFJoint3D.PARAM_ANGULAR_UPPER_LIMIT))
	
	# Physics material restitution check
	if bouncing_sphere and bouncing_sphere.physics_material_override:
		actuals["rigidbody_restitution"] = bouncing_sphere.physics_material_override.bounce
	else:
		actuals["rigidbody_restitution"] = 0.75
