extends Node
class_name Pipeline
# Hint - extend me!

var type: int
var args: Dictionary = {}
var thread: Thread
var coordinator: Coordinator

signal done

func _init(args: Dictionary, parent: Node):
	# the args should contain size at a minimum
	self.args = args
	parent.add_child(self)

func run(coordinator: Coordinator):
	# handles execution of this object
	# if everything checks out, queue this task for processing
	self.coordinator = coordinator
	coordinator.process(self)
	
func _exec(thread: Thread):
	print('exec _exec', args)
	# coordinator will call this when its time to actually process stuff via
	# thread.start(pipeline, "_exec", thread)
	var result = null
	var complete = true
	self.thread = thread
	# work here
	# if QUEUE, for each job we need to execute the sub-pipeline
	if args.has('queue'):
		if args['queue'].size() > 0:
			var job = args['queue'].pop_front()
			# job['pipeline'] contains the Pipeline we need to run
			# job['params'] contains the arguments
			# job['pass'] contains the arguments we pass from the parent
			var _args = job['args']
			for k in job['pass'].keys():
				_args[k] = args[k]
			
			var pipeline: Pipeline = job['pipeline'].pipeline(_args, self)
			pipeline.run(coordinator)
			complete = false
			result = yield(pipeline, "done")
			
	# if TYPE_SHADER, use the renderer in the args or spawn a new renderer
	# and compute the result
	elif args.has('shader'):
		print('exec shader')
		args['data'].init_renderer(self)
		args['data'].renderer.set_brush_shader( args['shader'] )
		for param in args.keys():
			if param.substr(0,1) == 'u':
				args['data'].renderer.set_brush_shader_param(param, args[param])
		if (args.has('iterations')):
			args['data'].renderer.loop( args['iterations'] )
		else:
			args['data'].renderer.loop( 1 )
		result = yield(args['data'].renderer, "loop_done")
		print('shader yield')
	# if TYPE_CMD, just execute this code
	# commands are special in that they post process the results of both the
	# queue or shader
	# commands are not allowed to loop here
	# commands do not directly change completeness
	# commands are blocking
	# CAREFUL - it's possible for commands to have state depending on how they
	# are written
	if args.has('command'):
		args = args['command'].run(args, result, coordinator)
		
	if not complete:
		return _exec(thread)
		
	if args['data'].renderer != null:
		args['data'].teardown_renderer(self)
	call_deferred("_end", args)
	
func _end(result):
	# handles cleanup
	thread.wait_to_finish()
	# tell the coordinator we are done
	coordinator.release(thread)
	# forget the coordinator - this is the same as marking Pipeline as not busy
	coordinator = null
	# return the result
	emit_signal("done", result)

