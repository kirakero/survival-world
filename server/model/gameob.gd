extends Model
class_name GameObData

const SQLite = preload("res://addons/godot-sqlite/bin/gdsqlite.gdns")
const TABLE = 'gameobs'

var db: SQLite

func _init(_db):
	db = _db	

static func table_definition():
	var table_dict : Dictionary = Dictionary()
	
	table_dict["id"] = {"data_type":"string", "not_null": true}
	table_dict["pos_x"] = {"data_type":"int", "not_null": true}
	table_dict["pos_z"] = {"data_type":"int", "not_null": true}
	table_dict["json"] = {"data_type":"text", "not_null": true}
	
	return {
		'name': TABLE,
		'def': table_dict,
	}

func add_indexes():
	db.query(str("CREATE INDEX pos ON ", TABLE, "(pos_x, pos_z)"))
	db.query(str("CREATE INDEX id ON ", TABLE, "(id)"))

func insert(id: String, position: Vector2, data: Dictionary):
	db.insert_row(TABLE, {
		'id': id,
		'pos_x': int(position.x),
		'pos_z': int(position.y),
		'json': to_json(data),
	})

func update(id: String, data: Dictionary):
	db.update_rows(TABLE, "id = %s" % [id], {
		'json': sleep(data),
	})

func delete(id: String):
	db.delete_rows(TABLE, "id = %s" % [id])

func findOrFail(id: String):
	var query = "id = %s" % [id]
	var res = db.select_rows(TABLE, query, ["*"])
	if res.size():
		return wake(res[0]['id'], res[0]['json'])
	return null

func all_from_chunk(position: Vector2):
	var query = "pos_x = %s AND pos_z = %s" % [position.x, position.y]
	var res = db.select_rows(TABLE, query, ["*"])
	var out = []
	for item in res:
		out.append( wake(res[0]['id'], res[0]['json']) )
	return out
	
static func wake(id, json):
	var dict = parse_json(json)
	
	dict[ Def.TX_ID ] = id
	dict[ Def.TX_TYPE ] = Def.TYPE_RESOURCE
	dict[ Def.TX_SUBTYPE ] = int(dict[ Def.TX_SUBTYPE ])
	dict[ Def.TX_UPDATED_AT ] = 1

	# Assumed properties
	# Def.TX_POSITION 
	# Def.TX_ROTATION
	
	return dict

static func sleep(data: Dictionary) -> String:
	var out = {}
	var keys: Array = data.keys()
	keys.erase( Def.TX_ID )
	keys.erase( Def.TX_TYPE )
	keys.erase( Def.TX_SUBTYPE )
	keys.erase( Def.TX_UPDATED_AT )
	keys.erase( Def.QUAD )
	for key in keys:
		out[ key ] = data [ key ]
	return to_json(out)


	
