extends Node

const PATH = 'res://saved_data.json'

func save_maps(var data):
	var file := File.new()
	if file.open(PATH, File.WRITE) != OK:
		print('Error opening file [' + PATH + ']')
		return
	
	file.store_line(to_json(data))
	file.close()

func load_maps() -> Dictionary:
	# Check if there is a saved file
	var file = File.new()
	if not file.file_exists(PATH):
	    print('No file saved!')
	    return {}
	
	# Open existing file
	if file.open(PATH, File.READ) != 0:
	    print('Error opening file[' + PATH + ']')
	    return {}
	
	var text = ''
	while not file.eof_reached():
		text += file.get_line()
	
	# Get the data
	var data = {}
	data = parse_json(text)
	
	return data