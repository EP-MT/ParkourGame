extends Node3D

var scene_counter = 0
var scene_list = ["","res://Scenes/Level_Hub.tscn"]

func _on_area_3d_body_entered(body):
	if body.is_in_group("Player"):
		scene_counter += 1
		print("Inside")
		SceneSwitcher.changeScene(scene_list[scene_counter])
		

	
