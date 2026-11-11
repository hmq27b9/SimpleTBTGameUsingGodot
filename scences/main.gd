
extends Node2D

@onready var map = $Map
@onready var grid = $Grid
@onready var cursor = $Cursor
@onready var units = $Units
@onready var infantry = $Units/Infantry_1
@onready var enemy = $Units/Enemy_1


func _ready() -> void:
	infantry.setup(Vector2i(5, 5))

	var enemy = $Units/Enemy_Infantry_1
	enemy.setup(Vector2i(12, 5))

	cursor.position = grid.grid_to_world(cursor.grid_position)
