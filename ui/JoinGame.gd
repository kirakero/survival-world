extends Control



func _on_StartButton_pressed():
	$NinePatchRect.visible = false
	var server_host = $NinePatchRect/MarginContainer/VBoxContainer/ServerHostInput.text
	var server_password = $NinePatchRect/MarginContainer/VBoxContainer/ServerPWInput.text
	Global.start_remote( server_host, server_password )

