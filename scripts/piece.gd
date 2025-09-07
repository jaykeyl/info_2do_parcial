extends Node2D
class_name Piece

# configurations
@export_enum("Blue", "Green", "Light Green", "Orange", "Pink", "Yellow")
var color: String = "Blue"

var matched: bool = false

enum Special { NONE, ROW, COLUMN, RAINBOW }
var special: int = Special.NONE

@onready var sprite: Sprite2D = $Sprite2D

const TEX := {
	"Row": {
		"Blue": "res://assets/pieces/Blue Row.png",
		"Green": "res://assets/pieces/Green Row.png",
		"Light Green": "res://assets/pieces/Light Green Row.png",
		"Orange": "res://assets/pieces/Orange Row.png",
		"Pink": "res://assets/pieces/Pink Row.png",
		"Yellow": "res://assets/pieces/Yellow Row.png",
	},
	"Column": {
		"Blue": "res://assets/pieces/Blue Column.png",
		"Green": "res://assets/pieces/Green Column.png",
		"Light Green": "res://assets/pieces/Light Green Column.png",
		"Orange": "res://assets/pieces/Orange Column.png",
		"Pink": "res://assets/pieces/Pink Column.png",
		"Yellow": "res://assets/pieces/Yellow Column.png",
	},
	"Normal": {
		"Blue": "res://assets/pieces/Blue Piece.png",
		"Green": "res://assets/pieces/Green Piece.png",
		"Light Green": "res://assets/pieces/Light Green Piece.png",
		"Orange": "res://assets/pieces/Orange Piece.png",
		"Pink": "res://assets/pieces/Pink Piece.png",
		"Yellow": "res://assets/pieces/Yellow Piece.png",
	},
}

#lyfecycle
func _ready() -> void:
	if sprite == null:
		push_error("[Piece] Missing Sprite2D child.")
	set_normal()

# if there are 4 we change assets
func move(target: Vector2) -> void:
	var tw = create_tween()
	tw.set_trans(Tween.TRANS_ELASTIC)
	tw.set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "position", target, 0.4)

func dim() -> void:
	if sprite:
		sprite.modulate = Color(1, 1, 1, 0.5)

func set_normal() -> void:
	special = Special.NONE
	_set_sprite(_tex_path("Normal"))
	_restore_alpha()

func set_row_special() -> void:
	special = Special.ROW
	_set_sprite(_tex_path("Row"))
	_restore_alpha()
	print("[Piece] ROW special set for color=", color)

func set_column_special() -> void:
	special = Special.COLUMN
	_set_sprite(_tex_path("Column"))
	_restore_alpha()
	print("[Piece] COLUMN special set for color=", color)

func set_rainbow_special() -> void:
	special = Special.RAINBOW
	_set_sprite("res://assets/pieces/Rainbow.png")
	_restore_alpha()
	print("[Piece] RAINBOW special set")

# helpers 
func _restore_alpha() -> void:
	if sprite:
		sprite.modulate = Color(1, 1, 1, 1)

func _canon_color() -> String:
	var c := color.strip_edges()
	match c.to_lower():
		"blue":
			return "Blue"
		"green":
			return "Green"
		"light green", "light_green", "lightgreen":
			return "Light Green"
		"orange":
			return "Orange"
		"pink":
			return "Pink"
		"yellow":
			return "Yellow"
		_:
			return c

func _tex_path(kind: String) -> String:
	var canon := _canon_color()
	if not TEX.has(kind) or not TEX[kind].has(canon):
		push_error("[Piece] Missing TEX for %s/%s" % [kind, canon])
		return ""
	return TEX[kind][canon]

func _set_sprite(path: String) -> void:
	if path == "":
		return
	var tex := load(path)
	if tex == null:
		push_error("[Piece] Texture not found at %s" % path)
		return
	if sprite:
		sprite.texture = tex
