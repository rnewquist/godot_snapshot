# module_2d_extended.gd
extends Node2D
class_name Module2DExtended

@onready var tilemap_layer: TileMapLayer = $TileMapLayer
@onready var parallax: Parallax2D = $Parallax2D
@onready var astar_label: Label = $CanvasLayer/UI/AStarResult

var astar: AStarGrid2D
var calculated_path: PackedVector2Array

# Prediction vs Actual tracking
var predictions: Dictionary = {}
var actuals: Dictionary = {}

func _ready() -> void:
	setup_astar_grid()

func setup_astar_grid() -> void:
	astar = AStarGrid2D.new()
	astar.region = Rect2i(0, 0, 10, 10)
	astar.cell_size = Vector2(32, 32)
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar.update()
	
	# Place solid obstacle wall at column x = 5, y from 0 to 7
	for y in range(0, 8):
		astar.set_point_solid(Vector2i(5, y), true)
	
	# PREDICTION:
	# Start at (2, 2), End at (8, 2). Direct linear distance is 6 cells.
	# But solid wall at x=5 from y=0..7 forces path to route around bottom at y=8.
	# Expected Manhattan path length: (5-2) + (8-2) + (8-5) + (8-2) = 3 + 6 + 3 + 6 = 18 steps (19 points).
	predictions["astar_path_length"] = 19
	predictions["astar_routes_around_wall"] = true
	
	# ACTUAL:
	var path_pts: PackedVector2Array = astar.get_point_path(Vector2i(2, 2), Vector2i(8, 2))
	calculated_path = path_pts
	actuals["astar_path_length"] = path_pts.size()
	
	var routed_around: bool = false
	for pt: Vector2 in path_pts:
		if pt.y >= 8.0 * 32.0:
			routed_around = true
	actuals["astar_routes_around_wall"] = routed_around
	
	if astar_label:
		astar_label.text = "AStar2D Grid Path: %d points (Wall Detour: %s)" % [
			actuals["astar_path_length"],
			"YES" if routed_around else "NO"
		]

func _draw() -> void:
	# Draw AStar path in yellow
	if calculated_path.size() > 1:
		for i in range(calculated_path.size() - 1):
			draw_line(calculated_path[i] + Vector2(16, 16), calculated_path[i+1] + Vector2(16, 16), Color(1, 0.9, 0.2), 3.0)
	
	# Draw wall obstacles in red
	for y in range(0, 8):
		draw_rect(Rect2(5 * 32, y * 32, 32, 32), Color(0.9, 0.2, 0.2, 0.7))
