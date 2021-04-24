extends Node

var format

func _init(_format: int = -1):
	format = _format
	
# take the result, which is type Dictionary, extract the Image from data,
# and store it in args['data'], which is type ImageData
func run(args: Dictionary, result, _coordinator) -> Dictionary:		
	print('IslandRender: start with args ', args.keys())
	var points: Array = args['points']
	var extents: Rect2 = args['extents']
	
	var simplex = OpenSimplexNoise.new()
	simplex.seed = args['seed']
	simplex.octaves = 5
	simplex.period = 6
	
	var mask = PoolByteArray()
	mask = resize_and_fill(mask, int(extents.size.x) * int(extents.size.y), 0)

	for x in range(0, extents.size.x, 1):
		for y in range(0, extents.size.y, 1):

			var closest_c = null
			var closest = INF
			var w_point = Vector2(x,y) + extents.position
			for point in points:
				if not point[1]:
					continue
				var d = w_point.distance_to(point[0])
				# radius is the original radius of the poisson sample
				# here we can adjust it to be more or less island like

				var radius = point[1] * (1.0 + point[2])
				if d - radius < 0 and d < closest:
					closest = d
					closest_c = point

			if closest_c:
				if not closest_c[1]:
					continue

				# 1 is high, 0 is low
				var noise = (simplex.get_noise_2d(w_point.x, w_point.y) + 1) * 0.45
				assert (noise >= 0 and noise <= 1)
				# 1 is on the point, 0 is off point
				var closeness = 1.0 - closest / (closest_c[1] * (1.0 + closest_c[2])) 
				var base_height = 1
				base_height = ease(closeness, float(closest_c[3]))

				assert (closeness >= 0 and closeness <= 1)

				var height = max(noise * (1.0 + closeness), base_height)
				if height < 0.5:
					continue
				var p = x + y * extents.size.x
				mask[p] = 255

	return {"mask": mask, "_key": args['_key']}

func vector2key(key_vector: Vector2):
	return str(int(key_vector.x),',',int(key_vector.y))
	
func resize_and_fill(pool, size:int, value=0):
	if size < 1:
		return null
	pool.resize(1)
	pool[0]=value
	while pool.size() << 1 <= size:
		pool.append_array(pool)
	if pool.size() < size:
		pool.append_array(pool.subarray(0,size-pool.size()-1))
	return pool

