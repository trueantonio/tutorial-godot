extends PlayerState


func enter(_previous_state_path: String, _data := {}) -> void:
	player.animated_sprite.play("jump")


func physics_update(delta: float) -> void:
	# Wall jump has priority over a dash, just like in the original movement code.
	if can_wall_slide() and player.jump_buffer_timer > 0.0:
		player.perform_wall_jump(player.get_wall_normal())
		apply_jump_cut()
		player.move_and_slide()
		finished.emit(JUMPING, {"preserve_velocity": true})
		return

	# Dashing cancels a wall slide.
	if start_dash_if_requested():
		player.move_and_slide()
		return

	# Stay glued to the wall and slide down slowly while holding toward it.
	if can_wall_slide():
		apply_wall_slide_movement(delta)
		player.move_and_slide()
		finished.emit(WALL_SLIDING, {})
		return

	apply_gravity(delta)
	apply_air_movement(delta)

	if try_jump():
		apply_jump_cut()
		player.move_and_slide()
		return

	apply_jump_cut()
	player.move_and_slide()

	if player.is_on_floor():
		finished.emit(get_ground_state(), {})
	elif can_wall_slide():
		finished.emit(WALL_SLIDING, {})
