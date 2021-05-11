extends Model
class_name ConfigData
const SQLite = preload("res://addons/godot-sqlite/bin/gdsqlite.gdns")

const TABLE = 'config'

var db: SQLite

func _init(_db):
	db = _db	

static func table_definition():
	var table_dict : Dictionary = Dictionary()
	table_dict["name"] = {"data_type":"text", "not_null": true}
	table_dict["value"] = {"data_type":"text", "not_null": true}
	
	return {
		'name': TABLE,
		'def': table_dict,
	}

func insert(name: String, value: String):
	db.insert_row(TABLE, {
		'name': name,
		'value': value,
	})

# returns formatted config
func all() -> Dictionary:
	var out = {}
	for item in db.select_rows(TABLE, "", ["*"]):
		out[item['name']] = item['value']
	
	out['max_range_chunk'] = 192
	return out
