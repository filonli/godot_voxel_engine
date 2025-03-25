extends RayCast3D

@export var voxel_world: VoxelWorld
# Called when the node enters the scene tree for the first time.
func _ready():
	set_process_input(true) # Replace with function body.

var place_pos:Vector3i

var destroy_pos:Vector3i
var block = 1
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	$HintBreak.visible = is_colliding() and !Input.is_action_pressed("primiary")
	$HintPlace.visible = is_colliding() and Input.is_action_pressed("primiary")
	if is_colliding():
		var pos = get_collision_point()
		var posi = Vector3i(pos)
		place_pos = Vector3i(pos+ get_collision_normal()/3)
		
		$HintPlace.global_position = Vector3(place_pos)+Vector3.ONE/2
		$HintPlace.global_rotation_degrees = Vector3.ZERO
		
		destroy_pos = Vector3i(pos - get_collision_normal()/3)
		
		$HintBreak.global_position = Vector3(destroy_pos)+Vector3.ONE/2
		$HintBreak.global_rotation_degrees = Vector3.ZERO

func _input(event):
	if is_colliding():
		if event.is_action_released("primiary"):
			voxel_world.set_block(place_pos,block)
		if event.is_action_pressed("secondary"):
			voxel_world.set_block(destroy_pos,0)
		
	return
	if event.is_action_pressed("select_1"):
		block = 1
	if event.is_action_pressed("select_2"):
		block = 4
	if event.is_action_pressed("select_3"):
		block = 10
	if event.is_action_pressed("select_4"):
		block = 16
		
	
	if event.is_action_pressed("save_game"):
		voxel_world.save_world()
	
	if event.is_action_pressed("load_game"):
		voxel_world.load_world()
