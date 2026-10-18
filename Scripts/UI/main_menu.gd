extends Node2D

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://Scene/level_test.tscn")


func _on_options_pressed() -> void:
	#get_tree().change_scene_to_file("res://Scenes/UI/Options.tscn")
	pass

func _on_quit_pressed() -> void:
	get_tree().quit()
