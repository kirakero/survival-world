extends Reference
class_name ObChunk

var chunk: Chunk
var chunk_key
var my_objects: = []
var ghosts: = {}
var registry setget set_registry

func _init(_chunk):
	chunk = _chunk
	chunk_key = chunk.get_key()

func set_registry(value):
	registry = value

# load the 'default' objects from the chunk raw data
func load_all():
	for obj in range(0, chunk.obdata.size(), 4):
		var pos = Vector3.ZERO
		pos.x = chunk.obdata[obj + 0] / chunk.chunk_size
		pos.z = chunk.obdata[obj + 1] / chunk.chunk_size
		pos.y = chunk.height_from_local( pos )
		pos = pos + chunk.world_position
		
		# note: this is the same format as from gameob.gd at wake()
		var id = Uuid.v4()
		var local_index = my_objects.size()
		
		# add the object to the register and track it
		add({
			Def.TX_ID: Uuid.v4(),
			Def.TX_TYPE: Def.TYPE_RESOURCE,
			Def.TX_POSITION: pos, 
			Def.TX_ROTATION: Vector3(0, random_from_vector2(Vector2(pos.x, pos.y), 360.0), 0),
			Def.TX_SUBTYPE: chunk.obdata[obj + 2],
			Def.TX_ORIGIN: Def.ORIGIN_BASEMAP,
		})
		
	# load the stored objects from the database
	for object in Api.provider._gameob_get(chunk.position):
		add(object)
		

func add(gameob: Dictionary):
	var local_index = my_objects.size()
	gameob[ Def.TX_UPDATED_AT ] = ServerTime.now()
	gameob[ Def.QUAD ] = chunk_key
	gameob[ Def.QUAD_INDEX ] = local_index
	registry.objects[ gameob[Def.TX_ID] ] = gameob
	my_objects.append( registry.objects[ gameob[Def.TX_ID] ] )
	
# game object has entered the zone
# this happens before the object is actually updated
# call the ghostbusters
func enter(gameob: Dictionary):
	if ghosts.has( gameob[ Def.TX_ID ] ):
		my_objects[ ghosts[ gameob[ Def.TX_ID ] ]] = null
		ghosts.erase( gameob[ Def.TX_ID ] )

# game object has left the zone
# this happens before the object is actually updated
# add a ghost
func exit(gameob: Dictionary):
	ghosts[ gameob[ Def.TX_ID ] ] = my_objects.size()
	my_objects.append({
		Def.TX_ID: gameob[ Def.TX_ID ],
		Def.TX_TYPE: Def.TYPE_GHOST,
		Def.TX_POSITION: chunk.world_position, 
		Def.TX_UPDATED_AT: ServerTime.now(),
	})



# returns the objects ready to be send to client
func serialize(until = 0):
	var i = my_objects.size()
	var out
	while (i > 0):
		i = i - 1
		var cur_key = my_objects[i]
		# the key was nullified (due to an object change)
		if cur_key == null:
			continue
		var gameob: Dictionary
		if typeof(cur_key) == TYPE_DICTIONARY:
			# its a local friendly ghost
			gameob = cur_key
		else:
			gameob = registry.objects[ cur_key ].duplicate()
		# we've hit the point where objects no longer need to be synced
		if gameob[ Def.TX_UPDATED_AT ] < until:
			break
		gameob.erase( Def.QUAD )
		gameob.erase( Def.QUAD_INDEX )
		out.append( gameob )
		
		
static func random_from_vector2(st: Vector2, mult = 1.0):
	var a = sin(st.dot(Vector2(12.9898,78.233)))*43758.5453123
	return (a - int(a)) * mult

