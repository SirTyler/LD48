extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _input(event):
	if Input.is_action_just_pressed("ui_accept"):
		$Timer.stop()
		_on_Timer_timeout()


func _on_Timer_timeout():
	SceneChanger.change_scene("res://ui/instructions/instructions.tscn")
