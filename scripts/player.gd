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

# Wall movement.
const WALL_SLIDE_SPEED = 30.0
const WALL_STICK_SPEED = 24.0
const WALL_JUMP_VELOCITY = JUMP_VELOCITY
const WALL_JUMP_PUSH = 0.0

# Sword attack.
const ATTACK_DURATION = 0.20
const ATTACK_COOLDOWN = 0.32
const ATTACK_OFFSET = 14.0

var jumps_left := MAX_JUMPS
var air_dashes_left := MAX_AIR_DASHES
var coyote_timer := COYOTE_TIME
var jump_buffer_timer := 0.0
var dash_timer := 0.0
var dash_cooldown_timer := 0.0
var dash_direction := 1.0
var is_wall_sliding := false
var attack_timer := 0.0
var attack_cooldown_timer := 0.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var jump_sound: AudioStreamPlayer2D = $JumpSound
@onready var double_jump_sound: AudioStreamPlayer2D = $DoubleJumpSound
@onready var dash_sound: AudioStreamPlayer2D = $DashSound
@onready var sword: Sprite2D = $Sword
@onready var sword_hitbox: Area2D = $SwordHitbox
@onready var sword_slash: Line2D = $SwordSlash
@onready var sword_sound: AudioStreamPlayer2D = $SwordSound


func _physics_process(delta: float) -> void:
	var on_floor := is_on_floor()
	var direction := Input.get_axis("move_left", "move_right")
	var wall_normal := get_wall_normal()
	var pushing_into_wall := direction != 0.0 and direction * wall_normal.x < 0.0

	# Timers.
	coyote_timer = COYOTE_TIME if on_floor else maxf(coyote_timer - delta, 0.0)
	jump_buffer_timer = maxf(jump_buffer_timer - delta, 0.0)
	dash_timer = maxf(dash_timer - delta, 0.0)
	dash_cooldown_timer = maxf(dash_cooldown_timer - delta, 0.0)
	attack_timer = maxf(attack_timer - delta, 0.0)
	attack_cooldown_timer = maxf(attack_cooldown_timer - delta, 0.0)

	is_wall_sliding = (
		not on_floor
		and is_on_wall()
		and pushing_into_wall
		and velocity.y > 0.0
		and dash_timer <= 0.0
	)

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
		if is_wall_sliding:
			velocity.y = minf(velocity.y, WALL_SLIDE_SPEED)

	# Buffer jump presses so they still work a few frames before landing.
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = JUMP_BUFFER_TIME

	# Jump, wall jump, double jump, or coyote jump.
	if jump_buffer_timer > 0.0:
		if is_wall_sliding:
			_wall_jump(wall_normal)
		elif coyote_timer > 0.0:
			_jump(JUMP_VELOCITY, false)
		elif jumps_left > 0:
			_jump(DOUBLE_JUMP_VELOCITY, true)

	# Release jump early for a shorter hop.
	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= JUMP_CUT_MULTIPLIER

	# Dash.
	if Input.is_action_just_pressed("dash") and dash_cooldown_timer <= 0.0 and dash_timer <= 0.0:
		_start_dash(on_floor)

	# Face the direction of movement before attacking.
	if direction != 0.0:
		animated_sprite.flip_h = direction < 0.0

	# Sword attack.
	if Input.is_action_just_pressed("attack") and attack_cooldown_timer <= 0.0:
		_start_attack()

	if dash_timer > 0.0:
		velocity.x = dash_direction * DASH_SPEED
		velocity.y = 0.0
	elif is_wall_sliding:
		# Stick to the wall and slide down slowly while holding toward it.
		velocity.x = -wall_normal.x * WALL_STICK_SPEED
	else:
		var target_speed := direction * SPEED
		var acceleration := GROUND_ACCELERATION if on_floor else AIR_ACCELERATION
		var friction := GROUND_FRICTION if on_floor else AIR_FRICTION
		if direction != 0.0:
			velocity.x = move_toward(velocity.x, target_speed, acceleration * delta)
		else:
			velocity.x = move_toward(velocity.x, 0.0, friction * delta)

	# Sword swing visual and hit detection.
	if attack_timer > 0.0:
		var attack_progress := 1.0 - attack_timer / ATTACK_DURATION
		sword.rotation = lerpf(-PI / 3.0, PI / 3.0, attack_progress)
		sword_slash.modulate.a = attack_timer / ATTACK_DURATION
		for area in sword_hitbox.get_overlapping_areas():
			_try_hit(area)
	else:
		sword.visible = false
		sword_slash.visible = false
		sword_hitbox.monitoring = false

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


func _wall_jump(wall_normal: Vector2) -> void:
	velocity.x = wall_normal.x * WALL_JUMP_PUSH
	velocity.y = WALL_JUMP_VELOCITY
	jump_buffer_timer = 0.0
	coyote_timer = 0.0
	dash_timer = 0.0
	jumps_left = MAX_JUMPS - 1
	is_wall_sliding = false
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


func _start_attack() -> void:
	attack_timer = ATTACK_DURATION
	attack_cooldown_timer = ATTACK_COOLDOWN

	var facing_left := animated_sprite.flip_h
	var offset := -ATTACK_OFFSET if facing_left else ATTACK_OFFSET
	sword_hitbox.position.x = offset
	sword_slash.position.x = offset
	sword_slash.scale.x = -1.0 if facing_left else 1.0
	sword_slash.visible = true
	sword_slash.modulate.a = 1.0
	sword.position = Vector2(-4.0 if facing_left else 4.0, -12.0)
	sword.scale.x = -1.0 if facing_left else 1.0
	sword.rotation = -PI / 3.0
	sword.visible = true
	sword_hitbox.monitoring = true
	sword_sound.play()


func _try_hit(area: Area2D) -> void:
	var target := area.get_parent()
	if target and target.has_method("take_hit"):
		target.take_hit()


func _on_sword_hitbox_area_entered(area: Area2D) -> void:
	_try_hit(area)


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
