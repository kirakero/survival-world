extends Node
class_name Pipeline
# Hint - extend me!

#var type: int
var args: Dictionary = {}
var thread: Thread
var coordinator: Coordinator
var callback

signal done

func _init(_args: Dictionary, parent: Node, _callback = null):
	# the args should contain size at a minimum
	args = _args
	parent.call_deferred("add_child", self)
	callback = _callback

func run(_coordinator: Coordinator):
	# handles execution of this object
	# if everything checks out, queue this task for processing
	if self.coordinator != null:
		print('already running')
		return
	coordinator = _coordinator
	coordinator.process(self)
	
func _exec(_thread: Thread):
#	print('exec _exec', args.keys())
	print('exec _exec')
	# coordinator will call this when its time to actually process stuff via
	# thread.start(pipeline, "_exec", thread)
	var result = null
	var complete = true
	thread = _thread
	# work here
	# if QUEUE, for each job we need to execute the sub-pipeline
	if args.has('queue'):
		if args['queue'].size() > 0:
			var job = args['queue'].pop_front()
			var _args = job['args']
			for k in job['pass']:
				_args[k] = args[k]
			if job.has('pass-as'):
				for k in job['pass-as'].keys():
					_args[job['pass-as'][k]] = args[k]
			if job.has('batch'):
				var batch = BatchPipeline.new(self, job, _args)
				batch.run(coordinator)
				result = yield(batch, "done")
				batch.queue_free()
				
			else:
				# job['pipeline'] contains the Pipeline we need to run
				# job['params'] contains the arguments
				# job['pass'] contains the arguments we pass from the parent

				var pipeline: Pipeline = job['pipeline'].pipeline(_args, self)
				
				print('send args', _args.keys(), ' to ', pipeline)
				pipeline.run(coordinator)
				complete = false
				result = yield(pipeline, "done")
				pipeline.queue_free()
			
			if job.has('merge'):
				for k in job['merge']:
					args[k] = result[k]
			
	# if TYPE_SHADER, use the renderer in the args or spawn a new renderer
	# and compute the result
	elif args.has('shader'):
		print('exec shader')
		args['data'].init_renderer(self)
		args['data'].renderer.set_brush_shader( args['shader'] )
		for param in args.keys():
			if param.substr(0,2) == 'u_':
				args['data'].renderer.set_brush_shader_param(param, args[param])
		if (args.has('iterations')):
			if args['iterations'] > 0:
				args['data'].renderer.loop( args['iterations'] )
				result = yield(args['data'].renderer, "loop_done") 
				print('shader yield')
			else:
				print('shader yield skip')
		else:
			args['data'].renderer.loop( 1 )
			result = yield(args['data'].renderer, "loop_done") 
			print('shader yield def')
		args['data'].teardown_renderer(self)
	# if TYPE_CMD, just execute this code
	# commands are special in that they post process the results of both the
	# queue or shader
	# commands are not allowed to loop here
	# commands do not directly change completeness
	# commands are blocking
	# CAREFUL - it's possible for commands to have state depending on how they
	# are written
	
	if args.has('command'):
		var _args = args
		# overwrite args if needed
#		if args['cmd-args']:
#			for k in args['cmd-args'].keys():
#				_args[k] = args['cmd-args'][k]
#		print ('cmd start', _args.keys())
		args = args['command'].run(_args, result, coordinator)
		print('cmd complete ', args.keys())
	
	if not complete:
		return _exec(thread)
		
	call_deferred("_end", args)
	
func _end(result):
	# handles cleanup
	thread.wait_to_finish()
	# tell the coordinator we are done
	if coordinator != null and not thread.is_active():
		coordinator.release(thread)
	# return the result
	print('pipeline is ending with result ', result.keys())
	emit_signal("done", result)
	if callback != null:
		callback.call_deferred('_done', self, args, result)
