extends Node
class_name Pipeline
# Hint - extend me!

#var type: int
var args: Dictionary = {}
var thread: Thread
var coordinator: Coordinator
var callback
var _silence = 	true

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
	if not _silence:	
		print('exec _exec', args.keys())
#	print('exec _exec')
	# coordinator will call this when its time to actually process stuff via
	# thread.start(pipeline, "_exec", thread)
	var result = null
	var complete = true
	thread = _thread
	# work here
	
	if args.has('pre-command'):
		var _args = args
		args = args['pre-command'].run(_args, result, coordinator)
		if not _silence:	
			print('pre-cmd complete ', args.keys())
		args.erase('pre-command')
			
	# if QUEUE, for each job we need to execute the sub-pipeline
	
	if args.has('queue'):
		if args['queue'].size() > 0:
			var job = args['queue'].pop_front()
			
			
			if job.has('batch'):
				var _args_all = []
				for _args in args[job['batch']]:
					for k in job['args'].keys():
						_args[k] = job['args'][k]
					if job.has('args-as'):
						for k in job['args-as'].keys():
							_args[job['args-as'][k]] = _args[k]
					if job.has('pass'):
						for k in job['pass']:
							_args[k] = args[k]
					if job.has('pass-as'):
						for k in job['pass-as'].keys():
							_args[job['pass-as'][k]] = args[k]
					_args_all.append(_args)
				var batch = BatchPipeline.new(self, job, _args_all)
				batch.run(coordinator)
				var _result = yield(batch, "done")
				result = []
				result.resize(_result.size())
				for i in range(_result.size()):
					result[_result[i]['_key']] = _result[i]
				if not _silence:
					print('batch done')
				batch.queue_free()
				
			else:
				# job['pipeline'] contains the Pipeline we need to run
				# job['params'] contains the arguments
				# job['pass'] contains the arguments we pass from the parent
				var _args = job['args']
				if job.has('pass'):
					for k in job['pass']:
						_args[k] = args[k]
				if job.has('pass-as'):
					for k in job['pass-as'].keys():
						_args[job['pass-as'][k]] = args[k]
				var pipeline: Pipeline = job['pipeline'].pipeline(_args, self)
				if not _silence:
					print('send args', _args.keys(), ' to ', pipeline)
				pipeline.run(coordinator)
				
				result = yield(pipeline, "done")
				pipeline.queue_free()
			
			complete = false
			if job.has('merge'):
				for k in job['merge']:
					args[k] = result[k]
			if job.has('results-as'):
					args[job['results-as']] = result
			if job.has('unset'):
				for k in job['unset']:
					args.erase(k)
			
	# if TYPE_SHADER, use the renderer in the args or spawn a new renderer
	# and compute the result
	elif args.has('shader'):
		var src_data = 'data'
		if args['shader/data']:
			src_data = args['shader/data']
		if not _silence:
			print('exec shader')
		args[src_data].init_renderer(self)
		args[src_data].renderer.set_brush_shader( args['shader'] )
		for param in args.keys():
			if param.substr(0,2) == 'u_':
				args[src_data].renderer.set_brush_shader_param(param, args[param])
		if (args.has('iterations')):
			if args['iterations'] > 0:
				args[src_data].renderer.loop( args['iterations'] )
				result = yield(args[src_data].renderer, "loop_done") 
				if not _silence:
					print('shader yield')
			elif not _silence:
				print('shader yield skip')
		else:
			args[src_data].renderer.loop( 1 )
			result = yield(args[src_data].renderer, "loop_done") 
			if not _silence:
				print('shader yield def')
		args[src_data].teardown_renderer(self)
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
		args = args['command'].run(_args, result, coordinator)
		if not _silence:
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
	if not _silence:	
		print('pipeline is ending with result ', result.keys())
	emit_signal("done", result)
	if callback != null:
		callback.call_deferred('_done', self, args, result)
