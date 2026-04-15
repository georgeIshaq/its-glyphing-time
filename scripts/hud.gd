extends CanvasLayer

signal restart_requested

@onready var health_bar: ProgressBar = $MarginContainer/VBoxContainer/HealthBar
@onready var element_label: Label = $MarginContainer/VBoxContainer/ElementLabel
@onready var score_label: Label = $TopRight/ScoreLabel
@onready var wave_label: Label = $TopRight/WaveLabel
@onready var glyph_label: Label = $CenterFeedback/GlyphLabel
@onready var spell_label: Label = $CenterFeedback/SpellLabel
@onready var wave_banner: Label = $CenterFeedback/WaveBanner
@onready var game_over_panel: PanelContainer = $GameOverPanel
@onready var game_over_score: Label = $GameOverPanel/VBoxContainer/FinalScoreLabel
@onready var game_over_wave: Label = $GameOverPanel/VBoxContainer/FinalWaveLabel

func _ready() -> void:
	game_over_panel.visible = false
	glyph_label.modulate.a = 0.0
	spell_label.modulate.a = 0.0
	wave_banner.modulate.a = 0.0

func update_health(current: int, maximum: int) -> void:
	health_bar.max_value = maximum
	health_bar.value = current

	# Color shifts as health drops
	var ratio: float = float(current) / float(maximum)
	if ratio > 0.6:
		health_bar.modulate = Color(0.3, 1.0, 0.3)
	elif ratio > 0.3:
		health_bar.modulate = Color(1.0, 0.8, 0.2)
	else:
		health_bar.modulate = Color(1.0, 0.2, 0.2)

func update_element(element: String) -> void:
	var color: Color
	match element:
		"fire":
			color = Color(1.0, 0.45, 0.1)
		"ice":
			color = Color(0.45, 0.85, 1.0)
		"lightning":
			color = Color(1.0, 0.95, 0.3)
		_:
			color = Color.WHITE

	element_label.text = "[%s]" % element.to_upper()
	element_label.add_theme_color_override("font_color", color)

func update_score(value: int) -> void:
	score_label.text = "Score: %d" % value

func update_wave(value: int) -> void:
	if value > 0:
		wave_label.text = "Wave %d" % value
	else:
		wave_label.text = ""

func show_glyph_feedback(glyph_type: String, element: String) -> void:
	glyph_label.text = glyph_type.to_upper()
	_flash_label(glyph_label, _get_element_color(element), 1.0)

func show_spell_name(spell_name: String, element: String) -> void:
	spell_label.text = spell_name
	_flash_label(spell_label, _get_element_color(element), 1.5)

func show_wave_banner(wave_num: int) -> void:
	wave_banner.text = "~ Wave %d ~" % wave_num
	_flash_label(wave_banner, Color(1, 1, 1), 2.0)

func show_game_over(final_score: int, final_wave: int) -> void:
	game_over_panel.visible = true
	game_over_score.text = "Score: %d" % final_score
	game_over_wave.text = "Reached Wave %d" % final_wave

func _flash_label(label: Label, color: Color, duration: float) -> void:
	label.add_theme_color_override("font_color", color)
	label.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_interval(duration * 0.6)
	tween.tween_property(label, "modulate:a", 0.0, duration * 0.4)

func _get_element_color(element: String) -> Color:
	match element:
		"fire": return Color(1.0, 0.45, 0.1)
		"ice": return Color(0.45, 0.85, 1.0)
		"lightning": return Color(1.0, 0.95, 0.3)
		_: return Color.WHITE

func _on_restart_button_pressed() -> void:
	restart_requested.emit()
