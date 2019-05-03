extends Node2D

enum MAP_TYPE { IMAGE = 0, NOISE, RANDOM_NR }

var data: Dictionary = {}

var popup = []

var current_free_id = 0

var thread: Thread
var mutex: Mutex
var running = true

onready var testing = preload("res://Scripts/Testing.gdns").new()

func _ready():
	$MapHandler/FullScreenButton.connect('pressed', self, '_on_full_screen_button_pressed')
	data = SaveLoad.load_maps()
	_p_createOptions()
	
	generate_map(data['maps'][0])
	set_information(0)
	
	thread = Thread.new()
	mutex = Mutex.new()
	thread.start(self, '_p_thread_func', null, Thread.PRIORITY_HIGH)
	
	#print(testing.map($MapHandler.map))
	#var tile = testing.create_tile()
	#print(tile)
	#print(tile.str2())
	#var tile = testing.get_tile()
	#print(tile.str2())
	#testing.delete_tile()

func _p_createOptions():
	current_free_id = 0
	for map in data['maps']:
		$CanvasLayer/UI/OptionButton.add_item(map['name'], current_free_id)
		current_free_id += 1

func _exit_tree():
	running = false
	thread.wait_to_finish()
	$MapHandler/FullScreenButton.disconnect('pressed', self, '_on_full_screen_button_pressed')
	SaveLoad.save_maps(data)

func _process(delta):
	# Update the tile map after a path has been found
	if search_for_path == 2:
		for pos in path:
			$MapHandler.map.tiles[pos.x + pos.y * $MapHandler.map.width].tile_index = Global.TILES.red
		$MapHandler.map.update_tile_map()
		mutex.lock()
		search_for_path = 0
		mutex.unlock()
	
	var new = false
	if not popup.empty():
		if popup[0] == 'img':
			if popup[1].has_changed:
				popup[1].has_changed = false
				data['maps'].append(
				{
					"img": "res://Img/Maps/" + popup[1].name_for_map,
					"name": "[img]" + popup[1].name_for_map,
					"type": 0
				})
				new = true
		
		if popup[0] == 'noise':
			if popup[1].has_changed:
				popup[1].has_changed = false
				data['maps'].append(
				{
					"height": popup[1].height,
					"name": "[noise]" + popup[1].map_name,
					"octaves": popup[1].octaves,
					"period": popup[1].period,
					"persistence": popup[1].persistence,
					"seed": popup[1].seed_nr,
					"type": 1,
					"width": popup[1].width
				})
				new = true
		
		if popup[0] == 'random':
			if popup[1].has_changed:
				popup[1].has_changed = false
				data['maps'].append(
				{
					"height": popup[1].height,
					"name": "[random]" + popup[1].name_of_map,
					"seed": popup[1].seed_nr,
					"type": 2,
					"width": popup[1].width,
					"spread": popup[1].spread
				})
				new = true
	
	if new == true:
		$CanvasLayer/UI/OptionButton.add_item(data['maps'][data['maps'].size() - 1]['name'], current_free_id)
		current_free_id += 1
		popup[1].free()
		popup = []
	
	$CanvasLayer/ProgressBar.visible = testing.getProgressBarVisible()
	$CanvasLayer/ProgressBar.value = testing.getProgressBarValue() * $CanvasLayer/ProgressBar.max_value

func set_information(id: int):
	var text = ''
	for key in data['maps'][id].keys():
		text += str(key) + ': ' + str(data['maps'][id][key]) + '\n'
	$CanvasLayer/Panel/MarginContainer/Info.text = text

func _on_OptionButton_item_selected(ID):
	generate_map(data['maps'][ID])
	set_information(ID)

func generate_map(map_data):
	var x : int = map_data['type']
	match x:
		0:#MAP_TYPE.IMAGE:
			$MapHandler.generate_new_map(map_data['img'])
			map_data['width'] = $MapHandler.map.width
			map_data['height'] = $MapHandler.map.height
		
		1:#MAP_TYPE.NOISE:
			map_data['seed'] = $MapHandler.generate_new_map_with_noise(map_data['width'], map_data['height'], map_data['seed'], 
			map_data['octaves'], map_data['period'], map_data['persistence'])
		
		2:#MAP_TYPE.RANDOM_NR:
			map_data['seed'] = $MapHandler.generate_new_map_with_random_numbers(map_data['width'], map_data['height'], map_data['spread'], map_data['seed'])
	
	$MapHandler.update_FullScreenButtonSize()
	_p_clear_things_to_make_path()
	
	# Create the map on the c++ side
	testing.cleanup()
	testing.init($MapHandler.map.width, $MapHandler.map.height, $MapHandler.map.get_pool_int_array())

func _on_NewMapImageButton_pressed():
	var isit = true
	if not popup.empty() and popup[0] == 'img':
		isit = false
	
	if not popup.empty():
		popup[1].free()
		popup = []
	
	if isit == true:
		var new_map_image = load('res://Scenes/Popups/NewMapImage.tscn').instance()
		$CanvasLayer.add_child(new_map_image)
		popup = ['img', new_map_image]

func _on_NewMapNoiseButton_pressed():
	var isit = true
	if not popup.empty() and popup[0] == 'noise':
		isit = false
	
	if not popup.empty():
		popup[1].free()
		popup = []
	
	if isit == true:
		var new_map_image = load('res://Scenes/Popups/NewMapNoise.tscn').instance()
		$CanvasLayer.add_child(new_map_image)
		popup = ['noise', new_map_image]

func _on_NewMapRandomButton_pressed():
	var isit = true
	if not popup.empty() and popup[0] == 'random':
		isit = false
	
	if not popup.empty():
		popup[1].free()
		popup = []
	
	if isit == true:
		var new_map_image = load('res://Scenes/Popups/NewMapRandom.tscn').instance()
		$CanvasLayer.add_child(new_map_image)
		popup = ['random', new_map_image]

func _on_Button_pressed():
	if data['maps'].size() > 1:
		var index = $CanvasLayer/UI/OptionButton.get_selected_id()
		data['maps'].erase(data['maps'][index])
		for i in $CanvasLayer/UI/OptionButton.get_item_count():
			$CanvasLayer/UI/OptionButton.remove_item(0)
		_p_createOptions()

func _on_SaveAsImageButton_pressed():
	var map = data['maps'][$CanvasLayer/UI/OptionButton.get_selected_id()]
	if not map.has('img'):
		# Create .png image from current map
		var img = Image.new()
		img.create(map.width, map.height, false, Image.FORMAT_RGBA8)
		img.lock()
		for tile in $MapHandler.map.tiles:
			img.set_pixelv(tile.pos, Color(0, 0, 0, 1) if tile.tile_index == Global.TILES.wall else Color(1, 1, 1, 1))
		img.unlock()
		print('filled new image with pixels')
		var name = map['name'].split(']')[1]
		img.save_png('res://Img/Maps/' + name + '.png')
		
		# Add to the list of maps
		data['maps'].append(
		{
			"img": "res://Img/Maps/" + name + '.png',
			"name": "[img]" + name,
			"type": 0
		})
		$CanvasLayer/UI/OptionButton.add_item(data['maps'][data['maps'].size() - 1]['name'], current_free_id)
		current_free_id += 1

# ------------------------------------ Choose Algorithm ---------------------------------------------
var AStar_script = preload('../Scripts/Algorithms/MyAStar.gd')
var AStarSearch_script = preload('../Scripts/Algorithms/AStarSearch.gd')
var DynamicNearestNeighbour_script = preload('../Scripts/Algorithms/DNN.gd')
var GreedySearch_script = preload('../Scripts/Algorithms/GS.gd')
var NearestNeighbor_script = preload('../Scripts/Algorithms/NearestNeighbor.gd')

var current_algorithm_script = AStar_script
var current_algorithm_id = 0
var selected_type_to_place = -1

var start_pos := Vector2(0, 0)
var end_pos := Vector2(1, 0)
var goal_pints = []
var path = []

var search_for_path: int = 0
var save_whole_map: bool = false

# Check if the position is a valid one
func _p_is_valid(pos: Vector2) -> bool:
	if pos.x >= 0 and pos.x < $MapHandler.map.width and pos.y >= 0 and pos.y < $MapHandler.map.height:
		 return $MapHandler.map.tilev(pos).tile_index != Global.TILES.wall
	return false

# Get a random valid position on the current map
func _p_rand_valid_pos_on_map() -> Vector2:
	var pos: Vector2 = Vector2(randi() % $MapHandler.map.width, randi() % $MapHandler.map.height)
	if not _p_is_valid(pos):
		pos = _p_rand_valid_pos_on_map()
	return pos

# Check if a vector2 is in a PoolVector2Array
func _p_in_pool_vector2_array(var pool_vector2_array: PoolVector2Array, var vector2: Vector2) -> bool:
	for v in pool_vector2_array:
		if v == vector2:
			return true
	return false

# Get two different random valid positions on the current map
func _p_two_rand_valid_pos_on_map() -> PoolVector2Array:
	var ret : PoolVector2Array
	ret.append(_p_rand_valid_pos_on_map())
	
	var pos: Vector2 = _p_rand_valid_pos_on_map()
	while _p_in_pool_vector2_array(ret, pos):
		pos = _p_rand_valid_pos_on_map()
	
	ret.append(pos)
	return ret

# Get N random valid positions on the current map. With the condition that all positions is different
func _p_n_rand_valid_pos_on_map(var points: PoolVector2Array, var nr_of_points: int) -> PoolVector2Array:
	var new_points: PoolVector2Array
	for i in range(nr_of_points):
		var v : Vector2 = _p_rand_valid_pos_on_map()
		while _p_in_pool_vector2_array(points, v):
			v = _p_rand_valid_pos_on_map()
		points.append(v)
		new_points.append(v)
		
	return new_points

# Create the data for one map
func _p_thread_create_data_tl(var map_id: int, var iterations: int, var nr_of_goal_points: int):
	print("starting simulation to create data")
	
	var apmap = []
	for i in range(iterations):
		var two_pos = _p_two_rand_valid_pos_on_map()
		var points = _p_n_rand_valid_pos_on_map(two_pos, nr_of_goal_points)
		apmap.append([two_pos[0], two_pos[1], points])
	
	for algorithm_id in range(1, 5):
		print(algorithm_id)
		for i in range(iterations):
			# Start timer
			var old_time = OS.get_ticks_msec()
			var p = testing.calculatePath(algorithm_id, apmap[i][0], apmap[i][1], apmap[i][2])
			# Stop timer
			var dt_time = (OS.get_ticks_msec() - old_time) / 1000.0
			# Add time taken and path length to data to be saved
			SaveLoad.add_data_to_save(algorithm_id, dt_time, p.size())
	
	# Save data
	SaveLoad.save_tl_all(data['maps'][map_id]['name'], $CanvasLayer/PathfindingBox/Algorithms)
	
	print("Done with creating data from whole map")

func _p_thread_func(data):
	while running:
		mutex.lock()
		if search_for_path == 1:
			print('searching')
			var old_time = OS.get_ticks_msec()
			#var algorithm = current_algorithm_script.new()
			path = testing.calculatePath(current_algorithm_id, start_pos, end_pos, goal_pints)
			#path = algorithm.calculatePath($MapHandler.map, start_pos, end_pos, goal_pints, $CanvasLayer/ProgressBar)
			#algorithm.free()
			var dt_time = (OS.get_ticks_msec() - old_time) / 1000.0
			print(dt_time)
			SaveLoad.add_data_to_save(current_algorithm_id, dt_time, path.size())
			print('done')
			search_for_path = 2
		if save_whole_map:
			for i in range(SaveLoad.data_tl.size()):
				SaveLoad.data_tl[i].clear()
			_p_thread_create_data_tl($CanvasLayer/UI/OptionButton.get_selected_id(), 50, 7)
			save_whole_map = false
		mutex.unlock()

func _p_clear_things_to_make_path():
	goal_pints = []
	path = []
	start_pos = Vector2(0, 0)
	end_pos = Vector2(1, 0)
	selected_type_to_place = -1

func _p_get_tile_pos_from_mouse() -> Vector2:
	var mouse_pos = get_viewport().get_mouse_position()
	var world_pos = (mouse_pos - get_viewport_rect().size/2) * $MapHandler.zoom + $MapHandler/Camera2D.position
	return $MapHandler/TileMap.world_to_map(world_pos)

func _p_set_empty_tile(tile_pos: Vector2):
	if tile_pos.x >= 0 and tile_pos.x < $MapHandler.map.width and tile_pos.y >= 0 and tile_pos.y < $MapHandler.map.height:
		if selected_type_to_place != -1 and $MapHandler.map.tiles[tile_pos.x + (tile_pos.y * $MapHandler.map.width)].tile_index != Global.TILES.wall:
			$MapHandler.map.tiles[tile_pos.x + tile_pos.y * $MapHandler.map.width].tile_index = Global.TILES.cell
			$MapHandler.map.update_tile_map()

func _on_full_screen_button_pressed():
	if search_for_path == 0:
		if Input.is_action_just_pressed("mouse_left"):
			if $MapHandler.map.tilev(_p_get_tile_pos_from_mouse()).tile_index == Global.TILES.wall:
				return
			if selected_type_to_place == Global.TILES.start:
				if _p_get_tile_pos_from_mouse() == end_pos:
					return
				_p_set_empty_tile(start_pos)
				start_pos = _p_get_tile_pos_from_mouse()
			if selected_type_to_place == Global.TILES.end:
				if _p_get_tile_pos_from_mouse() == start_pos:
					return
				_p_set_empty_tile(end_pos)
				end_pos = _p_get_tile_pos_from_mouse()
			if selected_type_to_place == Global.TILES.goal_point:
				goal_pints.append(_p_get_tile_pos_from_mouse())
			var tile_pos = _p_get_tile_pos_from_mouse()
			if tile_pos.x >= 0 and tile_pos.x < $MapHandler.map.width and tile_pos.y >= 0 and tile_pos.y < $MapHandler.map.height:
				if selected_type_to_place != -1:
					$MapHandler.map.tiles[tile_pos.x + (tile_pos.y * $MapHandler.map.width)].tile_index = selected_type_to_place
					$MapHandler.map.update_tile_map()
		
		if Input.is_action_just_pressed("mouse_right"):
			if $MapHandler.map.tilev(_p_get_tile_pos_from_mouse()).tile_index == Global.TILES.wall:
				return
			var tile_pos = _p_get_tile_pos_from_mouse()
			if $MapHandler.map.tilev(tile_pos).tile_index == Global.TILES.goal_point:
				goal_pints.erase(tile_pos)
			_p_set_empty_tile(tile_pos)

func _on_StartButton_pressed():
	for pos in path:
		$MapHandler.map.tilev(pos).tile_index = Global.TILES.cell
	$MapHandler.map.tilev(start_pos).tile_index = Global.TILES.start
	$MapHandler.map.tilev(end_pos).tile_index = Global.TILES.end
	for pos in goal_pints:
		$MapHandler.map.tilev(pos).tile_index = Global.TILES.goal_point
	$MapHandler.map.update_tile_map()
	mutex.lock()
	search_for_path = 1
	mutex.unlock()

func _on_Algorithms_item_selected(ID):
	current_algorithm_id = ID
	match ID:
		# A*
		0:
			current_algorithm_script = AStar_script
		# AS
		1:
			current_algorithm_script = AStarSearch_script
		# DNN
		2:
			current_algorithm_script = DynamicNearestNeighbour_script
		# GS
		3:
			current_algorithm_script = GreedySearch_script
		# NN
		4:
			current_algorithm_script = NearestNeighbor_script


func _on_SetStartButton_pressed():
	selected_type_to_place = Global.TILES.start

func _on_SetEndButton_pressed():
	selected_type_to_place = Global.TILES.end

func _on_SetGoalPointButton_pressed():
	selected_type_to_place = Global.TILES.goal_point

func _on_CreateDataFileButton_pressed():
	var temp = true
	for i in range(SaveLoad.data_tl.size()):
		if not SaveLoad.data_tl[i].empty():
			temp = false
	if temp:
		# Generate map that the data is comming from
		print("map is generating")
		generate_map(data['maps'][$CanvasLayer/UI/OptionButton.get_selected_id()])
		print("map has been generated")
		save_whole_map = temp
	else:
		SaveLoad.save_tl_all('current_map', $CanvasLayer/PathfindingBox/Algorithms)
