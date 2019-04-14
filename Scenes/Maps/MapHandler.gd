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
	
	map.tiles = tiles
	
	var mg = _p_find_groups(map)
#	var groups = mg[1]
#	for group in groups:
#		for tile in group:
#			tile.tile_index = Global.TILES.goal_point
	
	_p_generate_roads_from_groups(map, mg[0], mg[1])

func _p_generate_roads_from_groups(map: MapGD.Map, group_list: Array, groups: Array):
	# Find biggest group as the main group
	var main_group_index = 0
	var index = 0
	for group in groups:
		if group.size() > groups[main_group_index].size():
			main_group_index = index
		index += 1
	
	# Make roads to the main group
	var tile_index_for_cell = groups[0][0].tile_index
	for group_index in groups.size():
		if main_group_index != group_index:
			var pos : Vector2 = groups[group_index][0].pos
			var goal : Vector2 = groups[main_group_index][0].pos
			for tile in groups[main_group_index]:
				if tile.pos.distance_to(pos) < goal.distance_to(pos):
					goal = tile.pos
			
			var l = pos.distance_squared_to(goal)
			for i in l:
				pos = pos.linear_interpolate(goal, i / l).round()
				if group_list[pos.x + (pos.y * map.width)] != group_index and group_list[pos.x + (pos.y * map.width)] != -1:
					break
				elif group_list[pos.x + (pos.y * map.width)] == -1:
					group_list[pos.x + (pos.y * map.width)] = group_index
					map.tiles[pos.x + (pos.y * map.width)].tile_index = tile_index_for_cell
					groups[group_index].append(map.tiles[pos.x + (pos.y * map.width)])
			
			# Move all cells in th group to the main group
			for tile in groups[group_index]:
				groups[main_group_index].append(tile)
				group_list[tile.pos.x + (tile.pos.y * map.width)] = main_group_index
	
	var main_group = groups[main_group_index]
	groups.clear()
	groups.append(main_group)

# Function that returns an array of all the groups in the map and 
# a list of all the cells and which group they belong to.
# With a max number of groups as 10000
func _p_find_groups(map: MapGD.Map) -> Array:
	# Get start pos for iteration
	var current_x = 0
	var current_y = 0
	for tile in map.tiles:
		if tile.tile_index != Global.TILES.wall:
			current_x = tile.pos.x
			current_y = tile.pos.y
			break
	
	var group_list = []
	for tile in map.tiles:
		group_list.append(-1)
	
	var current_group = 0
	var groups = []
	groups.append([])
	var open_list = []
	open_list.append([current_x, current_y])
	var all_searched = false
	var MAX_GROUPS = 10000
	var groups_found = MAX_GROUPS
	while not all_searched:
		
		# Iterate over whole group
		while not open_list.empty():
			current_x = open_list[0][0]
			current_y = open_list[0][1]
			open_list.pop_front()
			group_list[current_x + (current_y * map.width)] = current_group
			groups[current_group].append(map.tiles[current_x + (current_y * map.width)])
			
			for x in [-1, 0, 1]:
				for y in [-1, 0, 1]:
					if not (x == 0 and y == 0):
						var index = (current_x + x) + ((current_y + y) * map.width)
						if (current_x + x) >= 0 and (current_x + x) < map.width and (current_y + y) >= 0 and (current_y + y) < map.height:
							if map.tiles[index].tile_index != Global.TILES.wall:
								if group_list[index] == -1:
									group_list[index] = current_group
									open_list.append([current_x + x, current_y + y])
									groups[current_group].append(map.tiles[index])
		
		# Find new group
		for index in map.tiles.size():
			if map.tiles[index].tile_index != Global.TILES.wall:
				if group_list[index] == -1:
					current_group += 1
					groups.append([])
					open_list.append([map.tiles[index].pos.x, map.tiles[index].pos.y])
					break
		
		# Check if all the cells has been searched
		if open_list.empty() or groups_found == 0:
			all_searched = true
		groups_found -= 1
	
	return [group_list, groups]

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