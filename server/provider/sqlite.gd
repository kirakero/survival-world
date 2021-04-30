extends Reference
class_name SQLiteProvider
const SQLite = preload("res://addons/godot-sqlite/bin/gdsqlite.gdns")

const DB_DATA_DIR = 'user://savegame/'
var db
var db_name
var game
var connected_to = null

var Config: ConfigData = null
var Chunks: ChunkData = null
	
func _connect():
	if connected_to != null:
		return
	db = SQLite.new()
	db.path = db_name
	# Open the database as usual.
	db.open_db()
	
	# Load the binding into the default models
	Config = ConfigData.new(db)
	Chunks = ChunkData.new(db)
	connected_to = game
	
func _disconnect():
	if connected_to == null:
		return
	# Close the current database
	db.close_db()
	connected_to = null
	game = null

func _is_connected():
	if connected_to == game and connected_to != null:
		return true
	
	return false

func _res(data, res, code = 200):
	# transmit the res to the api
	res['_key'] = data['_key']
	res['_callback'] = data['_callback']
	data['_sender'].call_deferred('done', data['_callback'], res, code)

func _okay(data, res, code = 200):
	return _res(data, res, code)
	
func _error(data, res: String, code = 400):
	return _res(data, {'message': res}, code)

# establish a connection to the provided database
func conn_post(data: Dictionary):
	if connected_to != null:
		_disconnect()
	
	# make sure a savegame directory exists in the first place
	var dir = Directory.new()
	if not dir.dir_exists(DB_DATA_DIR):
		dir.make_dir(DB_DATA_DIR)

	game = data['game']
	db_name = str(DB_DATA_DIR, game)
	
	_connect()

# disconnect from database
func conn_delete(data: Dictionary):
	if connected_to != null:
		_disconnect()

# create a world (provided the game is empty)	
func world_post(data: Dictionary):
	if _is_connected():
		return _error(data, 'Connected to another game')
	# make sure the database is empty
	# SELECT name FROM sqlite_master WHERE type='table' AND name='{table_name}'
	var dir = Directory.new()
	if dir.file_exists(str(db_name, '.db')):
		return _error(data, 'Game exists')
	
	game = data['newgame']
	db_name = str(DB_DATA_DIR, game)
	_connect()
	
	# create the tables for storing basic game data and the map
	var config_table = ConfigData.table_definition()
	db.create_table(config_table['name'], config_table['def'])

	Config.insert('game', data['newgame'])
	Config.insert('seed', str(data['seed']))
	Config.insert('world_size', str(data['world_size']))
	Config.insert('chunk_size', str(data['chunk_size']))

	var chunk_table = ChunkData.table_definition()
	db.create_table(chunk_table['name'], chunk_table['def'])
	Chunks.add_indexes()
#	db.query('BEGIN TRANSACTION;')
#	var pba = PoolByteArray([0])
#	var world_half = data['world_size'] * 0.5
#	for x in range(-world_half, world_half, data['chunk_size']):
#		for y in range(-world_half, world_half, data['chunk_size']):
#			Chunks.insert(Vector2(x, y), pba)
#	db.query('COMMIT TRANSACTION;')
	return _okay(data, {})

# get a world ie. load its settings
func world_get(data: Dictionary):
	if not _is_connected():
		return _error(data, 'Not connected')
	var res = Config.all()
	return _okay(data, res)

# get a chunk from the map at position as Vector2	
func chunk_get(data: Dictionary):
	if not _is_connected():
		return _error(data, 'Not connected')
	var res = Chunks.first(data['position'])
	return _okay(data, res)

# update a single chunk
func chunk_post(data: Dictionary):
	if not _is_connected():
		return _error(data, 'Not connected')	
	Chunks.update(data['position'], data['chunk'])
	return _okay(data, {})
	
# get a chunk from the map at position as Vector2	
func multichunk_get(data: Dictionary):
	if not _is_connected():
		return _error(data, 'Not connected')
	var res = Chunks.where(data['data'])
	return _okay(data, res)

# update many chunks
func multichunk_post(data: Dictionary):
	if not _is_connected():
		return _error(data, 'Not connected')
	db.query('BEGIN TRANSACTION;')
	for item in data['data']:
		Chunks.insert(item['position'], item['chunk'])
	db.query('COMMIT;')
	return _okay(data, {})
	
	
	
