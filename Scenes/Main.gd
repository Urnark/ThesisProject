extends Node2D

export(Array, Image) var image_maps

enum MAP_TYPE { IMAGE = 0, NOISE, RANDOM_NR }

var data: Dictionary = {}

var popup = []

var current_free_id = 0

func _ready():
	data = SaveLoad.load_maps()
	for map in data['maps']:
		$CanvasLayer/UI/OptionButton.add_item(map['name'], current_free_id)
		current_free_id += 1
	
	generate_map(data['maps'][0])
	set_information(0)

func _exit_tree():
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
	#text += 'Width: ' + data['maps'][id]['width'] + '\n'
	#text += 'Height:' + data['maps'][id]['height'] + '\n'
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
		$CanvasLayer/UI/OptionButton.remove_item(index)
		$CanvasLayer/UI/OptionButton.select((index - 1) if index - 1 >= 0 else 0)

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