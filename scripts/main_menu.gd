extends Control

const GAME_SCENE_PATH := "res://scenes/game.tscn"

const TEX_BG  := preload("res://assets/background.png")
const TEX_BTN := preload("res://assets/bottom_ui.png")

@export var default_target_score: int = 1000
@export var default_moves: int = 20
@export var default_time: int = 90

@onready var bg: TextureRect = $background
@onready var btn_moves: TextureButton = $start_moves_btn
@onready var btn_time:  TextureButton = $start_time_btn

func _ready() -> void:
	if bg:
		bg.texture = TEX_BG
		bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_skin_button(btn_moves, "JUGAR POR MOVIMIENTOS")
	_skin_button(btn_time,  "JUGAR POR TIEMPO")

	btn_moves.pressed.connect(_on_start_moves)
	btn_time.pressed.connect(_on_start_time)

func _skin_button(b: TextureButton, text: String) -> void:
	if b == null: return
	b.texture_normal  = TEX_BTN
	b.texture_hover   = TEX_BTN
	b.texture_pressed = TEX_BTN
	b.stretch_mode = TextureButton.STRETCH_SCALE

	var lbl: Label = b.get_node_or_null("Label")
	if lbl == null:
		lbl = Label.new()
		lbl.name = "Label"
		b.add_child(lbl)
	lbl.anchor_left = 0; lbl.anchor_top = 0; lbl.anchor_right = 1; lbl.anchor_bottom = 1
	lbl.offset_left = 0; lbl.offset_top = 0; lbl.offset_right = 0; lbl.offset_bottom = 0
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	lbl.text = text


func _on_start_moves() -> void:
	GameConfig.set_moves_mode(default_target_score, default_moves)
	get_tree().change_scene_to_file(GAME_SCENE_PATH)

func _on_start_time() -> void:
	GameConfig.set_time_mode(default_target_score, default_time)
	get_tree().change_scene_to_file(GAME_SCENE_PATH)
