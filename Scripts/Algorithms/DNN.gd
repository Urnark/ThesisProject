extends Node

const a_star = preload('MyAStar.gd')

func _p_calculate_h(a: Vector2, b: Vector2) -> float:
	return a.distance_to(b)

func _p_nn(all: Array, pos: Vector2) -> Array:
	var distance_to_nn = _p_calculate_h(pos, all[0])
	var g = all[0]
	for goal in all:
		var temp_dist = _p_calculate_h(pos, goal)
		if distance_to_nn > temp_dist:
			distance_to_nn = temp_dist
			g = goal
	return g

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
	#path.append(start_pos)
	
	var current_pos := start_pos
	# Loop through all goals
	while not goal_points.empty():
		# Get the closest goal from the current position
		var goal = _p_nn(goal_points, current_pos)
		var distance_to_nn = _p_calculate_h(current_pos, goal)
		
		# Calculate a path from the current position to the goal
		var path_to_goal = aStar.calculatePath(map, current_pos, goal)
		
		# See if a goal that is closer exists and if so use it instead
		var step = 10
		for i in (path_to_goal.size() - 1) / step:
			# Find a new goal that is closer to the position in the current path to the goal
			var temp_goal = _p_nn(goal_points, path_to_goal[(path_to_goal.size() - 2) - (i * step)])
			if temp_goal != goal:
				# If the path to the new goal from the current position is shorter use it instead
				var temp_path_to_goal = aStar.calculatePath(map, current_pos, temp_goal)
				if temp_path_to_goal.size() < path_to_goal.size():
					path_to_goal = temp_path_to_goal
					break
		
		# Add all the positions in the path to the goal to the final path
		for i in path_to_goal.size() - 1:
			path.append(path_to_goal[(path_to_goal.size() - 2) - i])
		# Set the current position to the goal that the path leads to
		current_pos = path_to_goal[0]
		# Remove the goal from the list of goals
		goal_points.erase(path_to_goal[0])
		current_bar_step += bar_step
		_p_set_value(progress_bar, current_bar_step)
	
	# Add the path that leads to the end position to the final path
	var path_to_goal = aStar.calculatePath(map, current_pos, end_pos)
	for i in path_to_goal.size() - 1:
		path.append(path_to_goal[(path_to_goal.size() - 1) - i])
	
	_p_set_value(progress_bar, progress_bar.max_value)
	
	aStar.free()
	if progress_bar != null:
		progress_bar.visible = false
	return path