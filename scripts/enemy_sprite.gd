extends Node2D
# Draws enemies as distinct geometric shapes based on enemy type

@export var enemy_type: String = "basic"
@export var size: float = 14.0

var base_color: Color = Color(1.0, 0.3, 0.3)
var pulse_time: float = 0.0

func _process(delta: float) -> void:
	pulse_time += delta * 3.0
	queue_redraw()

func _draw() -> void:
	var pulse: float = 0.9 + sin(pulse_time) * 0.1
	var s: float = size * pulse

	match enemy_type:
		"basic":
			_draw_basic(s)
		"fast":
			_draw_fast(s)
		"tank":
			_draw_tank(s)
		"ranged":
			_draw_ranged(s)
		_:
			_draw_basic(s)

func _draw_basic(s: float) -> void:
	# Pentagon - standard grunt
	base_color = Color(1.0, 0.3, 0.3)
	var points: PackedVector2Array = _make_polygon(5, s)
	draw_colored_polygon(points, base_color)
	draw_colored_polygon(_make_polygon(5, s * 0.5), Color(0.6, 0.1, 0.1))

func _draw_fast(s: float) -> void:
	# Thin triangle - fast enemy
	base_color = Color(1.0, 0.7, 0.2)
	var points := PackedVector2Array([
		Vector2(s, 0),
		Vector2(-s * 0.7, -s * 0.4),
		Vector2(-s * 0.7, s * 0.4),
	])
	draw_colored_polygon(points, base_color)
	var inner := PackedVector2Array([
		Vector2(s * 0.5, 0),
		Vector2(-s * 0.3, -s * 0.2),
		Vector2(-s * 0.3, s * 0.2),
	])
	draw_colored_polygon(inner, Color(0.6, 0.4, 0.1))

func _draw_tank(s: float) -> void:
	# Hexagon - tanky enemy
	base_color = Color(0.6, 0.2, 0.8)
	var points: PackedVector2Array = _make_polygon(6, s * 1.2)
	draw_colored_polygon(points, base_color)
	draw_colored_polygon(_make_polygon(6, s * 0.7), Color(0.3, 0.1, 0.5))
	draw_colored_polygon(_make_polygon(6, s * 0.3), Color(0.8, 0.4, 1.0))

func _draw_ranged(s: float) -> void:
	# Square with gap - ranged enemy
	base_color = Color(0.3, 0.9, 0.4)
	var points: PackedVector2Array = _make_polygon(4, s)
	draw_colored_polygon(points, base_color)
	# "Eye" in center
	draw_circle(Vector2.ZERO, s * 0.35, Color(0.1, 0.4, 0.15))
	draw_circle(Vector2.ZERO, s * 0.15, Color(1, 1, 0.5))

func _make_polygon(sides: int, radius: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(sides):
		var angle: float = TAU * float(i) / float(sides) - PI / 2.0
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return points
