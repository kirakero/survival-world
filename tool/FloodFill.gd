extends Node


func _flood_fill_array(bytearray, mask, origin, low, high, width, height, spacing = 1) -> Array:
	print ('_flood_fill_array params', [origin, low, high, width, height, spacing])
	var array := []
	
	
	
	var stack := [origin]
	var DIRECTIONS = [
		Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT
	]
	
	
	while not stack.empty():
		var current = stack.pop_back()
		array.append(current)
		
		for direction in DIRECTIONS:
			var coordinates = current + direction * spacing
			
			
			if coordinates in array:
				continue
			if coordinates.x < 0 or coordinates.x > width - 1 or coordinates.y < 0 or coordinates.y > height - 1:
				continue
			
			var p = (coordinates.x) + (coordinates.y) * width
			
			if bytearray[p] < low or bytearray[p] > high or mask[p] > 0:
				continue

			stack.append(coordinates)
			if (stack.size() > 10):
				print ('over 1000 oh noes')
			
	return [array, mask]

func _flood_fill_pba(bytearray, origin, low, high, width, height, spacing = 1) -> PoolByteArray:
	var pba = PoolByteArray()
	pba.resize(bytearray.size())
	for coord in _flood_fill_array(bytearray, origin, low, high, width, height, spacing):
		var p = (coord.x) + (coord.y) * width
		pba[p] = 1
	return pba
