extends Node

const PATH = 'res://saved_data.json'
const PATH_TL = 'res://data/saved_data_tl'

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

#################################################################################################################
# Save and time to calculate a path and the paths length

var data_tl = [[], [], [], [], []]
 
func add_data_to_save(var type: int, var time: float, var length: int):
	data_tl[type].append([time, length])
	
func save_tl(var type_id: int, var type_name: String):
	var file := File.new()
	if file.open(PATH_TL + '_' + type_name + '.txt', File.WRITE) != OK:
		print('Error opening file [' + PATH_TL + '_' + type_name + '.txt]')
		return
	
	for tl in data_tl[type_id]:
		file.store_line(str(tl[0]) + ", " + str(tl[1]) + "\r")
	
	data_tl[type_id].clear()
	file.close()
	
func save_tl_all(var algorithms: OptionButton):
	for i in range(data_tl.size()):
		if not data_tl[i].empty():
			var text : String = algorithms.get_item_text(i)
			if i == 0 or i == 1:
				text = text.replace('*', 'Star')
			print(text)
			save_tl(i, text)
	