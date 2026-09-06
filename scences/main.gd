extends Node2D

@onready var map = $Map
@onready var grid = $Grid
@onready var cursor = $Cursor

func _ready() -> void:
	cursor.position = grid.grid_to_world(cursor.grid_position)
