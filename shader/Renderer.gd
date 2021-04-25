tool
extends Node
class_name Renderer

var _viewport : Viewport
var _viewport_sprite : Sprite
var _brush_material := ShaderMaterial.new()
var _image : Image
var _texture : ImageTexture
var _modified_shader_params := {}
const BRUSH_TEXTURE_SHADER_PARAM = "u_brush_texture"
var _will_draw = false
#var _is_looping = false
var _job = 0
var _silence = true

signal texture_region_changed(newimg)
signal loop_done(newimg)

func _init(dimensions: Vector2):
	_viewport = Viewport.new()
	_viewport.size = dimensions
	_viewport.render_target_update_mode = Viewport.UPDATE_ONCE
	_viewport.render_target_v_flip = true
	_viewport.render_target_clear_mode = Viewport.CLEAR_MODE_ONLY_NEXT_FRAME
	_viewport.hdr = false
	_viewport.transparent_bg = true

	_viewport_sprite = Sprite.new()
	_viewport_sprite.centered = false
	_viewport_sprite.material = _brush_material
	_viewport.call_deferred("add_child", _viewport_sprite)
	
	call_deferred("add_child", _viewport)
	
func set_image(image: Image, texture: ImageTexture):
	assert(image != null and texture != null)
	_image = image
	_texture = texture
	_texture.set_flags(0)
	_viewport_sprite.set_texture(_texture)
		
func set_brush_texture(texture: Texture):
	_brush_material.set_shader_param(BRUSH_TEXTURE_SHADER_PARAM, texture)


func set_brush_shader(shader: Shader):
	if _brush_material.shader != shader:
		_brush_material.shader = shader


func set_brush_shader_param(p: String, v):
	_modified_shader_params[p] = true
	_brush_material.set_shader_param(p, v)


func clear_brush_shader_params():
	for key in _modified_shader_params:
		_brush_material.set_shader_param(key, null)
	_modified_shader_params.clear()

func iterate():
	if _will_draw:
		return
	_will_draw = true
	
func _process(_delta):
	if not _will_draw:
		return
	if not _silence:
		print('process render step')
	_will_draw = false
	_viewport.render_target_update_mode = Viewport.UPDATE_ONCE
	yield(VisualServer, "frame_post_draw")
#	var data := _viewport.get_texture().get_data()
#	var tex = ImageTexture.new()
#	tex.create_from_image(data, 0)
	_viewport_sprite.set_texture(_viewport.get_texture())
	emit_signal("texture_region_changed", _viewport.get_texture().get_data())
	

func loop(steps, job = null, last = null):
	if not _silence:
		print('loop')
	if not job:
		_job = _job + 1
		job = _job
	if job != _job:
		return
	if not _silence:
		print ([steps, job, last])
	if steps > 0:
		iterate()
		last = yield(self, "texture_region_changed")
		steps = steps - 1
		loop(steps, job, last)
	else:
		emit_signal("loop_done", last)



