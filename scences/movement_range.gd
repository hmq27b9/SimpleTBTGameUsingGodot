
extends Node2D

const TILE_SIZE := 48

var reachable_cells: Dictionary = {}
var attack_cells: Dictionary = {}

@onready var map = get_parent().get_node("Map")
@onready var units = get_parent().get_node("Units")


func calculate_reachable(
	start: Vector2i,
	movement_points: int,
	moving_unit: Node
) -> void:
	reachable_cells.clear()

	var directions: Array[Vector2i] = [
		Vector2i.UP,
		Vector2i.DOWN,
		Vector2i.LEFT,
		Vector2i.RIGHT
	]

	var visited: Dictionary = {}
	var movement_costs: Dictionary = {}

	movement_costs[start] = 0

	while true:
		var current_cell := Vector2i.ZERO
		var current_cost: int = 999999
		var found_cell := false

		# Find the unvisited cell with the lowest movement cost.
		for cell in movement_costs:
			if visited.has(cell):
				continue

			var cost: int = movement_costs[cell]

			if cost < current_cost:
				current_cost = cost
				current_cell = cell
				found_cell = true

		if not found_cell:
			break

		visited[current_cell] = true
		reachable_cells[current_cell] = current_cost

		for direction in directions:
			var next_cell: Vector2i = current_cell + direction

			if not map.is_inside_map(next_cell):
				continue

			if visited.has(next_cell):
				continue

			# Check whether another unit occupies this cell.
			var occupied := false

			for unit in units.get_children():
				if unit == moving_unit:
					continue

				if unit.grid_position == next_cell:
					occupied = true
					break

			if occupied:
				continue

			var terrain_cost: int = map.get_movement_cost(next_cell)

			if terrain_cost >= 999:
				continue

			var new_cost: int = current_cost + terrain_cost

			if new_cost > movement_points:
				continue

			if (
				not movement_costs.has(next_cell)
				or new_cost < movement_costs[next_cell]
			):
				movement_costs[next_cell] = new_cost

	queue_redraw()


func calculate_attack_range(
	center: Vector2i,
	attack_range: int
) -> void:
	attack_cells.clear()

	for x in range(-attack_range, attack_range + 1):
		for y in range(-attack_range, attack_range + 1):

			var distance: int = abs(x) + abs(y)

			if distance == 0 or distance > attack_range:
				continue

			var cell: Vector2i = center + Vector2i(x, y)

			if map.is_inside_map(cell):
				attack_cells[cell] = true

	queue_redraw()


func is_reachable(cell: Vector2i) -> bool:
	return reachable_cells.has(cell)


func is_attackable(cell: Vector2i) -> bool:
	return attack_cells.has(cell)


func clear_range() -> void:
	reachable_cells.clear()
	attack_cells.clear()

	queue_redraw()


func _draw() -> void:
	# Draw blue movement-range tiles.
	for cell in reachable_cells:
		if cell == Vector2i.ZERO:
			continue

		var rect := Rect2(
			cell.x * TILE_SIZE,
			cell.y * TILE_SIZE,
			TILE_SIZE,
			TILE_SIZE
		)

		draw_rect(
			rect,
			Color(0.1, 0.4, 1.0, 0.3),
			true
		)

		draw_rect(
			rect,
			Color(0.2, 0.5, 1.0, 0.8),
			false,
			2.0
		)

	# Draw red attack-range tiles.
	for cell in attack_cells:
		var rect := Rect2(
			cell.x * TILE_SIZE,
			cell.y * TILE_SIZE,
			TILE_SIZE,
			TILE_SIZE
		)

		draw_rect(
			rect,
			Color(1.0, 0.1, 0.1, 0.3),
			true
		)

		draw_rect(
			rect,
			Color(1.0, 0.2, 0.2, 0.8),
			false,
			2.0
		)
