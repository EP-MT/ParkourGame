extends CharacterBody3D

var mouse_sensitivity := 0.001
var twist_input := 0.0
var pitch_input := 0.0
var jump_counter = 0
var sprint_counter = 0
var can_wall_run = false
var is_crouching = false
var is_sliding = false
var start_spawn = Vector3.ZERO

var grapple_counter = 0
var is_grappling = false
var grapple_point = Vector3.ZERO
var grapple_speed = 11.0
var grapple_force = 2000.0
var swing_damping = 0.6

@onready var grapplecast = $TwistPivot/PitchPivot/Camera3D/GrappleCast
@export_range(5, 10, 0.1) var Crouch_speed : float = 7.0
@export_range(25, 28, 0.1) var Slide_speed : float = 30.0
@onready var twist_pivot := $TwistPivot
@onready var pitch_pivot := $TwistPivot/PitchPivot
@onready var camera := $TwistPivot/PitchPivot/Camera3D
@onready var body := $Body
@onready var skin := $skin
@onready var raycast = $RayCast3D
@onready var raycast2 = $RayCast3D2
@onready var crouch = $AnimationPlayer
@onready var headbob = $AnimationPlayer
@onready var cast = $coruch_checker
@onready var footsteps = $AudioStreamPlayer3D
@onready var UI = $TwistPivot/PitchPivot/Camera3D/UI/Label

const SPEED = 10.0
const JUMP_VELOCITY = 15
var gravity = 30

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
func _input(event):
	if event.is_action_pressed("R"):
		is_grappling = false
		self.set_position(start_spawn)
		
		if event.is_action_released("LMB"):
			is_grappling = false
	
func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta

	if is_on_floor():
		jump_counter = 0
		can_wall_run = true

	movement(delta)
	wall_run()
	move_and_slide()
	grapple(delta)


	twist_pivot.rotate_y(twist_input)
	pitch_pivot.rotate_x(pitch_input)
	pitch_pivot.rotation.x = clamp(pitch_pivot.rotation.x, deg_to_rad(-75), deg_to_rad(90))
	raycast.rotate_y(twist_input)
	raycast2.rotate_y(twist_input)
	twist_input = 0.0
	pitch_input = 0.0
	
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			twist_input = -event.relative.x * mouse_sensitivity
			pitch_input = -event.relative.y * mouse_sensitivity

func movement(delta):
	var input_dir = Input.get_vector("right", "left", "down", "up")
	var direction = Vector3(input_dir.x, 0, input_dir.y).rotated(Vector3.UP, twist_pivot.rotation.y).normalized()

	if direction:
		velocity.x = -direction.x * SPEED
		velocity.z = -direction.z * SPEED

		if footsteps.playing == false and is_on_floor():
			if is_sliding == false:
				footsteps.play()
		
		if is_on_floor() and direction and footsteps.playing and is_sliding == false and is_crouching == false:
			State("WALKING")
			
		if Input.is_action_pressed("shift") and is_on_floor() and sprint_counter == 0 and not is_crouching and not is_sliding:
			State("SPRINTING")
			velocity.x *= 2
			velocity.z *= 2
			footsteps.stop()
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
		footsteps.stop()

	if input_dir.x > 0:
		twist_pivot.rotation.z = lerp_angle(twist_pivot.rotation.z, deg_to_rad(2.5), 0.05)
	elif input_dir.x < 0:
		twist_pivot.rotation.z = lerp_angle(twist_pivot.rotation.z, deg_to_rad(-2.5), 0.05)
	else:
		twist_pivot.rotation.z = lerp_angle(twist_pivot.rotation.z, deg_to_rad(0), 0.05)

	if Input.is_action_just_pressed("jump") and jump_counter < 1:
		State("JUMPING")
		velocity.y = JUMP_VELOCITY
		jump_counter += 1
		
	Slide()
	
func wall_run():
	if Input.is_action_pressed("jump") and Input.is_action_pressed("up") and is_on_wall():
		if can_wall_run:
			var input_dir = Input.get_vector("right", "left", "down", "up")
			var direction = Vector3(input_dir.x, 0, input_dir.y).rotated(Vector3.UP, twist_pivot.rotation.y).normalized()
			velocity.y = 0
			velocity.x = -direction.x * SPEED * 2
			velocity.z = -direction.z * SPEED * 2
			if raycast.get_collider():
				twist_pivot.rotation.z = lerp_angle(0, 2.5, 0.05)
			elif raycast2.get_collider():
				twist_pivot.rotation.z = lerp_angle(0, -2.5, 0.05)
			jump_counter = 0
			var stick_to_thefucknwall = get_wall_normal()
			direction = stick_to_thefucknwall * SPEED
			State("WALLRUNNING")
			await get_tree().create_timer(4).timeout
			can_wall_run = false
			
func Slide():
	if Input.is_action_just_pressed("slide") and is_on_floor() and is_sliding == false:
		is_sliding = true
		crouch.play("Crouch", -1, Slide_speed, true)
		State("SLIDING")
		velocity.x *= 2
		velocity.z *= 2
		
	elif Input.is_action_just_pressed("slide"):
			is_sliding = false
			crouch.play("Crouch", 1, -Slide_speed)
			State("STANDING") 
			velocity.x /= 2
			velocity.z /= 2
			
func grapple(delta):
	if grapple_counter == 1:
		await get_tree().create_timer(2).timeout
		grapple_counter = 0
		
	elif grapple_counter == 0:
		if Input.is_action_pressed("LMB"):
			grapplecast.force_raycast_update()
			if grapplecast.is_colliding():
				grapple_point = grapplecast.get_collision_point()
				is_grappling = true
				
		if is_grappling:
			var direction = (grapple_point - global_transform.origin).normalized()
			var distance = global_transform.origin.distance_to(grapple_point)

			if distance > 20:
				is_grappling = false
				
			elif distance < 2:
				is_grappling = false
				
			else:
				var grapple_vector = direction * grapple_force * delta
				velocity += grapple_vector
				velocity *= swing_damping
				move_and_slide()
				await get_tree().create_timer(1).timeout
				grapple_counter += 1
				
		else:
			is_grappling = false
		
		
func State(state : String):
	UI.text = "STATE:" + state
