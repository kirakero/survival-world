extends Model
class_name ChunkData

const SQLite = preload("res://addons/godot-sqlite/bin/gdsqlite.gdns")
const TABLE = 'chunks'

var db: SQLite


const TYPE_PLAYER = 0		# this is a Player
const TYPE_RESOURCE = 1 	# this is a body in the environment that might move
const TYPE_GHOST = 2 		# this is a default body in the environment that was altered
const TYPE_CHUNK = 3 		# this is a map chunk
const TYPE_TERRAIN = 4 		# this is a single map height

const TX_ID = 'I'
const TX_TYPE = 'T'
const TX_DATA = 'D'
const TX_TIME = 't'
const TX_ERASE = 'E' # erase mode
const TX_INTENT = 'i'

const TX_UPDATED_AT = 'U' # database save time
const TX_CHUNK_DATA = 'C' # compressed chunk data

const INTENT_CLIENT = 0		# objects in the local/player domain
const INTENT_SERVER = 1		# objects in the server/world domain

const DIRTY_SENDER = 0
const DIRTY_TYPE = 1
const DIRTY_ID = 2

const TX_PHYS_POSITION = 'P'

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

func first(position: Vector2):
	var query = "pos_x = '%s' and pos_y = '%s'" % [position.x, position.y]
	var res = db.select_rows(TABLE, query, ["*"])
	if res.size():
		return {
			Def.TX_ID: Fun.make_chunk_key(position.x, position.y),
			Def.TX_TYPE: Def.TYPE_CHUNK,
			Def.TX_POSITION: Vector3(res[0]['pos_x'], 0, res[0]['pos_y']),
			Def.TX_UPDATED_AT: ServerTime.now(),
			Def.TX_CREATED_AT: ServerTime.now(),
			Def.TX_CHUNK_DATA: res[0]['chunk'],
			Def.TX_OBJECT_DATA: PoolByteArray(),
		}
	return {
		Def.TX_ID: Fun.make_chunk_key(position.x, position.y),
		Def.TX_TYPE: Def.TYPE_CHUNK,
		Def.TX_POSITION: Vector3(position.x, 0, position.y),
		Def.TX_UPDATED_AT: ServerTime.now(),
		Def.TX_CREATED_AT: ServerTime.now(),
		Def.TX_CHUNK_DATA: PoolByteArray(),
		Def.TX_OBJECT_DATA: PoolByteArray(),
	}

func where(positions: Array) -> Array:
	var values = PoolStringArray()
	for p in positions:
		values.append("'%s,%s'" % [int(p.x), int(p.y)])
	return db.select_rows(TABLE, 'pos_x || "," || pos_y IN (%s)' % values.join(','), ['*'])
	
