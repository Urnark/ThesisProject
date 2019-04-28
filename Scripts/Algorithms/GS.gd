extends Node

const a_star = preload('MyAStar.gd')

class pathItem:
	var length
	var node1
	var node2
	var path = []
	
	func _init(p_length, p_node1, p_node2, p_path):
		length = p_length
		node1 = p_node1
		node2 = p_node2
		path = p_path

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

func isConnectedToNode(startNode: nodeItem, endNode: nodeItem) -> bool:
	var result = false
	var currentNode = startNode
	var prevNode
	while(currentNode != null && currentNode != endNode):
		if(currentNode.connectedNode1 != prevNode):
			prevNode = currentNode
			currentNode = currentNode.connectedNode1
		else:
			prevNode = currentNode
			currentNode = currentNode.connectedNode2
	if(currentNode == endNode):
		result = true
	return result
	
func pathLength(startNode: nodeItem) -> int:
	var result = 0
	var currentNode = startNode
	var prevNode
	while(currentNode != null):
		result += 1
		if(currentNode.connectedNode1 != prevNode):
			prevNode = currentNode
			currentNode = currentNode.connectedNode1
		else:
			prevNode = currentNode
			currentNode = currentNode.connectedNode2
	
	return result

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
		
	var startNode = nodeItem.new(start_pos)
	var endNode = nodeItem.new(end_pos)
		
	var aStar = a_star.new()
	
	var allPaths = []
	var exists = false
	
	#Add all possible paths to allPaths
	for node1 in goal_points:
		for node2 in goal_points:
			if !(node1 == node2) :
				for item in allPaths:
					if item.node1 == node1 && item.node2 == node2:
						exists = true
					elif item.node1 == node2 && item.node2 == node1:
						exists = true
				if !exists:
					var path_between_nodes = aStar.calculatePath(map, node1.node, node2.node)
					allPaths.append(pathItem.new(path_between_nodes.size(), node1, node2, path_between_nodes))
				exists = false
	
	#sort allPaths
	for i in range(allPaths.size() - 1):
		for j in range(allPaths.size() - 2):
			if(allPaths[j].length > allPaths[j + 1].length):
				var temp = allPaths[j + 1]
				allPaths[j + 1] = allPaths[j]
				allPaths[j] = temp
	
	#Connect start node to closest node
	var startNodeShortestPath
	startNodeShortestPath = aStar.calculatePath(map, startNode.node, goal_points[0].node)
	var startNodeNextNode = goal_points[0]
	for item in goal_points:
		var tempStartPath = aStar.calculatePath(map, startNode.node, item.node)
		if(tempStartPath.size() < startNodeShortestPath.size()):
			startNodeShortestPath = tempStartPath
			startNodeNextNode = item
	startNodeNextNode.nrOfConnections += 1
	startNode.nrOfConnections += 1
	startNodeNextNode.connectedNode1 = startNode
	startNode.connectedNode1 = startNodeNextNode
	
	#Connect end node to closest node
	var endNodeShortestPath
	endNodeShortestPath = aStar.calculatePath(map, endNode.node, goal_points[0].node)
	var endNodeNextNode = goal_points[0]
	for item in goal_points:
		var tempEndPath = aStar.calculatePath(map, endNode.node, item.node)
		if(tempEndPath.size() < endNodeShortestPath.size()):
			endNodeShortestPath = tempEndPath
			endNodeNextNode = item
	endNodeNextNode.nrOfConnections += 1
	endNode.nrOfConnections += 1
	endNodeNextNode.connectedNode1 = endNode
	endNode.connectedNode1 = endNodeNextNode
	
	
	#Pick shortest paths
	var selectedPaths = []
	var flag = false
	var found = false
	while(pathLength(startNode) < (goal_points.size() + 1)):
		for path in allPaths:
			found = false
			if(path.node1.nrOfConnections < 2 && path.node2.nrOfConnections < 2):
				if(isConnectedToNode(path.node1, startNode) || isConnectedToNode(path.node2, startNode)):
					if(isConnectedToNode(path.node1, endNode) || isConnectedToNode(path.node2, endNode)):
						flag = true
						if((pathLength(path.node1) + pathLength(path.node2)) >= goal_points.size() + 1):
							selectedPaths.append(path)
							allPaths.erase(path)
							found = true
							if(path.node1.connectedNode1 != null):
								path.node1.connectedNode2 = path.node2
							else:
								path.node1.connectedNode1 = path.node2
								
							if(path.node2.connectedNode1 != null):
								path.node2.connectedNode2 = path.node1
							else:
								path.node2.connectedNode1 = path.node1
							path.node1.nrOfConnections += 1
							path.node2.nrOfConnections += 1
				if(!flag):
					selectedPaths.append(path)
					allPaths.erase(path)
					found = true
					if(path.node1.connectedNode1 != null):
						path.node1.connectedNode2 = path.node2
					else:
						path.node1.connectedNode1 = path.node2
						
					if(path.node2.connectedNode1 != null):
						path.node2.connectedNode2 = path.node1
					else:
						path.node2.connectedNode1 = path.node1
					path.node1.nrOfConnections += 1
					path.node2.nrOfConnections += 1
				flag = false
			if(found):
				break
	
	var path = []
	
	for i in startNodeShortestPath.size() - 1:
		path.append(startNodeShortestPath[startNodeShortestPath.size() - 1 - i])
	
	for item in selectedPaths:
		for i in item.path.size() - 1:
			path.append(item.path[item.path.size() - 1 - i])
	
	
	for i in endNodeShortestPath.size() - 1:
		path.append(endNodeShortestPath[endNodeShortestPath.size() - 1 - i])
	
	return path