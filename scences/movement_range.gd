
extends Node2D

const TILE_SIZE := 48

var reachable_cells: Dictionary = {}

@onready var map = get_parent().get_node("Map")
@onready var units = get_parent().get_node("Units")


func calculate_reachable(start: Vector2i, movement_points: int, moving_unit: Node) -> void:
	clear_range()

	var frontier: Array[Vector2i] = [start]
	var visited: Dictionary = {}

	reachable_cells[start] = 0

	var directions := [
		Vector2i(0, -1),
		Vector2i(0, 1),
		Vector2i(-1, 0),
		Vector2i(1, 0)
	]

	while not frontier.is_empty():
		# Find the cell with the lowest movement cost.
		var best_index := 0

		for i in range(1, frontier.size()):
			if reachable_cells[frontier[i]] < reachable_cells[frontier[best_index]]:
				best_index = i

		var current: Vector2i = frontier.pop_at(best_index)

		if visited.has(current):
			continue

		visited[current] = true

		var current_cost: int = reachable_cells[current]

		for direction in directions:
			var next_cell: Vector2i = current + direction

			if not map.is_inside_map(next_cell):
				continue

			if is_cell_blocked(next_cell, moving_unit):
				continue

			var terrain_cost: int = map.get_movement_cost(next_cell)

			# Water and other extremely expensive terrain are impassable.
			if terrain_cost >= 999:
				continue

			var total_cost := current_cost + terrain_cost

			if total_cost > movement_points:
				continue

			if reachable_cells.has(next_cell):
				if total_cost >= reachable_cells[next_cell]:
					continue

			reachable_cells[next_cell] = total_cost
			frontier.append(next_cell)

	queue_redraw()


func is_cell_blocked(cell: Vector2i, moving_unit: Node) -> bool:
	for unit in units.get_children():
		if unit != moving_unit and unit.grid_position == cell:
			return true

	return false


func is_reachable(cell: Vector2i) -> bool:
	return reachable_cells.has(cell)


func clear_range() -> void:
	reachable_cells.clear()
	queue_redraw()


func _draw() -> void:
	for cell in reachable_cells:
		# Don't highlight the unit's starting position.
		if reachable_cells[cell] == 0:
			continue

		var rect := Rect2(
			cell.x * TILE_SIZE,
			cell.y * TILE_SIZE,
			TILE_SIZE,
			TILE_SIZE
		)

		draw_rect(
			rect,
			Color(0.1, 0.45, 1.0, 0.35)
		)

		draw_rect(
			rect,
			Color(0.3, 0.65, 1.0, 0.9),
			false,
			2.0
		)
