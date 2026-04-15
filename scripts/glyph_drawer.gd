extends Node2D

const GlyphRecognizerScript = preload("res://scripts/glyph_recognizer.gd")

signal glyph_recognized(result: Dictionary, points: PackedVector2Array)

@onready var stroke_line: Line2D = $StrokeLine

var is_drawing: bool = false
var points: PackedVector2Array = []

var min_point_distance: float = 8.0
var normal_time_scale: float = 1.0
var draw_time_scale: float = 0.25

# Tap should be tiny in BOTH total size and total travel
var tap_max_bbox_diagonal: float = 22.0
var tap_max_path_length: float = 28.0

var element_color: Color = Color(1.0, 0.45, 0.1)  # default fire

func _ready() -> void:
	stroke_line.clear_points()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			start_drawing(event.position)
		else:
			finish_drawing(event.position)

	elif event is InputEventMouseMotion and is_drawing:
		append_point_if_far_enough(event.position)

func set_element(element: String) -> void:
	match element:
		"fire": element_color = Color(1.0, 0.45, 0.1)
		"ice": element_color = Color(0.45, 0.85, 1.0)
		"lightning": element_color = Color(1.0, 0.95, 0.3)
		_: element_color = Color.WHITE

func start_drawing(start_pos: Vector2) -> void:
	is_drawing = true
	points = PackedVector2Array()
	stroke_line.clear_points()
	stroke_line.default_color = element_color

	Engine.time_scale = draw_time_scale

	points.append(start_pos)
	stroke_line.add_point(start_pos)

func append_point_if_far_enough(pos: Vector2) -> void:
	if points.is_empty():
		points.append(pos)
		stroke_line.add_point(pos)
		return

	if points[points.size() - 1].distance_to(pos) >= min_point_distance:
		points.append(pos)
		stroke_line.add_point(pos)

func finish_drawing(release_pos: Vector2) -> void:
	if not is_drawing:
		return

	is_drawing = false
	Engine.time_scale = normal_time_scale

	if points.is_empty():
		clear_stroke()
		return

	# Ensure release point is included
	if points[points.size() - 1].distance_to(release_pos) > 0.0:
		points.append(release_pos)
		stroke_line.add_point(release_pos)

	var bbox: Rect2 = get_bounding_box(points)
	var bbox_diagonal: float = bbox.size.length()
	var path_length: float = get_path_length(points)

	var result: Dictionary

	# True tap = tiny footprint and tiny total movement
	if bbox_diagonal <= tap_max_bbox_diagonal and path_length <= tap_max_path_length:
		result = {
			"type": "tap",
			"size": "small",
			"confidence": 1.0,
			"center": release_pos
		}
	else:
		var recognizer = GlyphRecognizerScript.new()
		result = recognizer.recognize(points)

	print("drawer bbox_diag:", bbox_diagonal, "path:", path_length, "result:", result)
	glyph_recognized.emit(result, points)
	clear_stroke()

func clear_stroke() -> void:
	points = PackedVector2Array()
	stroke_line.clear_points()

func get_bounding_box(input_points: PackedVector2Array) -> Rect2:
	var min_x: float = input_points[0].x
	var min_y: float = input_points[0].y
	var max_x: float = input_points[0].x
	var max_y: float = input_points[0].y

	for p: Vector2 in input_points:
		min_x = min(min_x, p.x)
		min_y = min(min_y, p.y)
		max_x = max(max_x, p.x)
		max_y = max(max_y, p.y)

	return Rect2(Vector2(min_x, min_y), Vector2(max_x - min_x, max_y - min_y))

func get_path_length(input_points: PackedVector2Array) -> float:
	var total: float = 0.0
	for i in range(1, input_points.size()):
		total += input_points[i - 1].distance_to(input_points[i])
	return total
