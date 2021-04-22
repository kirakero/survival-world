extends Node

var format

func _init(format: int = -1):
	self.format = format
	
# take the result, which is type Dictionary, extract the Image from data,
# and store it in args['data'], which is type ImageData
func run(args: Dictionary, result: Image, coordinator) -> Dictionary:
	var result_image: Image = result
	
	if format != -1:
		result_image.convert(self.format)
		args['data'].format = self.format
		print('convert', self.format)
	else:
		args['data'].format = result_image.get_format()
		print('no convert', args['data'].format)
	args['data'].size = result_image.get_size()	
	args['data'].pa = result_image.get_data()
	
	return args
