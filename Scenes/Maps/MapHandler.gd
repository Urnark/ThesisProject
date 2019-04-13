extends Node2D

const MapGD = preload('Map.gd')
var map : MapGD.Map

var zoom : Vector2 = Vector2(1, 1)

func _ready():
	# Randomize the seed to creating random maps
	randomize()

func generate_new_map_from_image(image_of_map: Image):
	# Clear the tile map
	$TileMap.clear()
	
	# Create new map
	map = MapGD.Map.new($TileMap)
	map.use_image_for_map(image_of_map)
	map.update_tile_map()

func generate_new_map_with_noise(width: int, height: int, var seed_nr = -1, 
octaves: int = 1, period: float = 20, persistence: float = 1) -> int:
	# Clear the tile map
	$TileMap.clear()
	
	var _seed = seed_nr
	# Set seed for the number generation
	if not seed_nr == -1:
		seed(seed_nr)
	else:
		_seed = randi()
		seed(_seed)
	
	# Create new map
	map = MapGD.Map.new($TileMap)
	map.width = width
	map.height = height
	_p_generate_tile_map_with_noise(_seed, map, octaves, period, persistence)
	map.update_tile_map()
	
	return _seed

func generate_new_map_with_random_numbers(width: int, height: int, var seed_nr = -1) -> int:
	# Clear the tile map
	$TileMap.clear()
	
	var _seed = seed_nr
	# Set seed for the number generation
	if not seed_nr == -1:
		seed(seed_nr)
	else:
		_seed = randi()
		seed(_seed)
	
	# Create new map
	map = MapGD.Map.new($TileMap)
	map.width = width
	map.height = height
	_p_generate_tile_map_with_ranom_numbers(map)
	map.update_tile_map()
	
	return _seed

func generate_new_map(path_to_file: String):
	# Clear the tile map
	$TileMap.clear()
	
	# Create new map
	map = MapGD.Map.new($TileMap)
	map.load_map(path_to_file)
	#_p_generate_tile_map_with_noise(map)
	#map.set_wireframe()
	map.update_tile_map()

# Generating tiles to the choosen map with a noise function,
# almost guarantees that a cell is always reachable
func _p_generate_tile_map_with_noise(seed_nr: int, map: MapGD.Map, octaves: int = 1, period: float = 20, persistence: float = 1):
	var noise = OpenSimplexNoise.new()
	noise.seed = seed_nr
	noise.octaves = octaves
	noise.period = period
	noise.persistence = persistence
	var noise_image = noise.get_image(map.width, map.height)
	noise_image.lock()
	
	var tiles = []
	for y in map.height:
		for x in map.width:
			var noise_p = noise_image.get_pixel(x, y).r
			tiles.append(MapGD.Tile.new(Global.TILES.wall if noise_p > 0.5 else Global.TILES.cell, Vector2(x, y)))
	
	noise_image.unlock()
	
	for y in map.height / noise.period:
		for x in map.width:
			var yy = y * noise.period
			tiles[x + yy * map.width].tile_index = Global.TILES.cell
	for x in map.width:
		tiles[x + (map.height - 1) * map.width].tile_index = Global.TILES.cell
	
	map.tiles = tiles

# Generating tiles to the choosen map with only random numbers
func _p_generate_tile_map_with_ranom_numbers(var map: MapGD.Map):
	var tiles = []
	for y in map.height:
		for x in map.width:
			tiles.append(MapGD.Tile.new(_p_get_tile_index(), Vector2(x, y)))
	map.tiles = tiles

func _p_get_tile_index() -> int:
	#return randi() % TILES.size()
	return Global.TILES.wall if randi() % 2 == 0 else Global.TILES.cell

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
	
	if Input.is_action_pressed('ui_left'):
		pos.x -= speed
	if Input.is_action_pressed('ui_right'):
		pos.x += speed
	if Input.is_action_pressed('ui_up'):
		pos.y -= speed
	if Input.is_action_pressed('ui_down'):
		pos.y += speed
	
	$Camera2D.position = pos