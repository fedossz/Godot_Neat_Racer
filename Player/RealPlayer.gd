extends KinematicBody2D



var vel = Vector2()
var v = 0
var turn_dir
var next_rot
var score = 0.1
var time_idle: float
var time_d: float
var turn_force: float
var lost_control: bool
var lc_turned: bool
var is_moving: bool

export (Texture) var dot_texture

signal death

func _ready():
	rotation_degrees = -80
	$"../../RaceTrack1/finish_cp".connect("body_entered", self, "loop_completed")
	for rcp in $"../../RaceTrack1/reward_cp".get_children():
		rcp.connect("body_entered", self, "add_score")
	for i in range($Rays.get_child_count()):
		var new_ins_dot = Sprite.new()
		new_ins_dot.set_texture(dot_texture)
		new_ins_dot.scale = Vector2(3,3)
		new_ins_dot.material = ShaderMaterial.new()
		new_ins_dot.material.shader = load("res://Player/RedColorChange.shader")
		new_ins_dot.material.set_shader_param("new_color", Color(1, 1, 0, 1))
		$Ray_dots.add_child(new_ins_dot)



func _physics_process(delta):
	if rand_range(0, 100) < 5:
		lost_control = false
	if !lost_control:
		player_input()
		pass
	else:
		if !lc_turned:
			next_rot = rotation_degrees + 60 * turn_dir
			lc_turned = true
		rotation_degrees = lerp(rotation_degrees, next_rot, 0.07)
		v -= 3
	if v < 20:
		lost_control = false
		lc_turned = false

	vel.x = v * sin(rotation)
	vel.y = v * cos(rotation)
	vel.y = -vel.y

	move_and_slide(vel)
	
	if is_on_ceiling() or is_on_floor() or is_on_wall():
		crash()


func _process(delta):
	time_d += delta
	if !v:
		time_idle += delta
	else:
		time_idle = 0
	if time_idle > 500 and is_moving == false and (v < 5 and v > -5):
		score = -3
		crash()
	for i in range(len($Rays.get_children())):
		if $Rays.get_children()[i].is_colliding():
			$Ray_dots.get_children()[i].visible = true
			$Ray_dots.get_children()[i].position = to_local($Rays.get_children()[i].get_collision_point())
		else:
			$Ray_dots.get_children()[i].visible = false
	#$Raycastposlinedr.update()




func player_input():
	if Input.is_action_pressed("gasgasgas"):
		gas()
	elif Input.is_action_pressed("brakeme"):
		brake()
	if v != 0:
		if Input.is_action_pressed("turn_left"):
			turn_left()
		elif Input.is_action_pressed("turn_right"):
			turn_right()
		if Input.is_action_just_released("turn_left") or Input.is_action_just_released("turn_right"):
			turn_force = 0


func gas():
	v = clamp(v + 3, v+3, $"../..".max_speed)


func brake():
	v -= 5


func turn_left():
	turn_force += 0.1
	turn_dir = -1
	rotation_degrees -= clamp(abs(v * 0.01), 0, 4.5)
	if (v > 83 or v < -50) and turn_force > 12:
		lost_control = true
		turn_force = 0
		v -= 4


func turn_right():
	turn_force += 0.1
	turn_dir = 1
	rotation_degrees += clamp(abs(v * 0.01), 0, 4.5)
	if (v > 83 or v < -50) and turn_force > 12:
		lost_control = true
		turn_force = 0
		v -= 4



func add_score(body):
	if body == self:
		if v < 0:
			score -= 2
		else:
			score += 1
	#uncomment this if you want to display player's score too
	#$"../..".update_score(score)


func loop_completed(body):
	if body == self:
		if score >= 28:
			score += 10





func crash():
	emit_signal("death")
	score = 0
	#$"../..".reset_score()
	respawn()



func respawn():
	v = 0
	vel = Vector2(0, 0)
	rotation_degrees = -80
	position = Vector2(0, 0)
