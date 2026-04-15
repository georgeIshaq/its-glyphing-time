extends Node

const PROJECTILE_SCENE := preload("res://spells/SpellProjectile.tscn")

signal spell_cast(spell_name: String, element: String)

func cast_spell(glyph: Dictionary, element: String, player_pos: Vector2, points: PackedVector2Array) -> void:
	var glyph_type: String = glyph.get("type", "unknown")

	match glyph_type:
		"tap":
			cast_tap_strike(glyph.get("center", player_pos), element)
		"circle":
			if glyph.get("size") == "small":
				cast_burst(glyph.get("center", player_pos), element)
			else:
				cast_ring(glyph, element, player_pos)
		"line":
			cast_wall(glyph.get("start", player_pos), glyph.get("end", player_pos), element)
		"jagged":
			cast_beam(glyph.get("start", player_pos), glyph.get("end", player_pos), element)
		"spiral":
			if glyph.get("variant") == "tight":
				cast_homing_projectile(glyph.get("center", player_pos), element)
			else:
				cast_nova(glyph.get("center", player_pos), element)
		"triangle":
			cast_triangle_blast(points, element)
		"scribble":
			cast_scatter(glyph.get("center", player_pos), element)
		_:
			pass

func get_element_color(element: String) -> Color:
	match element:
		"fire": return Color(1.0, 0.45, 0.1)
		"ice": return Color(0.45, 0.85, 1.0)
		"lightning": return Color(1.0, 0.95, 0.3)
		_: return Color.WHITE

# --- Tap Strike: single fast projectile toward cursor ---
func cast_tap_strike(target: Vector2, element: String) -> void:
	var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return

	var dir: Vector2 = (target - player.global_position)
	if dir.length() < 5.0:
		dir = Vector2.RIGHT
	dir = dir.normalized()

	var projectile = PROJECTILE_SCENE.instantiate()
	projectile.global_position = player.global_position + dir * 20.0
	projectile.direction = dir
	projectile.speed = 600.0
	projectile.element = element
	projectile.damage = 1
	get_tree().current_scene.add_child(projectile)
	spell_cast.emit("Tap Strike", element)

# --- Burst: 8 projectiles radiating outward from center ---
func cast_burst(center: Vector2, element: String) -> void:
	for i in range(8):
		var angle: float = TAU * float(i) / 8.0
		var dir: Vector2 = Vector2.RIGHT.rotated(angle)

		var projectile = PROJECTILE_SCENE.instantiate()
		projectile.global_position = center
		projectile.direction = dir
		projectile.speed = 400.0
		projectile.element = element
		projectile.damage = 1
		get_tree().current_scene.add_child(projectile)
	spell_cast.emit("Burst", element)

# --- Ring: expanding damage ring from center ---
func cast_ring(glyph: Dictionary, element: String, player_pos: Vector2) -> void:
	var center: Vector2 = glyph.get("center", player_pos)
	var ring_count: int = 16
	var ring_radius: float = 30.0

	for i in range(ring_count):
		var angle: float = TAU * float(i) / float(ring_count)
		var dir: Vector2 = Vector2.RIGHT.rotated(angle)

		var projectile = PROJECTILE_SCENE.instantiate()
		projectile.global_position = center + dir * ring_radius
		projectile.direction = dir
		projectile.speed = 250.0
		projectile.element = element
		projectile.damage = 2
		projectile.lifetime = 0.8
		get_tree().current_scene.add_child(projectile)
	spell_cast.emit("Ring", element)

# --- Wall: line of stationary damaging projectiles ---
func cast_wall(start: Vector2, end: Vector2, element: String) -> void:
	var wall_dir: Vector2 = (end - start)
	var wall_length: float = wall_dir.length()
	var segment_count: int = max(int(wall_length / 30.0), 3)
	var step: Vector2 = wall_dir / float(segment_count)

	for i in range(segment_count + 1):
		var pos: Vector2 = start + step * float(i)
		var projectile = PROJECTILE_SCENE.instantiate()
		projectile.global_position = pos
		projectile.direction = Vector2.ZERO
		projectile.speed = 0.0
		projectile.element = element
		projectile.damage = 1
		projectile.lifetime = 3.0
		projectile.pierce = true
		get_tree().current_scene.add_child(projectile)
	spell_cast.emit("Wall", element)

# --- Beam: rapid-fire chain of projectiles along the drawn path ---
func cast_beam(start: Vector2, end: Vector2, element: String) -> void:
	var dir: Vector2 = (end - start).normalized()
	var beam_length: float = start.distance_to(end)
	var projectile_count: int = max(int(beam_length / 25.0), 5)

	for i in range(projectile_count):
		var t: float = float(i) / float(projectile_count)
		var pos: Vector2 = start.lerp(end, t)
		var spread: Vector2 = Vector2(randf_range(-8.0, 8.0), randf_range(-8.0, 8.0))

		var projectile = PROJECTILE_SCENE.instantiate()
		projectile.global_position = pos + spread
		projectile.direction = dir
		projectile.speed = 700.0
		projectile.element = element
		projectile.damage = 1
		projectile.lifetime = 0.6
		get_tree().current_scene.add_child(projectile)
	spell_cast.emit("Beam", element)

# --- Homing Projectile: seeks nearest enemy ---
func cast_homing_projectile(target_hint: Vector2, element: String) -> void:
	var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return

	var dir: Vector2 = (target_hint - player.global_position).normalized()
	if dir.length() < 0.1:
		dir = Vector2.RIGHT

	var projectile = PROJECTILE_SCENE.instantiate()
	projectile.global_position = player.global_position + dir * 20.0
	projectile.direction = dir
	projectile.speed = 350.0
	projectile.element = element
	projectile.damage = 3
	projectile.lifetime = 3.0
	projectile.homing = true
	projectile.homing_strength = 4.0
	get_tree().current_scene.add_child(projectile)
	spell_cast.emit("Homing Bolt", element)

# --- Nova: massive burst of projectiles in all directions ---
func cast_nova(center: Vector2, element: String) -> void:
	var nova_count: int = 24

	for i in range(nova_count):
		var angle: float = TAU * float(i) / float(nova_count)
		var dir: Vector2 = Vector2.RIGHT.rotated(angle)

		var projectile = PROJECTILE_SCENE.instantiate()
		projectile.global_position = center
		projectile.direction = dir
		projectile.speed = 350.0
		projectile.element = element
		projectile.damage = 2
		projectile.lifetime = 1.2
		get_tree().current_scene.add_child(projectile)
	spell_cast.emit("Nova", element)

# --- Triangle Blast: fires projectiles from each vertex toward opposite center ---
func cast_triangle_blast(points: PackedVector2Array, element: String) -> void:
	if points.size() < 3:
		return

	# Find the 3 most extreme points as triangle vertices
	var vertices: Array[Vector2] = _find_triangle_vertices(points)
	var tri_center: Vector2 = (vertices[0] + vertices[1] + vertices[2]) / 3.0

	for vertex in vertices:
		var dir: Vector2 = (tri_center - vertex).normalized()
		# Fire a spread of 3 projectiles from each vertex
		for j in range(3):
			var spread_angle: float = deg_to_rad((j - 1) * 12.0)
			var spread_dir: Vector2 = dir.rotated(spread_angle)

			var projectile = PROJECTILE_SCENE.instantiate()
			projectile.global_position = vertex
			projectile.direction = spread_dir
			projectile.speed = 500.0
			projectile.element = element
			projectile.damage = 2
			projectile.lifetime = 1.0
			get_tree().current_scene.add_child(projectile)
	spell_cast.emit("Triangle Blast", element)

# --- Scatter: chaotic spray of projectiles ---
func cast_scatter(center: Vector2, element: String) -> void:
	var scatter_count: int = 12

	for i in range(scatter_count):
		var angle: float = randf() * TAU
		var dir: Vector2 = Vector2.RIGHT.rotated(angle)

		var projectile = PROJECTILE_SCENE.instantiate()
		projectile.global_position = center + Vector2(randf_range(-20, 20), randf_range(-20, 20))
		projectile.direction = dir
		projectile.speed = randf_range(300.0, 600.0)
		projectile.element = element
		projectile.damage = 1
		projectile.lifetime = randf_range(0.5, 1.2)
		get_tree().current_scene.add_child(projectile)
	spell_cast.emit("Scatter", element)

func _find_triangle_vertices(points: PackedVector2Array) -> Array[Vector2]:
	if points.size() <= 3:
		var result: Array[Vector2] = []
		for p in points:
			result.append(p)
		while result.size() < 3:
			result.append(result[0] + Vector2(10, 0))
		return result

	# Use first, last, and the point farthest from the line between them
	var a: Vector2 = points[0]
	var b: Vector2 = points[points.size() - 1]
	var ab: Vector2 = b - a
	var ab_len: float = max(ab.length(), 1.0)

	var max_dist: float = 0.0
	var c: Vector2 = (a + b) * 0.5

	for p in points:
		var ap: Vector2 = p - a
		var cross: float = abs(ab.x * ap.y - ab.y * ap.x) / ab_len
		if cross > max_dist:
			max_dist = cross
			c = p

	var result: Array[Vector2] = [a, b, c]
	return result
