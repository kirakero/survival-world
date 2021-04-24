extends Node
class_name Coordinator

var sleeping: Array = []
var queue: Array = []
var mutex

func _init(maxthreads = 4):
	mutex = Mutex.new()
	for _i in range(maxthreads):
		sleeping.append(Thread.new())

func process(pipeline):
	call_deferred("_process", pipeline)

func _process(pipeline):
	print('coord recvd')
	mutex.lock()
	var thread: Thread = sleeping.pop_back()
	if thread == null or thread.is_active():
		print('coordinator queue ', queue.size())
		queue.append(pipeline)
#		if thread != null && not thread.is_active():
#			sleeping.append(thread)
		mutex.unlock()
	else:
		print('coordinator process ', queue.size())
		var _status = thread.start(pipeline, "_exec", thread)
		print('thread started with ', _status)

func release(thread: Thread):
	call_deferred("_release", thread)

func _release(thread: Thread):
	mutex.lock()
	var pipeline = queue.pop_back()
	if pipeline != null:
		print('attempt with ', pipeline)
		var _status = thread.start(pipeline, "_exec", thread)
		print('thread started with ', _status)
	else:
		sleeping.append(thread)
	mutex.unlock()
	print('coordinator release ', queue.size())

func terminate():
	for thread in sleeping:
		thread = null
		
