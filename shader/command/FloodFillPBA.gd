extends Node
	
func run(pag, args: Dictionary):
	# required
	var origin: Vector2 = args['origin']
	
	# optional
	var value = null
	var low = 0
	var high = 255
	var spacing = 1
	
	if args.has('value'):
		value = args['value']
	if args.has('low'):
		low = args['low']	
	if args.has('high'):
		high = args['high']
	if args.has('spacing'):
		spacing = args['spacing']
	
	var array := []
	var stack := [origin]
	var DIRECTIONS = [
		Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT
	]
	
	while not stack.empty():
		var current = stack.pop_back()
		array.append(current)
		if value:
			pag.writev(current, value)
		for direction in DIRECTIONS:
			var coordinates = current + direction * spacing
			if coordinates in array || not pag.hasv(coordinates):
				continue
			
			var val = pag.readv(coordinates)
			
			if val < low or val > high:
				continue

			stack.append(coordinates)
			
	return pag
