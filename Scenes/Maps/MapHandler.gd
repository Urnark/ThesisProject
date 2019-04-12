extends Node2D

const WIDTH := 500
const HEIGHT := 500

const MapGD = preload('Map.gd')

var zoom : Vector2 = Vector2(1, 1)
var map : MapGD.Map

func _ready():
	# Randomize the seed to creating random maps
	randomize()
	
	map = MapGD.Map.new(WIDTH, HEIGHT, $TileMap)
	_p_generate_tile_map_with_noise(map)
	#map.set_wireframe()
	map.update_tile_map()

# Generating tiles to the choosen map with a noise function,
# almost guarantees that a cell is always reachable
func _p_generate_tile_map_with_noise(var map: MapGD.Map):
	var noise = OpenSimplexNoise.new()
	noise.octaves = 1
	noise.period = 20
	noise.persistence = 1
	var noise_image = noise.get_image(WIDTH, HEIGHT)
	noise_image.lock()
	
	var tiles = []
	for y in HEIGHT:
		for x in WIDTH:
			var noise_p = noise_image.get_pixel(x, y).r
			tiles.append(MapGD.Tile.new(Global.TILES.wall if noise_p > 0.5 else Global.TILES.cell, Vector2(x, y)))
			#tiles.append(MapGD.Tile.new(_p_get_tile_index(), Vector2(x, y)))
	
	noise_image.unlock()
	
	for y in HEIGHT / noise.period:
		for x in WIDTH:
			var yy = y * noise.period
			tiles[x + yy * WIDTH].tile_index = Global.TILES.cell
	for x in WIDTH:
		tiles[x + (HEIGHT - 1) * WIDTH].tile_index = Global.TILES.cell
	
	map.set_tiles(tiles)

# Generating tiles to the choosen map with only random numbers
func _p_generate_tile_map_with_ranom_numbers(var map: MapGD.Map):
	var tiles = []
	for y in HEIGHT:
		for x in WIDTH:
			tiles.append(MapGD.Tile.new(_p_get_tile_index(), Vector2(x, y)))
	map.set_tiles(tiles)

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