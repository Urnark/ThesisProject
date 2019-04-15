extends Node2D

enum MAP_TYPE { IMAGE = 0, NOISE, RANDOM_NR }

var data: Dictionary = {}

var popup = []

var current_free_id = 0

func _ready():
	$MapHandler/Camera2D/FullScreenButton.connect('pressed', self, '_on_full_screen_button_pressed')
	data = SaveLoad.load_maps()
	_p_createOptions()
	
	generate_map(data['maps'][0])
	set_information(0)

func _p_createOptions():
	current_free_id = 0
	for map in data['maps']:
		$CanvasLayer/UI/OptionButton.add_item(map['name'], current_free_id)
		current_free_id += 1

func _exit_tree():
	$MapHandler/Camera2D/FullScreenButton.disconnect('pressed', self, '_on_full_screen_button_pressed')
	SaveLoad.save_maps(data)

func _process(delta):
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
					"width": popup[1].width
				})
				new = true
	
	if new == true:
		$CanvasLayer/UI/OptionButton.add_item(data['maps'][data['maps'].size() - 1]['name'], current_free_id)
		current_free_id += 1
		popup[1].free()
		popup = []

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
			map_data['seed'] = $MapHandler.generate_new_map_with_random_numbers(map_data['width'], map_data['height'], map_data['seed'])

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

var current_algorithm_script = AStar_script
var selected_type_to_place = -1

var start_pos := Vector2(0, 0)
var end_pos := Vector2(0, 0)

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
	if Input.is_action_just_pressed("mouse_left"):
		if selected_type_to_place == Global.TILES.start:
			_p_set_empty_tile(start_pos)
			start_pos = _p_get_tile_pos_from_mouse()
		if selected_type_to_place == Global.TILES.end:
			_p_set_empty_tile(end_pos)
			end_pos = _p_get_tile_pos_from_mouse()
		var tile_pos = _p_get_tile_pos_from_mouse()
		if tile_pos.x >= 0 and tile_pos.x < $MapHandler.map.width and tile_pos.y >= 0 and tile_pos.y < $MapHandler.map.height:
			if selected_type_to_place != -1:
				$MapHandler.map.tiles[tile_pos.x + (tile_pos.y * $MapHandler.map.width)].tile_index = selected_type_to_place
				$MapHandler.map.update_tile_map()
	
	if Input.is_action_just_pressed("mouse_right"):
		var tile_pos = _p_get_tile_pos_from_mouse()
		_p_set_empty_tile(tile_pos)

func _on_StartButton_pressed():
	var algorithm = current_algorithm_script.new()
	var path = algorithm.calculatePath($MapHandler.map, start_pos, end_pos)
	algorithm.free()
	
	for pos in path:
		$MapHandler.map.tiles[pos.x + pos.y * $MapHandler.map.width].tile_index = Global.TILES.red
	$MapHandler.map.update_tile_map()

func _on_Algorithms_item_selected(ID):
	match ID:
		# A*
		0:
			current_algorithm_script = AStar_script
#		# AS
#		1:
#
#		# DNN
#		2:
#
#		# GS
#		3:
#
#		# NN
#		4:
#

func _on_SetStartButton_pressed():
	selected_type_to_place = Global.TILES.start

func _on_SetEndButton_pressed():
	selected_type_to_place = Global.TILES.end

func _on_SetGoalPointButton_pressed():
	selected_type_to_place = Global.TILES.goal_point
