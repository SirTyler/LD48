extends Node

export (int) var offset = 96

signal GUI_CLOSE

var skills = [
	["Double Move", "double_move", false, null],
	["Triple Move", "triple_move", false, "double_move"],
	["Treasure Scanner", "bonus_scan", false, null],
	["Advanced Treasure Scanner","bonus_scan_adv", false, "bonus_scan"],
	["Mega Treasure Scanner", "bonus_scan_mega", false, "bonus_scan_adv"],
	["Rock Bomb", "bomb", false, null],
	["Wild Tile", "wild", false, "bomb"],
	["Wild Bomb", "auto_bomb", false, "wild"]
]
var skills_owned = []
onready var skill_base = preload("res://skills/_Skill.tscn")

func _ready():
	SceneChanger.layer = 0
	_generate_skills()

func get_skill(id: int):
	if(id > 0 and id < skills.size()):
		#Name, refrence, enabled
		return skills[id]
	else: return null

func skills_left() -> int:
	return (skills.size() - skills_owned.size())

func has_skill(id: int) -> bool:
	if(id > 0 and id < skills.size()):
		return skills[id][2]
	else: return false

func owns_skill_name(id: String) -> bool:
	for i in skills_owned:
		if(i == id):
			return true
	return false

func has_skill_name(id: String) -> bool:
	for i in skills:
		if(i[1] == id):
			return i[2]
	return false

func _generate_skills():
	for i in skills.size():
		var node = skill_base.instance()
		var button = node.get_node("Button")
		var label = node.get_node("Button/Label")
		
		label.text = skills[i][0]
		node.set_position(Vector2(0,(i * 128) + offset))
		if(!skills[i][2]):
			button.connect("toggled", self, "_skill_toggle")
		else:
			button.pressed = true
			button.disabled = true
		self.add_child(node)
		skills[i].append(node)
	_disable_unowned_preq()

func _check_skills():
	skills_owned.clear()
	for i in skills.size():
		var node = skills[i][4]
		var button = node.get_node("Button")
		button.pressed = skills[i][2]
		if(button.pressed):
			button.disabled = true
			skills_owned.append(skills[i][1])
		else:
			button.disabled = false
	_disable_unowned_preq()

func _disable_unowned_preq():
	for i in skills.size():
		var node = skills[i][4]
		var button = node.get_node("Button")
		if(not owns_skill_name(skills[i][1])):
				var preq = skills[i][3]
				if(preq != null and owns_skill_name(preq)):
					button.disabled = false
				elif(preq == null):
					button.disabled = false
				else:
					button.disabled = true

func _skill_toggle(value):
	var close = false
	for i in skills.size():
		var node = skills[i][4]
		var button = node.get_node("Button")
		if(button.pressed):
			if(not owns_skill_name(skills[i][1])):
				var preq = skills[i][3]
				if(preq != null and owns_skill_name(preq)):
					skills_owned.append(skills[i][1])
					skills[i][2] = true
					button.disabled = true
					close = true
				elif(preq == null):
					skills_owned.append(skills[i][1])
					skills[i][2] = true
					button.disabled = true
					close = true
				else:
					close = false
					button.pressed = false
			else:
				close = false
				button.pressed = false
	if(close):
		self.visible = false
		emit_signal("GUI_CLOSE")
