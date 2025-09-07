extends TextureRect

@onready var score_label   = $MarginContainer/HBoxContainer/score_label
@onready var target_label  = $MarginContainer/HBoxContainer/target_label
@onready var counter_label = $MarginContainer/HBoxContainer/counter_label

var current_score: int = 0
var mode: String = "MOVES" 

func _fmt_int(n: int, width: int = 3) -> String:
	return "%0*d" % [width, max(0, n)]

func reset(score := 0) -> void:
	current_score = max(0, score)
	if score_label:
		score_label.text = _fmt_int(current_score, 3)

func set_mode(new_mode: String) -> void:
	mode = new_mode
	if counter_label:
		var ls: LabelSettings = counter_label.label_settings
		if ls:
			if mode == "TIME":
				ls.font_size = 30
			else:
				ls.font_size = 60

func set_target(t: int) -> void:
	if target_label:
		target_label.text = "META: %d" % max(0, t)

func set_score(total: int) -> void:
	current_score = max(0, total)
	if score_label:
		score_label.text = _fmt_int(current_score, 3)

func add_score(points: int) -> void:
	set_score(current_score + max(0, points))

func set_moves(moves: int) -> void:
	if counter_label:
		counter_label.text = _fmt_int(max(0, moves), 2)

func set_time(seconds: int) -> void:
	var s: int = max(0, seconds)
	var mm := int(s / 60)
	var ss := int(s % 60)
	if counter_label:
		counter_label.text = "%02d:%02d" % [mm, ss]
