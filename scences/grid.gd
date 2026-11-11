extends Node2D

const TILE_SIZE := 48
const MAP_WIDTH := 20
const MAP_HEIGHT := 15

func grid_to_world(cell: Vector2i) -> Vector2:
	return Vector2(
		cell.x * TILE_SIZE + TILE_SIZE / 2.0,
		cell.y * TILE_SIZE + TILE_SIZE / 2.0
	)


func world_to_grid(world_position: Vector2) -> Vector2i:
	return Vector2i(
		floor(world_position.x / TILE_SIZE),
		floor(world_position.y / TILE_SIZE)
	)


func is_inside_grid(cell: Vector2i) -> bool:
	return (
		cell.x >= 0
		and cell.x < MAP_WIDTH
		and cell.y >= 0
		and cell.y < MAP_HEIGHT
	)


func _draw() -> void:
	for x in range(MAP_WIDTH + 1):
		var start := Vector2(x * TILE_SIZE, 0)
		var end := Vector2(x * TILE_SIZE, MAP_HEIGHT * TILE_SIZE)

		draw_line(start, end, Color(0.15, 0.15, 0.15), 1.0)

	for y in range(MAP_HEIGHT + 1):
		var start := Vector2(0, y * TILE_SIZE)
		var end := Vector2(MAP_WIDTH * TILE_SIZE, y * TILE_SIZE)

		draw_line(start, end, Color(0.15, 0.15, 0.15), 1.0)
