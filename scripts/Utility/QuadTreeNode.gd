extends Reference
class_name QuadTree

var child = []
var size
var value: int
var x
var y
var half
var NODE = load("res://scripts/Utility/QuadTreeNode.gd")
var ref = null
var disable_optimization
var showops = false
var position: Vector2
var key: String

const OP_ADD = 1
const OP_SUBTRACT = 0

func _init(_x, _y, _size, _value = OP_SUBTRACT, _disable_optimization = false):
	x = _x
	y = _y
	position = Vector2(x, y)
	key = '%s,%s' % [x, y]
	value = _value
	size = _size
	half = size * 0.5
	disable_optimization = _disable_optimization
	assert (size > 0)

func setval(a: int, b = null, comp = COMP_STRICT):
	if b != null:
		if b > a:
			a = b
		
	child = []
	value = a
	

func add_children(value = false):
	child = [
			NODE.new(x, y, half, value),
			NODE.new(x + half, y, half, value),
			NODE.new(x, y + half, half, value),
			NODE.new(x + half, y + half, half, value),
	]

func all():
	return query(x, y, size)

func all_as_array():
	var out = []
	for i in query(x, y, size):
		out.append([i.x, i.y, i.size])
	return out

func istrue(truth):
	return value == truth

func query(_x, _y, _s, truth = OP_ADD):
	if istrue(truth) and _x <= x and _y <= y and _x + _s >= x + size and _y + _s >= y + size:
		return [self]

	var res = []
	for ch in child:
		res.append_array( ch.query(_x, _y, _s) )
	
	return res

func contains(_x, _y, _s, truth = OP_ADD):
	if istrue(truth) and _x >= x and _y >= y and _x + _s <= x + size and _y + _s <= y + size:
		return [self]

	var res = []
	for ch in child:
		res.append_array( ch.contains(_x, _y, _s) )
	
	return res

func is_empty(truth = OP_ADD):
	if istrue(truth):
		return false
	if child.size() == 4:
		for quad in child:
			if not quad.is_empty(truth):
				return false
	
	return true

func operation( op: int, _x, _y, _s = 16 ):
	if showops:
		print('OP operation(%s, %s, %s, %s)' % [op, _x, _y, _s])

	assert(_s > 1)
	if istrue(op) and child.size() != 4:
		return

	if child == []:
		add_children(value)
	
	var x_and_half = x + half
	var y_and_half = y + half
	var _x_and__s = _x + _s
	var _y_and__s = _y + _s
	var _x_min_x = _x - x
	var _y_min_y = _y - y
	
	# 1st quad
	if _x < x_and_half and _y < y_and_half: 
		if _x_min_x <= 0 and _y_min_y <= 0 and _x_and__s >= x_and_half and _y_and__s >= y_and_half: # we cover the entire child
			child[0].setval(op)
		else:
			child[0].operation(op, _x, _y, _s)
	
	# 2nd quad
	if _x_and__s > x_and_half and _y < y_and_half: 
		if _x_min_x <= half and _y_min_y <= 0 and _x_and__s >= x + size and _y_and__s >= y_and_half: # we cover the entire child
			child[1].setval(op)
		else:
			child[1].operation(op, _x, _y, _s)
		
	# 3rd quad
	if _x < x_and_half and _y_and__s > y_and_half: 
		if _x_min_x <= 0 and _y_min_y <= half and _x_and__s >= x_and_half and _y_and__s >= y + size: # we cover the entire child
			child[2].setval(op)
		else:
			child[2].operation(op, _x, _y, _s)

	# 4th quad
	if _x_and__s > x_and_half and _y_and__s > y_and_half: 
		if _x_min_x <= half and _y_min_y <= half and _x_and__s >= x + size and _y_and__s >= y + size: # we cover the entire child
			child[3].setval(op)
		else:
			child[3].operation(op, _x, _y, _s)

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
	if child.size() == 4:
		for quad in range(4):
			result.child.append(child[quad].copy())
	return result

const INTERSECT_KEEP_A = 1
const INTERSECT_KEEP_B = 2
const INTERSECT_BOTH = 3
const UNION = 4
const COMP_STRICT = 1
const COMP_NONZERO = 2

static func isequal(a, b, comp) -> bool:
	if COMP_NONZERO == comp:
		if a > 0 and b > 0:
			return true
		if a == 0 and b == 0:
			return true
		return false
	return a == b

static func isnotequal(a, b, comp) -> bool:
	if COMP_NONZERO == comp:
		if a > 0 and b == 0:
			return true
		if a == 0 and b > 0:
			return true
		return false
	return a != b

static func intersect(treeA, treeB, mode = INTERSECT_BOTH, comp = COMP_STRICT, init = false):
	if treeA.showops and init == false:
		var optype = 'intersect'
		if mode == UNION:
			optype = 'union'
		print('OP %s(mode = %s)' % [optype, mode])
	
	assert(treeA.size == treeB.size)
	var result = treeA.NODE.new(treeA.x, treeA.y, treeA.size, init)
	
	if treeA.child.size() == 0 and treeB.child.size() == 0:
		if mode == UNION:
			if isequal(treeA.value, treeB.value, comp):
				result.setval(treeA.value, treeB.value, comp)
					
		elif isnotequal(treeA.value, treeB.value, comp):
			if (mode & INTERSECT_BOTH) == INTERSECT_BOTH:
				result.setval(treeA.value, treeB.value, comp)
			elif (mode & INTERSECT_KEEP_A) == INTERSECT_KEEP_A:
				result.setval(treeA.value)
			elif (mode & INTERSECT_KEEP_B) == INTERSECT_KEEP_B:
				result.setval(treeB.value)
		
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
			result.child.append( intersect(treeA_child[quad], treeB_child[quad], mode, comp) )
		
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
	return intersect(treeA, treeB, UNION)



### DEBUG
func getval():
	if child.size() == 4:
		return 'mixed'
	return value
	
func showval():
	return '%s, %s, size %s == %s' % [x, y, size, getval()]
	
func debug(label = '', depth = 0):
	print(label, '#'.repeat(depth), ' ', showval())
	if str(getval()) == 'mixed':
		for c in child:
			c.debug(label, depth+1)

		
