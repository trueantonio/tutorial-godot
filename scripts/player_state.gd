class_name PlayerState
extends State

const IDLE = "Idle"
const RUNNING = "Run"
const JUMPING = "Jump"
const FALLING = "Fall"
const DASHING = "Dash"
const WALL_SLIDING = "WallSlide"

@onready var player: Player = owner as Player


func _ready() -> void:
	assert(player != null, "PlayerState must be used inside a Player scene. The owner must be a Player node.")


func get_input_direction() -> float:
	return Input.get_axis("move_left", "move_right")


func is_pushing_into_wall() -> bool:
	var direction := get_input_direction()
	var wall_normal := player.get_wall_normal()
	return direction != 0.0 and direction * wall_normal.x < 0.0


func can_wall_slide() -> bool:
	return (
		not player.is_on_floor()
		and player.is_on_wall()
		and is_pushing_into_wall()
		and player.velocity.y > 0.0
		and player.dash_timer <= 0.0
	)


func get_ground_state() -> String:
	if get_input_direction() != 0.0 or absf(player.velocity.x) > 5.0:
		return RUNNING
	return IDLE


func start_dash_if_requested() -> bool:
	if not Input.is_action_just_pressed("dash"):
		return false

	if player.try_start_dash(player.is_on_floor()):
		finished.emit(DASHING, {})
		return true

	return false


func try_jump() -> bool:
	if player.jump_buffer_timer <= 0.0:
		return false

	if player.coyote_timer > 0.0:
		finished.emit(JUMPING, {"jump_velocity": Player.JUMP_VELOCITY, "is_double": false})
		return true

	if player.jumps_left > 0:
		finished.emit(JUMPING, {"jump_velocity": Player.DOUBLE_JUMP_VELOCITY, "is_double": true})
		return true

	return false


func apply_gravity(delta: float) -> void:
	player.velocity += player.get_gravity() * delta


func apply_air_movement(delta: float) -> void:
	player.apply_horizontal_movement(delta, false)


func apply_ground_movement(delta: float) -> void:
	player.apply_horizontal_movement(delta, true)


func apply_wall_slide_movement(delta: float) -> void:
	player.velocity += player.get_gravity() * delta
	player.velocity.y = minf(player.velocity.y, Player.WALL_SLIDE_SPEED)
	player.velocity.x = -player.get_wall_normal().x * Player.WALL_STICK_SPEED


func apply_jump_cut() -> void:
	player.apply_jump_cut()
