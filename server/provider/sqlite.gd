extends Reference
class_name SQLiteProvider
const SQLite = preload("res://addons/godot-sqlite/bin/gdsqlite.gdns")

const DB_DATA_DIR = 'user://savegame/'
var db
var db_name
var game
var is_connected = false

func _init(_game):
	game = _game
	db_name = str(DB_DATA_DIR, game)
	
func _connect():
	db = SQLite.new()
	db.path = db_name
	db.verbose_mode = true
	# Enable foreign keys.
	db.foreign_keys = true
	# Open the database as usual.
	db.open_db()
	is_connected = true
	
func _disconnect():
	if not is_connected:
		return
	# Close the current database
	db.close_db()

func _res(data, res, code = 200):
	# transmit the res to the api
	res['_key'] = data['_key']
	res['_callback'] = data['_callback']
	data['_sender'].call_deferred('done', data['_callback'], res, code)

func _okay(data, res, code = 200):
	return _res(data, res, code)
	
func _error(data, res, code = 400):
	return _res(data, res, code)


func world_post(data: Dictionary):
	# this endpoint is allowed to switch databases if needed
	# in this case we should make sure the game doesnt already exist
	_disconnect()
	var file = File.new()
	if file.file_exists( str(DB_DATA_DIR, data['newgame'],'.db') ):
		return _error(data, {'message': 'Game exists'})
		
	game = data['newgame']
	db_name = str(DB_DATA_DIR, game)
	
	var dir = Directory.new()
	if not dir.dir_exists(DB_DATA_DIR):
		dir.make_dir(DB_DATA_DIR)
	dir.copy('res://server/database/empty.db', str(db_name,'.db'))

	_connect()
	# create the tables for storing basic game data and the map
	var config_table = ConfigData.table_definition()
	db.create_table(config_table['name'], config_table['def'])

	ConfigData.insert(db, 'game', data['newgame'])
	ConfigData.insert(db, 'seed', str(data['seed']))
	ConfigData.insert(db, 'world_size', str(data['world_size']))
	ConfigData.insert(db, 'chunk_size', str(data['chunk_size']))

	var chunk_table = ChunkData.table_definition()
	db.create_table(chunk_table['name'], chunk_table['def'])
#
	return _okay(data, {})
	

	
	
	
	
	
	
	
	
	
	
	
	
	
