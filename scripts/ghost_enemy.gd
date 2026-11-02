extends Node2D

@export var speed := 70.0
@export var roam_rect := Rect2(-224, -288, 1376, 528)
@export var retarget_min_time := 2.0
@export var retarget_max_time := 4.5
@export var bob_height := 2.0
@export var bob_speed := 3.0

var target_position := Vector2.ZERO
var retarget_timer := 0.0
var bob_time := 0.0
var rng := RandomNumberGenerator.new()

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	rng.randomize()
	_update_roam_rect_from_tilemap()
	target_position = _pick_random_point()
	retarget_timer = rng.randf_range(retarget_min_time, retarget_max_time)


func _process(delta: float) -> void:
	retarget_timer -= delta
	if retarget_timer <= 0.0 or global_position.distance_to(target_position) < 12.0:
		target_position = _pick_random_point()
		retarget_timer = rng.randf_range(retarget_min_time, retarget_max_time)

	var to_target := target_position - global_position
	if to_target.length_squared() > 0.01:
		global_position = global_position.move_toward(target_position, speed * delta)
		if absf(to_target.x) > 0.5:
			animated_sprite.flip_h = to_target.x > 0.0

	# Gentle floating motion so it reads as a ghost.
	bob_time += delta
	animated_sprite.position.y = -12.0 + sin(bob_time * bob_speed) * bob_height


func _update_roam_rect_from_tilemap() -> void:
	var tile_map := get_parent().get_node_or_null("TileMap") as TileMap
	if tile_map == null or tile_map.tile_set == null:
		return

	var used := tile_map.get_used_rect()
	var tile_size := tile_map.tile_set.tile_size
	var world_rect := Rect2(
		tile_map.global_position + Vector2(used.position) * Vector2(tile_size),
		Vector2(used.size) * Vector2(tile_size)
	)
	roam_rect = world_rect.grow(-8.0)


func _pick_random_point() -> Vector2:
	var point := Vector2.ZERO
	for _i in 8:
		point = Vector2(
			rng.randf_range(roam_rect.position.x, roam_rect.end.x),
			rng.randf_range(roam_rect.position.y, roam_rect.end.y)
		)
		if point.distance_to(global_position) > 48.0:
			return point
	return point
