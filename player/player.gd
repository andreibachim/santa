extends CharacterBody2D
class_name Player 

const MAX_SPEED = 300.0
const MIN_SPEED = 150.0
const ACC = 25
const DRAG = 25
var speed = MIN_SPEED
const JUMP_VELOCITY = -320.0

@onready var name_label := $Name
@onready var sprite := $Sprite

var player_name: String
var color: Color

var test = 1_000_000.0

func _ready() -> void:
	if (multiplayer.is_server() || multiplayer.get_unique_id() != get_multiplayer_authority()):
		set_physics_process(false)
		$Camera.enabled = false
	else:
		z_index = 2
	name_label.text = player_name
	sprite.self_modulate = color

var jmp: float = 0.0
func _physics_process(delta: float) -> void:
	if not is_on_floor():
		if Input.is_action_pressed("ui_accept"):
			jmp = lerp(jmp, 0.0, 0.1)
		else: 
			jmp = 0.0
		velocity.y += (980 - jmp) * delta
		speed = max(MIN_SPEED, speed - DRAG * delta)
	else:
		velocity.y = 0
		speed = min(MAX_SPEED, speed + ACC * delta)
		
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y -= 200
		jmp = 1000
		
	velocity.x = 1 * speed
	move_and_slide()

func set_player_name(value: String) -> void:
	player_name = value

func set_color(value: Color) -> void:
	color = value
