extends Node

var format

func _init(_format: int = -1):
	format = _format
	
# take the result, which is type Dictionary, extract the Image from data,
# and store it in args['data'], which is type ImageData
func run(args: Dictionary, result: Image, _coordinator) -> Dictionary:
	if result == null:
		print('warning - imagetodata result is null')
		return args

	var src_data = 'data'
	if args['shader/data']:
		src_data = args['shader/data']

#	print ('cmd instructions ', [args, result, _coordinator])
	if format != -1 and result.get_format() != format:
		result.convert(format)
		args[src_data].format = format
#		print('convert', format)
	else:
		args[src_data].format = result.get_format()
#		print('no convert', args[src_data].format)
	assert(args[src_data].size == result.get_size())
#	args[src_data].size = result.get_size()	
	args[src_data].pa = result.get_data()
#	print('data size ', args[src_data].size, ' and length ', args[src_data].pa.size())
	return args
