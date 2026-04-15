extends "res://scripts/enemy_basic.gd"
# Tank enemy: high HP, slow, hits hard

func _ready() -> void:
	super._ready()
	move_speed = 70.0
	hp = 8
	enemy_type = "tank"
	var sprite = get_node_or_null("Sprite2D")
	if sprite:
		sprite.enemy_type = "tank"
		sprite.size = 20.0
