@tool
extends MeshInstance3D
class_name ChunkMeshInstance

# Called when the node enters the scene tree for the first time.
func _ready():
	set_process(true)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Engine.is_editor_hint(): return
	var distance_to_camera = get_viewport().get_camera_3d().global_position.distance_to(global_position)
	
	visible = distance_to_camera < Chunk.chunk_size.length()*8
	
	if distance_to_camera < 25:
		add_to_group('nav_mesh')
		#visible = true
	else :
		remove_from_group('nav_mesh')
		#visible = false
