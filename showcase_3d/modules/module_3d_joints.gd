# module_3d_joints.gd
extends Node3D
class_name Module3DJoints

@onready var hinge_door: RigidBody3D = $HingeSection/DoorBody
@onready var slider_piston: RigidBody3D = $SliderSection/PistonBody
@onready var pin_bob: RigidBody3D = $PinSection/PinBob
@onready var cone_bob: RigidBody3D = get_node_or_null("ConeTwistSection/ConeBob")
@onready var gimbal_body: RigidBody3D = get_node_or_null("Generic6DOFSection/GimbalBody")
@onready var raycast: RayCast3D = $RayCast3D

func _ready() -> void:
	# Apply initial impulses to test constraints
	if hinge_door:
		hinge_door.apply_torque_impulse(Vector3(0, 8.0, 0))
	if slider_piston:
		slider_piston.apply_central_impulse(Vector3(12.0, 0, 0))
	if pin_bob:
		pin_bob.apply_central_impulse(Vector3(5.0, 0, 0))
	if cone_bob:
		cone_bob.apply_central_impulse(Vector3(3.0, 0, 3.0))
	if gimbal_body:
		gimbal_body.apply_torque_impulse(Vector3(4.0, 2.0, 1.0))
		gimbal_body.apply_central_impulse(Vector3(2.0, 0, 0))
