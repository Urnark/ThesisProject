extends Node

class Tile:
	var tile_index = Global.TILES.cell
	var pos := Vector2(0, 0)
	
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
	
	func _init(var width: int, var height: int, var tile_map: TileMap):
		self.width = width
		self.height = height
		self.tile_map = tile_map
	
	func set_tiles(var tiles: Array):
		self.tiles = tiles
	
	func update_tile_map():
		for x in self.width:
			for y in self.height:
				tile_map.set_cellv(self.tiles[x + y * width].pos, self.tiles[x + y * width].tile_index)
	
	func set_wireframe():
		for tile in self.tiles:
			if tile.tile_index == Global.TILES.cell:
				tile.tile_index = Global.TILES.grid_cell
		update_tile_map()