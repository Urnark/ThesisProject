extends Node2D

const WIDTH := 500
const HEIGHT := 500

const TILES = {
	'wall': 0,
	'grid_cell': 1,
	'cell': 2,
	'start': 3,
	'end': 4,
	'goal_point': 5
}

class Tile:
	var tile_index = TILES.cell
	var pos := Vector2(0, 0)
	
	func _init(var tile_index: int, var pos: Vector2):
		self.tile_index = tile_index
		self.pos = pos
	
	func get_pos() -> Vector2:
		return self.pos

class Map:
	var width := 0
	var height := 0
	var tiles = []
	var tile_map
	
	func _init(var width: int, var height: int):
		self.width = width
		self.height = height
	
	func set_tile_map(var tile_map: TileMap):
		self.tile_map = tile_map
	
	func set_tiles(var tiles: Array):
		self.tiles = tiles
	
	func update_tile_map():
		for x in self.width:
			for y in self.height:
				tile_map.set_cellv(self.tiles[x + y * width].pos, self.tiles[x + y * width].tile_index)
	
	func set_wireframe():
		for tile in self.tiles:
			if tile.tile_index == TILES.cell:
				tile.tile_index = TILES.grid_cell
		update_tile_map()

var zoom : Vector2 = Vector2(1, 1)
var map: Map = Map.new(WIDTH, HEIGHT)

func _ready():
	# Randomize the seed to creating random maps
	randomize()
	
	_p_generateTileMap(map)
	map.update_tile_map()

# Make a tiles for the choosen map
func _p_generateTileMap(var map: Map):
	var tiles = []
	for y in HEIGHT:
		for x in WIDTH:
			tiles.append(Tile.new(_p_get_tile_index(), Vector2(x, y)))
	
	map.set_tiles(tiles)
	map.set_tile_map($TileMap)

func _p_get_tile_index() -> int:
	#return randi() % TILES.size()
	return TILES.wall if randi() % 2 == 0 else TILES.cell

func _input(event):
	# Wheel Up Event
	if event.is_action_pressed("zoom_in"):
		_zoom_camera(-1)
	# Wheel Down Event
	elif event.is_action_pressed("zoom_out"):
		_zoom_camera(1)

func _zoom_camera(dir):
	zoom += Vector2(0.1, 0.1) * dir * zoom
	$Camera2D.zoom = zoom

func _process(delta):
	var pos : Vector2 = $Camera2D.position
	var speed := 10 * zoom.length()
	
	if Input.is_key_pressed(KEY_LEFT):
		pos.x -= speed
	if Input.is_key_pressed(KEY_RIGHT):
		pos.x += speed
	if Input.is_key_pressed(KEY_UP):
		pos.y -= speed
	if Input.is_key_pressed(KEY_DOWN):
		pos.y += speed
		
	$Camera2D.position = pos