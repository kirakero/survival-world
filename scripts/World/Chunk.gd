extends Reference
class_name Chunk

var position: Vector2
var data: PoolByteArray
var obdata: PoolByteArray
var chunk_size: int
var heights: = []
var world_position
var container

var my_objects: = []
var ghosts: = {}
var chunk_key
var fully_loaded = false

var allow_update = [ Def.TX_POSITION ]

func _init(_position: Vector2, _container):
	position = _position
	container = _container
	chunk_key = Fun.make_chunk_key(position.x, position.y)
	world_position = Vector3(position.x, 0, position.y)
	chunk_size = Global.DATA.config['chunk_size']

func set_ChunkData( gameob: Dictionary ):
	# load the heightmap and any default objects into the chunk
	var uncompressed = gameob[Def.TX_CHUNK_DATA]
	if uncompressed.size() > 0:
		uncompressed = gameob[Def.TX_CHUNK_DATA].decompress(pow(Global.DATA.config['chunk_size'] + 2, 2) * 4)
		
	data = uncompressed
	obdata = gameob[Def.TX_OBJECT_DATA]
	
	generate_heights()

func get_ChunkMesh():
	# todo clean this up when cyclic errors are a thing of the past
	var cm = preload("res://scripts/World/ChunkMesh.gd").new()
	cm.chunk_basic = self
	return cm

func get_key():
	return '%s,%s' % [position.x, position.y]

static func bytes2height(pixel_high, pixel_low):
	return ((((pixel_high & 0xff) << 8) | (pixel_low & 0xff))  - 65534/2) * 0.25

static func height2bytes(height):
	height = int(height * 4.0) + 65534/2
	var high = ((height >> 8) & 0xff)
	var low = height & 0xff
	return [high, low]

func height_from_local(position: Vector3):
	return _get_height_from_rounded( int(position.x), int(position.z) ) #todo interpolate

func _get_height_from_rounded(pos_x: int, pos_y: int):
	var i = (pos_x + 1) + (pos_y + 1 * (chunk_size + 2))
	if heights.size() > i:
		return heights[i]
	return 0

func generate_heights():
	var _heights = []
	var _ch_half = Vector3(chunk_size * 0.5, 0, chunk_size * 0.5)
	for _z in range(0, chunk_size + 2):
		for _x in range(0, chunk_size + 2):
			var pixel = (_x * 4) + (_z * (chunk_size + 2) * 4)
			var nh = -0.5
			if pixel < data.size():
				if data[pixel] == 255:
					nh = 1
#				nh = bytes2height(data[pixel], data[pixel + 1])
#				assert(data[pixel] != 0)
### removed -1 from being added to _x and _z
			_heights.append(Vector3(_x, nh,_z) - _ch_half)
	
	heights = _heights

### from ObChunk

# load the 'default' objects from the chunk raw data
func load_all():
	for obj in range(0, obdata.size(), 4):
		var pos = Vector3.ZERO
		pos.x = obdata[obj + 0] / chunk_size
		pos.z = obdata[obj + 1] / chunk_size
		pos.y = height_from_local( pos )
		pos = pos + world_position
		
		# note: this is the same format as from gameob.gd at wake()
		var id = Uuid.v4()
		var local_index = my_objects.size()
		
		# add the object to the register and track it
		add({
			Def.TX_ID: Uuid.v4(),
			Def.TX_TYPE: Def.TYPE_RESOURCE,
			Def.TX_POSITION: pos, 
			Def.TX_ROTATION: Vector3(0, random_from_vector2(Vector2(pos.x, pos.y), 360.0), 0),
			Def.TX_SUBTYPE: obdata[obj + 2],
			Def.TX_ORIGIN: Def.ORIGIN_BASEMAP,
		})
	
	fully_loaded = true
	# load the stored objects from the database
#	for object in Api.provider._gameob_get(chunk.position):
#		add(object)
		

func add(gameob: Dictionary):
	var local_index = my_objects.size()
	gameob[ Def.TX_UPDATED_AT ] = ServerTime.now()
	gameob[ Def.TX_CREATED_AT ] = ServerTime.now()
	gameob[ Def.QUAD ] = chunk_key
	gameob[ Def.QUAD_INDEX ] = local_index
	container.objects[ gameob[Def.TX_ID] ] = gameob
	my_objects.append( gameob[Def.TX_ID] )
	print ( 'CHUNK ADD ', gameob[Def.TX_ID], ' to ', chunk_key, '@', local_index)
	
func update(gameob: Dictionary, is_entering):
	for k in gameob.keys():
		if allow_update.has(k):
			container.objects[ gameob[ Def.TX_ID ] ][ k ] = gameob[ k ]

	if my_objects.has( gameob[ Def.TX_ID ] ):
		my_objects.erase( gameob[ Def.TX_ID ] )
	my_objects.append( gameob[ Def.TX_ID ] )

	container.objects[ gameob[ Def.TX_ID ] ][ Def.QUAD ] = chunk_key
	container.objects[ gameob[ Def.TX_ID ] ][ Def.TX_UPDATED_AT ] = ServerTime.now()
	
# client side remove
func remove(gameob: Dictionary):
	if my_objects.has( gameob[ Def.TX_ID ] ):
		my_objects.erase( gameob[ Def.TX_ID ] )
	
# game object has entered the zone
# call the ghostbusters
func enter( id ):
	var g_id = "ghost/%s" % id
	if my_objects.has( g_id ):
		my_objects.erase( g_id )

# game object has left the zone
# add a ghost
func exit( id ):
	var g_id = "ghost/%s" % id
	add({
		Def.TX_ID: g_id,
		Def.TX_TYPE: Def.TYPE_GHOST,
		Def.TX_POSITION: world_position, 
		Def.TX_UPDATED_AT: ServerTime.now(),
	})



# returns the objects ready to be send to client
func serialize(until = 0, exclude = ''):
	var i = my_objects.size()
	var out
	while (i > 0):
		i = i - 1
		var cur_key = my_objects[i]
		# the key was nullified (due to an object change)
		if cur_key == null:
			continue
		var gameob: Dictionary

		gameob = container.objects[ cur_key ].duplicate()
		# exclude allows the most efficient filtering of objects that should
		# not be sent to the user transmitting their physics to the server
		if gameob[ Def.TX_FOCUS ] == exclude:
			continue
		# we've hit the point where objects no longer need to be synced
		if gameob[ Def.TX_UPDATED_AT ] < until:
			break
		gameob.erase( Def.QUAD )
		gameob.erase( Def.QUAD_INDEX )
		out.append( gameob )

# returns the objects ready to be send to client
func bifurcated_delta(since, exclude):
	var i = my_objects.size()
	var txr = []
	var txp = []
	var last = container.objects[ my_objects[ my_objects.size() - 1] ] [ Def.TX_UPDATED_AT ] 
	while (i > 0):
		i = i - 1
		var cur_key = my_objects[i]
		# the key was nullified (due to an object change)
		if cur_key == null:
			continue
		var gameob: Dictionary
		gameob = container.objects[ cur_key ].duplicate(true)
		# exclude allows the most efficient filtering of objects that should
		# not be sent to the user transmitting their physics to the server
		if gameob.has( Def.TX_FOCUS ) and gameob[ Def.TX_FOCUS ] == exclude:
			continue
		# we've hit the point where objects no longer need to be synced
		if gameob[ Def.TX_UPDATED_AT ] < since:
			break

		gameob.erase( Def.QUAD )
		gameob.erase( Def.QUAD_INDEX )
		
		if gameob[ Def.TX_CREATED_AT ] >= since:
			# this object was created after our most recent query
			# it needs to be sent with reliable
			txr.append( gameob )
		else:
			# this is a physics update so we can send unreliable
			txp.append( gameob )
	
#	print ('bifur since ', since ,': ' , { 'txr': txr, 'txp': txp } )
	return { 'txr': txr, 'txp': txp, 'last': last }
		
static func random_from_vector2(st: Vector2, mult = 1.0):
	var a = sin(st.dot(Vector2(12.9898,78.233)))*43758.5453123
	return (a - int(a)) * mult


