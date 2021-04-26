extends Model
class_name ChunkData

const SQLite = preload("res://addons/godot-sqlite/bin/gdsqlite.gdns")
const TABLE = 'chunks'

static func table_definition():
	var table_dict : Dictionary = Dictionary()
	table_dict["id"] = {"data_type":"int", "primary_key": true, "not_null": true, "auto_increment": true}
	table_dict["pos_x"] = {"data_type":"int", "not_null": true}
	table_dict["pos_y"] = {"data_type":"int", "not_null": true}
	table_dict["chunk"] = {"data_type":"blob", "not_null": true}
	table_dict["updated_at"] = {"data_type":"int", "not_null": true}
	
	return {
		'name': TABLE,
		'def': table_dict,
	}

static func insert(db: SQLite, position: Vector2, chunk: PoolByteArray):
	db.insert_row(TABLE, {
		'position_x': int(position.x),
		'position_y': int(position.y),
		'chunk': chunk,
		'updated_at': OS.get_unix_time(),
	})
