extends Node
class_name Def

const TYPE_PLAYER = 0		# this is a Player
const TYPE_RESOURCE = 1 	# this is a body in the environment that might move
const TYPE_REMOVED = 2 		# this is a default body in the environment that was altered
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
