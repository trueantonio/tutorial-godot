extends PlayerState


func enter(_previous_state_path: String, data := {}) -> void:
	player.animated_sprite.play("jump")

	# The wall-slide state applies the wall-jump velocity itself and asks us
	# to preserve it, so we don't overwrite it here.
	if data.get("preserve_velocity", false):
		return

	player.perform_jump(
		data.get("jump_velocity", Player.JUMP_VELOCITY),
		data.get("is_double", false)
	)


func physics_update(delta: float) -> void:
	apply_gravity(delta)
	apply_air_movement(delta)

	# A second jump press while airborne performs a double jump.
	if try_jump():
		apply_jump_cut()
		player.move_and_slide()
		return

	apply_jump_cut()

	if start_dash_if_requested():
		player.move_and_slide()
		return

	player.move_and_slide()

	if player.is_on_floor():
		finished.emit(get_ground_state(), {})
	elif player.velocity.y >= 0.0:
		finished.emit(FALLING, {})
