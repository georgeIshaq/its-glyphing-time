extends Line2D
# Motion trail behind the player

var max_points: int = 15
var point_spacing: float = 8.0

func _process(_delta: float) -> void:
	var parent: Node2D = get_parent()
	if parent == null:
		return

	var current_pos: Vector2 = parent.global_position

	if get_point_count() == 0 or current_pos.distance_to(get_point_position(0)) >= point_spacing:
		add_point(current_pos, 0)

	while get_point_count() > max_points:
		remove_point(get_point_count() - 1)
