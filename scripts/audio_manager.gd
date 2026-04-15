extends Node

# Preloaded sound effects
var sounds: Dictionary = {}

func _ready() -> void:
	sounds = {
		"spell_fire": preload("res://audio/spell_fire.wav"),
		"spell_ice": preload("res://audio/spell_ice.wav"),
		"spell_lightning": preload("res://audio/spell_lightning.wav"),
		"enemy_hit": preload("res://audio/enemy_hit.wav"),
		"enemy_death": preload("res://audio/enemy_death.wav"),
		"player_damage": preload("res://audio/player_damage.wav"),
		"health_pickup": preload("res://audio/health_pickup.wav"),
		"wave_start": preload("res://audio/wave_start.wav"),
		"combo": preload("res://audio/combo.wav"),
		"glyph_draw": preload("res://audio/glyph_draw.wav"),
	}

func play(sound_name: String, volume_db: float = 0.0) -> void:
	if not sounds.has(sound_name):
		return
	var player := AudioStreamPlayer.new()
	player.stream = sounds[sound_name]
	player.volume_db = volume_db
	add_child(player)
	player.play()
	player.finished.connect(player.queue_free)

func play_spell(element: String) -> void:
	match element:
		"fire": play("spell_fire")
		"ice": play("spell_ice")
		"lightning": play("spell_lightning")
		_: play("spell_fire")
