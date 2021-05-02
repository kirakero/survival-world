extends Reference

var child = []
var size
var value setget setval
var x
var y
var half
var NODE = load("res://scripts/Utility/QuadTreeNode.gd")

const OP_ADD = true
const OP_SUBTRACT = false

func _init(_x, _y, _size, _value):
	x = _x
	y = _y
	value = _value
	size = _size
	half = size * 0.5
	assert (size > 0)

func setval(_value):
	print([x, y, ', size', size, 'setval to', _value])
	child = []
	value = _value

func getval():
	if child.size() == 4:
		return 'mixed'
	return value
	
func showval():
	return '%s, %s, size %s == %s' % [x, y, size, getval()]

func operation(op, _x, _y, _s = 16 ):
#	print('start op', [op, _x, _y, _s] )
	assert(_s > 1)
	if value == op and child.size() != 4:
#		print('end op already ==')
		return

	if child == []:
		child = [
			NODE.new(x, y, half, value),
			NODE.new(x + half, y, half, value),
			NODE.new(x, y + half, half, value),
			NODE.new(x + half, y + half, half, value),
		]
	
	# 1st quad
	if _x < x + half and _y < y + half: 
		if _x - x <= 0 and _y - y <= 0 and _x + _s >= x + half and _y + _s >= y + half: # we cover the entire child
			child[0].setval(op)
		else:
			child[0].operation(op, _x, _y, _s)
	
	# 2nd quad
	if _x + _s > x + half and _y < y + half: 
		if _x - x <= half and _y - y <= 0 and _x + _s >= x + size and _y + _s >= y + half: # we cover the entire child
			child[1].setval(op)
		else:
			child[1].operation(op, _x, _y, _s)
		
	# 3rd quad
	if _x < x + half and _y + _s > y + half: 
		if _x - x <= 0 and _y - y <= half and _x + _s >= x + half and _y + _s >= y + size: # we cover the entire child
			child[2].setval(op)
		else:
			child[2].operation(op, _x, _y, _s)

	# 4th quad
	if _x + _s > x + half and _y + _s > y + half: 
		if _x - x <= half and _y - y <= half and _x + _s >= x + size and _y + _s >= y + size: # we cover the entire child
			child[3].setval(op)
		else:
			child[3].operation(op, _x, _y, _s)

	for c in child:
		if c.value != op or c.child.size() == 4:
			return
	setval(op)
	
# returns a new tree where the ORIGNAL tree was NOT IN the GIVEN tree
func intersect(tree, result = null):
	assert(tree.size == size)
	if result == null:
		print('result is null')
		result = NODE.new(0, 0, size, false)
	
	if value == tree.value and child.size() == 0:
		# nothing - equal
		pass
	elif child.size() == 0:
		result.value = true
	else:
		result.child = [null, null, null, null]
		assert(result.child[0] == null)
		for quad in range(4):
			print('add quad', [child[quad].x, child[quad].y, child[quad].size])
			result.child[quad] = NODE.new(child[quad].x, child[quad].y, child[quad].size, false)
			child[quad].intersect(tree.child[quad], result.child[quad])
	
	return result

func debug(depth = 0):
	print('#'.repeat(depth), ' ', showval())
	if str(getval()) == 'mixed':
		for c in child:
			c.debug(depth+1)

		
