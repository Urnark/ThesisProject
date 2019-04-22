extends Node

const a_star = preload('MyAStar.gd')

class pathItem:
	var length
	var node1
	var node2
	
	func _init(p_length, p_node1, p_node2):
		length = p_length
		node1 = p_node1
		node2 = p_node2

class nodeItem:
	var node
	var nrOfConnections
	var connectedNode1
	var connectedNode2
	
	func _init(p_node):
		node = p_node
		nrOfConnections = 0
		connectedNode1 = null
		connectedNode2 = null
	

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
		goal_points.append(nodeItem.new(goal))
		
	var aStar = a_star.new()
	
	#Connect the start node to the closest goal node	
	var startNodeShortestPath
	startNodeShortestPath = aStar.calculatePath(map, start_pos, goal_points[0].node)
	var startNodeNextNode = goal_points[0]
	for goal in goal_points:
		var tempStartPath = aStar.calculatePath(map, start_pos, goal.node)
		if(tempStartPath.size() < startNodeShortestPath.size()):
			startNodeShortestPath = tempStartPath
			startNodeNextNode = goal
	startNodeNextNode.nrOfConnections += 1
	
	print("Connected startnode to closest goal node")
	
	#Connect the end node to the closest goal node
	var endNodeShortestPath
	endNodeShortestPath = aStar.calculatePath(map, end_pos, goal_points[0].node)
	var endNodePrevNode = goal_points[0]
	for goal in goal_points:
		if (goal != startNodeNextNode):
			var tempEndPath = aStar.calculatePath(map, end_pos, goal.node)
			if(tempEndPath.size() < endNodeShortestPath.size()):
				endNodeShortestPath = tempEndPath
				endNodePrevNode = goal	
	endNodePrevNode.nrOfConnections += 1
	
	print("Connected endnode to closest goal node")
	
	var pathList = []
	var tempPaths = []
	var exists = false
	
	#Fill pathList with all possible node connections
	for node1 in goal_points:
		for node2 in goal_points:
			if !(node1 == node2) :
				for item in pathList:
					if item.node1 == node1 && item.node2 == node2:
						exists = true
					elif item.node1 == node2 && item.node2 == node1:
						exists = true
				if !exists:
					var path_between_nodes = aStar.calculatePath(map, node1.node, node2.node)
					pathList.append(pathItem.new(path_between_nodes.size(), node1, node2))
				exists = false
	
	print("Filled pathList with all possible node connections")
	
	#Pick the shortest path and add it to tempPaths
	for i in range(goal_points.size() - 1):
		var selectedPath = pathList[0]
		for item in pathList:
			if item.node1.nrOfConnections < 2 && item.node2.nrOfConnections < 2 && item.length < selectedPath.length:
				var node = item.node2
				var prevNode
				var alreadyConnected = false
				while (node != null):
					if (node == item.node1):
						alreadyConnected = true
						break
					prevNode = node
					if (node.connectedNode1 != prevNode):
						node = node.connectedNode1
					else:
						node = node.connectedNode2
				if !alreadyConnected:
					selectedPath = item
		selectedPath.node1.nrOfConnections += 1
		selectedPath.node2.nrOfConnections += 1
		tempPaths.append(selectedPath)
	
	print("Picked the shortest paths and added them to tempPaths")
	
	#Connect all the paths
	var sortedNodes = []
	var currentNode = startNodeNextNode
	var found = false
	sortedNodes.append(startNodeNextNode)
	
	while tempPaths.size() > 0:
		for item in tempPaths:
			found = false
			if currentNode == item.node1:
				sortedNodes.append(item.node2)
				currentNode = item.node2
				tempPaths.erase(item)
				found = true
				tempPaths.erase(item)
			elif currentNode == item.node2:
				sortedNodes.append(item.node1)
				currentNode = item.node1
				tempPaths.erase(item)
				found = true
				tempPaths.erase(item)
			if found:
				break
	
	print("Connected all the nodes via shortest paths")
	
	var path = []
#	path.append(start_pos)
	
	var p = aStar.calculatePath(map, start_pos, startNodeNextNode.node)
	
	for i in p.size() - 2:
		path.append(p[p.size() - 2 - i])
	
	
	#append the goal node connections
	for i in sortedNodes.size() - 1:
		var p2 = aStar.calculatePath(map, sortedNodes[i].node, sortedNodes[i + 1].node)
		print(i)
		for j in p2.size() - 1:
			path.append(p2[p2.size() - 2 - j])

	var p3 = aStar.calculatePath(map, sortedNodes[sortedNodes.size() - 1].node, end_pos)
	
	for i in p3.size() - 2:
		path.append(p3[p3.size() - 2 - i])

		
#	path.append(end_pos)
	
	_p_set_value(progress_bar, progress_bar.max_value)
	
	aStar.free()
	if progress_bar != null:
		progress_bar.visible = false
	
	return path