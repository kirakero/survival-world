extends KinematicBody

var direction = Vector3.BACK
var velocity = Vector3.ZERO
var strafe_dir = Vector3.ZERO
var strafe = Vector3.ZERO

var aim_turn = 0

var vertical_velocity = 0
var gravity = 20

var movement_speed = 0
var walk_speed = 1.5
var run_speed = 5
var acceleration = 6
var angular_acceleration = 7

var roll_magnitude = 17

var jump_speed = 10

var physics_active = false
var chunk_size = Vector3.ONE
var last_pos
var will_roll = false

var tx

signal chunk_changed

func _ready():
	direction = Vector3.BACK.rotated(Vector3.UP, $Camroot/h.global_transform.basis.get_euler().y)
	# Sometimes in the level design you might need to rotate the Player object itself
	# So changing the direction at the beginning
	chunk_size = Vector3(Global.DATA.config['chunk_size'], 0.0, Global.DATA.config['chunk_size'])
	tx = {
		Def.TX_PLAYER_STRAFE:  Vector2(0, 0),
		Def.TX_PLAYER_IWR: 0,
		Def.TX_PLAYER_AIM: 1,
		Def.TX_PLAYER_ROLL: false,
		Def.TX_ROTATION: $Mesh.rotation,
		Def.TX_POSITION: translation
	}
	connect("chunk_changed", Global.CLI, "_on_player_chunk_changed")

func _input(event):
	
	
	if event is InputEventMouseMotion:
		aim_turn = -event.relative.x * 0.015 #animates player with mouse movement while aiming (used in line 104)
	
	if event is InputEventKey: #checking which buttons are being pressed
		if event.as_text() == "W" || event.as_text() == "A" || event.as_text() == "S" || event.as_text() == "D" || event.as_text() == "Space":
			if event.pressed:
				get_node("Status/" + event.as_text()).color = Color("ff6666")
			else:
				get_node("Status/" + event.as_text()).color = Color("ffffff")

	if !$AnimationTree.get("parameters/roll/active"): # The "Tap To Roll" system
		if event.is_action_pressed("sprint"):
			if $roll_window.is_stopped():
				$roll_window.start()
				
		if event.is_action_released("sprint"):
			if !$roll_window.is_stopped():
				velocity = direction * roll_magnitude
				$roll_window.stop()
				$AnimationTree.set("parameters/roll/active", true)
				will_roll = true
				$AnimationTree.set("parameters/aim_transition/current", 1)
				$roll_timer.start()

var out = false
func _physics_process(delta):
	if Input.is_action_just_pressed("debug_zoom_out"):
		if not out:
			$Camroot/h/v.translation = Vector3(0, 64, 0)
			$Camroot/h/v/Camera.far = 256
		else:
			$Camroot/h/v.translation = Vector3(0, 1.415, 0)
			$Camroot/h/v/Camera.far = 128
		out = !out
		
	if !$roll_timer.is_stopped():
		acceleration = 3.5
	else:
		acceleration = 5
	var aim = 0
	if Input.is_action_pressed("aim"):
		$Status/Aim.color = Color("ff6666")
		if !$AnimationTree.get("parameters/roll/active"):
			$AnimationTree.set("parameters/aim_transition/current", 0)
	else:
		$Status/Aim.color = Color("ffffff")
		$AnimationTree.set("parameters/aim_transition/current", 1)
		aim = 1
	
	
	var h_rot = $Camroot/h.global_transform.basis.get_euler().y
	
	if Input.is_action_pressed("movement_forward") ||  Input.is_action_pressed("movement_backward") ||  Input.is_action_pressed("movement_left") ||  Input.is_action_pressed("movement_right"):
		
		direction = Vector3(Input.get_action_strength("movement_left") - Input.get_action_strength("movement_right"),
					0,
					Input.get_action_strength("movement_forward") - Input.get_action_strength("movement_backward"))

		strafe_dir = direction
		
		direction = direction.rotated(Vector3.UP, h_rot).normalized()
		
		if Input.is_action_pressed("sprint") && $AnimationTree.get("parameters/aim_transition/current") == 1:
			movement_speed = run_speed
#			$AnimationTree.set("parameters/iwr_blend/blend_amount", lerp($AnimationTree.get("parameters/iwr_blend/blend_amount"), 1, delta * acceleration))
		else:
			movement_speed = walk_speed
#			$AnimationTree.set("parameters/iwr_blend/blend_amount", lerp($AnimationTree.get("parameters/iwr_blend/blend_amount"), 0, delta * acceleration))
	else:
#		$AnimationTree.set("parameters/iwr_blend/blend_amount", lerp($AnimationTree.get("parameters/iwr_blend/blend_amount"), -1, delta * acceleration))
		movement_speed = 0
		strafe_dir = Vector3.ZERO
		
		if $AnimationTree.get("parameters/aim_transition/current") == 0:
			direction = $Camroot/h.global_transform.basis.z
	
	velocity = lerp(velocity, direction * movement_speed, delta * acceleration)

	
	

	if !is_on_floor() and physics_active:
		vertical_velocity += gravity * delta
	else:
		if Input.is_action_just_pressed("movement_jump"):
			vertical_velocity = -jump_speed
			print('jump')
#		else:
#			vertical_velocity = 0
	move_and_slide(velocity + Vector3.DOWN * vertical_velocity, Vector3.UP)
	
	if $AnimationTree.get("parameters/aim_transition/current") == 1:
		$Mesh.rotation.y = lerp_angle($Mesh.rotation.y, atan2(direction.x, direction.z) - rotation.y, delta * angular_acceleration)
		# Sometimes in the level design you might need to rotate the Player object itself
		# - rotation.y in case you need to rotate the Player object
	else:
		$Mesh.rotation.y = lerp_angle($Mesh.rotation.y, $Camroot/h.rotation.y, delta * angular_acceleration)
		# lerping towards $Camroot/h.rotation.y while aiming, h_rot(as in the video) doesn't work if you rotate Player object
		
	
	strafe = lerp(strafe, strafe_dir + Vector3.RIGHT * aim_turn, delta * acceleration)
	
	$AnimationTree.set("parameters/strafe/blend_position", Vector2(-strafe.x, strafe.z))
	
	var iw_blend = (velocity.length() - walk_speed) / walk_speed
	var wr_blend = (velocity.length() - walk_speed) / (run_speed - walk_speed)

	#find the graph here: https://www.desmos.com/calculator/4z9devx1ky

	var iwr = -1
	if velocity.length() <= walk_speed:
		$AnimationTree.set("parameters/iwr_blend/blend_amount" , iw_blend)
		iwr = iw_blend
	else:
		$AnimationTree.set("parameters/iwr_blend/blend_amount" , wr_blend)
		iwr = wr_blend
		
	aim_turn = 0
	
	tx = {
		Def.TX_PLAYER_STRAFE: Vector2(-strafe.x, strafe.z),
		Def.TX_PLAYER_IWR: velocity.length(),
		Def.TX_PLAYER_AIM: aim,
		Def.TX_PLAYER_ROLL: false,
		Def.TX_ROTATION: $Mesh.rotation,
		Def.TX_POSITION: translation
	}
#	$Status/Label.text = "direction : " + String(direction)
#	$Status/Label2.text = "direction.length() : " + String(direction.length())
#	$Status/Label3.text = "velocity : " + String(velocity)
#	$Status/Label4.text = "velocity.length() : " + String(velocity.length())
	
	var pos = Global.DATA.get_chunk_pos( translation )
	if pos != last_pos:
		last_pos = pos
		emit_signal('chunk_changed', last_pos)

