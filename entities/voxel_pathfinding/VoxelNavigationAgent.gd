extends Node3D
class_name VoxelNavigationAgent

var target_pos:Vector3
var path:Array[Vector3]

@onready var last_update_time = Time.get_unix_time_from_system()

@onready var _pathfinder = get_parent().get_parent().get_node("VoxelPathfinder") as VoxelPathfinder

func _ready():
	_pathfinder.agents.append(self)

func _exit_tree():
	_pathfinder.agents.erase(self)

func is_has_path()-> bool:
	return path != null and path.size()>0

func get_next_point() -> Vector3:
	var pos_offset = Vector3(0.5,0,0.5)
	if is_has_path():
		if global_position.distance_to(path[0]+pos_offset)< 0.75:
			
			path.remove_at(0)
		
		if is_has_path():
			return path[0]+pos_offset
	return Vector3.ZERO
