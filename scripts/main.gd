extends Node2D

@onready var glyph_drawer = $GlyphDrawer
@onready var spell_system = $SpellSystem
@onready var player: CharacterBody2D = $Player
@onready var enemies_node: Node2D = $Enemies
@onready var camera: Camera2D = $Player/Camera2D
@onready var hud = $HUD

const ENEMY_BASIC_SCENE := preload("res://scenes/EnemyBasic.tscn")
const ENEMY_FAST_SCENE := preload("res://scenes/EnemyFast.tscn")
const ENEMY_TANK_SCENE := preload("res://scenes/EnemyTank.tscn")
const ENEMY_RANGED_SCENE := preload("res://scenes/EnemyRanged.tscn")

var active_element: String = "fire"
var score: int = 0
var game_over: bool = false

# Wave system
var wave: int = 0
var enemies_remaining_in_wave: int = 0
var wave_timer: float = 0.0
var between_waves: bool = true
var wave_delay: float = 3.0
var spawn_margin: float = 80.0

func _ready() -> void:
	glyph_drawer.glyph_recognized.connect(_on_glyph_recognized)
	spell_system.spell_cast.connect(_on_spell_cast)
	player.health_changed.connect(_on_player_health_changed)
	player.player_died.connect(_on_player_died)
	hud.update_element(active_element)
	hud.update_score(score)
	hud.update_wave(0)
	hud.update_health(player.hp, player.max_hp)
	hud.restart_requested.connect(_on_restart)

	# Start first wave after a short delay
	between_waves = true
	wave_timer = 1.5

func _process(delta: float) -> void:
	if game_over:
		return

	# Wave spawning logic
	if between_waves:
		wave_timer -= delta
		if wave_timer <= 0.0:
			_start_next_wave()
	else:
		# Check if wave is cleared
		var alive_enemies: int = get_tree().get_nodes_in_group("enemies").size()
		if alive_enemies == 0 and enemies_remaining_in_wave <= 0:
			between_waves = true
			wave_timer = wave_delay

func _input(event: InputEvent) -> void:
	if game_over:
		return

	if event.is_action_pressed("switch_fire"):
		active_element = "fire"
		hud.update_element(active_element)
		glyph_drawer.set_element(active_element)
	elif event.is_action_pressed("switch_ice"):
		active_element = "ice"
		hud.update_element(active_element)
		glyph_drawer.set_element(active_element)
	elif event.is_action_pressed("switch_lightning"):
		active_element = "lightning"
		hud.update_element(active_element)
		glyph_drawer.set_element(active_element)

func _on_glyph_recognized(result: Dictionary, points: PackedVector2Array) -> void:
	if game_over:
		return

	var glyph_type: String = result.get("type", "unknown")
	hud.show_glyph_feedback(glyph_type, active_element)
	spell_system.cast_spell(result, active_element, player.global_position, points)

func _on_spell_cast(spell_name: String, element: String) -> void:
	hud.show_spell_name(spell_name, element)
	# Screen shake scales with spell power
	match spell_name:
		"Tap Strike":
			camera.shake(3.0)
		"Burst":
			camera.shake(6.0)
		"Nova":
			camera.shake(10.0)
		"Ring":
			camera.shake(8.0)
		"Triangle Blast":
			camera.shake(7.0)
		"Beam":
			camera.shake(5.0)
		_:
			camera.shake(4.0)

func _on_player_health_changed(current: int, maximum: int) -> void:
	hud.update_health(current, maximum)
	if current < maximum:
		camera.shake(12.0, 4.0)  # Strong shake when hit

func _on_player_died() -> void:
	game_over = true
	Engine.time_scale = 1.0
	hud.show_game_over(score, wave)

func _on_restart() -> void:
	Engine.time_scale = 1.0
	get_tree().reload_current_scene()

func _start_next_wave() -> void:
	wave += 1
	between_waves = false
	hud.update_wave(wave)
	hud.show_wave_banner(wave)

	var enemy_count: int = 2 + wave * 2
	enemies_remaining_in_wave = enemy_count

	for i in range(enemy_count):
		# Stagger spawns slightly
		var timer := get_tree().create_timer(float(i) * 0.4)
		timer.timeout.connect(_spawn_enemy)

func _pick_enemy_scene() -> PackedScene:
	# Wave 1-2: only basic enemies
	# Wave 3+: introduce fast enemies
	# Wave 5+: introduce ranged enemies
	# Wave 7+: introduce tanks
	var roll: float = randf()

	if wave >= 7 and roll < 0.15:
		return ENEMY_TANK_SCENE
	elif wave >= 5 and roll < 0.3:
		return ENEMY_RANGED_SCENE
	elif wave >= 3 and roll < 0.45:
		return ENEMY_FAST_SCENE
	else:
		return ENEMY_BASIC_SCENE

func _spawn_enemy() -> void:
	enemies_remaining_in_wave -= 1
	var enemy = _pick_enemy_scene().instantiate()

	# Spawn outside the viewport
	var viewport_rect: Rect2 = get_viewport().get_visible_rect()
	var cam_pos: Vector2 = player.global_position
	var half_w: float = viewport_rect.size.x * 0.5 + spawn_margin
	var half_h: float = viewport_rect.size.y * 0.5 + spawn_margin

	var side: int = randi() % 4
	var spawn_pos: Vector2
	match side:
		0: spawn_pos = Vector2(cam_pos.x + randf_range(-half_w, half_w), cam_pos.y - half_h) # top
		1: spawn_pos = Vector2(cam_pos.x + randf_range(-half_w, half_w), cam_pos.y + half_h) # bottom
		2: spawn_pos = Vector2(cam_pos.x - half_w, cam_pos.y + randf_range(-half_h, half_h)) # left
		3: spawn_pos = Vector2(cam_pos.x + half_w, cam_pos.y + randf_range(-half_h, half_h)) # right

	enemy.global_position = spawn_pos
	enemy.tree_exiting.connect(_on_enemy_killed.bind(enemy))
	enemies_node.add_child(enemy)

func _on_enemy_killed(enemy: Node) -> void:
	if not game_over and enemy.hp <= 0:
		score += 10
		hud.update_score(score)
