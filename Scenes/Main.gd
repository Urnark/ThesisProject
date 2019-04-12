extends Node2D

const PATH_TO_DIRECTORY := 'res://Img/Maps'

onready var file_names = get_png_file_names_in_directory(PATH_TO_DIRECTORY)

func _ready():
	print(file_names)
	
	var id = 0
	for file_name in file_names:
		$CanvasLayer/UI/OptionButton.add_item(file_name, id)
		id += 1
	
	$MapHandler.generate_new_map(PATH_TO_DIRECTORY + '/' + file_names[0])

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
	$MapHandler.generate_new_map(PATH_TO_DIRECTORY + '/' + file_names[ID])
