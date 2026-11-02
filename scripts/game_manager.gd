extends Node

const TOTAL_COINS := 15

var score := 0
var has_won := false

@onready var score_label: Label = $ScoreLabel
@onready var win_label: Label = $UI/WinLabel
@onready var win_sound: AudioStreamPlayer = $WinSound


func add_point() -> void:
	score += 1
	score_label.text = "You collected " + str(score) + " coins."

	if score >= TOTAL_COINS and not has_won:
		has_won = true
		win_label.visible = true
		win_sound.play()
