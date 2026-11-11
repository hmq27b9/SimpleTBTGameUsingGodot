
extends Node2D

@onready var grid = $Grid
@onready var cursor = $Cursor
@onready var infantry = $Units/Infantry_1
@onready var enemy = $Units/Enemy_Infantry_1


func _ready() -> void:
	# Player unit starting position.
	infantry.setup(Vector2i(5, 5))

	# Enemy unit starting position.
	enemy.setup(Vector2i(6, 5))

	# Position the cursor.
	cursor.position = grid.grid_to_world(cursor.grid_position)
