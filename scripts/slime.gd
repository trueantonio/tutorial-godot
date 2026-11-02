extends Node2D

@export var speed := 60.0
var direction := 1
var is_dead := false

@onready var ray_cast_right: RayCast2D = $RayCastRight
@onready var ray_cast_left: RayCast2D = $RayCastLeft
@onready var ray_cast_floor: RayCast2D = $RayCastFloor
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var death_sound: AudioStreamPlayer2D = get_node_or_null("DeathSound") as AudioStreamPlayer2D


func _process(delta: float) -> void:
	if is_dead:
		return

	if ray_cast_right.is_colliding():
		direction = -1
		animated_sprite.flip_h = true
	if ray_cast_left.is_colliding():
		direction = 1
		animated_sprite.flip_h = false

	ray_cast_floor.position.x = 6.0 * direction
	if not ray_cast_floor.is_colliding():
		direction *= -1
		animated_sprite.flip_h = direction < 0

	position.x += direction * speed * delta


func take_hit() -> void:
	if is_dead:
		return

	is_dead = true
	set_process(false)
	animated_sprite.hide()

	var hurtbox := get_node_or_null("Hurtbox")
	if hurtbox:
		hurtbox.set_deferred("monitorable", false)
	var killzone := get_node_or_null("killzone")
	if killzone:
		killzone.set_deferred("monitoring", false)
	if death_sound:
		death_sound.play()

	await get_tree().create_timer(0.45).timeout
	queue_free()
