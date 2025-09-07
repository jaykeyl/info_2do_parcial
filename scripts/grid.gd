extends Node2D

# configurations
enum { WAIT, MOVE }
var state

@export var width: int
@export var height: int
@export var x_start: int
@export var y_start: int
@export var offset: int
@export var y_offset: int

#score y modos de juego
@export_enum("MOVES", "TIME")
var game_mode: String = "MOVES"
var game_ended: bool = false  

@export var target_score: int = 1000
@export var starting_moves: int = 20
@export var starting_time: int = 60

@export var points_per_piece: int = 10
@export var combo_bonus: float = 0.25
func calculate_dynamic_target() -> int:
	var movements := starting_moves
	var time_seconds := starting_time
	var ppp := points_per_piece

	#valores aleatrios
	var avg_matches_per_turn := randi_range(3, 5)
	var cascade_factor := randf_range(1.1, 1.4)
	var difficulty_factor := randf_range(0.9, 1.2)

	var result := 0

	if game_mode == "MOVES":
		result = int(movements * avg_matches_per_turn * ppp * cascade_factor * difficulty_factor)
	elif game_mode == "TIME":
		var avg_time_per_turn := 3.0 
		var turns := float(time_seconds) / avg_time_per_turn
		result = int(turns * avg_matches_per_turn * ppp * cascade_factor * difficulty_factor)

	return max(10, result)


var current_score: int = 0
var moves_left: int = 0
var time_left: int = 0

var cascade_depth: int = 0
var consumed_move: bool = false

func _ui():
	return get_parent().get_node_or_null("top_ui")

func _msg_label():
	return get_parent().get_node_or_null("msg_label")

func _update_ui() -> void:
	var ui = _ui()
	if ui == null: return
	if ui.has_method("set_score"):
		ui.set_score(current_score)
	if game_mode == "MOVES":
		if ui.has_method("set_moves"): ui.set_moves(moves_left)
	else:
		if ui.has_method("set_time"): ui.set_time(time_left)

func _begin_run_after_successful_swap() -> void:
	if not consumed_move:
		consumed_move = true
		if game_mode == "MOVES":
			moves_left = max(0, moves_left - 1)
			_update_ui()
		print("[Moves] Successful move consumed. Remaining:", moves_left)

func _maybe_finish_run() -> void:
	consumed_move = false
	cascade_depth = 0
	if game_mode == "MOVES" and moves_left <= 0:
		if current_score >= target_score:
			game_won()
		else:
			game_over()


var possible_pieces = [
	preload("res://scenes/blue_piece.tscn"),
	preload("res://scenes/green_piece.tscn"),
	preload("res://scenes/light_green_piece.tscn"),
	preload("res://scenes/pink_piece.tscn"),
	preload("res://scenes/yellow_piece.tscn"),
	preload("res://scenes/orange_piece.tscn"),
]

var all_pieces = []

var piece_one = null
var piece_two = null
var last_place = Vector2.ZERO
var last_direction = Vector2.ZERO
var move_checked = false

var first_touch = Vector2.ZERO
var final_touch = Vector2.ZERO
var is_controlling = false

# lifecycle
func _ready():
	state = MOVE
	randomize()
	all_pieces = make_2d_array()

	#autoload !!
	game_mode      = GameConfig.game_mode
	starting_moves = GameConfig.starting_moves
	starting_time  = GameConfig.starting_time
	points_per_piece = points_per_piece

	target_score = calculate_dynamic_target()

	spawn_pieces()

	current_score = 0
	moves_left = starting_moves
	time_left = starting_time
	_update_ui()

	var ui = _ui()
	if ui and ui.has_method("set_mode"): ui.set_mode(game_mode)
	if ui and ui.has_method("set_target"): ui.set_target(target_score)

	#timer
	if game_mode == "TIME":
		var t: Timer = get_parent().get_node_or_null("game_timer")
		if t:
			time_left = starting_time
			t.start()
			_update_ui()

func _process(_delta):
	if state == MOVE:
		touch_input()

func make_2d_array():
	var array = []
	for i in width:
		array.append([])
		for j in height:
			array[i].append(null)
	return array

func grid_to_pixel(column, row):
	var new_x = x_start + offset * column
	var new_y = y_start - offset * row
	return Vector2(new_x, new_y)

func pixel_to_grid(px, py):
	var new_x = round((px - x_start) / offset)
	var new_y = round((py - y_start) / -offset)
	return Vector2(new_x, new_y)

func in_grid(column, row):
	return column >= 0 and column < width and row >= 0 and row < height

func _get_piece(i: int, j: int):
	if i < 0 or i >= width or j < 0 or j >= height:
		return null
	return all_pieces[i][j]

func _set_piece(i: int, j: int, p):
	all_pieces[i][j] = p

func spawn_pieces():
	for i in width:
		for j in height:
			var rand = randi_range(0, possible_pieces.size() - 1)
			var piece = possible_pieces[rand].instantiate()

			var max_loops = 100
			var loops = 0
			while (match_at(i, j, piece.color) and loops < max_loops):
				rand = randi_range(0, possible_pieces.size() - 1)
				loops += 1
				piece = possible_pieces[rand].instantiate()

			add_child(piece)
			piece.position = grid_to_pixel(i, j)
			all_pieces[i][j] = piece

func match_at(i, j, color):
	if i > 1:
		if all_pieces[i - 1][j] != null and all_pieces[i - 2][j] != null:
			if all_pieces[i - 1][j].color == color and all_pieces[i - 2][j].color == color:
				return true
	if j > 1:
		if all_pieces[i][j - 1] != null and all_pieces[i][j - 2] != null:
			if all_pieces[i][j - 1].color == color and all_pieces[i][j - 2].color == color:
				return true
	return false

func collapse_columns():
	for i in width:
		for j in height:
			if all_pieces[i][j] == null:
				for k in range(j + 1, height):
					if all_pieces[i][k] != null:
						all_pieces[i][k].move(grid_to_pixel(i, j))
						all_pieces[i][j] = all_pieces[i][k]
						all_pieces[i][k] = null
						break
	get_parent().get_node("refill_timer").start()

func refill_columns():
	for i in width:
		for j in height:
			if all_pieces[i][j] == null:
				var rand = randi_range(0, possible_pieces.size() - 1)
				var piece = possible_pieces[rand].instantiate()

				var max_loops = 100
				var loops = 0
				while (match_at(i, j, piece.color) and loops < max_loops):
					rand = randi_range(0, possible_pieces.size() - 1)
					loops += 1
					piece = possible_pieces[rand].instantiate()

				add_child(piece)
				piece.position = grid_to_pixel(i, j - y_offset)
				piece.move(grid_to_pixel(i, j))
				all_pieces[i][j] = piece
	check_after_refill()

func check_after_refill():
	for i in width:
		for j in height:
			if all_pieces[i][j] != null and match_at(i, j, all_pieces[i][j].color):
				cascade_depth += 1
				find_matches()
				get_parent().get_node("destroy_timer").start()
				return
	state = MOVE
	move_checked = false
	_maybe_finish_run()


# input and swap
func touch_input():
	var mouse_pos = get_global_mouse_position()
	var grid_pos = pixel_to_grid(mouse_pos.x, mouse_pos.y)
	if Input.is_action_just_pressed("ui_touch") and in_grid(grid_pos.x, grid_pos.y):
		first_touch = grid_pos
		is_controlling = true

	if Input.is_action_just_released("ui_touch") and in_grid(grid_pos.x, grid_pos.y) and is_controlling:
		is_controlling = false
		final_touch = grid_pos
		touch_difference(first_touch, final_touch)

func touch_difference(grid_1, grid_2):
	var difference = grid_2 - grid_1
	if abs(difference.x) > abs(difference.y):
		if difference.x > 0:
			swap_pieces(grid_1.x, grid_1.y, Vector2(1, 0))
		elif difference.x < 0:
			swap_pieces(grid_1.x, grid_1.y, Vector2(-1, 0))
	if abs(difference.y) > abs(difference.x):
		if difference.y > 0:
			swap_pieces(grid_1.x, grid_1.y, Vector2(0, 1))
		elif difference.y < 0:
			swap_pieces(grid_1.x, grid_1.y, Vector2(0, -1))

func swap_pieces(column, row, direction: Vector2):
	var first_piece = _get_piece(column, row)
	var other_piece = _get_piece(column + direction.x, row + direction.y)
	if first_piece == null or other_piece == null:
		return

	# raindow activation
	var first_is_rainbow := _is_rainbow(first_piece)
	var other_is_rainbow := _is_rainbow(other_piece)

	state = WAIT
	store_info(first_piece, other_piece, Vector2(column, row), direction)
	_set_piece(column, row, other_piece)
	_set_piece(column + direction.x, row + direction.y, first_piece)
	first_piece.move(grid_to_pixel(column + direction.x, row + direction.y))
	other_piece.move(grid_to_pixel(column, row))

	# Rainbow x Rainbow = clear all
	if first_is_rainbow and other_is_rainbow:
		_mark_all_pieces()
		first_piece.matched = true
		other_piece.matched = true
		get_parent().get_node("destroy_timer").start()
		return

	# Rainbow + Color = clear that color
	if first_is_rainbow or other_is_rainbow:
		var target_color: String = other_piece.color if first_is_rainbow else first_piece.color
		_mark_all_of_color(target_color)
		first_piece.matched = true
		other_piece.matched = true
		get_parent().get_node("destroy_timer").start()
		return

	# Normal flow
	if not move_checked:
		find_matches()

func store_info(first_piece, other_piece, place, direction):
	piece_one = first_piece
	piece_two = other_piece
	last_place = place
	last_direction = direction

func swap_back():
	if piece_one != null and piece_two != null:
		swap_pieces(last_place.x, last_place.y, last_direction)
	state = MOVE
	move_checked = false


# scanning for matches (3/4/5 and T)
func find_matches():
	var horiz_runs: Array = []
	var vert_runs: Array = []

	# collect horizontal runs
	for j in height:
		var i := 0
		while i < width:
			var p = _get_piece(i, j)
			if p == null:
				i += 1
				continue
			var color = p.color
			var run: Array = []
			var k := i
			while k < width:
				var pk = _get_piece(k, j)
				if pk != null and pk.color == color:
					run.append(Vector2i(k, j))
					k += 1
				else:
					break
			if run.size() >= 3:
				horiz_runs.append({"coords": run, "orient": "H"})
			i = k if run.size() >= 3 else i + 1

	# collect vertical runs
	for i in width:
		var j := 0
		while j < height:
			var p2 = _get_piece(i, j)
			if p2 == null:
				j += 1
				continue
			var color2 = p2.color
			var run2: Array = []
			var t := j
			while t < height:
				var pt = _get_piece(i, t)
				if pt != null and pt.color == color2:
					run2.append(Vector2i(i, t))
					t += 1
				else:
					break
			if run2.size() >= 3:
				vert_runs.append({"coords": run2, "orient": "V"})
			j = t if run2.size() >= 3 else j + 1

	# merge intersecting runs (T, crosses)
	var groups: Array = []
	groups.append_array(horiz_runs)
	groups.append_array(vert_runs)

	var merged := true
	while merged:
		merged = false
		for a_idx in range(groups.size()):
			if merged: break
			for b_idx in range(a_idx + 1, groups.size()):
				var A = groups[a_idx]
				var B = groups[b_idx]
				var intersects := false
				for ca in A.coords:
					for cb in B.coords:
						if ca == cb:
							intersects = true
							break
					if intersects: break
				if intersects:
					var set := {}
					for v in A.coords: set[str(v)] = v
					for v in B.coords: set[str(v)] = v
					var union_coords: Array = []
					for k in set.keys(): union_coords.append(set[k])
					groups[a_idx] = { "coords": union_coords, "orient": (A.orient + B.orient) }
					groups.remove_at(b_idx)
					merged = true
					break

	# process groups
	for g in groups:
		var coords: Array = g.coords
		var n := coords.size()
		if n < 3:
			continue

		if n == 4 and (g.orient == "H" or g.orient == "V"):
			var promote_idx := _choose_promotion_index(coords)
			for idx in range(n):
				var pos: Vector2i = coords[idx]
				var piece = _get_piece(pos.x, pos.y)
				if piece == null: continue
				if idx == promote_idx:
					_promote_to_striped(piece, g.orient == "H")
					piece.matched = false
				else:
					piece.matched = true
					if piece.has_method("dim"): piece.dim()
		elif n >= 5:
			_promote_group_to_rainbow(coords)
		else:
			for pos3 in coords:
				var p3 = _get_piece(pos3.x, pos3.y)
				if p3:
					p3.matched = true
					if p3.has_method("dim"): p3.dim()

	get_parent().get_node("destroy_timer").start()

# promoting pieces: makinf=g them striped or rainbow
func _promote_to_striped(piece: Piece, is_horizontal: bool) -> void:
	if piece == null:
		return
	if is_horizontal:
		piece.set_row_special()
	else:
		piece.set_column_special()
	piece.matched = false
	var spr: Sprite2D = piece.get_node_or_null("Sprite2D")
	if spr: spr.modulate = Color(1, 1, 1, 1)
	print("Promoted piece color=%s to %s special" % [piece.color, ("ROW" if is_horizontal else "COLUMN")])

func _promote_group_to_rainbow(coords: Array) -> void:
	var promote_idx := _choose_promotion_index(coords)
	var pos: Vector2i = coords[promote_idx]
	var promote_piece = _get_piece(pos.x, pos.y)
	if promote_piece and promote_piece.has_method("set_rainbow_special"):
		promote_piece.set_rainbow_special()
		promote_piece.matched = false
		var spr: Sprite2D = promote_piece.get_node_or_null("Sprite2D")
		if spr: spr.modulate = Color(1,1,1,1)
	else:
		print("WARN: rainbow could not be set at ", pos)

	for idx in range(coords.size()):
		if idx == promote_idx: continue
		var p = _get_piece(coords[idx].x, coords[idx].y)
		if p:
			p.matched = true
			if p.has_method("dim"): p.dim()

func _choose_promotion_index(run_coords: Array) -> int:
	var a := Vector2i(int(last_place.x), int(last_place.y))
	var b := Vector2i(int(last_place.x + last_direction.x), int(last_place.y + last_direction.y))
	for idx in range(run_coords.size()):
		var c: Vector2i = run_coords[idx]
		if c == a or c == b:
			return idx
	return min(1, run_coords.size() - 1)


# destroy and expansions
func destroy_matched():
	_expand_rainbow_clears()
	_expand_line_clears_for_striped()

	var was_matched := false
	var destroyed := 0
	for i in width:
		for j in height:
			var p = _get_piece(i, j)
			if p != null and p.matched:
				was_matched = true
				destroyed += 1
				p.queue_free()
				_set_piece(i, j, null)

	move_checked = true

	if was_matched:
		_begin_run_after_successful_swap()

		var multiplier := 1.0 + float(cascade_depth) * combo_bonus
		var gained := int(round(float(destroyed * points_per_piece) * multiplier))
		current_score += gained
		_update_ui()
		print("[Score] +%d (destroyed=%d, cascade=%d, x%.2f) total=%d"
			% [gained, destroyed, cascade_depth, multiplier, current_score])

		get_parent().get_node("collapse_timer").start()
	else:
		swap_back()

func _expand_rainbow_clears() -> void:
	var rainbow_positions: Array[Vector2i] = []
	var matched_colors := {}

	for i in width:
		for j in height:
			var p = _get_piece(i, j)
			if p == null or not p.matched:
				continue
			if "special" in p and p.special == p.Special.RAINBOW:
				rainbow_positions.append(Vector2i(i, j))
			else:
				if "color" in p:
					matched_colors[p.color] = true

	if rainbow_positions.size() == 0:
		return

	if rainbow_positions.size() >= 2:
		_mark_all_pieces()
		return

	if matched_colors.size() == 0:
		return
	for i in width:
		for j in height:
			var p2 = _get_piece(i, j)
			if p2 != null and "color" in p2 and matched_colors.has(p2.color):
				p2.matched = true
				if p2.has_method("dim"): p2.dim()

func _expand_line_clears_for_striped() -> void:
	var rows_to_clear: Array[int] = []
	var cols_to_clear: Array[int] = []

	for i in width:
		for j in height:
			var p = _get_piece(i, j)
			if p != null and p.matched:
				if "special" in p:
					if p.special == 1:
						if not rows_to_clear.has(j):
							rows_to_clear.append(j)
					elif p.special == 2:
						if not cols_to_clear.has(i):
							cols_to_clear.append(i)

	for row in rows_to_clear:
		_mark_row_for_clear(row)
	for col in cols_to_clear:
		_mark_col_for_clear(col)

func _mark_row_for_clear(row: int) -> void:
	for c in range(width):
		var p = _get_piece(c, row)
		if p != null:
			p.matched = true
			if p.has_method("dim"): p.dim()

func _mark_col_for_clear(col: int) -> void:
	for r in range(height):
		var p = _get_piece(col, r)
		if p != null:
			p.matched = true
			if p.has_method("dim"): p.dim()


# rainbow helpers
func _is_rainbow(p) -> bool:
	return p != null and "special" in p and p.special == p.Special.RAINBOW

func _mark_all_of_color(color: String) -> void:
	if color == "" or color == null:
		return
	print("RAINBOW: clearing color -> ", color)
	for i in width:
		for j in height:
			var q = _get_piece(i, j)
			if q != null and "color" in q and q.color == color:
				q.matched = true
				if q.has_method("dim"): q.dim()

func _mark_all_pieces() -> void:
	print("RAINBOW x RAINBOW: clearing entire board")
	for i in width:
		for j in height:
			var q = _get_piece(i, j)
			if q != null:
				q.matched = true
				if q.has_method("dim"): q.dim()


# timers
func _on_destroy_timer_timeout():
	destroy_matched()

func _on_collapse_timer_timeout():
	collapse_columns()

func _on_refill_timer_timeout():
	refill_columns()

func _on_game_timer_timeout() -> void:
	if game_mode != "TIME": return
	if state == WAIT and not consumed_move:
		pass
	time_left = max(0, time_left - 1)
	_update_ui()
	if time_left <= 0:
		if current_score >= target_score:
			game_won()
		else:
			game_over()

func game_won() -> void:
	if game_ended: return
	game_ended = true
	state = WAIT
	var msg = _msg_label()
	if msg:
		msg.visible = true
		msg.text = " GANASTE !!:D"
	print("GANASTE !! :D")
	get_tree().paused = true

func game_over() -> void:
	if game_ended: return
	game_ended = true
	state = WAIT
	var msg = _msg_label()
	if msg:
		msg.visible = true
		msg.text = "PERDISTE XD"
	print("PERDISTE ):")
	get_tree().paused = true
