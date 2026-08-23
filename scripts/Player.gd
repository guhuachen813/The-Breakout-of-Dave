extends CharacterBody2D

const GameConfig = preload("res://scripts/GameConfig.gd")
const PLAYER_TEXTURE = preload("res://assets/sprites/player_dave_user.png")

var max_hp := GameConfig.PLAYER["max_hp"]
var hp := GameConfig.PLAYER["max_hp"]
var base_speed := GameConfig.PLAYER["speed"]
var speed_multiplier := 1.0
var invincible_left := 0.0
var last_dir := "s"
var bounds := Rect2(Vector2.ZERO, GameConfig.MAP_SIZE)

var sprite: Sprite2D
var camera: Camera2D

func _ready() -> void:
	sprite = Sprite2D.new()
	sprite.texture = PLAYER_TEXTURE
	sprite.scale = Vector2(0.936, 0.936)
	add_child(sprite)
	camera = Camera2D.new()
	camera.zoom = GameConfig.CAMERA_ZOOM
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(GameConfig.MAP_SIZE.x)
	camera.limit_bottom = int(GameConfig.MAP_SIZE.y)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 8.0
	add_child(camera)
	camera.make_current()

func reset_player() -> void:
	global_position = GameConfig.PLAYER_START
	hp = max_hp
	invincible_left = 0.0
	speed_multiplier = 1.0
	last_dir = "s"
	velocity = Vector2.ZERO

func step_player(delta: float, allow_input: bool, scripted_input: Vector2 = Vector2.ZERO) -> void:
	if invincible_left > 0.0:
		invincible_left = max(0.0, invincible_left - delta)
		sprite.modulate = Color(1.0, 0.55, 0.55, 1.0) if int(invincible_left * 12.0) % 2 == 0 else Color.WHITE
	else:
		sprite.modulate = Color.WHITE
	var input_vec := Vector2.ZERO
	if allow_input:
		if scripted_input.length_squared() > 0.001:
			input_vec = scripted_input
		else:
			input_vec.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
			input_vec.y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
		input_vec = input_vec.normalized()
	velocity = input_vec * base_speed * speed_multiplier
	global_position += velocity * delta
	global_position.x = clamp(global_position.x, 80.0, GameConfig.MAP_SIZE.x - 80.0)
	global_position.y = clamp(global_position.y, 80.0, GameConfig.MAP_SIZE.y - 80.0)
	if input_vec.length_squared() > 0.001:
		sprite.flip_h = input_vec.x < 0.0

func can_take_hit() -> bool:
	return invincible_left <= 0.0 and hp > 0.0

func take_damage(amount: float) -> bool:
	if not can_take_hit():
		return false
	hp = max(0.0, hp - amount)
	invincible_left = GameConfig.PLAYER["invincible_time"]
	return true
