extends Node

var game_mode: String = "MOVES" ##por defecto es el de movimieintos
var target_score: int = 1000
var starting_moves: int = 20
var starting_time: int = 90

func set_moves_mode(target: int, moves: int) -> void:
	game_mode = "MOVES"
	target_score = max(0, target)
	starting_moves = max(1, moves)

func set_time_mode(target: int, seconds: int) -> void:
	game_mode = "TIME"
	target_score = max(0, target)
	starting_time = max(1, seconds)
