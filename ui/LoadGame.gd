extends Control
var selected = null


func _on_LoadGame_tree_entered():
	# load games
	
	var games = Global.DATA.sync_my_world_index()
	var target = $NinePatchRect/MarginContainer/VBoxContainer/LocalGamesList
	for game in games:
		var button = $NinePatchRect/MarginContainer/VBoxContainer/LocalGamesList/GameOptionButton.duplicate()
		button.connect("pressed", self, "_on_GameOptionButton_pressed", [ button ] )
		var label: Label = button.get_child(0)
		label.text = game
		
		target.add_child(button)
	target.remove_child($NinePatchRect/MarginContainer/VBoxContainer/LocalGamesList/GameOptionButton)
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	$NinePatchRect/MarginContainer/VBoxContainer/SeedInput.text = str(rng.randi_range(1000000,9999999))
	
	print( OS.get_cmdline_args())
	if OS.get_cmdline_args().size() == 2:
		Global.start_server( OS.get_cmdline_args()[1], true, 'server_password' )
#
#	Global.api.local_server = true
#	Global.api.send_player({'P': Vector3(1, 1, 1)})


func _on_GameOptionButton_pressed(button):
	print('pressed for ', button.get_child(0).text)
	var target = $NinePatchRect/MarginContainer/VBoxContainer/LocalGamesList
	for child in target.get_children():
		if child != button:
			child.pressed = false
	if button.pressed:
		selected = button.get_child(0).text
#	$NinePatchRect.visible = false
#	Global.load_world( button.get_child(0).text )


func _on_CreateButton_pressed():
	var new_map = {
		'newgame': $NinePatchRect/MarginContainer/VBoxContainer/NameInput.text,
		'seed': int($NinePatchRect/MarginContainer/VBoxContainer/SeedInput.text),
		'world_size': 8192,
		'chunk_size': 64,
	}
	print(new_map)
	if new_map['newgame'].length() > 0 and new_map['seed'] > 0:
		Global.create_world(new_map)
	pass # Replace with function body.


func _on_StartButton_pressed():
	if selected != null:
		$NinePatchRect.visible = false
		var server_start = $NinePatchRect/MarginContainer/VBoxContainer/CheckBox.pressed
		var server_password = $NinePatchRect/MarginContainer/VBoxContainer/ServerPWInput.text
		Global.start_local( selected, server_start, server_password )

