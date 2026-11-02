extends Area2D

var collected := false

@onready var game_manager: Node = %GameManager
@onready var animation_player: AnimationPlayer = $AnimationPlayer


func _on_body_entered(body: Node2D) -> void:
	if collected:
		return

	collected = true
	set_deferred("monitoring", false)
	game_manager.add_point()
	animation_player.play("pickup_animation")
