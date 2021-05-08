extends Node
class_name Fun


static func make_chunk_key(x, y):
	return '%s,%s' % [x, y]

static func strip_meta(data):
	data.erase('_key')
	data.erase('_callback')
	return data

static func resize_and_fill(pool, _size:int, value=0):
	if _size < 1:
		return null
	pool.resize(1)
	pool[0]=value
	while pool.size() << 1 <= _size:
		pool.append_array(pool)
	if pool.size() < _size:
		pool.append_array(pool.subarray(0,_size-pool.size()-1))
	return pool
