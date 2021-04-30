extends Model
class_name ChunkData

const SQLite = preload("res://addons/godot-sqlite/bin/gdsqlite.gdns")
const TABLE = 'chunks'

var db: SQLite

func _init(_db):
	db = _db	

static func table_definition():
	var table_dict : Dictionary = Dictionary()
	table_dict["pos_x"] = {"data_type":"int", "not_null": true}
	table_dict["pos_y"] = {"data_type":"int", "not_null": true}
	table_dict["chunk"] = {"data_type":"blob", "not_null": true}
	table_dict["updated_at"] = {"data_type":"int", "not_null": true}
	
	return {
		'name': TABLE,
		'def': table_dict,
	}

func add_indexes():
	db.query(str("CREATE INDEX pos ON ", TABLE, "(pos_x, pos_y)"))

func insert(position: Vector2, chunk: PoolByteArray):
	db.insert_row(TABLE, {
		'pos_x': int(position.x),
		'pos_y': int(position.y),
		'chunk': chunk,
		'updated_at': OS.get_system_time_msecs(),
	})

func update(position: Vector2, chunk: PoolByteArray):
	db.update_rows(TABLE, "pos_x = %s AND pos_y = %s" % [int(position.x), int(position.y)], {
		'chunk': chunk,
		'updated_at': OS.get_system_time_msecs(),
	})

func first(position: Vector2) -> Dictionary:
	var query = "pos_x = '%' and pos_y = '%'" % [position.x, position.y]
	return db.select_rows(TABLE, query, ["*"])[0]

func where(positions: Array) -> Array:
	var values = PoolStringArray()
	for p in positions:
		values.append("'%s,%s'" % [int(p.x), int(p.y)])
	return db.select_rows(TABLE, 'pos_x || "," || pos_y IN (%s)' % values.join(','), ['*'])
	
