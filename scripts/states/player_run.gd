extends PlayerState


func enter(_previous_state_path: String, _data := {}) -> void:
	player.animated_sprite.play("run")


func physics_update(delta: float) -> void:
	apply_ground_movement(delta)

	if try_jump():
		apply_jump_cut()
		player.move_and_slide()
		return

	if start_dash_if_requested():
		player.move_and_slide()
		return

	player.move_and_slide()

	if not player.is_on_floor():
		finished.emit(FALLING, {})
	elif get_input_direction() == 0.0 and absf(player.velocity.x) <= 5.0:
		finished.emit(IDLE, {})
