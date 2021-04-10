extends Node
class_name Ocean

var detect_map
var map
var center
var rivers = []
var config
var detect_edge

func _init(config: MapSettings, detect_map, detect_edge):
	self.config = config
	self.detect_map = detect_map
	self.detect_edge = detect_edge
	var _x = 0
	var _y = 0
	for coord in detect_map:
		var p = coord.x + coord.y * config.width
		_x = _x + coord[0]
		_y = _y + coord[1]
	center = config._spacing_snap(_x/detect_map.size(), _y/detect_map.size())
	
	
#	print('OCEAN; detected ', detect_map.size(),' points with center of ', center)

func can_link_river(target: Ocean = null) -> bool:
	if target:
		if center.distance_to(target.center) > config.MAX_RIVER_DISTANCE:
			return false
		
		if not target.can_link_river() or is_linked_to_ocean(target):
			return false
	
	var basis = 500 / config.SPACING
	var additional = 1500 / config.SPACING
	if rivers.size() == 0:
		if detect_map.size() > basis:
			return true
#		print ('detectmap ', basis, ' < ',detect_map.size())
		return false

	if detect_map.size() > additional * (rivers.size() - 1):
		return true
		
	return false

func add_river(river: River) -> void:
	rivers.append(river)

func is_linked_to_ocean(target: Ocean) -> bool:
	for river in rivers:
		if river.connects_to(target):
			return true
	return false
