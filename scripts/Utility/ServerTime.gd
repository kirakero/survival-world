extends Reference
class_name ServerTime

var latency
var latency_array: = []
var delta_latency = 0
var decimal_collector: float = 0.0
var clock

func _init():
	clock = system()
	latency = 1

func now():
	if clock:
		return clock
	return OS.get_system_time_msecs()

func system():
	return OS.get_system_time_msecs()

func add_latency(latency):
	latency_array.append(latency)
	if latency_array.size() == 9:
		var total_latency = 0
		latency_array.sort()
		var mid_point = latency_array[4]
		for i in range (latency_array.size() -1, -1, -1):
			if latency_array[i] > (2 * mid_point) and latency_array[i] > 20:
				latency_array.remove(i)
			else:
				total_latency += latency_array[i]
		var divlat = total_latency / latency_array.size()
		delta_latency = divlat - latency
		latency = divlat
		latency_array.clear()
		print ('Latency %s - Delta %s: Clock %s' % [ latency, delta_latency, clock ])

func tick(delta):
	# update our internal clock
	var d1000 = delta * 1000
	clock +=  int(d1000) + delta_latency
	delta_latency -= delta_latency
	decimal_collector += d1000 - int(d1000)
	if decimal_collector >= 1.00:
		clock += 1
		decimal_collector -= 1.0
