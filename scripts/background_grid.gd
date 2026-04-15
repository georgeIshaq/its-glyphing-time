extends Node2D
# Draws an infinite scrolling grid for spatial reference

var grid_size: float = 64.0
var grid_color: Color = Color(0.15, 0.18, 0.25, 0.5)
var grid_color_major: Color = Color(0.2, 0.24, 0.32, 0.6)

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	var camera: Camera2D = get_viewport().get_camera_2d()
	if camera == null:
		return

	var cam_pos: Vector2 = camera.global_position
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var half_w: float = viewport_size.x * 0.5 + grid_size
	var half_h: float = viewport_size.y * 0.5 + grid_size

	var start_x: float = snappedf(cam_pos.x - half_w, grid_size)
	var end_x: float = cam_pos.x + half_w
	var start_y: float = snappedf(cam_pos.y - half_h, grid_size)
	var end_y: float = cam_pos.y + half_h

	var x: float = start_x
	while x <= end_x:
		var is_major: bool = fmod(abs(x), grid_size * 4.0) < 1.0
		var color: Color = grid_color_major if is_major else grid_color
		draw_line(Vector2(x, start_y), Vector2(x, end_y), color, 1.0)
		x += grid_size

	var y: float = start_y
	while y <= end_y:
		var is_major: bool = fmod(abs(y), grid_size * 4.0) < 1.0
		var color: Color = grid_color_major if is_major else grid_color
		draw_line(Vector2(start_x, y), Vector2(end_x, y), color, 1.0)
		y += grid_size
