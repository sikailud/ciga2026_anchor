extends Node

signal score_changed(new_score: int)

var score: int = 0:
	set(value):
		score = value
		score_changed.emit(score)

func increase(amount: int) -> void:
	score += amount

func decrease(amount: int) -> void:
	score -= amount
