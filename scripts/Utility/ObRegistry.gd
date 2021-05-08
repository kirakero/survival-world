extends Reference


var chunks = {}
var obchunks = {}
var objects = {}
var chunk_size = 64

func _init(_chunk_size):
	chunk_size = _chunk_size

func add_chunk(chunk: Chunk):
	chunks[ chunk.get_key() ] = chunk
	obchunks[ chunk.get_key() ] = ObChunk.new( chunk )
	obchunks[ chunk.get_key() ].registry = self
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
	var pos_x: int = floor(gameob[ Def.TX_POSITION ].x / chunk_size) * chunk_size
	var pos_z: int = floor(gameob[ Def.TX_POSITION ].z / chunk_size) * chunk_size
	var key = Fun.make_chunk_key(pos_x, pos_z)
	if not chunks.has( key ):
		print ('Warning: tried to add gameob to unloaded chunk')
		return
	
	# finally, add it to the chunk
	obchunks[ key ].add( gameob )
	

func update(id, changes: Dictionary):
	
	
	pass
