
extends Node2D

const TILE_SIZE := 48
const MAP_WIDTH := 20
const MAP_HEIGHT := 15

var grid_position := Vector2i(0, 0)
var selected_unit = null
var command_locked := false

@onready var map = get_parent().get_node("Map")
@onready var units = get_parent().get_node("Units")
@onready var movement_range = get_parent().get_node("MovementRange")
@onready var turn_manager = get_parent().get_node("TurnManager")


func _ready() -> void:
	position = grid_to_world(grid_position)
	queue_redraw()


func _process(_delta: float) -> void:
	if command_locked or not turn_manager.is_player_turn():
		return

	var movement := Vector2i.ZERO

	# Right
	if Input.is_action_just_pressed("ui_right") or Input.is_action_just_pressed("move_right"):
		movement.x += 1

	# Left
	if Input.is_action_just_pressed("ui_left") or Input.is_action_just_pressed("move_left"):
		movement.x -= 1

	# Down
	if Input.is_action_just_pressed("ui_down") or Input.is_action_just_pressed("move_down"):
		movement.y += 1

	# Up
	if Input.is_action_just_pressed("ui_up") or Input.is_action_just_pressed("move_up"):
		movement.y -= 1

	# Move cursor
	if movement != Vector2i.ZERO:
		var new_position: Vector2i = grid_position + movement

		if is_inside_grid(new_position):
			grid_position = new_position
			position = grid_to_world(grid_position)

	# End player turn with Enter
	if Input.is_action_just_pressed("end_turn"):
		cancel_selection()
		turn_manager.end_player_turn()
		return

	# Select with Z
	if Input.is_action_just_pressed("select"):
		select_current_tile()

	# Cancel with X
	if Input.is_action_just_pressed("cancel"):
		cancel_selection()


func _unhandled_input(event: InputEvent) -> void:
	if command_locked or not turn_manager.is_player_turn():
		return

	if event is InputEventMouseButton and event.pressed:

		# Left mouse button: Select
		if event.button_index == MOUSE_BUTTON_LEFT:
			var cell := world_to_grid(get_global_mouse_position())

			if is_inside_grid(cell):
				grid_position = cell
				position = grid_to_world(grid_position)
				select_current_tile()

		# Right mouse button: Cancel
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			cancel_selection()


func select_current_tile() -> void:
	if command_locked or not turn_manager.is_player_turn():
		return

	# A unit is already selected: attempt to move it.
	if selected_unit != null:

		if grid_position == selected_unit.grid_position:
			return

		if movement_range.is_reachable(grid_position):
			var destination: Vector2i = grid_position
			var moving_unit = selected_unit

			command_locked = true
			movement_range.clear_range()

			print(moving_unit.unit_name, " moving to ", destination)

			await moving_unit.move_to_cell(destination)

			moving_unit.deselect()
			selected_unit = null

			print(moving_unit.unit_name, " has finished moving.")

			command_locked = false
			return

		print("Destination is not reachable.")
		return

	# No unit selected: check the current tile.
	var unit = get_unit_at(grid_position)

	if unit != null:

		if unit.team != 0:
			print("You cannot control enemy units.")
			return

		if unit.has_acted:
			print(unit.unit_name, " has already acted this turn.")
			return

		deselect_all_units()

		selected_unit = unit
		unit.select()

		movement_range.calculate_reachable(
			unit.grid_position,
			unit.movement,
			unit
		)

	else:
		print_terrain_info()


func cancel_selection() -> void:
	if command_locked:
		return

	deselect_all_units()

	selected_unit = null
	movement_range.clear_range()

	print("Selection cancelled.")


func get_unit_at(cell: Vector2i):
	for unit in units.get_children():
		if unit.grid_position == cell:
			return unit

	return null


func deselect_all_units() -> void:
	for unit in units.get_children():
		unit.deselect()


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
	var half := TILE_SIZE / 2.0
	var corner := 12.0

	# Top-left
	draw_line(Vector2(-half, -half), Vector2(-half + corner, -half), Color.WHITE, 3)
	draw_line(Vector2(-half, -half), Vector2(-half, -half + corner), Color.WHITE, 3)

	# Top-right
	draw_line(Vector2(half, -half), Vector2(half - corner, -half), Color.WHITE, 3)
	draw_line(Vector2(half, -half), Vector2(half, -half + corner), Color.WHITE, 3)

	# Bottom-left
	draw_line(Vector2(-half, half), Vector2(-half + corner, half), Color.WHITE, 3)
	draw_line(Vector2(-half, half), Vector2(-half, half - corner), Color.WHITE, 3)

	# Bottom-right
	draw_line(Vector2(half, half), Vector2(half - corner, half), Color.WHITE, 3)
	draw_line(Vector2(half, half), Vector2(half, half - corner), Color.WHITE, 3)
