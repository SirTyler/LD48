extends Node2D

func _ready():
	$Label.text = "MAX DEPTH:\n%d" % Global.depth

func _input(event):
	if Input.is_action_just_pressed("ui_accept"):
		Global.depth = 0
		Global.health = Global.max_health
		SceneChanger.change_scene("res://load.tscn")
