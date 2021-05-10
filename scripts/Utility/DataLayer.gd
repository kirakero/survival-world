extends Reference
class_name DataLayer

# The operational mode of the DataLayer and thus the current user's system
var mode = 0


var chunks = {}
var obchunks = {}
var objects = {}

var chunks_client = {}


var dirty_objects = []
var dirty_chunks = []

var pending_gameob: = []

var dirty_obchunks: QuadTree
var tick: int = 0

var config setget set_config


func add_mode(_mode):
	mode = mode | _mode

func set_config(value):
	config = value
	dirty_obchunks = QuadTree.new(config['world_size'] * -0.5, config['world_size'] * -0.5, config['world_size'])
	
# receive new objects
func receive(raw: Array, from: int):
	# ingest the data
	for item in raw:
		ingest_new( item, from )

# receive physics or other continuous data
func receive_partial(raw: Array, from: int):
	# ingest the data
	for item in raw:
		ingest_partial( item, from )

func ingest_new(data: Dictionary, from):
	# the server is not allowed to received chunks, so we know that the
	# client side chunks are dirty
	var id = data[ Def.ID ]
	if data[ Def.TX_TYPE ] == Def.TYPE_CHUNK:
		chunks_client[ id ] = data
		dirty_chunks.append( id )
		return
	data[ Def.TX_ID ] = id
	# the system expects this to be a brand new object...
	add( data )
	# dirty objects
	dirty_objects.append([ id, from ])

func ingest_partial(data: Dictionary, from):
	# the server is not allowed to received chunks, so we know that the
	# client side chunks are dirty
	# todo - since this is an update operation, we'd have to sort out the chunk
	# that might already be loaded...
	var id = data[ Def.ID ]
	if data[ Def.TX_TYPE ] == Def.TYPE_CHUNK:
		chunks_client[ id ] = data
		dirty_chunks.append( id )
		return
	data[ Def.TX_ID ] = id
	# the system expects this to be a brand new object...
	add( data )
	# dirty objects
	dirty_objects.append([ id, from ])

# when the server loads a chunk
func add_chunk(chunk: Chunk):
	chunks[ chunk.get_key() ] = chunk
	obchunks[ chunk.get_key() ] = ObChunk.new( chunk )
	obchunks[ chunk.get_key() ].load_all()

# object was created
# this would have come from an RPC reliable from the client, or created by
# an internal server process
func add(gameob: Dictionary):
	# validation
	assert(gameob.has( Def.TX_ID ))
	assert(not objects.has( gameob[ Def.TX_ID ] ))
	assert(gameob.has( Def.TX_TYPE ))
	assert(gameob.has( Def.TX_POSITION ))
	
	# determine the chunk key
	var pos_x: int = floor(gameob[ Def.TX_POSITION ].x / config['world_size']) * config['world_size']
	var pos_z: int = floor(gameob[ Def.TX_POSITION ].z / config['world_size']) * config['world_size']
	var key = Fun.make_chunk_key(pos_x, pos_z)
	if not chunks.has( key ):
		# try again later
		pending_gameob.append( gameob )
		return
	
	# finally, add it to the chunk and mark the obchunk as dirty
	obchunks[ key ].add( gameob )
	dirty_obchunks.operation(tick, pos_x, pos_z, config['world_size'])

func add_player(gameob: Dictionary):
	# validation
	assert(gameob.has( Def.TX_ID ))
	assert(not objects.has( gameob[ Def.TX_ID ] ))
	assert(gameob.has( Def.TX_POSITION ))
	
	gameob[ Def.TX_UPDATED_AT ] = ServerTime.now()
	gameob[ Def.TYPE ] = Def.TYPE_PLAYER
	gameob[ Def.QUAD ] = null
	
	objects[ gameob[Def.TX_ID] ] = gameob
	

func update(gameob: Dictionary):
	# validation
	assert(gameob.has( Def.TX_ID ))
	assert(gameob.has( Def.TX_POSITION ))
	assert(gameob.has( Def.TX_UPDATED_AT ))
		
	# data is partial but it will have an ID
	# make sure we dont process old data, and make sure we can update something
	if not objects.has( gameob[ Def.TX_ID ] ) || objects[ gameob[Def.TX_ID] ][ Def.TX_UPDATED_AT ] > gameob[ Def.TX_UPDATED_AT ]:
		return false
	
	gameob.erase( Def.TX_ID )
	gameob.erase( Def.TX_TYPE )
	
	var pos_x: int = floor(gameob[ Def.TX_POSITION ].x / config['world_size']) * config['world_size']
	var pos_z: int = floor(gameob[ Def.TX_POSITION ].z / config['world_size']) * config['world_size']
	var chunk_key = Fun.make_chunk_key(pos_x, pos_z)
	
	# write the new values
	for k in gameob.keys():
		objects[ gameob[Def.TX_ID] ][ k ] = gameob[ k ]
	
	# the object has moved into another chunk
	if chunk_key != objects[ gameob[Def.TX_ID] ][ Def.QUAD ]:
		# this is a special case for putting players into the chunks
		if objects[ gameob[Def.TX_ID] ].has( Def.QUAD ):
			chunks[ objects[ gameob[Def.TX_ID] ][ Def.QUAD ] ].exit( gameob[Def.TX_ID] )
			chunks[ chunk_key ].enter( gameob[Def.TX_ID] )
		objects[ gameob[Def.TX_ID] ][ Def.QUAD ] = chunk_key
		chunks[ chunk_key ].update( objects[ gameob[Def.TX_ID] ], true )
	else:
		chunks[ chunk_key ].update( objects[ gameob[Def.TX_ID] ], false )
	
	dirty_obchunks.operation(tick, pos_x, pos_z, config['world_size'])
	
	
func serialized(id):
	var gameob = Global.DATA.objects[ id ].duplicate()
	gameob.erase( Def.QUAD )
	gameob.erase( Def.QUAD_INDEX )
	return gameob
		
func serialized_partial(id):
	# todo return only the physics fields
	var gameob = Global.DATA.objects[ id ].duplicate()
	gameob.erase( Def.QUAD )
	gameob.erase( Def.QUAD_INDEX )
	gameob.erase( Def.TX_TYPE )
	gameob.erase( Def.TX_SUBTYPE )
	return gameob	
