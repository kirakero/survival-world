extends Control



func _on_LoadGame_tree_entered():
	# load games
	
	var games = Global.api.sync_my_world_index()
	var target = $NinePatchRect/VBoxContainer/VBoxContainer
	for game in games:
		var button = $Template/GameOptionButton.duplicate()
		button.connect("pressed", self, "_on_GameOptionButton_pressed", [ button ] )
		var label: Label = button.get_child(0)
		label.text = game
		
		target.add_child(button)
	
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	$NinePatchRect/VBoxContainer/SeedInput.text = str(rng.randi_range(1000000,9999999))
		


func _on_GameOptionButton_pressed(button):
	print('pressed for ', button.get_child(0).text)
	pass # Replace with function body.


func _on_CreateButton_pressed():
	var new_map = {
		'newgame': $NinePatchRect/VBoxContainer/NameInput.text,
		'seed': int($NinePatchRect/VBoxContainer/SeedInput.text),
		'world_size': 8192,
		'chunk_size': 64,
	}
	print(new_map)
	if new_map['newgame'].length() > 0 and new_map['seed'] > 0:
		Global.create_world(new_map)
	pass # Replace with function body.
