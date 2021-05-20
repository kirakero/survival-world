extends Spatial

var mesh_instance
var x
var z
var data: PoolByteArray
var chunk_size
var should_remove = true 
var chunk_basic setget set_chunkbasic
var load_queue = []
var loading_queue = []
var loaded = []
var loaded_time = 0
var lod = 3
var lods = [64, 96, 320, 1024]
var trans_lod = null
var counter = 0.0
var processing = false
var objects
var load_mutex
var will_draw = [ Def.TYPE_RESOURCE, Def.TYPE_PLAYER ]
func _init():
	load_mutex = Mutex.new()
	pass
	

func _ready():
	
	pass


func _physics_process(delta):
	counter += delta
	if counter > 0.1 and not processing:
		counter = 0
		processing = true
		# LOD
		var distance = (Global.CLI.player.translation * Vector3(1,0,1) ).distance_to( translation )
		var new_lod = 0
		while( distance > lods[new_lod] ):
			new_lod += 1
		var trans_lod = lod
		if (new_lod != lod):
			var amount = new_lod - lod
			amount = amount / abs(amount) #normalize
			trans_lod += amount
		
		call_deferred("lod_%s" % trans_lod)		

func queue_new_objects():
	var recent_time = Global.CLI.objects[ Global.CLI.chunks[ chunk_basic.chunk_key ].my_objects[ \
			Global.CLI.chunks[ chunk_basic.chunk_key ].my_objects.size() - 1 \
		] ][ Def.TX_UPDATED_AT ]
	if loaded_time == recent_time:
			return
			
	var objects: Array = Global.CLI.chunks[ chunk_basic.chunk_key ].my_objects.duplicate()
	var orig_loaded_time = loaded_time
	loaded_time = recent_time
	while (objects.size()):
		var ob = objects.pop_back()
		if will_draw.has(Global.CLI.objects[ ob ][ Def.TX_TYPE ]) \
		and orig_loaded_time < Global.CLI.objects[ ob ][ Def.TX_UPDATED_AT ] \
		and str(ob) != str(Global.NET.my_id) \
		and not load_queue.has( ob ) \
		and not loading_queue.has( ob ) \
		and not loaded.has( ob ):
			Global.CLI._debug('%s will spawn %s' % [name, ob])
			load_queue.append( ob )
		else:
			print(load_queue.has( ob ) , loading_queue.has( ob ) , loaded.has( ob ) )
			Global.CLI._debug('%s NO SPAWN %s' % [name, ob])
		

# Entering these functions does not imply lod = lod_?
func lod_0():
	if lod == 0:
		process_load_queue()
		
		queue_new_objects()
	else:
		print ("%s lod 1 >> 0" % chunk_basic.chunk_key)
	lod = 0
	processing = false

func lod_1():
	if lod == 0:
		print ("%s lod 0 >> 1" % chunk_basic.chunk_key)
		# for now nothing
		pass
		
	elif lod == 1:
		# process the queue
		process_load_queue()
		
		# check to see if we have new stuffs
		queue_new_objects()
	elif lod == 2:
		# load all the stuff
		print ("%s lod 2 >> 1" % chunk_basic.chunk_key)
		# check to see if we have new stuffs
		queue_new_objects()
#		var objects = Global.CLI.chunks[ chunk_basic.chunk_key ].my_objects.duplicate()
#		for ob in objects:
#			Global.CLI._debug('spawn check %s' % ob)
#			if Global.CLI.objects[ ob ][ Def.TX_TYPE ] == Def.TYPE_RESOURCE \
#			or Global.CLI.objects[ ob ][ Def.TX_TYPE ] == Def.TYPE_PLAYER \
#			and ob != Global.NET.my_id \
#			and not load_queue.has( ob ) and not loading_queue.has( ob ):
#				Global.CLI._debug('%s will spawn %s' % [name, ob])
#				load_queue.append( ob )
#			else:
#				Global.CLI._debug('%s NO SPAWN %s' % [name, ob])
#			loaded_time = Global.CLI.objects[ ob ][ Def.TX_UPDATED_AT ]
	
	lod = 1
	processing = false

func lod_2():
	if lod == 1:
		# we need to remove all loaded game objects
		print ("%s lod 1 >> 2" % chunk_basic.chunk_key)
		if objects:
			remove_objects()
			add_object_container()
	
	elif lod == 3:
		print ("%s lod 3 >> 2" % chunk_basic.chunk_key)
		# we are entering LOD 2 for the first time
		if not objects:
			add_object_container()
	
	lod = 2
	processing = false
	
	
func lod_3():	
	# unload all
	print ('unloading %s' % chunk_basic.chunk_key)
	Global.CLI.loaded_ref.erase( chunk_basic.chunk_key )
	Global.CLI.loaded_chunks.erase( chunk_basic.chunk_key )
	queue_free()

func process_load_queue():
	if load_queue.size() == 0 or Global.CLI.chunk_threads.size() == 0:
		return
	
	if name =='@@201':
		print ('-===== start')
		print (loading_queue, load_queue, loaded)
		print ('-=====-')
	Global.CLI.chunk_mutex.lock()
	load_mutex.lock()
	var id = load_queue.pop_back()
	loading_queue.append( id )
	load_mutex.unlock()
	var thread: Thread = Global.CLI.chunk_threads.pop_back()
	Global.CLI.chunk_mutex.unlock()
	thread.start(self, "load_gameob", [id, thread])

func add_object_container():
	objects = Spatial.new()
	add_child(objects)

func remove_objects():
	if objects:
		print('empty ', name)
		objects.queue_free()
		load_mutex.lock()
		load_queue = []
		loading_queue = []
		loaded_time = 0
		loaded = []
		load_mutex.unlock()
		objects = null
		
func load_gameob(_data):
	var id = _data[0]
	var thread = _data[1]
	if lod > 1:
		# we interrupt loading because the LOD is not in a good state
		call_deferred('load_done', thread, null)
		return	
	var obj
	match Global.CLI.objects[ id ][ Def.TX_TYPE ]:
		Def.TYPE_RESOURCE:
			obj = preload("res://assets/tree.tscn").instance()
			obj.init( id, self )
		Def.TYPE_PLAYER:
			obj = preload("res://assets/OtherPlayer.tscn").instance()
			obj.name = str('p',id)
			obj.init( id, self )
			
	call_deferred('load_done', thread, [id, obj])

func load_done(thread, data):
	var id = data[0]
	var obj = data[1]
	thread.wait_to_finish()
	Global.CLI.chunk_mutex.lock()
	if loading_queue.has( id ) and objects:
		# we only want to add the object if we are still in an acceptable LOD
		objects.add_child(obj)
		load_mutex.lock()
		loading_queue.erase( id )
		if name =='@@201':
			print ('-===== fin', id)
		loaded.append( id )
		load_mutex.unlock()
	else:
		print('obj is getting tossed ', id)
	Global.CLI.chunk_threads.append(thread)
	Global.CLI.chunk_mutex.unlock()

func set_chunkbasic(_chunk_basic):
	chunk_basic = _chunk_basic
	chunk_size = _chunk_basic.chunk_size
	x = _chunk_basic.position.x / chunk_size
	z = _chunk_basic.position.y / chunk_size

func generate():
	assert(chunk_basic != null)
	generate_water()
	generate_chunk()

func generate_chunk():
	var mesh: ArrayMesh = ArrayMesh.new()
	var arr = []
	arr.resize(Mesh.ARRAY_MAX)

	var verts = PoolVector3Array()
	verts.resize( (chunk_size + 1) * (chunk_size + 1) )
	var uvs = PoolVector2Array()
	uvs.resize( verts.size() )
	var normals = PoolVector3Array()
	normals.resize( verts.size() )
	var indices = PoolIntArray( )
	indices.resize( (chunk_size ) * (chunk_size ) * 6 )
	var vert_index = 0
	var index_index = 0
	
	for _z in range(0, chunk_size + 1):
		for _x in range(0, chunk_size + 1):
			var t = _x + (_z - 1) * (chunk_size + 2)
			var b = _x + (_z + 1) * (chunk_size + 2)
			var l = _x - 1 + _z * (chunk_size + 2)
			var r = _x + 1 + _z * (chunk_size + 2)
			normals[ _x + (_z) * (chunk_size + 1)] = Vector3(2*(chunk_basic.heights[l].y-chunk_basic.heights[r].y), 4, 2*(chunk_basic.heights[t].y-chunk_basic.heights[b].y)).normalized()
			uvs[_x + _z * (chunk_size + 1)] = Vector2(_x / (chunk_size + 0.0), _z / (chunk_size + 0.0))
			
	for _z in range(1, chunk_size + 2):
		for _x in range(1, chunk_size + 2):
			verts[vert_index] = chunk_basic.heights[_x + _z * (chunk_size + 2)]

			var vert_topleft = vert_index
			var vert_topright = vert_topleft + 1
			var vert_bottomleft = vert_topleft + chunk_size + 1
			var vert_bottomright = vert_bottomleft + 1

			if _x < chunk_size+1 and _z < chunk_size+1:
				indices[index_index + 0] = vert_topleft
				indices[index_index + 1] = vert_topright
				indices[index_index + 2] = vert_bottomleft
				indices[index_index + 3] = vert_topright
				indices[index_index + 4] = vert_bottomright
				indices[index_index + 5] = vert_bottomleft

				index_index = index_index + 6
			
			vert_index = vert_index + 1

	# Assign arrays to mesh array.
	arr[Mesh.ARRAY_VERTEX] = verts
	arr[Mesh.ARRAY_TEX_UV] = uvs
	arr[Mesh.ARRAY_NORMAL] = normals
	arr[Mesh.ARRAY_INDEX] = indices

	# Create mesh surface from mesh array.
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	mesh_instance = MeshInstance.new()
	mesh_instance.mesh = mesh
#	var msec = OS.get_ticks_msec()
	mesh_instance.create_trimesh_collision()
#	print("create_trimesh_collision took: ", OS.get_ticks_msec() - msec)
	mesh_instance.set_material_override(preload("res://scenes/uv-test.material"))
	add_child(mesh_instance)
	
func generate_water():
	var plane_mesh = PlaneMesh.new()
	plane_mesh.size = Vector2(chunk_size, chunk_size)
	plane_mesh.subdivide_width = chunk_size * 0.5
	plane_mesh.subdivide_depth = chunk_size * 0.5
	
	plane_mesh.material = preload("res://zOld/water.material")
	var mesh_instance = MeshInstance.new()
	mesh_instance.mesh = plane_mesh
	add_child(mesh_instance)
