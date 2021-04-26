extends Model
class_name ConfigData
const SQLite = preload("res://addons/godot-sqlite/bin/gdsqlite.gdns")

const TABLE = 'config'

static func table_definition():
	var table_dict : Dictionary = Dictionary()
	table_dict["id"] = {"data_type":"int", "primary_key": true, "not_null": true, "auto_increment": true}
	table_dict["name"] = {"data_type":"text", "not_null": true}
	table_dict["value"] = {"data_type":"text", "not_null": true}
	
	return {
		'name': TABLE,
		'def': table_dict,
	}

static func insert(db: SQLite, name: String, value: String):
	db.insert_row(TABLE, {
		'name': name,
		'value': value,
	})
