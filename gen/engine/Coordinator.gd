extends Node
class_name Coordinator

var sleeping: Array = []
var queue: Array = []
var mutex
var _silence = true

func _init(maxthreads = 4):
	mutex = Mutex.new()
	for _i in range(maxthreads):
		sleeping.append(Thread.new())

func process(pipeline):
	call_deferred("_process", pipeline)

func _process(pipeline):
	if not _silence:
		print('coord recvd')
	mutex.lock()
	var thread: Thread = sleeping.pop_back()
	if thread == null or thread.is_active():
		if not _silence:
			print('coordinator queue ', queue.size())
		queue.append(pipeline)
#		if thread != null && not thread.is_active():
#			sleeping.append(thread)
		mutex.unlock()
	else:
		if not _silence:
			print('coordinator process ', queue.size())
		var _status = thread.start(pipeline, "_exec", thread)
		if not _silence:
			print('thread started with ', _status)

func release(thread: Thread):
	call_deferred("_release", thread)

func _release(thread: Thread):
	mutex.lock()
	var pipeline = queue.pop_back()
	if pipeline != null:
		if not _silence:
			print('attempt with ', pipeline)
		var _status = thread.start(pipeline, "_exec", thread)
		if not _silence:
			print('thread started with ', _status)
	else:
		sleeping.append(thread)
	mutex.unlock()
	if not _silence:
		print('coordinator release ', queue.size())

func terminate():
	for thread in sleeping:
		thread = null
		
