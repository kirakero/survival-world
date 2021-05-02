extends Node2D


func _init():
	
	print('-----------')
	var time_start = OS.get_ticks_msec()
	var testquad = load("res://scripts/Utility/QuadTreeNode.gd").new(0, 0, 16, false)
	testquad.operation(testquad.OP_ADD, 0, 0, 8)
	var elapsed_time = OS.get_ticks_msec() - time_start
#	print ('took ', elapsed_time)
	testquad.debug()

	print('-----------')
	var time_start2 = OS.get_ticks_msec()
	var testquad2 = load("res://scripts/Utility/QuadTreeNode.gd").new(0, 0, 16, false)
	testquad2.operation(testquad2.OP_ADD, 4, 4, 4)
	testquad2.operation(testquad2.OP_ADD, 8, 4, 4)
	var elapsed_time2 = OS.get_ticks_msec() - time_start2
#	print ('took ', elapsed_time2)
	testquad2.debug()
	print('-----------')
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

	print(' intersect BOTH ')
	var testquad3 = testquad.intersect(testquad, testquad2, 3)
	testquad3.debug()

	print('-----------')
	print(' intersect KEEP A ')
	var testquad4 = testquad.intersect(testquad, testquad2, 1)
	testquad4.debug()

	print('-----------')
	print(' intersect KEEP B ')
	var testquad5 = testquad.intersect(testquad, testquad2, 2)
	testquad5.debug()

	print('-----------')
