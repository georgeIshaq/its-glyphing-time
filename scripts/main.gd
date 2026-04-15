extends Node2D

@onready var glyph_drawer = $GlyphDrawer
@onready var recognized_label: Label = $UI/RecognizedLabel
@onready var element_label: Label = $UI/ElementLabel
@onready var spell_system = $SpellSystem
@onready var player: Node2D = $Player

var active_element: String = "fire"

func _ready() -> void:
	glyph_drawer.glyph_recognized.connect(_on_glyph_recognized)
	update_element_label()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("switch_fire"):
		print("fire pressed")
		active_element = "fire"
		update_element_label()
	elif event.is_action_pressed("switch_ice"):
		print("ice pressed")
		active_element = "ice"
		update_element_label()
	elif event.is_action_pressed("switch_lightning"):
		print("lightning pressed")
		active_element = "lightning"
		update_element_label()

func _on_glyph_recognized(result: Dictionary, points: PackedVector2Array) -> void:
	print("recognized:", result)

	recognized_label.text = "Glyph: %s %s %s (%.2f)" % [
		result.get("type", "unknown"),
		str(result.get("size", "")),
		str(result.get("variant", "")),
		result.get("confidence", 0.0)
	]
	recognized_label.modulate = Color(1, 1, 0.4, 1)

	var tween = create_tween()
	tween.tween_property(recognized_label, "modulate", Color(1, 1, 1, 1), 0.2)

	spell_system.cast_spell(result, active_element, player.global_position, points)

func update_element_label() -> void:
	element_label.text = "Element: %s" % active_element
