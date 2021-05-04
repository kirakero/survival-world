extends Node
class_name Fun


static func make_chunk_key(x, y):
	return '%s,%s' % [x, y]

static func strip_meta(data):
	data.erase('_key')
	data.erase('_callback')
	return data
