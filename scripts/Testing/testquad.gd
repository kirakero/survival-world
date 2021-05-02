extends Node2D


func _init():
	
	print('add 1040,1024 size 16')
	var time_start = OS.get_ticks_msec()
	var testquad = load("res://scripts/Utility/QuadTreeNode.gd").new(0, 0, 8192, false)
	testquad.operation(testquad.OP_ADD, 1040, 1024, 16)
	var elapsed_time = OS.get_ticks_msec() - time_start
	print ('took ', elapsed_time)
	
	print('add 1040,1024 size 32')
	time_start = OS.get_ticks_msec()
	var testquad2 = load("res://scripts/Utility/QuadTreeNode.gd").new(0, 0, 8192, false)
	testquad2.operation(testquad.OP_ADD, 1040, 1024, 16)
	elapsed_time = OS.get_ticks_msec() - time_start
	print ('took ', elapsed_time)
#	print('subtract 0,12 size 2')
#	testquad.operation(testquad.OP_SUBTRACT, 0, 12, 2)
#
#	print('add 5,2 size 2')
#	testquad.operation(testquad.OP_ADD, 5, 2, 2)
#	testquad.debug()
#
#
#	print('add 0,12 size 2')
#	testquad.add(0, 12, 2)
##	testquad.add(4, 12, 2)
	var testquad3 = testquad.intersect(testquad2)

	testquad3.debug()
