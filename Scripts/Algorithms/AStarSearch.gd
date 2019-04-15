extends Node

const a_star = preload('MyAStar.gd')

func calculatePath(map: a_star.MapGD.Map, start_pos: Vector2, end_pos: Vector2, _goal_points: Array) -> Array:
	# Make a copy of the array of goal points so they are not removed
	var goal_points = []
	for goal in _goal_points:
		goal_points.append(goal)
	
	var aStar = a_star.new()
	
	var path = []
	path.append(start_pos)
	
	var current_pos := start_pos
	# Loop through all goals
	while not goal_points.empty():
		# Get the path from the current position to the closest goal
		var path_to_goal = aStar.calculatePath(map, current_pos, goal_points[0])
		for goal in goal_points:
			var temp_path = aStar.calculatePath(map, current_pos, goal)
			if path_to_goal.size() > temp_path.size():
				path_to_goal = temp_path
		
		# Add all the positions in the path to the goal to the final path
		for i in path_to_goal.size() - 1:
			path.append(path_to_goal[(path_to_goal.size() - 2) - i])
		# Set the current position to the goal that the path leads to
		current_pos = path_to_goal[0]
		# Remove the goal from the list of goals
		goal_points.erase(path_to_goal[0])
	
	# Add the path that leads to the end position to the final path
	var path_to_goal = aStar.calculatePath(map, current_pos, end_pos)
	for i in path_to_goal.size():
		path.append(path_to_goal[(path_to_goal.size() - 1) - i])
	
	aStar.free()
	return path