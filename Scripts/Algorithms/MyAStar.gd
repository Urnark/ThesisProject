extends Node

const MapGD = preload('../../Scenes/Maps/Map.gd')

func _p_compare_tile(a: MapGD.Tile, b: MapGD.Tile):
	if a.f == b.f:
		return a.h < b.h
	else:
		return a.f < b.f

func _p_is_valid(map : MapGD.Map, pos: Vector2) -> bool:
	if pos.x >= 0 and pos.x < map.width and pos.y >= 0 and pos.y < map.height:
		 return map.tilev(pos).tile_index != Global.TILES.wall
	return false

func _p_calculate_h(a: Vector2, b: Vector2) -> float:
	return a.distance_to(b)

func _p_make_path(map : MapGD.Map, start_pos: Vector2, end_pos: Vector2) -> Array:
	var path = []
	path.append(end_pos)
	var pos = end_pos
	while pos != start_pos:
		pos = map.tilev(pos).parent.pos
		path.append(pos)
	return path

func calculatePath(map : MapGD.Map, start_pos: Vector2, end_pos: Vector2, goal_points: Array = []) -> Array:
	assert(start_pos != end_pos)
	assert(_p_is_valid(map, start_pos))
	assert(_p_is_valid(map, end_pos))
	
	for tile in map.tiles:
		tile.f = -1.0
		tile.g = -1.0
		tile.h = -1.0
		tile.visited = false
		tile.parent = null
	
	var open = []
	var tile : MapGD.Tile = map.tilev(start_pos)
	tile.f = 0.0
	tile.g = 0.0
	tile.h = 0.0
	tile.visited = false
	open.append(tile)
	
	while not open.empty():
		open.sort_custom(self, '_p_compare_tile')
		tile = open.pop_front()
		tile.visited = true
		
		for pos in [[-1, -1], [-1, 0], [-1, 1], [0, -1], [0, 1], [1, -1], [1, 0], [1, 1]]:
			var p := Vector2(pos[0], pos[1]) + tile.pos
			if _p_is_valid(map, p):
				var cell = map.tile(p.x, p.y)
				if p == end_pos:
					cell.parent = tile
					return _p_make_path(map, start_pos, end_pos)
				elif cell.visited == false:
					var g = tile.g + (10.0 if (pos == [-1, -1] or pos == [-1, 1] or pos == [1, -1] or pos == [1, 1]) else 5.0)
					var h = _p_calculate_h(p, end_pos)
					var f = g + h
					# Check if this path is better than the one already present
					if (cell.f == -1.0 or
						cell.f > f):
						# Update the details of this neighbour node
						cell.f = f
						cell.g = g
						cell.h = h
						cell.parent = tile
						open.append(cell)
	return []