extends Node

var format

func _init(_format: int = -1):
	format = _format
	
# take the result, which is type Dictionary, extract the Image from data,
# and store it in args['data'], which is type ImageData
func run(args: Dictionary, result, _coordinator) -> Dictionary:		
	var rng = RandomNumberGenerator.new()
	rng.seed = args['seed']
	var center = args['poisson/size_v2'] * 0.5
	var margin = ceil(args['poisson/basic_size_v2'])
	var matched = args['indexed']
	
	var islands = []
	
	for group in matched.keys():
		var points_index = []
		# Determine center of the island
		var all_points = Vector2.ZERO
		for point in matched[group]:
			all_points = all_points + point[0]

		all_points = all_points / matched[group].size()

		# Determine extents and assemble the preprocessing point data
		var extent_low = Vector2(INF, INF)
		var extent_high = Vector2.ZERO
		for point in matched[group]:
			var r = rng.randf_range(1.0, 3.5)
			point[0] = point[0].move_toward(all_points,  point[0].distance_to(all_points) * 0.35)
			point[0].x = int(point[0].x)
			point[0].y = int(point[0].y)
#			point[1] = 6 - r #todo change me
			points_index.append(point)
			if point[0].x < extent_low.x:
				extent_low.x = point[0].x
			if point[0].y < extent_low.y:
				extent_low.y = point[0].y

			if point[0].x > extent_high.x:
				extent_high.x = point[0].x
			if point[0].y > extent_high.y:
				extent_high.y = point[0].y

		var extent = Rect2(int(extent_low.x), int(extent_low.y), 0, 0)
		extent.end = Vector2(int(extent_high.x), int(extent_high.y))
		extent = extent.grow(margin)

#		# island spacing
#		var dir = (extent.position + extent.size * 0.5) - center
#		var mag = abs(dir.distance_to(Vector2.ZERO) / center.distance_to(Vector2.ZERO) * spread)
#		dir = dir.normalized()
#		extent.position = extent.position + dir * mag
#		print(['modify', extent.position + extent.size * 0.5, dir, mag])
#		extent.position = Vector2(int(extent.position.x), int(extent.position.y))

		islands.append({
			'points': points_index,
			'extents': extent,
		})

	return {
		'islands': islands
	}

func vector2key(key_vector: Vector2):
	return str(int(key_vector.x),',',int(key_vector.y))
