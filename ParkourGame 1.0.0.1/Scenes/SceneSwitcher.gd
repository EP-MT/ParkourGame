extends Node

func changeScene(path : String):
		get_tree().change_scene_to_file(path)
