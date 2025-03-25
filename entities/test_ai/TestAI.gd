extends CharacterBody3D

@onready var target: Node3D = get_parent().get_node("Player")
#@onready var agent = $NavigationAgent3D
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")


var rand_pos:Vector3 
var jumpTimer:float = 0
func update_rand_pos():
	rand_pos = position + Vector3(randf_range(-1,1),0,randf_range(-1,1))*5

func _ready():
	randomize()
	update_rand_pos()
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	#if !target: return
	var noYTargPos = rand_pos
	if target.position.distance_to(position) < 25:
		noYTargPos = target.position
	
	
	
	noYTargPos.y = position.y
	if (noYTargPos-position).length()>1: 
		look_at(noYTargPos)
		velocity = (noYTargPos-position).normalized()*2
	
	if is_on_floor() and $JumpCast.is_colliding() and !$hCheck.is_colliding():
		jumpTimer = 0.15
		
		
	if jumpTimer > 0:
		velocity.y = 15
		jumpTimer = move_toward(jumpTimer,-0.1,delta)
	else:
		velocity.y = -gravity
		
	move_and_slide()
