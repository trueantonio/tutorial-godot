extends PlayerState


func enter(_previous_state_path: String, _data := {}) -> void:
	player.animated_sprite.play("jump")


func physics_update(delta: float) -> void:
	if player.is_on_floor():
		apply_ground_movement(delta)
		player.move_and_slide()
		finished.emit(get_ground_state(), {})
		return

	# Released the wall: go back to normal air movement this same frame.
	if not can_wall_slide():
		apply_gravity(delta)
		apply_air_movement(delta)
		player.move_and_slide()
		finished.emit(FALLING, {})
		return

	if player.jump_buffer_timer > 0.0:
		player.perform_wall_jump(player.get_wall_normal())
		apply_jump_cut()
		player.move_and_slide()
		finished.emit(JUMPING, {"preserve_velocity": true})
		return

	if start_dash_if_requested():
		player.move_and_slide()
		return

	apply_wall_slide_movement(delta)
	player.move_and_slide()

	if player.is_on_floor():
		finished.emit(get_ground_state(), {})
