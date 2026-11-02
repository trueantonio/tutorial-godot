extends CharacterBody2D


const SPEED = 130.0
const JUMP_VELOCITY = -300.0
const DOUBLE_JUMP_VELOCITY = -260.0
const MAX_JUMPS = 2

# Quality-of-life timers.
const COYOTE_TIME = 0.10
const JUMP_BUFFER_TIME = 0.12
const JUMP_CUT_MULTIPLIER = 0.45

# Movement.
const GROUND_ACCELERATION = 2000.0
const AIR_ACCELERATION = 1200.0
const GROUND_FRICTION = 2400.0
const AIR_FRICTION = 900.0

# Dash.
const DASH_SPEED = 320.0
const DASH_DURATION = 0.16
const DASH_COOLDOWN = 0.55
const MAX_AIR_DASHES = 1

var jumps_left := MAX_JUMPS
var air_dashes_left := MAX_AIR_DASHES
var coyote_timer := COYOTE_TIME
var jump_buffer_timer := 0.0
var dash_timer := 0.0
var dash_cooldown_timer := 0.0
var dash_direction := 1.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var jump_sound: AudioStreamPlayer2D = $JumpSound
@onready var double_jump_sound: AudioStreamPlayer2D = $DoubleJumpSound
@onready var dash_sound: AudioStreamPlayer2D = $DashSound


func _physics_process(delta: float) -> void:
	var on_floor := is_on_floor()

	# Timers.
	coyote_timer = COYOTE_TIME if on_floor else maxf(coyote_timer - delta, 0.0)
	jump_buffer_timer = maxf(jump_buffer_timer - delta, 0.0)
	dash_timer = maxf(dash_timer - delta, 0.0)
	dash_cooldown_timer = maxf(dash_cooldown_timer - delta, 0.0)

	# Recharge jumps and air dashes when touching the ground.
	if on_floor:
		jumps_left = MAX_JUMPS
		air_dashes_left = MAX_AIR_DASHES
	elif coyote_timer <= 0.0 and jumps_left == MAX_JUMPS:
		# Walking off a ledge uses the first jump.
		jumps_left = MAX_JUMPS - 1

	# Gravity (disabled during a dash so it stays horizontal).
	if not on_floor and dash_timer <= 0.0:
		velocity += get_gravity() * delta

	# Buffer jump presses so they still work a few frames before landing.
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = JUMP_BUFFER_TIME

	# Jump, double jump, or coyote jump.
	if jump_buffer_timer > 0.0:
		if coyote_timer > 0.0:
			_jump(JUMP_VELOCITY, false)
		elif jumps_left > 0:
			_jump(DOUBLE_JUMP_VELOCITY, true)

	# Release jump early for a shorter hop.
	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= JUMP_CUT_MULTIPLIER

	# Dash.
	if Input.is_action_just_pressed("dash") and dash_cooldown_timer <= 0.0 and dash_timer <= 0.0:
		_start_dash(on_floor)

	# Horizontal movement.
	var direction := Input.get_axis("move_left", "move_right")
	if direction != 0.0:
		animated_sprite.flip_h = direction < 0.0

	if dash_timer > 0.0:
		velocity.x = dash_direction * DASH_SPEED
		velocity.y = 0.0
	else:
		var target_speed := direction * SPEED
		var acceleration := GROUND_ACCELERATION if on_floor else AIR_ACCELERATION
		var friction := GROUND_FRICTION if on_floor else AIR_FRICTION
		if direction != 0.0:
			velocity.x = move_toward(velocity.x, target_speed, acceleration * delta)
		else:
			velocity.x = move_toward(velocity.x, 0.0, friction * delta)

	_update_animation(on_floor, direction)
	move_and_slide()


func _jump(jump_velocity: float, is_double_jump: bool) -> void:
	velocity.y = jump_velocity
	jump_buffer_timer = 0.0
	coyote_timer = 0.0
	dash_timer = 0.0
	jumps_left -= 1

	if is_double_jump:
		double_jump_sound.play()
		_flash_sprite()
	else:
		jump_sound.play()


func _start_dash(on_floor: bool) -> void:
	if not on_floor:
		if air_dashes_left <= 0:
			return
		air_dashes_left -= 1

	var direction := Input.get_axis("move_left", "move_right")
	if direction == 0.0:
		direction = -1.0 if animated_sprite.flip_h else 1.0

	dash_direction = signf(direction)
	dash_timer = DASH_DURATION
	dash_cooldown_timer = DASH_COOLDOWN
	dash_sound.play()


func _flash_sprite() -> void:
	animated_sprite.modulate = Color(1.6, 1.6, 2.0)
	var tween := create_tween()
	tween.tween_property(animated_sprite, "modulate", Color.WHITE, 0.18)


func _update_animation(on_floor: bool, direction: float) -> void:
	if not on_floor:
		animated_sprite.play("jump")
	elif absf(velocity.x) > 5.0 or direction != 0.0:
		animated_sprite.play("run")
	else:
		animated_sprite.play("idle")
