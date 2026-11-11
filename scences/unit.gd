
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
@export var attack_range := 1
@export var team: Team = Team.PLAYER

var hp := 10
var grid_position := Vector2i.ZERO

var selected := false
var has_moved := false
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
        " selected | HP: ", hp, "/", max_hp,
        " | Movement: ", movement,
        " | Attack: ", attack,
        " | Defense: ", defense
    )


func deselect() -> void:
    selected = false
    queue_redraw()


func move_to_cell(cell: Vector2i) -> void:
    if is_moving or has_moved or has_acted:
        return

    is_moving = true

    var target_position := Vector2(
        cell.x * TILE_SIZE + TILE_SIZE / 2.0,
        cell.y * TILE_SIZE + TILE_SIZE / 2.0
    )

    var tween := create_tween()
    tween.set_trans(Tween.TRANS_SINE)
    tween.set_ease(Tween.EASE_IN_OUT)
    tween.tween_property(self, "position", target_position, 0.25)

    await tween.finished

    grid_position = cell
    has_moved = true
    is_moving = false

    queue_redraw()


func take_damage(amount: int) -> void:
    hp = max(0, hp - amount)
    queue_redraw()

    print(
        unit_name,
        " took ", amount,
        " damage. HP: ", hp, "/", max_hp
    )

    if hp <= 0:
        print(unit_name, " was destroyed!")
        queue_free()


func reset_turn() -> void:
    has_moved = false
    has_acted = false
    selected = false

    queue_redraw()


func draw_hp_bar() -> void:
    var bar_width: float = 36.0
    var bar_height: float = 5.0
    var bar_y: float = -27.0

    var hp_ratio: float = clamp(
        float(hp) / float(max_hp),
        0.0,
        1.0
    )

    draw_rect(
        Rect2(
            -bar_width / 2.0,
            bar_y,
            bar_width,
            bar_height
        ),
        Color(0.2, 0.2, 0.2)
    )

    var hp_color := Color.GREEN

    if hp_ratio <= 0.3:
        hp_color = Color.RED
    elif hp_ratio <= 0.6:
        hp_color = Color.YELLOW

    draw_rect(
        Rect2(
            -bar_width / 2.0,
            bar_y,
            bar_width * hp_ratio,
            bar_height
        ),
        hp_color
    )

    draw_rect(
        Rect2(
            -bar_width / 2.0,
            bar_y,
            bar_width,
            bar_height
        ),
        Color.WHITE,
        false,
        1.0
    )


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

    draw_hp_bar()
