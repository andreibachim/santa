extends CharacterBody2D
class_name Player 

const SPEED = 150.0
const JUMP_VELOCITY = -320.0

func _enter_tree() -> void:
	if (multiplayer.is_server()):
		set_multiplayer_authority(multiplayer.get_remote_sender_id())
	else:
		print("Setting authority to " + str(multiplayer.get_unique_id()))
		set_multiplayer_authority(multiplayer.get_unique_id())
		
func update_color(color: Color) -> void:
	print("this code run on the server? " +  str(multiplayer.is_server()))
	modulate = color

func _physics_process(delta: float) -> void:
	if multiplayer.is_server(): return
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
