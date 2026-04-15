extends Node

const PROJECTILE_SCENE := preload("res://spells/SpellProjectile.tscn")

func cast_spell(glyph: Dictionary, element: String, player_pos: Vector2, points: PackedVector2Array) -> void:
	var glyph_type: String = glyph.get("type", "unknown")
	print("cast_spell:", glyph_type, glyph)

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
			print("Unknown glyph, no spell")

func cast_tap_strike(target: Vector2, element: String) -> void:
	print("tap strike:", target, element)

	var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		print("no player found in group 'player'")
		return

	var dir: Vector2 = target - player.global_position
	if dir.length() < 5.0:
		dir = Vector2.RIGHT

	dir = dir.normalized()

	var projectile = PROJECTILE_SCENE.instantiate()
	projectile.global_position = player.global_position + dir * 20.0
	projectile.direction = dir
	projectile.element = element
	get_tree().current_scene.add_child(projectile)

	print("spawned tap projectile at:", projectile.global_position, "dir:", projectile.direction, "element:", projectile.element)

func cast_burst(target: Vector2, element: String) -> void:
	print("burst:", target, element)

	for i in range(8):
		var angle: float = TAU * float(i) / 8.0
		var dir: Vector2 = Vector2.RIGHT.rotated(angle)

		var projectile = PROJECTILE_SCENE.instantiate()
		projectile.global_position = target
		projectile.direction = dir
		projectile.element = element
		get_tree().current_scene.add_child(projectile)

	print("spawned burst projectiles at:", target, "element:", element)

func cast_ring(glyph: Dictionary, element: String, player_pos: Vector2) -> void:
	var center: Vector2 = glyph.get("center", player_pos)
	var dist_to_player: float = center.distance_to(player_pos)

	if dist_to_player < 100.0:
		print("Protective self ring:", element)
	else:
		print("Area ring:", element, center)

func cast_wall(start: Vector2, end: Vector2, element: String) -> void:
	print("Wall:", element, start, end)

func cast_beam(start: Vector2, end: Vector2, element: String) -> void:
	print("Beam:", element, start, end)

func cast_homing_projectile(target_hint: Vector2, element: String) -> void:
	print("Homing projectile:", element, target_hint)

func cast_nova(center: Vector2, element: String) -> void:
	print("Nova:", element, center)

func cast_triangle_blast(points: PackedVector2Array, element: String) -> void:
	print("Triangle blast:", element, points.size())

func cast_scatter(center: Vector2, element: String) -> void:
	print("Scatter:", element, center)
