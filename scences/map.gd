extends Node2D

const TILE_SIZE := 48
const MAP_WIDTH := 20
const MAP_HEIGHT := 15


enum Terrain {
	GRASS,
	FOREST,
	MOUNTAIN,
	ROAD,
	WATER
}


var terrain_data := {
	Terrain.GRASS: {
		"name": "Grass",
		"movement_cost": 1,
		"defense": 0,
		"color": Color(0.35, 0.65, 0.30)
	},

	Terrain.FOREST: {
		"name": "Forest",
		"movement_cost": 2,
		"defense": 2,
		"color": Color(0.15, 0.45, 0.18)
	},

	Terrain.MOUNTAIN: {
		"name": "Mountain",
		"movement_cost": 3,
		"defense": 4,
		"color": Color(0.45, 0.40, 0.35)
	},

	Terrain.ROAD: {
		"name": "Road",
		"movement_cost": 1,
		"defense": 0,
		"color": Color(0.65, 0.58, 0.42)
	},

	Terrain.WATER: {
		"name": "Water",
		"movement_cost": 999,
		"defense": 0,
		"color": Color(0.20, 0.45, 0.70)
	}
}


var map_data: Array = []


func _ready() -> void:
	create_map()
	queue_redraw()


func create_map() -> void:
	map_data.clear()

	for y in range(MAP_HEIGHT):
		var row: Array = []

		for x in range(MAP_WIDTH):
			row.append(Terrain.GRASS)

		map_data.append(row)

	# Forest
	map_data[2][3] = Terrain.FOREST
	map_data[2][4] = Terrain.FOREST
	map_data[3][3] = Terrain.FOREST
	map_data[3][4] = Terrain.FOREST

	map_data[8][12] = Terrain.FOREST
	map_data[8][13] = Terrain.FOREST
	map_data[9][12] = Terrain.FOREST
	map_data[9][13] = Terrain.FOREST

	# Mountains
	map_data[5][7] = Terrain.MOUNTAIN
	map_data[5][8] = Terrain.MOUNTAIN
	map_data[6][7] = Terrain.MOUNTAIN
	map_data[6][8] = Terrain.MOUNTAIN

	# Road
	for x in range(2, 18):
		map_data[10][x] = Terrain.ROAD

	# Water
	for y in range(2, 7):
		map_data[y][17] = Terrain.WATER
		map_data[y][18] = Terrain.WATER


func get_terrain(cell: Vector2i) -> int:
	if not is_inside_map(cell):
		return Terrain.WATER

	return map_data[cell.y][cell.x]


func get_terrain_data(cell: Vector2i) -> Dictionary:
	var terrain := get_terrain(cell)
	return terrain_data[terrain]


func get_movement_cost(cell: Vector2i) -> int:
	return get_terrain_data(cell)["movement_cost"]


func get_defense_bonus(cell: Vector2i) -> int:
	return get_terrain_data(cell)["defense"]


func is_inside_map(cell: Vector2i) -> bool:
	return (
		cell.x >= 0
		and cell.x < MAP_WIDTH
		and cell.y >= 0
		and cell.y < MAP_HEIGHT
	)


func _draw() -> void:
	for y in range(MAP_HEIGHT):
		for x in range(MAP_WIDTH):

			var cell := Vector2i(x, y)
			var terrain := get_terrain_data(cell)

			var rect := Rect2(
				x * TILE_SIZE,
				y * TILE_SIZE,
				TILE_SIZE,
				TILE_SIZE
			)

			draw_rect(rect, terrain["color"])
