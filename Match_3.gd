extends Node2D

export (int) var start = 2
var normal_start = 2
export (int) var difficulty = 0
export (int) var y_offset = 2
export (float) var level_scale = 1.5
export (int) var level_start = 75
export (int) var fill_lines = 3

export (bool) var toggle_delete_debug = true

var width = 3
var height = 5
var x_start = 192
var y_start = 960
var offset = 128

var start_touch = Vector2.ZERO
var end_touch = Vector2.ZERO
var buffer = 50
var moving = false

var grid = []
var random = RandomNumberGenerator.new()

var max_moves = 1
var move_count = 0

var special_used = false
export (int) var special_counter_max = 10
var special_counter = 0

onready var tiles = [
	preload("res://tiles/Wild.tscn"),
	preload("res://tiles/Bomb.tscn"),
	preload("res://tiles/Rock.tscn"),
	preload("res://tiles/Blue.tscn"), 
	preload("res://tiles/Red.tscn"),
	preload("res://tiles/Yellow.tscn"),
	preload("res://tiles/Green.tscn"),
	preload("res://tiles/Purple.tscn"),
	preload("res://tiles/Light_Pink.tscn"),
	preload("res://tiles/Light_Orange.tscn"),
	preload("res://tiles/Light_Green.tscn")]

onready var skills = []

enum {
	WAIT,
	MOVE
}
onready var STATE = MOVE

var _score_disable = false
var score_bar
var level_up_ui
var drill

func _ready():
	drill = get_parent().get_node("drill")
	level_up_ui = get_parent().get_node("Container")
	score_bar = get_parent().get_node("bar")
	score_bar.max_value = level_start
	random.randomize()
	for x in width:
		grid.append([])
		for _y in height:
			grid[x].append(null)
	_generate_grid()


func _generate_grid():
	for y in height:
		for x in width:
			var m = start
			if(special_used):
				m = normal_start
			var i = random.randi_range(m, clamp(m + difficulty, m, tiles.size() - 1))
			var node = tiles[i].instance()
			var loops = 0
			while(_pattern_match(x, y, i) && loops < 100):
				i = random.randi_range(m, clamp(m + difficulty, m, tiles.size() - 1))
				loops += 1
			if(i == 0 or i == 1):
				special_used = true
			node = tiles[i].instance()
			node.set_position(_grid_to_pixel(Vector2(x,y)))
			self.add_child(node)
			grid[x][y] = node


func _refill_grid():
	for y in height:
		for x in width:
			if(grid[x][y] == null):
				var m = start
				if(special_used):
					m = normal_start
				var i = random.randi_range(m, clamp(m + difficulty, m, tiles.size() - 1))
				var node = tiles[i].instance()
				var loops = 0
				while(_pattern_match(x, y, i) && loops < 100):
					i = random.randi_range(m, clamp(m + difficulty, m, tiles.size() - 1))
					loops += 1
				if(i == 0 or i == 1):
					special_used = true
				node = tiles[i].instance()
				self.add_child(node)
				node.set_position(_grid_to_pixel(Vector2(x,y - y_offset)))
				node.move(_grid_to_pixel(Vector2(x,y)))
				$swipe2.play()
				grid[x][y] = node
	_post_refill()


func _refill_line(size):
	for y in size:
		for x in width:
			if(grid[x][y] == null):
				var m = start
				if(special_used):
					m = normal_start
				var i = random.randi_range(m, clamp(m + difficulty, m, tiles.size() - 1))
				var node = tiles[i].instance()
				var loops = 0
				while(_pattern_match(x, y, i) && loops < 100):
					i = random.randi_range(m, clamp(m + difficulty, m, tiles.size() - 1))
					loops += 1
				if(i == 0 or i == 1):
					special_used = true
				node = tiles[i].instance()
				self.add_child(node)
				node.set_position(_grid_to_pixel(Vector2(x,y - y_offset)))
				node.move(_grid_to_pixel(Vector2(x,y)))
				$swipe2.play()
				grid[x][y] = node
	for y in range(height - 1, 0, -1):
		for x in width:
			if grid[x][y] == null:
				for k in range(y - 1, -1 , -1):
					if grid[x][k] != null:
						grid[x][k].move(_grid_to_pixel(Vector2(x,y)))
						$swipe2.play()
						grid[x][y] = grid[x][k]
						grid[x][k] = null
						break
	_post_refill()

func shift_up():
	var used = false
	_count_special()
	for y in range(height -1, -1, -1):
		for x in width:
			if(grid[x][y] != null):
				if(y + 1 >= height):
					if(_score_disable == false):
						score_bar.value -= grid[x][y].score
					Global.health -= grid[x][y].score
					grid[x][y].queue_free()
					grid[x][y] = null
					Global.depth += 1
					used = true
				else:
					grid[x][y].move(_grid_to_pixel(Vector2(x,y + 1)))
					grid[x][y + 1] = grid[x][y]
					grid[x][y] = null
	if(used): $swipe.play()

func _is_in_bounds(position: Vector2) -> bool:
	if(position.x < width and position.x >= 0):
		if(position.y < height and position.y >= 0):
			return true
	return false

func _bomb(position):
	var a = clamp(position.x + 1, 0, width - 1)
	var b = clamp(position.y + 1, 0, height - 1)
	var c = clamp(position.x - 1, 0, width)
	var d = clamp(position.y - 1, 0, width)

	var n = grid[position.x][position.y]
	n.matched = true
	
	n = grid[a][position.y]
	if(n != null and not n.matched):
		if(n.special == 1): _bomb(Vector2(a,position.y))
		n.matched = true
	n = grid[c][position.y]
	if(n != null and not n.matched):
		if(n.special == 1): _bomb(Vector2(c,position.y))
		n.matched = true
	n = grid[position.x][b]
	if(n != null and not n.matched):
		if(n.special == 1): _bomb(Vector2(position.x,b))
		n.matched = true
	n = grid[position.x][d]
	if(n != null and not n.matched):
		if(n.special == 1): _bomb(Vector2(position.x,d))
		n.matched = true

func _swap(position, direction):
	var new_tile = grid[position.x][position.y]
	var old_tile = grid[position.x + direction.x][position.y + direction.y]
	
	if(new_tile == null): return
	if(old_tile == null): return
	
	if(new_tile.special > 0):
		#Bomb
		if(new_tile.special == 1):
			_bomb(position)
		STATE = WAIT
		move_count += 1
		find_matches()
	else:
		STATE = WAIT
		move_count += 1
		grid[position.x][position.y] = old_tile
		grid[position.x + direction.x][position.y + direction.y] = new_tile
		old_tile.move(_grid_to_pixel(position))
		new_tile.move(_grid_to_pixel(Vector2(position.x + direction.x, position.y + direction.y)))
		$swipe.play()
		find_matches()

func _find_direction(alpha: Vector2, beta: Vector2) -> Vector2:
	var diff = beta - alpha
	if(abs(diff.x) > abs(diff.y)):
		if(diff.x > 0 and diff.x > buffer):
			return Vector2(1,0)
		elif(diff.x < 0 and diff.x < -buffer):
			return Vector2(-1,0)
	elif(abs(diff.x) < abs(diff.y)):
		if(diff.y > 0 and diff.y > buffer):
			return Vector2(0,-1)
		elif(diff.y < 0 and diff.y < -buffer):
			return Vector2(0,1)
	return Vector2.ZERO

func _match_color(color: int, check: int, special: int = 0) -> bool:
	if(color != -1):
		if(check == color or check == 0): return true
		else: return false
	else:
		return false

func _pattern_match(x, y, color) -> bool:
	if(x > 1):
		#Check 3 Left
		if(grid[x - 1][y] != null and grid[x - 2][y] != null):
			if(_match_color(color, grid[x- 1][y].color) and _match_color(color, grid[x- 2][y].color)):
				return true
	if(y > 1):
		#Check 3 Down
		if(grid[x][y - 1] != null and grid[x][y - 2] != null):
			if(_match_color(color, grid[x][y - 1].color) and _match_color(color, grid[x][y - 2].color)):
				return true
	if(x > 0  and x < width):
		if(y > 0 and y < height):
			#Left T
			if(grid[x - 1][y] != null and grid[x][y - 1] != null):
				if(_match_color(color, grid[x - 1][y].color) and _match_color(color, grid[x][y - 1].color)):
					return true
			#Right T
			if(grid[x - 1][y] != null and grid[x - 1][y - 1] != null):
				if(_match_color(color, grid[x - 1][y].color) and _match_color(color, grid[x - 1][y - 1].color)):
					return true
			#Reverse L
			if(grid[x][y - 1] != null and grid[x - 1][y - 1] != null):
				if(_match_color(color, grid[x][y - 1].color) and _match_color(color, grid[x - 1][y - 1].color)):
					return true
			#L
			if(x + 1 < width):
				if(grid[x][y - 1] != null and grid[x + 1][y - 1] != null):
					if(_match_color(color, grid[x][y - 1].color) and _match_color(color, grid[x + 1][y - 1].color)):
						return true
	return false


func find_matches():
	for x in width:
		for y in height:
			if grid[x][y] != null:
				var color = grid[x][y].color
				if(x > 1):
					#Check 3 Left
					if(grid[x - 1][y] != null and grid[x - 2][y] != null):
						if(_match_color(color, grid[x - 1][y].color) and _match_color(color, grid[x - 2][y].color)):
							if(grid[x][y].special == 1):
								_bomb(Vector2(x,y))
							else:
								grid[x][y].matched = true
							if(grid[x-1][y].special == 1):
								_bomb(Vector2(x-1,y))
							else:
								grid[x-1][y].matched = true
							if(grid[x-2][y].special == 1):
								_bomb(Vector2(x-2,y))
							else:
								grid[x-2][y].matched = true
				if(y > 1):
					#Check 3 Down
					if(grid[x][y - 1] != null and grid[x][y - 2] != null):
						if(_match_color(color, grid[x][y - 1].color) and _match_color(color, grid[x][y - 2].color)):
							if(grid[x][y].special == 1):
								_bomb(Vector2(x,y))
							else:
								grid[x][y].matched = true
							if(grid[x][y-1].special == 1):
								_bomb(Vector2(x,y-1))
							else:
								grid[x][y-1].matched = true
							if(grid[x][y-2].special == 1):
								_bomb(Vector2(x,y-2))
							else:
								grid[x][y-2].matched = true
				if(x + 1 < width):
					if(y > 0 and y < height):
						#L
						if(grid[x][y - 1] != null and grid[x + 1][y - 1] != null):
							if(_match_color(color, grid[x][y - 1].color) and _match_color(color, grid[x + 1][y - 1].color)):
								if(grid[x][y].special == 1):
									_bomb(Vector2(x,y))
								else:
									grid[x][y].matched = true
								if(grid[x][y-1].special == 1):
									_bomb(Vector2(x,y-1))
								else:
									grid[x][y-1].matched = true
								if(grid[x + 1][y - 1].special == 1):
									_bomb(Vector2(x+1,y-1))
								else:
									grid[x + 1][y - 1 ].matched = true
				if(x > 0  and x < width):
					if(y > 0 and y < height):
						#Left T
						if(grid[x - 1][y] != null and grid[x][y - 1] != null):
							if(_match_color(color, grid[x - 1][y].color) and _match_color(color, grid[x][y - 1].color)):
								if(grid[x][y].special == 1):
									_bomb(Vector2(x,y))
								else:
									grid[x][y].matched = true
								if(grid[x-1][y].special == 1):
									_bomb(Vector2(x-1,y))
								else:
									grid[x-1][y].matched = true
								if(grid[x][y-1].special == 1):
									_bomb(Vector2(x,y-1))
								else:
									grid[x][y-1].matched = true
						#Right T
						if(grid[x - 1][y] != null and grid[x - 1][y - 1] != null):
							if(_match_color(color, grid[x - 1][y].color) and _match_color(color, grid[x - 1][y - 1].color)):
								if(grid[x][y].special == 1):
									_bomb(Vector2(x,y))
								else:
									grid[x][y].matched = true
								if(grid[x-1][y].special == 1):
									_bomb(Vector2(x-1,y))
								else:
									grid[x-1][y].matched = true
								if(grid[x-1][y-1].special == 1):
									_bomb(Vector2(x-1,y-1))
								else:
									grid[x-1][y-1].matched = true
						#Reverse L
						if(grid[x][y - 1] != null and grid[x - 1][y - 1] != null):
							if(_match_color(color, grid[x][y - 1].color) and _match_color(color, grid[x - 1][y - 1].color)):
								if(grid[x][y].special == 1):
									_bomb(Vector2(x,y))
								else:
									grid[x][y].matched = true
								if(grid[x][y-1].special == 1):
									_bomb(Vector2(x,y-1))
								else:
									grid[x][y - 1].matched = true
								if(grid[x-1][y-1].special == 1):
									_bomb(Vector2(x-1,y-1))
								else:
									grid[x - 1][y - 1].matched = true
	get_parent().get_node("trashcan_timer").start()


func remove_matches():
	for x in width:
		for y in height:
			if grid[x][y] != null:
				if grid[x][y].matched:
					if(_score_disable == false):
						score_bar.value += grid[x][y].score
					grid[x][y].queue_free()
					grid[x][y] = null
	get_parent().get_node("collapse_timer").start()

func collapse():
	for y in range(height - 1, 0, -1):
		for x in width:
			if grid[x][y] == null:
				for k in range(y - 1, -1 , -1):
					if grid[x][k] != null:
						grid[x][k].move(_grid_to_pixel(Vector2(x,y)))
						grid[x][y] = grid[x][k]
						grid[x][k] = null
						$swipe2.play()
						break
	get_parent().get_node("refill_timer").start()


func _grid_to_pixel(position: Vector2) -> Vector2:
	return Vector2(x_start + offset * position.x, y_start - offset * position.y)


func _pixel_to_grid(position: Vector2) -> Vector2:
	return Vector2(round((position.x - x_start) / offset), round((position.y - y_start) / -offset))


func touch_input():
	if(Input.is_action_just_pressed("ui_touch")):
		start_touch = get_global_mouse_position()
		var pos = _pixel_to_grid(start_touch)
		if(_is_in_bounds(pos)):
			moving = true
	if(Input.is_action_just_released("ui_touch")):
		end_touch = get_global_mouse_position()
		var pos = _pixel_to_grid(end_touch)
		if(_is_in_bounds(pos) and moving):
			var dir = _find_direction(start_touch, end_touch)
			if (dir != Vector2.ZERO):
				_swap(_pixel_to_grid(start_touch), dir)
				find_matches()
				moving = false

func _count_special():
	special_counter += 1
	if(special_counter > special_counter_max):
		special_used = false


func _process(_delta):
	if(STATE == MOVE):
		drill.stop(false)
		touch_input()
	elif(STATE == WAIT):
		drill.play("idle")


func _post_refill():
	get_parent().get_node("Label").text = ("DEPTH: %d" % Global.depth)
	get_parent().get_node("health").get_node("Label").text = ("HEALTH: %d" % Global.health)
	if(Global.health < 0):
		SceneChanger.change_scene("res://ui/GameOver.tscn")
		STATE = MOVE
	else:
		for x in width:
			for y in height:
				if grid[x][y] != null:
					if(score_bar.value >= score_bar.max_value):
						_post_score()
						return
					if(_pattern_match(x,y,grid[x][y].color)):
						find_matches()
						get_parent().get_node("trashcan_timer").start()
						return
		if(score_bar.value < score_bar.max_value):
			if(move_count < max_moves):
				STATE = MOVE
			else:
				move_count = 0
				shift_up()
				STATE = MOVE
		else:
			shift_up()
			STATE = MOVE


func _post_score():
	if(!_score_disable):
		$ding.play()
		SceneChanger.layer = 0
		drill.get_node("AnimatedSprite").visible = false
		level_up_ui.visible = true
	else:
		_on_level_GUI_CLOSE()

func _on_trashcan_timeout():
	if(toggle_delete_debug):
		remove_matches()
	else:
		get_parent().get_node("trashcan_timer").start()


func _on_collapse_timeout():
	collapse()


func _on_refill_timeout():
	#_refill_grid()
	_refill_line(fill_lines)


func has_skill_name(id: String) -> bool:
	for i in skills:
		if(i == id):
			print ("%s is %s" % [i, id])
			return i[0]
	return false

func add_skill(id: String) -> bool:
	if(has_skill_name(id)): return false
	else:
		skills.append(id)
		if (id == "double_move"):
			max_moves = 2
		if (id == "triple_move"):
			max_moves = 3
		if (id == "bonus_scan"):
			difficulty = clamp(difficulty + 2, start, 99)
		if (id == "bonus_scan_adv"):
			fill_lines = clamp(fill_lines + 1, 0, height - 1)
			difficulty = clamp(difficulty + 2, start, 99)
		if (id == "bonus_scan_mega"):
			fill_lines = clamp(fill_lines + 2, 0, height - 1)
			difficulty = clamp(difficulty + 2, start, 99)
		if(id == "wild"):
			start = 0
		if(id == "bomb"):
			start = 1
		if(id == "auto_bomb"):
			tiles[1] = preload("res://tiles/AutoBomb.tscn")
		return true

func _on_level_GUI_CLOSE():
	SceneChanger.layer = 1
	drill.get_node("AnimatedSprite").visible = true
	score_bar.max_value = ceil(score_bar.max_value * level_scale)
	#level_up_ui._check_skills()
	if(level_up_ui.skills_left() > 0):
		score_bar.value = 0
	else:
		score_bar.value = 0
		score_bar.visible = false
		_score_disable = true
	
	if level_up_ui.owns_skill_name("double_move"):
			add_skill("double_move")
	if level_up_ui.owns_skill_name("triple_move"):
			add_skill("triple_move")
	if level_up_ui.owns_skill_name("bonus_scan"):
			add_skill("bonus_scan")
	if level_up_ui.owns_skill_name("bonus_scan_adv"):
			add_skill("bonus_scan_adv")
	if level_up_ui.owns_skill_name("bonus_scan_mega"):
			add_skill("bonus_scan_mega")
	if level_up_ui.owns_skill_name("wild"):
			add_skill("wild")
	if level_up_ui.owns_skill_name("bomb"):
			add_skill("bomb")
	if level_up_ui.owns_skill_name("auto_bomb"):
			add_skill("auto_bomb")
	STATE = MOVE
