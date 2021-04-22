extends Node
class_name Coordinator

var sleeping: Array = []
var queue: Array = []
var mutex

signal release

func _init(maxthreads = 4):
	mutex = Mutex.new()
	for i in range(maxthreads):
		sleeping.append(Thread.new())

func process(pipeline):
	mutex.lock()
	var thread: Thread = sleeping.pop_back()
	if thread == null:
		queue.append(pipeline)
		mutex.unlock()
	else:
		print('coordinator process')
		thread.start(pipeline, "_exec", thread)

func release(thread: Thread):
	mutex.lock()
	var pipeline = queue.pop_back()
	if pipeline != null:
		thread.start(pipeline, "_exec", thread)
	else:
		sleeping.append(thread)
	mutex.unlock()
	print('coordinator release')
