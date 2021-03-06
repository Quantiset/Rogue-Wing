extends Node2D



func _process(delta: float) -> void:
	$ParallaxBackground.scroll_offset += Vector2(delta * 60, delta * 60)



func _on_TouchScreenButton_pressed(button: String):
	match button:
		"Start":
			get_tree().change_scene("res://Scenes/Main.tscn")
		"Quit":
			get_tree().quit()
		"Ship":
			get_tree().change_scene("res://Scenes/ShipSelect.tscn")


func _on_TheButton_mouse_entered(button: String):
	get_node(button+"Button").modulate.a = 1.2
func _on_TheButton_mouse_exited(button: String):
	get_node(button+"Button").modulate.a = 1
