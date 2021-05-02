extends Reference
class_name QuadTree

var tree = QuadTreeNode
var size = 16

func _init(_size):
	tree = QuadTreeNode.new( false, _size)


func add( x, y, s = 16, o = 0, leaf = null ):
	if leaf == null:
		leaf = tree
	var current_leaf_size = pow(2, o)
	var leaf_size_half = int(current_leaf_size / 2)
	if (typeof(leaf) == TYPE_BOOL and leaf == true) or s == size / current_leaf_size:
		# we can write here - the cell matches
		# we dont care what's written here
		leaf = true
	else:
		var q1 = false
		var q2 = false
		var q3 = false
		var q4 = false
		# determine the quad
		if x < pos_x + leaf_size_half:
			if y < pos_y + leaf_size_half:
				q1 = add( x, y, s, o+1, leaf, pos_x, pos_y)
			else:
				q2 = add( x, y, s, o+1, leaf, pos_x, pos_y + leaf_size_half)
		else:
			if y < pos_y + leaf_size_half:
				q3 = add( x, y, s, o+1, leaf, pos_x + leaf_size_half, pos_y)
			else:
				q4 = add( x, y, s, o+1, leaf, pos_x + leaf_size_half, pos_y + leaf_size_half)
		
		leaf = [q1, q2, q3, q4]

		
