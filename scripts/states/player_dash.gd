extends PlayerState


func enter(_previous_state_path: String, _data := {}) -> void:
	player.velocity.x = player.dash_direction * Player.DASH_SPEED
	player.velocity.y = 0.0
	player.update_locomotion_animation(player.is_on_floor())


func physics_update(delta: float) -> void:
	# Jumping cancels a dash, as it did before.
	if try_jump():
		apply_jump_cut()
		player.move_and_slide()
		return

	player.dash_timer = maxf(player.dash_timer - delta, 0.0)

	if player.dash_timer > 0.0:
		player.velocity.x = player.dash_direction * Player.DASH_SPEED
		player.velocity.y = 0.0
		player.update_locomotion_animation(player.is_on_floor())
		player.move_and_slide()
		return

	# The dash just ended: apply normal movement for this frame and leave.
	if player.is_on_floor():
		apply_ground_movement(delta)
	else:
		apply_gravity(delta)
		apply_air_movement(delta)

	player.update_locomotion_animation(player.is_on_floor())
	player.move_and_slide()

	if player.is_on_floor():
		finished.emit(get_ground_state(), {})
	else:
		finished.emit(FALLING, {})
