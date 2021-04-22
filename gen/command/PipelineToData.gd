extends Node

var format

func _init(format: int = -1):
	self.format = format
	
# take the result, which is type Image, and store it in args['data'], which is 
# type ImageData
func run(args: Dictionary, result: Image, coordinator) -> Dictionary:
	if format != -1:
		result.convert(self.format)
	else:
		args['data'].format = result.get_format()
	
	args['data'].size = result.get_size()	
	args['data'].pa = result.get_data()
	
	return args
