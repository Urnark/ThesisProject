extends Node2D

onready var file_names = get_png_file_names_in_directory(PATH_TO_DIRECTORY)

export(String) var PATH_TO_DIRECTORY = 'res://Img/Maps'
export(Array, Image) var image_maps

func _ready():
#	print(file_names)
#
#	var id = 0
#	for file_name in file_names:
#		$CanvasLayer/UI/OptionButton.add_item(file_name, id)
#		id += 1
#	$MapHandler.generate_new_map(PATH_TO_DIRECTORY + '/' + file_names[0])
	
	for image_index in image_maps.size():
		$CanvasLayer/UI/OptionButton.add_item('map[' + str(image_index) + ']', image_index)
	$MapHandler.generate_new_map_from_image(image_maps[0])

# If all the files in the directory is used
func get_png_file_names_in_directory(path: String) -> Array:
	var file_names = []
	var dir = Directory.new()
	if dir.open(path) == OK:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while (file_name != ""):
			if not dir.current_is_dir() and file_name.ends_with('.png'):
				file_names.append(file_name)
			file_name = dir.get_next()
	else:
		print("An error occurred when trying to access the path")
	
	return file_names

func _on_OptionButton_item_selected(ID):
	$MapHandler.generate_new_map_from_image(image_maps[ID])
