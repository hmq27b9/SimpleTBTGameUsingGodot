
extends Node2D

const TILE_SIZE := 48
const MAP_WIDTH := 20
const MAP_HEIGHT := 15

var grid_position := Vector2i.ZERO
var selected_unit: Node = null
var command_locked := false

@onready var map = get_parent().get_node("Map")
@onready var grid = get_parent().get_node("Grid")
@onready var units = get_parent().get_node("Units")
@onready var movement_range = get_parent().get_node("MovementRange")
@onready var turn_manager = get_parent().get_node("TurnManager")


func _ready() -> void:
	position = grid.grid_to_world(grid_position)


func _process(_delta: float) -> void:
	if command_locked:
		return

	if not turn_manager.is_player_turn():
		return

	var direction := Vector2i.ZERO

	if (
		Input.is_action_just_pressed("move_up")
		or Input.is_action_just_pressed("ui_up")
	):
		direction = Vector2i.UP

	elif (
		Input.is_action_just_pressed("move_down")
		or Input.is_action_just_pressed("ui_down")
	):
		direction = Vector2i.DOWN

	elif (
		Input.is_action_just_pressed("move_left")
		or Input.is_action_just_pressed("ui_left")
	):
		direction = Vector2i.LEFT

	elif (
		Input.is_action_just_pressed("move_right")
		or Input.is_action_just_pressed("ui_right")
	):
		direction = Vector2i.RIGHT

	if direction != Vector2i.ZERO:
		move_cursor(direction)

	if Input.is_action_just_pressed("select"):
		await select_current_tile()

	if Input.is_action_just_pressed("cancel"):
		cancel_selection()

	if Input.is_action_just_pressed("end_turn"):
		if selected_unit != null:
			cancel_selection()

		turn_manager.end_player_turn()


func _unhandled_input(event: InputEvent) -> void:
	if command_locked:
		return

	if not turn_manager.is_player_turn():
		return

	if event is InputEventMouseButton:
		if not event.pressed:
			return

		if event.button_index == MOUSE_BUTTON_LEFT:
			grid_position = world_to_grid(get_global_mouse_position())

			if is_inside_grid(grid_position):
				position = grid.grid_to_world(grid_position)
				await select_current_tile()

		elif event.button_index == MOUSE_BUTTON_RIGHT:
			cancel_selection()


func move_cursor(direction: Vector2i) -> void:
	var next_cell: Vector2i = grid_position + direction

	if not is_inside_grid(next_cell):
		return

	grid_position = next_cell
	position = grid.grid_to_world(grid_position)


func select_current_tile() -> void:
	if command_locked or not turn_manager.is_player_turn():
		return

	# A unit is already selected.
	if selected_unit != null:

		# Check whether the cursor is over an enemy.
		var target = get_unit_at(grid_position)

		if target != null and target.team != selected_unit.team:
			var distance: int = (
				abs(target.grid_position.x - selected_unit.grid_position.x)
				+ abs(target.grid_position.y - selected_unit.grid_position.y)
			)

			if distance <= selected_unit.attack_range:
				attack_unit(selected_unit, target)
				return

		# Clicking the selected unit's own tile does nothing.
		if grid_position == selected_unit.grid_position:
			return

		# Prevent moving twice.
		if selected_unit.has_moved:
			print("This unit has already moved.")
			return

		# Attempt to move.
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

		# Show movement range only if the unit hasn't moved.
		if not unit.has_moved:
			movement_range.calculate_reachable(
				unit.grid_position,
				unit.movement,
				unit
			)
		else:
			movement_range.reachable_cells.clear()

		# Always show attack range.
		movement_range.calculate_attack_range(
			unit.grid_position,
			unit.attack_range
		)

	else:
		print_terrain_info()


func attack_unit(attacker: Node, defender: Node) -> void:
	if attacker.has_acted or command_locked:
		return

	if not is_instance_valid(defender):
		return

	var terrain_defense: int = map.get_defense_bonus(
		defender.grid_position
	)

	var damage: int = max(
		1,
		attacker.attack - defender.defense - terrain_defense
	)

	print(
		attacker.unit_name,
		" attacks ",
		defender.unit_name,
		" for ",
		damage,
        " damage!"
	)

	defender.take_damage(damage)

	# Attacking consumes the unit's remaining action.
	attacker.has_moved = true
	attacker.has_acted = true

	attacker.deselect()

	selected_unit = null
	movement_range.clear_range()


func cancel_selection() -> void:
	if command_locked:
		return

	deselect_all_units()

	selected_unit = null
	movement_range.clear_range()


func deselect_all_units() -> void:
	for unit in units.get_children():
		unit.deselect()


func get_unit_at(cell: Vector2i) -> Node:
	for unit in units.get_children():
		if unit.grid_position == cell:
			return unit

	return null


func print_terrain_info() -> void:
	var terrain = map.get_terrain(grid_position)
	var terrain_data: Dictionary = map.get_terrain_data(grid_position)

	print(
		"Terrain: ", terrain_data["name"],
		" | Movement Cost: ", terrain_data["movement_cost"],
		" | Defense Bonus: ", terrain_data["defense"]
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
	var half_size: float = TILE_SIZE / 2.0
	var corner_size: float = 10.0
	var color := Color.WHITE
	var line_width: float = 2.0

	# Top-left.
	draw_line(
		Vector2(-half_size, -half_size),
		Vector2(-half_size + corner_size, -half_size),
		color,
		line_width
	)

	draw_line(
		Vector2(-half_size, -half_size),
		Vector2(-half_size, -half_size + corner_size),
		color,
		line_width
	)

	# Top-right.
	draw_line(
		Vector2(half_size, -half_size),
		Vector2(half_size - corner_size, -half_size),
		color,
		line_width
	)

	draw_line(
		Vector2(half_size, -half_size),
		Vector2(half_size, -half_size + corner_size),
		color,
		line_width
	)

	# Bottom-left.
	draw_line(
		Vector2(-half_size, half_size),
		Vector2(-half_size + corner_size, half_size),
		color,
		line_width
	)

	draw_line(
		Vector2(-half_size, half_size),
		Vector2(-half_size, half_size - corner_size),
		color,
		line_width
	)

	# Bottom-right.
	draw_line(
		Vector2(half_size, half_size),
		Vector2(half_size - corner_size, half_size),
		color,
		line_width
	)

	draw_line(
		Vector2(half_size, half_size),
		Vector2(half_size, half_size - corner_size),
		color,
		line_width
	)
