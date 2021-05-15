extends Reference

var queued = []
var mutex: Mutex

var threads = []

func _init():
	mutex = Mutex.new()
	threads = [ Thread.new(), Thread.new(), ]
	
func queue( pos_x, pos_z ):
	mutex.lock()
	queued.append( Vector2( pos_x, pos_z ) )
	mutex.unlock()

var counter = 0.0
func run(delta):
	counter = counter + delta
	if counter < 0.1:
		return
	counter = 0.0
	
	mutex.lock()
	if queued.size() > 0 and threads.size() > 0:
		var next = queued.pop_front()
		var thread = threads.pop_front()
		thread.start(self, "load_chunk", [next, thread])
	mutex.unlock()

func load_chunk(_data):
	var pos = _data[0]
	var key = Fun.make_chunk_key( pos.x, pos.y )
	var thread = _data[1]
	
	var res = Global.DATA.world_provider._chunk_get( pos )
	# this is the object that can be transmitted to connected peers
	# register the basic object using the server route that syncs
	Global.SRV.add_gameob(res, -1, pos.x, pos.y)
	
	# load the server version of the chunk data
	Global.SRV.chunks[ key ].set_ChunkData( res )
	Global.SRV.chunks[ key ].load_all()
	
	call_deferred('load_done', _data[0], thread)

func load_done(key, thread):
	thread.wait_to_finish()
	mutex.lock()
	threads.append(thread)
	mutex.unlock()
		
	
	
