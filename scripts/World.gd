extends Spatial

var chunk_size = 64
var chunk_amount = 8
var load_amount = 8

var noise
var chunks = {}
var unready_chunks = []
var will_load_chunks = []
var threads: = []
var thread_count = 3
var processing = false
var mutex: Mutex
var loaded = false 

signal world_loaded

func _ready():	
	noise = OpenSimplexNoise.new()
	noise.seed = 2
	noise.octaves = 6
	noise.period = 240
	for i in range(thread_count):
		threads.append(Thread.new())

	chunk_size = Global.config.chunk_size
	mutex = Mutex.new()

func load_chunk(array):
	var thread = array[0]
	var x = array[1]
	var z = array[2]
	var data = array[3]
	
	var chunk = MeshChunk.new(noise, data, x * chunk_size, z * chunk_size, chunk_size)
	chunk.translation = Vector3(x * chunk_size, 0, z * chunk_size)

func load_done(_thread):
	_thread.wait_to_finish()
	mutex.lock()
	threads.append(_thread)
	mutex.lock()
	processing = false
	var player_translation = $Player.translation
	var p_x = int(player_translation.x) / chunk_size
	var p_z = int(player_translation.z) / chunk_size

func _process(delta):
	update_chunks()
	clean_up_chunks()
	reset_chunks()
	
func update_chunks():
	var player_translation = $Player.translation
	var p_x = int(player_translation.x) / chunk_size
	var p_z = int(player_translation.z) / chunk_size
	
	for x in range(p_x - chunk_amount * 0.5, p_x + chunk_amount * 0.5):
		for z in range(p_z - chunk_amount * 0.5, p_z + chunk_amount * 0.5):
			var key = str(x) + "," + str(z)
			var v = Vector2(x * chunk_size, z * chunk_size)
			var chunk = chunks.get(key)
			if chunks.has(key):
				chunk.should_remove = false
			elif not unready_chunks.has(v):
				unready_chunks.append(v) 
				will_load_chunks.append(v) 
	
	# determine if the player can load safely
	# and we are 'good enough'
	var key = str(p_x) + "," + str(p_z)
	if not loaded and chunks.size() == chunk_amount * chunk_amount and unready_chunks.size() == 0:
		loaded = true
		$Player.physics_active = true
		emit_signal('world_loaded')
		
	if will_load_chunks.size() > 0:
		mutex.lock()
		var _thread = threads.pop_back()
		if _thread != null:
			var _will_load = will_load_chunks.pop_back()
			call_deferred("thread_chunks", [_will_load], _thread)	
		mutex.unlock()

func thread_chunks( to_process, the_thread ):
	the_thread.start(self, "load_chunks", [to_process, the_thread])
	
func load_chunks( _data ):
	var to_process = _data[0]
	var _thread = _data[1]
	Global.api.async_multichunk_get( to_process )
	var results = yield(Global.api, "multichunk_get_done")

	for wanted_chunk in to_process:
		
		var uncompressed = PoolByteArray()
		for result in results['data']['data']:
			if to_process.has(wanted_chunk) && int(result.pos_x)  == wanted_chunk.x and int(result.pos_y) == wanted_chunk.y:
				uncompressed = result.chunk.decompress(pow(chunk_size + 2, 2) * 4)
		
		var chunk = MeshChunk.new(noise, uncompressed, wanted_chunk.x / chunk_size, wanted_chunk.y / chunk_size, chunk_size)
		chunk.translation = Vector3(chunk.x * chunk_size, 0, chunk.z * chunk_size)
		call('add_mesh', chunk, wanted_chunk)
			
			
	call_deferred("load_done", _thread)
	
func add_mesh(chunk, wanted_chunk):
	mutex.lock()
	add_child(chunk)
	var key = str(wanted_chunk.x / chunk_size) + "," + str(wanted_chunk.y / chunk_size)
	chunks[key] = chunk
	unready_chunks.erase(wanted_chunk)
	mutex.unlock()
	
func clean_up_chunks():
	for key in chunks:
		var chunk = chunks[key]
		if chunk.should_remove and chunk.translation.distance_to($Player.translation) > load_amount * 0.75 * chunk_size:
			chunk.queue_free()
			chunks.erase(key)
	
func reset_chunks():
	for key in chunks:
		chunks[key].should_remove = true
	
	
	
