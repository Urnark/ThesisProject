extends Node

const a_star = preload('MyAStar.gd')
	
	
func _p_set_value(progress_bar: ProgressBar, value: float):
	if progress_bar != null:
		progress_bar.value = value

func calculatePath(map: a_star.MapGD.Map, start_pos: Vector2, end_pos: Vector2, _goal_points: Array, progress_bar: ProgressBar = null) -> Array:
	if progress_bar != null:
		progress_bar.value = 0.0
		progress_bar.visible = true
	
	var bar_step = 100.0 / (_goal_points.size() + 1) as float
	var current_bar_step = 0
	
		# Make a copy of the array of goal points so they are not removed
	var goal_points = []
	for goal in _goal_points:
		goal_points.append(goal)
		
	var aStar = a_star.new() 
	var path = []
	
	var currentNode = start_pos
	var closestNode
	
	while (goal_points.size() > 0):
		var closestDistance = 10000
		for goal in goal_points:
			if(currentNode != goal):
				var dist = currentNode.distance_to(goal)
				if(dist < closestDistance):
					closestDistance = dist
					closestNode = goal
		var currentPath = aStar.calculatePath(map, currentNode, closestNode)
		for i in currentPath.size() - 1:
			path.append(currentPath[currentPath.size() - 2 - i])
		currentNode = closestNode
		goal_points.erase(closestNode)
				
				
	
	var finalPath = aStar.calculatePath(map, currentNode, end_pos)
	
	for i in finalPath.size() - 1:
		path.append(finalPath[finalPath.size() - 1 - i])
	
	
	aStar.free()
	if progress_bar != null:
		progress_bar.visible = false
	
	return path