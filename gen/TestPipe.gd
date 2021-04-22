extends Node

static func pipeline(args: Dictionary, parent: Node):
	var imgtodata = preload("res://gen/command/ImageToData.gd").new(Image.FORMAT_L8)
	args['data'] = ImageData.new(Vector2(100, 100))
	args['shader'] = preload("res://gen/shader/CellularRadius.shader")
	args['u_offset'] = Vector2(500, 500)
	args['command'] = imgtodata
	
	return Pipeline.new(args, parent)
