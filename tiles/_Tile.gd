extends Node2D

export (int) var color = 0
export (int) var special = 0
export (int) var score = 0

onready var tween = $Tween
var matched = false

func _process(delta):
	if(matched):
		dim()

func move(target):
	tween.interpolate_property(self, "position", position, target, 0.5, Tween.TRANS_ELASTIC, Tween.EASE_OUT)
	tween.start()

func dim():
	$Sprite.modulate.a = 0.5
