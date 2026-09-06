extends Node2D

const TILE_SIZE := 48
const MAP_WIDTH := 20
const MAP_HEIGHT := 15

var grid_position := Vector2i(0, 0)

@onready var map = get_parent().get_node("Map")


func _ready() -> void:
	position = grid_to_world(grid_position)
	queue_redraw()


func _process(_delta: float) -> void:
	var movement := Vector2i.ZERO

	if Input.is_action_just_pressed("ui_right"):
		movement.x += 1

	if Input.is_action_just_pressed("ui_left"):
		movement.x -= 1

	if Input.is_action_just_pressed("ui_down"):
		movement.y += 1

	if Input.is_action_just_pressed("ui_up"):
		movement.y -= 1

	if movement != Vector2i.ZERO:
		var new_position := grid_position + movement

		if is_inside_grid(new_position):
			grid_position = new_position
			position = grid_to_world(grid_position)

			print_terrain_info()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var cell := world_to_grid(get_global_mouse_position())

			if is_inside_grid(cell):
				grid_position = cell
				position = grid_to_world(grid_position)

				print_terrain_info()


func grid_to_world(cell: Vector2i) -> Vector2:
	return Vector2(
		cell.x * TILE_SIZE + TILE_SIZE / 2.0,
		cell.y * TILE_SIZE + TILE_SIZE / 2.0
	)


func world_to_grid(pos: Vector2) -> Vector2i:
	return Vector2i(
		floor(pos.x / TILE_SIZE),
		floor(pos.y / TILE_SIZE)
	)


func is_inside_grid(cell: Vector2i) -> bool:
	return (
		cell.x >= 0
		and cell.x < MAP_WIDTH
		and cell.y >= 0
		and cell.y < MAP_HEIGHT
	)


func print_terrain_info() -> void:
	var data: Dictionary = map.get_terrain_data(grid_position)

	print(
		"Tile: ",
		grid_position,
		" | Terrain: ",
		data["name"],
		" | Movement: ",
		data["movement_cost"],
		" | Defense: +",
		data["defense"]
	)


func _draw() -> void:
	var half := TILE_SIZE / 2.0

	# Top-left
	draw_line(
		Vector2(-half, -half),
		Vector2(-half + 12, -half),
		Color.WHITE,
		3
	)

	draw_line(
		Vector2(-half, -half),
		Vector2(-half, -half + 12),
		Color.WHITE,
		3
	)

	# Top-right
	draw_line(
		Vector2(half, -half),
		Vector2(half - 12, -half),
		Color.WHITE,
		3
	)

	draw_line(
		Vector2(half, -half),
		Vector2(half, -half + 12),
		Color.WHITE,
		3
	)

	# Bottom-left
	draw_line(
		Vector2(-half, half),
		Vector2(-half + 12, half),
		Color.WHITE,
		3
	)

	draw_line(
		Vector2(-half, half),
		Vector2(-half, half - 12),
		Color.WHITE,
		3
	)

	# Bottom-right
	draw_line(
		Vector2(half, half),
		Vector2(half - 12, half),
		Color.WHITE,
		3
	)

	draw_line(
		Vector2(half, half),
		Vector2(half, half - 12),
		Color.WHITE,
		3
	)
