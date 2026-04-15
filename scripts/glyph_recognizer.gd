class_name GlyphRecognizer
extends RefCounted

func recognize(raw_points: PackedVector2Array) -> Dictionary:
	var points := simplify_points(raw_points)

	if points.size() < 3:
		var fallback_center: Vector2 = points[0] if points.size() > 0 else Vector2.ZERO
		return {
			"type": "tap",
			"size": "small",
			"confidence": 0.3,
			"center": fallback_center
		}

	var bbox := get_bounding_box(points)
	var size := bbox.size
	var center := bbox.position + size * 0.5
	var start_point := points[0]
	var end_point := points[-1]

	var start_end_distance := start_point.distance_to(end_point)
	var diagonal: float = max(size.length(), 1.0)
	var closure_ratio: float = start_end_distance / diagonal

	var path_length: float = get_path_length(points)
	var direct_distance: float = max(start_point.distance_to(end_point), 1.0)
	var winding: float = estimate_total_turn(points)
	var corners: int = estimate_corner_count(points)

	var is_closed: bool = closure_ratio < 0.25
	var aspect_ratio: float = max(size.x, size.y) / max(min(size.x, size.y), 1.0)
	var compactness: float = path_length / max(diagonal, 1.0)

	# 1) Tap / dot
	if bbox.size.length() < 30.0:
		return {
			"type": "tap",
			"size": "small",
			"confidence": 0.95,
			"center": center
		}

	# 2) Triangle-like closed angular shape
	if is_closed and corners >= 3 and corners <= 4:
		return {
			"type": "triangle",
			"size": classify_size(size),
			"confidence": 0.8,
			"center": center
		}

	# 3) Circle / ring
	if is_closed and aspect_ratio < 1.45 and corners <= 4:
		return {
			"type": "circle",
			"size": classify_size(size),
			"confidence": 0.85,
			"center": center
		}
	
	# 4) Straight line
	if not is_closed and winding < 1.2 and compactness < 1.5:
		return {
			"type": "line",
			"size": classify_size(size),
			"confidence": 0.9,
			"start": start_point,
			"end": end_point
		}

	# 5) Zigzag / jagged line
	if not is_closed and winding >= 1.2 and winding < 4.5 and corners >= 3:
		return {
			"type": "jagged",
			"size": classify_size(size),
			"confidence": 0.75,
			"start": start_point,
			"end": end_point
		}

	if not is_closed and winding >= 5.5 and compactness >= 3.2:
		var tightness: float = path_length / max(diagonal, 1.0)
		return {
			"type": "spiral",
			"variant": "tight" if tightness > 5.0 else "loose",
			"size": classify_size(size),
			"confidence": 0.7,
			"center": center
		}
	
	# 7) Scribble fallback
	if winding > 2.0:
		return {
			"type": "scribble",
			"size": classify_size(size),
			"confidence": 0.6,
			"center": center
		}

	return {
		"type": "unknown",
		"confidence": 0.2,
		"center": center
	}

func simplify_points(points: PackedVector2Array) -> PackedVector2Array:
	if points.size() <= 2:
		return points

	var result: PackedVector2Array = []
	result.append(points[0])

	for i in range(1, points.size() - 1):
		if points[i].distance_to(result[-1]) >= 10.0:
			result.append(points[i])

	result.append(points[-1])
	return result

func get_bounding_box(points: PackedVector2Array) -> Rect2:
	var min_x := points[0].x
	var min_y := points[0].y
	var max_x := points[0].x
	var max_y := points[0].y

	for p in points:
		min_x = min(min_x, p.x)
		min_y = min(min_y, p.y)
		max_x = max(max_x, p.x)
		max_y = max(max_y, p.y)

	return Rect2(Vector2(min_x, min_y), Vector2(max_x - min_x, max_y - min_y))

func get_path_length(points: PackedVector2Array) -> float:
	var total := 0.0
	for i in range(1, points.size()):
		total += points[i - 1].distance_to(points[i])
	return total

func estimate_total_turn(points: PackedVector2Array) -> float:
	var total := 0.0
	for i in range(1, points.size() - 1):
		var a := (points[i] - points[i - 1]).normalized()
		var b := (points[i + 1] - points[i]).normalized()
		if a.length() == 0 or b.length() == 0:
			continue
		total += abs(a.angle_to(b))
	return total

func estimate_corner_count(points: PackedVector2Array) -> int:
	var corners := 0
	for i in range(1, points.size() - 1):
		var a := (points[i] - points[i - 1]).normalized()
		var b := (points[i + 1] - points[i]).normalized()
		if a.length() == 0 or b.length() == 0:
			continue
		var angle: float = abs(rad_to_deg(a.angle_to(b)))
		if angle > 40.0:
			corners += 1
	return corners

func classify_size(size: Vector2) -> String:
	return "small" if size.length() < 140.0 else "large"
