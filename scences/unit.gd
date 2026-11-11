extends Node2D

const TILE_SIZE := 48

enum Team {
	PLAYER,
	ENEMY
}

@export var unit_name := "Infantry"
@export var max_hp := 10
@export var movement := 3
@export var attack := 5
@export var defense := 1
@export var team: Team = Team.PLAYER

var hp := 10
var grid_position := Vector2i.ZERO

var selected := false
var has_acted := false
var is_moving := false


func _ready() -> void:
	hp = max_hp
	queue_redraw()


func setup(cell: Vector2i) -> void:
	grid_position = cell
	position = Vector2(
		cell.x * TILE_SIZE + TILE_SIZE / 2.0,
		cell.y * TILE_SIZE + TILE_SIZE / 2.0
	)


func select() -> void:
	if has_acted or is_moving:
		return

	selected = true
	queue_redraw()

	print(
		unit_name,
		" selected | HP: ",
		hp,
		"/",
		max_hp,
		" | Movement: ",
		movement,
		" | Attack: ",
		attack,
		" | Defense: ",
		defense
	)


func deselect() -> void:
	selected = false
	queue_redraw()


func move_to_cell(cell: Vector2i) -> void:
	if is_moving or has_acted:
		return

	is_moving = true
	grid_position = cell

	var target_position := Vector2(
		cell.x * TILE_SIZE + TILE_SIZE / 2.0,
		cell.y * TILE_SIZE + TILE_SIZE / 2.0
	)

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "position", target_position, 0.25)

	await tween.finished

	is_moving = false
	has_acted = true


func reset_turn() -> void:
	has_acted = false
	selected = false
	queue_redraw()


func _draw() -> void:
	var body_color := Color(0.2, 0.4, 0.9)

	if team == Team.ENEMY:
		body_color = Color(0.9, 0.2, 0.2)

	draw_circle(Vector2.ZERO, 16, body_color)

	draw_arc(
		Vector2.ZERO,
		16,
		0,
		TAU,
		32,
		Color.WHITE,
		2
	)

	if selected:
		draw_arc(
			Vector2.ZERO,
			22,
			0,
			TAU,
			32,
			Color.YELLOW,
			3
		)

	if has_acted:
		draw_arc(
			Vector2.ZERO,
			20,
			0,
			TAU,
			32,
			Color(0.5, 0.5, 0.5),
			2
		)
