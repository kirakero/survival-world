extends Node
class_name BatchPipeline

var pipeline
var job: Dictionary
var args: Dictionary
var coordinator: Coordinator
var results: Array
var mutex: Mutex

signal done

func _init(_pipeline, _job, _args):
	pipeline = _pipeline
	args = _args
	job = _job
	mutex = Mutex.new()
	
func run(_coordinator: Coordinator):
	# handles execution of this object
	# if everything checks out, queue this task for processing
	if self.coordinator != null:
		print('already running')
		return
	coordinator = _coordinator
	for item in args:
		call_deferred('_start_pipeline', item)

func _start_pipeline(_args):
	job['pipeline'].pipeline(_args, pipeline, self).run(coordinator)

func _done(_pipeline, _args, _result):
	mutex.lock()
	results.append({
		'args': _args,
		'result': _result
	})
	mutex.unlock()
	_pipeline.queue_free()
	if results.size() == args.size():
		emit_signal("done", results)
