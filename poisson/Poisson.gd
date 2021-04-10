extends Node2D
class_name Poisson
# Based on the following with transcode and several modifications 
# from https://github.com/SebLague/Poisson-Disc-Sampling

#var run = false
#
#func _process(delta):
#	if run:
#		return
#	run = true
#	var data = PoolByteArray()
#	var testsize = 128
#	data.resize(testsize * testsize * 4)
#	for i in data.size():
#		data[i] = 0
#	for point in GeneratePoints(5.0, Vector2(testsize, testsize)):
#		var p = floor(floor(point.x) * 4 + floor(point.y) * 4 * testsize)
#		data[p] = 255
#		data[p+1] = 255
#		data[p+2] = 255
#		data[p+3] = 255
#
#	var img = Image.new()
#	img.create_from_data(testsize, testsize, false, Image.FORMAT_RGBA8, data)
#	var tex = ImageTexture.new()
#	tex.create_from_image(img, 0)
#
#
#	$Sprite.set_texture(tex)
#
#	pass # Replace with function body.


func GeneratePoints(rngseed: int, radius: float, sampleRegionSize: Vector2, numSamplesBeforeRejection: int = 20) -> PoolVector2Array:
	var rng = RandomNumberGenerator.new()
	rng.seed = rngseed
	var cellSize: float = radius / sqrt(2)
	var grid = []
	var grid_dim: Vector2 = sampleRegionSize / cellSize
	grid_dim.x = ceil(grid_dim.x)
	grid_dim.y = ceil(grid_dim.y)
#	print (grid_dim)
	grid.resize( grid_dim.x * grid_dim.y )
	print (grid.size())
	var points = PoolVector2Array()
	var spawnPoints = PoolVector2Array()

	spawnPoints.append(sampleRegionSize/2)
	var iter = 0
	while (spawnPoints.size() > 0):
		iter = iter + 1
		var spawnIndex = rng.randi_range(0, spawnPoints.size() - 1)
#		print(spawnPoints)
		var spawnCentre = spawnPoints[spawnIndex]
		var candidateAccepted = false

		for i in range(numSamplesBeforeRejection):
			var angle = rng.randf() * PI * 2;
			var dir = Vector2(sin(angle), cos(angle));
			var candidate = spawnCentre + dir * rng.randf_range(radius, 2.0 * radius);
			if IsValid(candidate, sampleRegionSize, cellSize, radius, points, grid, grid_dim):
				var p = vector2key(candidate, grid_dim, cellSize)
				if p >= grid.size():
					print(['+G',candidate, p , cellSize, floor(candidate.x/cellSize) , floor(candidate.y/cellSize), floor(candidate.y/cellSize) * grid_dim.y, grid_dim.y])
					return points
					break
				points.append(candidate)
				spawnPoints.append(candidate)
				
			
				grid[p] = points.size();
#				print(grid)
				candidateAccepted = true
#				if int(candidate.x) == 1:
#				print ( candidate , ' add ')
				break
		if !candidateAccepted:
			spawnPoints.remove(spawnIndex)
		
#		if iter > 1000:
#			return points
		
	return points

func offsetVector2Array(points: Array, offset: Vector2) -> Array :
	for k in points.size():
		points[k-1] = points[k-1] + offset
	return points

func vector2key(point, grid_dim, cellSize):
	return floor(point.x/cellSize) + floor(point.y/cellSize) * grid_dim.y

func IsValid(candidate: Vector2, sampleRegionSize: Vector2, cellSize: float, radius: float, points: PoolVector2Array, grid: PoolIntArray, grid_dim: Vector2) -> bool:
	if candidate.x < 0 || candidate.x > sampleRegionSize.x - 1 || candidate.y < 0 || candidate.y > sampleRegionSize.y - 1:
		return false
		
	var cellX = floor(candidate.x)
	var cellY = floor(candidate.y)
	var searchStartX = max(0,cellX - cellSize * 2.0)
	var searchEndX = min(cellX + cellSize * 2.0, int(grid_dim.x) - 1.0)
	var searchStartY = max(0,cellY - cellSize * 2.0)
	var searchEndY = min(cellY + cellSize * 2.0, int(grid_dim.y) - 1.0)

	var logall  =[]
#	print ({'cellx':cellX, 'celly':cellY, 'startx':searchStartX,'endx':searchEndX,'starty':searchStartY,'endy':searchEndY,'cellsize':cellSize})
	var maxiter = 16
	for x in range(searchStartX, searchEndX, cellSize):
		for y in range(searchStartY, searchEndY, cellSize):
			maxiter = maxiter - 1
			if maxiter < 0:
				print (['bad iter', searchStartX, searchEndX, searchStartY, searchEndY])
				return false
			var g = vector2key(Vector2(x, y), grid_dim, cellSize)
			var p = grid[g] - 1
			if p != -1:
				var sqrDst = (candidate - points[p]).length_squared()
				if sqrDst < radius*radius:
#					logall.append([ 'too close', candidate, points[p], x, y, (candidate - points[p]).length_squared()])
					return false
#				else:
##					logall.append([ candidate, points[p], x, y, (candidate - points[p]).length_squared()])
#			else:
#				logall.append([ 'P!', g, x, y ])
#	print('adding---')
#	for l in logall:
##		print('  ', l)
	return true
	

