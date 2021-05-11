extends Node2D
const INTERSECT_KEEP_A = 1
const INTERSECT_KEEP_B = 2
const INTERSECT_BOTH = 3
const UNION = 4
const COMP_STRICT = 1
const COMP_NONZERO = 2

func _init():
	
	var testquad = QuadTree.new(-8, -8, 16, false)
	testquad.showops = true
	
	testquad.operation(123, -8, -8, 8)
	testquad.debug('testquad1')

	testquad.operation(145, -8, -6, 2)
	testquad.debug('testquad1')


	var testquad2 = QuadTree.new(-8, -8, 16, false)
	testquad2.showops = true
	testquad2.operation(145, -8, -4, 2)
	testquad2.debug('testquad2')

	var testquad3 = testquad.intersect(testquad, testquad2, INTERSECT_KEEP_A, COMP_NONZERO)
	testquad3.showops = true
	testquad3.debug('testquad3')
##
##
##	print('add 0,12 size 2')
##	testquad.add(0, 12, 2)
###	testquad.add(4, 12, 2)
#
#	print(' intersect BOTH ')
#	var testquad3 = testquad.intersect(testquad, testquad2, 3)
#	testquad3.debug()
#
#	print('-----------')
#	print(' intersect KEEP A ')
#	var testquad4 = testquad.intersect(testquad, testquad2, 1)
#	testquad4.debug()
#
#	print('-----------')
#	print(' intersect KEEP B ')
#	var testquad5 = testquad.intersect(testquad, testquad2, 2)
#	testquad5.debug()
#
#	print('-----------')
#
#	print (testquad3.query(0, 0, 16))
