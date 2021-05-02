extends Reference
class_name QuadTree

var child = []
var size
var value
var x
var y
var half
var NODE = load("res://scripts/Utility/QuadTreeNode.gd")
var ref = null
var disable_optimization

const OP_ADD = true
const OP_SUBTRACT = false

func _init(_x, _y, _size, _value, _disable_optimization = false):
	x = _x
	y = _y
	value = _value
	size = _size
	half = size * 0.5
	disable_optimization = _disable_optimization
	assert (size > 0)

func setval(_value, _ref= null):
#	print([x, y, ', size', size, 'setval to', _value])
	child = []
	value = _value
	if value and ref != null:
		ref = _ref

func getval():
	if child.size() == 4:
		return 'mixed'
	return value
	
func showval():
	return '%s, %s, size %s == %s' % [x, y, size, getval()]

func add_children(value = false):
	child = [
			NODE.new(x, y, half, value),
			NODE.new(x + half, y, half, value),
			NODE.new(x, y + half, half, value),
			NODE.new(x + half, y + half, half, value),
	]

func all():
	return query(0, 0, size)

func query(_x, _y, _s):
	# wholey contained and true -- immediately return
	if value and _x <= x and _y <= y and _x + _s >= x + size and _y + _s >= y + size:
		return [self]

	var res = []
	for ch in child:
		res.append_array( ch.query(_x, _y, _s) )
	
	return res

func is_empty():
	if value == true:
		return false
	if child.size() == 4:
		for quad in child:
			if not quad.is_empty():
				return false
	
	return true

func operation(op, _x, _y, _s = 16, _ref = false ):
#	print('start op', [op, _x, _y, _s] )
	assert(_s > 1)
	if value == op and child.size() != 4:
#		print('end op already ==')
		return

	if child == []:
		add_children(value)
	
	# 1st quad
	if _x < x + half and _y < y + half: 
		if _x - x <= 0 and _y - y <= 0 and _x + _s >= x + half and _y + _s >= y + half: # we cover the entire child
			child[0].setval(op, _ref)
		else:
			child[0].operation(op, _x, _y, _s, _ref)
	
	# 2nd quad
	if _x + _s > x + half and _y < y + half: 
		if _x - x <= half and _y - y <= 0 and _x + _s >= x + size and _y + _s >= y + half: # we cover the entire child
			child[1].setval(op, _ref)
		else:
			child[1].operation(op, _x, _y, _s, _ref)
		
	# 3rd quad
	if _x < x + half and _y + _s > y + half: 
		if _x - x <= 0 and _y - y <= half and _x + _s >= x + half and _y + _s >= y + size: # we cover the entire child
			child[2].setval(op, _ref)
		else:
			child[2].operation(op, _x, _y, _s, _ref)

	# 4th quad
	if _x + _s > x + half and _y + _s > y + half: 
		if _x - x <= half and _y - y <= half and _x + _s >= x + size and _y + _s >= y + size: # we cover the entire child
			child[3].setval(op, _ref)
		else:
			child[3].operation(op, _x, _y, _s, _ref)

#	if not disable_optimization:
#		for c in child:
#			if c.value != op or c.child.size() == 4:
#				return
#		setval(op)

func safeval():
	if !value or child.size() == 4:
		return false
	return true

func copy():
	var result = NODE.new(x, y, size, safeval(), ref)
#	print('copy', [x, y, size, safeval(), child.size()])
#	if x == 0 and y == 0 and size == 8:
#		assert(value == false)
	if child.size() == 4:
		for quad in range(4):
			result.child.append(child[quad].copy())
			
	
	return result

const INTERSECT_KEEP_A = 1
const INTERSECT_KEEP_B = 2
const INTERSECT_BOTH = 3

static func intersect(treeA, treeB, mode = INTERSECT_BOTH, init = false):
	assert(treeA.size == treeB.size)
	var result = treeA.NODE.new(treeA.x, treeA.y, treeA.size, init)
	
	if treeA.child.size() == 0 and treeB.child.size() == 0:
		if treeA.value != treeB.value:
			if (mode & INTERSECT_BOTH) == INTERSECT_BOTH:
				result.setval(treeA.value or treeB.value)
				if treeA.ref != null:
					result.ref = treeA.ref
				elif treeB.ref != null:
					result.ref = treeB.ref
			elif (mode & INTERSECT_KEEP_A) == INTERSECT_KEEP_A:
				result.setval(treeA.value, treeA.ref)
			elif (mode & INTERSECT_KEEP_B) == INTERSECT_KEEP_B:
				result.setval(treeB.value, treeB.ref)
	else:
		var treeA_child = treeA.child
		var treeB_child = treeB.child
		
		if treeA.child.size() == 0 and treeB.child.size() == 4:
			treeA_child = treeA.copy()
			treeA_child.add_children(treeA.value)
			treeA_child = treeA_child.child
		elif treeA.child.size() == 4 and treeB.child.size() == 0:
			treeB_child = treeB.copy()
			treeB_child.add_children(treeB.value)
			treeB_child = treeB_child.child
		
		for quad in range(4):
			result.child.append( intersect(treeA_child[quad], treeB_child[quad], mode) )
		
#		if not disable_optimization:
#			# node cleanup - necessary?
#			var st_true = 0
#			var st_false = 0
#			for quad in result.child:
#				if quad.value == true:
#					st_true = st_true + 1
#				elif quad.child.size() == 0:
#					st_false = st_false + 1
#			if st_false == 4:
#				result.setval(false)
#			elif st_true == 4:
#				result.setval(true)
			
	return result
	

static func union(treeA, treeB, mode = INTERSECT_BOTH, init = false):
	assert(treeA.size == treeB.size)
	var result = treeA.NODE.new(treeA.x, treeA.y, treeA.size, init)
	
	if treeA.child.size() == 0 and treeB.child.size() == 0:
		if treeA.value == treeB.value:
			if (mode & INTERSECT_BOTH) == INTERSECT_BOTH:
				result.setval(treeA.value or treeB.value)
				if treeA.ref != null:
					result.ref = treeA.ref
				elif treeB.ref != null:
					result.ref = treeB.ref
			elif (mode & INTERSECT_KEEP_A) == INTERSECT_KEEP_A:
				result.setval(treeA.value, treeA.ref)
			elif (mode & INTERSECT_KEEP_B) == INTERSECT_KEEP_B:
				result.setval(treeB.value, treeB.ref)
	else:
		var treeA_child = treeA.child
		var treeB_child = treeB.child
		
		if treeA.child.size() == 0 and treeB.child.size() == 4:
			treeA_child = treeA.copy()
			treeA_child.add_children(treeA.value)
			treeA_child = treeA_child.child
		elif treeA.child.size() == 4 and treeB.child.size() == 0:
			treeB_child = treeB.copy()
			treeB_child.add_children(treeB.value)
			treeB_child = treeB_child.child
		
		for quad in range(4):
			result.child.append( union(treeA_child[quad], treeB_child[quad], mode) )
			
	return result

func debug(depth = 0):
	print('#'.repeat(depth), ' ', showval())
	if str(getval()) == 'mixed':
		for c in child:
			c.debug(depth+1)

		
