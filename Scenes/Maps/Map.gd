extends Node

class Tile:
	var tile_index = Global.TILES.cell
	var pos := Vector2(0, 0)
	var f : float = 0.0
	var h : float = 0.0
	var g : float = 0.0
	var visited := false
	var parent = null
	
	func _init(var tile_index: int, var pos: Vector2):
		self.tile_index = tile_index
		self.pos = pos
	
	func get_pos() -> Vector2:
		return self.pos

class Map:
	var width := 0
	var height := 0
	var tiles = []
	var tile_map
	
	func _init(tile_map: TileMap):
		self.tile_map = tile_map
	
	func copy():
		var copy = Map.new(tile_map)
		for tile in tiles:
			copy.tiles.append(Tile.new(tile.tile_index, Vector2(tile.pos.x, tile.pos.y)))
		copy.height = height
		copy.width = width
		return copy
	
	func tile(x: int, y: int) -> Tile:
		return self.tiles[x + y * self.width]
		
	func tilev(pos: Vector2) -> Tile:
		return self.tiles[pos.x + pos.y * self.width]
	
	func update_tile_map():
		for x in self.width:
			for y in self.height:
				tile_map.set_cellv(self.tiles[x + y * width].pos, self.tiles[x + y * width].tile_index)
	
	func set_wireframe():
		for tile in self.tiles:
			if tile.tile_index == Global.TILES.cell:
				tile.tile_index = Global.TILES.grid_cell
		update_tile_map()
	
	func use_image_for_map(image: Image):
		# Get width and height of the image
		self.width = image.get_width()
		self.height = image.get_height()
		
		image.lock()
		
		# Fill the tiles list
		self.tiles.clear()
		for y in self.height:
			for x in self.width:
				var wall = true if image.get_pixel(x, y).r == 0 else false
				var tile_index = Global.TILES.wall if wall else Global.TILES.cell
				self.tiles.append(Tile.new(tile_index, Vector2(x, y)))
		
		image.unlock()
	
	func load_map(path: String):
		# Load map image from .png file
		var image = Image.new()
		image.load(path)
		
		self.use_image_for_map(image)
	
	func get_pool_int_array() -> PoolIntArray:
		var arr : PoolIntArray
		for y in self.height:
			for x in self.width:
				arr.append(tile(x, y).tile_index)
		
		return arr