extends Control

@onready var controls = $GridContainer/Control
@onready var lab = $GridContainer/Label
@onready var res = $GridContainer/Resume
@onready var con = $GridContainer/Controls
@onready var time = $GridContainer/times
@onready var quit = $GridContainer/Quit
@onready var back = $GridContainer/Back
var t = true
var f = false

var esc_counter = 0

var is_paused = false:
	set = set_pause

func _input(event):
	if event.is_action_pressed("esc") and esc_counter == 0:
		is_paused = !is_paused
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		esc_counter += 1
		
	elif event.is_action_pressed("esc") and esc_counter == 1:
		is_paused = !is_paused
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		esc_counter -= 1

func set_pause(value:bool):
	is_paused = value
	get_tree().paused = is_paused
	visible = is_paused
	
	

func _on_resume_pressed():
	is_paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	esc_counter -= 1

func _on_controls_pressed():
	visiblilty(f,f,f,f,f,t,t)

func _on_times_pressed():
	print("loop")

func _on_quit_pressed():
	get_tree().quit()


func _on_back_pressed():
	visiblilty(t,t,t,t,t,f,f)


func visiblilty(a : bool, b : bool, c : bool, d : bool, e : bool, f : bool, g : bool):
	lab.visible = a
	res.visible = b
	con.visible = c
	time.visible = d
	quit.visible = e
	controls.visible = f
	back.visible = g
