class_name GlyphRecognizer
extends RefCounted

# Resample to this many evenly-spaced points for consistent analysis
const RESAMPLE_COUNT: int = 64
# Minimum angle (degrees) at a point to count as a sharp corner
const CORNER_ANGLE_THRESHOLD: float = 55.0

func recognize(raw_points: PackedVector2Array) -> Dictionary:
	if raw_points.size() < 2:
		var c: Vector2 = raw_points[0] if raw_points.size() > 0 else Vector2.ZERO
		return {"type": "tap", "size": "small", "confidence": 1.0, "center": c}

	# Resample to uniform spacing
	var points: PackedVector2Array = resample(raw_points, RESAMPLE_COUNT)

	var bbox: Rect2 = get_bounding_box(points)
	var size: Vector2 = bbox.size
	var center: Vector2 = bbox.position + size * 0.5
	var diagonal: float = max(size.length(), 1.0)
	var start: Vector2 = points[0]
	var end: Vector2 = points[points.size() - 1]

	var path_length: float = get_path_length(points)
	var start_end_dist: float = start.distance_to(end)
	var closure_ratio: float = start_end_dist / diagonal
	var is_closed: bool = closure_ratio < 0.3
	var straightness: float = start_end_dist / max(path_length, 1.0)
	var compactness: float = path_length / diagonal
	var aspect_ratio: float = max(size.x, size.y) / max(min(size.x, size.y), 1.0)

	# Angular analysis
	var signed_angle: float = get_signed_total_turn(points)
	var total_turn: float = get_total_turn(points)
	var sharp_corners: Array[int] = find_sharp_corners(points)
	var corner_count: int = sharp_corners.size()

	# Radial variance (how circular the shape is)
	var radial_variance: float = get_radial_variance(points, center)
	var mean_radius: float = get_mean_radius(points, center)
	var normalized_variance: float = radial_variance / max(mean_radius, 1.0)

	# Direction consistency for spiral detection (how consistently it turns one way)
	var direction_consistency: float = abs(signed_angle) / max(total_turn, 0.01)

	# --- 1) Tap / dot ---
	if diagonal < 30.0:
		return {
			"type": "tap", "size": "small",
			"confidence": 0.95, "center": center
		}

	# --- 2) Straight line ---
	# High straightness, low total turning
	if not is_closed and straightness > 0.85 and total_turn < 0.8:
		return {
			"type": "line", "size": classify_size(size),
			"confidence": 0.9, "start": start, "end": end
		}

	# Slightly curved but still essentially a line
	if not is_closed and straightness > 0.7 and total_turn < 1.2 and corner_count <= 1:
		return {
			"type": "line", "size": classify_size(size),
			"confidence": 0.8, "start": start, "end": end
		}

	# --- 3) Circle ---
	# Closed shape with low radial variance = circle
	# Use normalized variance so it works at any scale
	if is_closed and normalized_variance < 0.25 and abs(signed_angle) > 4.5:
		return {
			"type": "circle", "size": classify_size(size),
			"confidence": 0.85, "center": center
		}

	# Slightly less perfect circles (more tolerance)
	if is_closed and normalized_variance < 0.35 and corner_count <= 2 and abs(signed_angle) > 4.0:
		return {
			"type": "circle", "size": classify_size(size),
			"confidence": 0.75, "center": center
		}

	# --- 4) Triangle ---
	# Closed shape with exactly 3 sharp corners
	if is_closed and corner_count >= 2 and corner_count <= 4 and normalized_variance > 0.15:
		# Verify the corners form a roughly triangular shape
		# (not just a wobbly circle with some noise corners)
		if _corners_are_well_spaced(sharp_corners, points.size()):
			return {
				"type": "triangle", "size": classify_size(size),
				"confidence": 0.8, "center": center
			}

	# --- 5) Spiral ---
	# Consistent turning in one direction, total turn > full circle
	if abs(signed_angle) > TAU * 0.9 and direction_consistency > 0.7 and compactness > 2.5:
		var tightness: float = compactness
		return {
			"type": "spiral",
			"variant": "tight" if tightness > 5.0 else "loose",
			"size": classify_size(size),
			"confidence": 0.75, "center": center
		}

	# --- 6) Zigzag / Jagged ---
	# Open shape with multiple direction reversals
	var reversals: int = count_direction_reversals(points)
	if not is_closed and reversals >= 2 and corner_count >= 2:
		return {
			"type": "jagged", "size": classify_size(size),
			"confidence": 0.75, "start": start, "end": end
		}

	# Also catch angular open shapes
	if not is_closed and total_turn > 1.5 and corner_count >= 3:
		return {
			"type": "jagged", "size": classify_size(size),
			"confidence": 0.7, "start": start, "end": end
		}

	# --- 7) Scribble fallback ---
	if total_turn > 3.0 or compactness > 3.0:
		return {
			"type": "scribble", "size": classify_size(size),
			"confidence": 0.6, "center": center
		}

	# --- 8) Unknown ---
	return {"type": "unknown", "confidence": 0.2, "center": center}

# ─── Resampling ───

func resample(raw_points: PackedVector2Array, n: int) -> PackedVector2Array:
	var total_len: float = get_path_length(raw_points)

	# Degenerate case: path too short to resample meaningfully
	if total_len < 0.001 or n < 2:
		var result: PackedVector2Array = []
		for i in range(n):
			result.append(raw_points[0])
		return result

	var interval: float = total_len / float(n - 1)
	var result: PackedVector2Array = [raw_points[0]]
	var accumulated: float = 0.0
	var seg_start: Vector2 = raw_points[0]
	var pt_index: int = 1

	while result.size() < n - 1 and pt_index < raw_points.size():
		var seg_end: Vector2 = raw_points[pt_index]
		var seg_len: float = seg_start.distance_to(seg_end)

		if seg_len < 0.001:
			pt_index += 1
			continue

		if accumulated + seg_len >= interval:
			var t: float = (interval - accumulated) / seg_len
			var new_point: Vector2 = seg_start.lerp(seg_end, t)
			result.append(new_point)
			seg_start = new_point  # continue from the inserted point
			accumulated = 0.0
			# Don't advance pt_index -- remaining segment may hold more points
		else:
			accumulated += seg_len
			seg_start = seg_end
			pt_index += 1

	# Ensure exactly n points
	while result.size() < n:
		result.append(raw_points[raw_points.size() - 1])

	return result

# ─── Geometry helpers ───

func get_bounding_box(points: PackedVector2Array) -> Rect2:
	var min_pt: Vector2 = points[0]
	var max_pt: Vector2 = points[0]
	for p in points:
		min_pt.x = min(min_pt.x, p.x)
		min_pt.y = min(min_pt.y, p.y)
		max_pt.x = max(max_pt.x, p.x)
		max_pt.y = max(max_pt.y, p.y)
	return Rect2(min_pt, max_pt - min_pt)

func get_path_length(points: PackedVector2Array) -> float:
	var total: float = 0.0
	for i in range(1, points.size()):
		total += points[i - 1].distance_to(points[i])
	return total

func get_mean_radius(points: PackedVector2Array, center: Vector2) -> float:
	var total: float = 0.0
	for p in points:
		total += p.distance_to(center)
	return total / float(points.size())

func get_radial_variance(points: PackedVector2Array, center: Vector2) -> float:
	var mean_r: float = get_mean_radius(points, center)
	var variance: float = 0.0
	for p in points:
		var diff: float = p.distance_to(center) - mean_r
		variance += diff * diff
	return sqrt(variance / float(points.size()))

# ─── Angular analysis ───

func get_total_turn(points: PackedVector2Array) -> float:
	var total: float = 0.0
	for i in range(1, points.size() - 1):
		var a: Vector2 = (points[i] - points[i - 1]).normalized()
		var b: Vector2 = (points[i + 1] - points[i]).normalized()
		if a.length_squared() < 0.001 or b.length_squared() < 0.001:
			continue
		total += abs(a.angle_to(b))
	return total

func get_signed_total_turn(points: PackedVector2Array) -> float:
	var total: float = 0.0
	for i in range(1, points.size() - 1):
		var a: Vector2 = (points[i] - points[i - 1]).normalized()
		var b: Vector2 = (points[i + 1] - points[i]).normalized()
		if a.length_squared() < 0.001 or b.length_squared() < 0.001:
			continue
		total += a.angle_to(b)
	return total

func find_sharp_corners(points: PackedVector2Array) -> Array[int]:
	# Find points where the angle changes sharply
	# Use a wider window to avoid noise from single-point wobble
	var corners: Array[int] = []
	var window: int = 3  # look 3 points back and forward

	var i: int = window
	while i < points.size() - window:
		var before: Vector2 = (points[i] - points[i - window]).normalized()
		var after: Vector2 = (points[i + window] - points[i]).normalized()
		if before.length_squared() < 0.001 or after.length_squared() < 0.001:
			i += 1
			continue

		var angle_deg: float = abs(rad_to_deg(before.angle_to(after)))
		if angle_deg > CORNER_ANGLE_THRESHOLD:
			corners.append(i)
			i += window  # skip ahead to avoid counting the same corner twice
		else:
			i += 1

	return corners

func count_direction_reversals(points: PackedVector2Array) -> int:
	# Count how many times the turning direction flips (CW <-> CCW)
	var reversals: int = 0
	var prev_sign: float = 0.0

	for i in range(1, points.size() - 1):
		var a: Vector2 = (points[i] - points[i - 1]).normalized()
		var b: Vector2 = (points[i + 1] - points[i]).normalized()
		if a.length_squared() < 0.001 or b.length_squared() < 0.001:
			continue

		var cross: float = a.x * b.y - a.y * b.x
		if abs(cross) < 0.01:
			continue

		var current_sign: float = sign(cross)
		if prev_sign != 0.0 and current_sign != prev_sign:
			reversals += 1
		prev_sign = current_sign

	return reversals

func _corners_are_well_spaced(corner_indices: Array[int], total_points: int) -> bool:
	# Corners should be roughly evenly distributed around the shape
	# (not clustered together from noise)
	if corner_indices.size() < 2:
		return false

	var min_spacing: int = total_points / 8  # at least 1/8 of the shape apart
	for i in range(1, corner_indices.size()):
		if corner_indices[i] - corner_indices[i - 1] < min_spacing:
			return false
	return true

func classify_size(size: Vector2) -> String:
	return "small" if size.length() < 140.0 else "large"
