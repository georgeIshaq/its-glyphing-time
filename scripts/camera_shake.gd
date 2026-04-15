extends Camera2D

var shake_intensity: float = 0.0
var shake_decay: float = 5.0

func _process(delta: float) -> void:
	if shake_intensity > 0.01:
		offset = Vector2(
			randf_range(-shake_intensity, shake_intensity),
			randf_range(-shake_intensity, shake_intensity)
		)
		shake_intensity = lerp(shake_intensity, 0.0, shake_decay * delta)
	else:
		shake_intensity = 0.0
		offset = Vector2.ZERO

func shake(intensity: float = 8.0, decay: float = 5.0) -> void:
	shake_intensity = max(shake_intensity, intensity)
	shake_decay = decay
