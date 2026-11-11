
extends Node

enum Turn {
	PLAYER,
	ENEMY
}

const PLAYER_TEAM := 0
const ENEMY_TEAM := 1

var current_turn: Turn = Turn.PLAYER
var enemy_turn_running: bool = false

@onready var units = get_parent().get_node("Units")
@onready var movement_range = get_parent().get_node("MovementRange")
@onready var map = get_parent().get_node("Map")


func _ready() -> void:
	print("Player turn started.")


func is_player_turn() -> bool:
	return current_turn == Turn.PLAYER


func end_player_turn() -> void:
	if current_turn != Turn.PLAYER or enemy_turn_running:
		return

	current_turn = Turn.ENEMY
	enemy_turn_running = true

	print("================================")
	print("Enemy turn started.")
	print("================================")

	# Reset enemy units.
	for unit in units.get_children():
		if unit.team == ENEMY_TEAM:
			unit.reset_turn()

	# Execute enemy AI.
	await run_enemy_turn()

	# Start the next player turn.
	end_enemy_turn()


func run_enemy_turn() -> void:
	for enemy in units.get_children():

		if not is_instance_valid(enemy):
			continue

		if enemy.team != ENEMY_TEAM:
			continue

		if enemy.has_acted:
			continue

		# Find the nearest player unit.
		var target = find_nearest_player(enemy)

		if target == null:
			continue

		print(enemy.unit_name, " is considering its move.")

		# Check whether the player is already in attack range.
		var distance: int = (
			abs(target.grid_position.x - enemy.grid_position.x)
			+ abs(target.grid_position.y - enemy.grid_position.y)
		)

		if distance <= enemy.attack_range:
			attack_unit(enemy, target)

			await get_tree().create_timer(0.3).timeout
			continue

		# Calculate enemy movement range.
		movement_range.calculate_reachable(
			enemy.grid_position,
			enemy.movement,
			enemy
		)

		# Find the best reachable destination.
		var destination: Vector2i = find_best_destination(
			enemy,
			target
		)

		movement_range.clear_range()

		# Move toward the player.
		if destination != enemy.grid_position:
			print(enemy.unit_name, " moving to ", destination)

			await enemy.move_to_cell(destination)

		# Check whether the player is still alive.
		if not is_instance_valid(target):
			enemy.has_acted = true
			continue

		# Check attack range again after moving.
		distance = (
			abs(target.grid_position.x - enemy.grid_position.x)
			+ abs(target.grid_position.y - enemy.grid_position.y)
		)

		if distance <= enemy.attack_range:
			attack_unit(enemy, target)
		else:
			enemy.has_acted = true
			print(enemy.unit_name, " cannot attack this turn.")

		await get_tree().create_timer(0.3).timeout


func find_nearest_player(enemy: Node):
	var nearest_player = null
	var shortest_distance: int = 999999

	for unit in units.get_children():
		if unit.team != PLAYER_TEAM:
			continue

		var distance: int = (
			abs(unit.grid_position.x - enemy.grid_position.x)
			+ abs(unit.grid_position.y - enemy.grid_position.y)
		)

		if distance < shortest_distance:
			shortest_distance = distance
			nearest_player = unit

	return nearest_player


func find_best_destination(enemy: Node, target: Node) -> Vector2i:
	var best_cell: Vector2i = enemy.grid_position

	var shortest_distance: int = (
		abs(target.grid_position.x - best_cell.x)
		+ abs(target.grid_position.y - best_cell.y)
	)

	for cell in movement_range.reachable_cells:
		var distance: int = (
			abs(target.grid_position.x - cell.x)
			+ abs(target.grid_position.y - cell.y)
		)

		if distance < shortest_distance:
			shortest_distance = distance
			best_cell = cell

	return best_cell


func attack_unit(attacker: Node, defender: Node) -> void:
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

	attacker.has_moved = true
	attacker.has_acted = true


func end_enemy_turn() -> void:
	current_turn = Turn.PLAYER
	enemy_turn_running = false

	# Reset player units for the new turn.
	for unit in units.get_children():
		if unit.team == PLAYER_TEAM:
			unit.reset_turn()

	movement_range.clear_range()

	print("================================")
	print("Player turn started.")
	print("================================")
