extends Node2D

var timer = 1

func _input(event):
	if Input.is_action_just_pressed("ui_accept"):
		next_timer()

func next_timer():
	if(timer == 1):
		_on_Timer_timeout()
		$Timer.stop()
	elif(timer == 2):
		_on_Timer2_timeout()
		$Timer2.stop()
	elif(timer == 3):
		_on_Timer3_timeout()
		$Timer3.stop()

func _on_Timer_timeout():
	timer += 1
	$AnimatedSprite.visible = false
	$Timer2.start()

func _on_Timer2_timeout():
	timer += 1
	$AnimatedSprite2.visible = false
	$Timer3.start()

func _on_Timer3_timeout():
	SceneChanger.change_scene("res://default.tscn")
