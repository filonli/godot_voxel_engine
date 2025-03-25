
extends Node3D
class_name VoxelPathfinder

class path_node:	
	extends Object
	
	var pos:Vector3i 
	var parent: path_node
	
	func cost(posA:Vector3,posB:Vector3)->float:
		var Gcost = posA.distance_to(Vector3(pos))
		var Hcost = posB.distance_to(Vector3(pos))
		var Fcost = Gcost+Hcost
		return Fcost

@export_category("Navigation settings")

@export var max_iterations := 50
@export var nagigation_update_rate:= 3.0
@export_category("DEBUG")
@export var debug_mesh_done: Mesh
@export var debug_mesh_new: Mesh
@export var path_debug_material: Material
@export var GENERATE := false
@export var debug := false
@export var debug_path := false

var start_point:Vector3
var target_point:Vector3
var voxel_world
var done_nodes = []
var new_nodes = []
var lastNode = null
var cur_path : Array[Vector3]

var time_to_update := 1.0

var a:int = 0
var iterating_navigation = false
var nav_done:= false

var agents :Array[VoxelNavigationAgent]
var cur_agent = null
var agents_cycle = 0

#GENERATION
func generate_navigation():
	
	iterating_navigation = true
	voxel_world = get_parent().get_node("VoxelWorld") as VoxelWorld
	
	start_point = cur_agent.global_position
	target_point = cur_agent.target_pos
	
	done_nodes = []
	new_nodes = []
	
	var posi = Vector3i(start_point)
	
	var n = path_node.new()
	n.pos = posi
	n.parent = null
	new_nodes.append(n)
	
	update_debug()
	
	a = 0
	nav_done = false

func _process(delta):
	
	updating_agents()
	
	if cur_agent and!nav_done:
		iterations_loop()
		
	
	if Engine.is_editor_hint():
		if GENERATE:
			GENERATE = false
			generate_navigation()

func iterations_loop():
	
	a+=1
	if a > max_iterations:
		nav_done = true
		a-=1
	else:
		nav_done = iteration()
	
	if nav_done:
		generate_path()
		

func voxel_check(pos) ->bool:
	#is in block
	var block = voxel_world.get_block(pos)
	if block != 0:return false
	
	#is dont has block under
	var block_under = voxel_world.get_block(pos+Vector3i.DOWN)
	if block_under == 0:return false
	
	#is has block above
	var block_above = voxel_world.get_block(pos+Vector3i.UP)
	if block_above != 0:return false
	
	return true

func add_node(pos,parent,array):
	if !voxel_check(pos):return
	
		
	
		
	var posi = Vector3i(pos)
	
	for i in new_nodes:
		if i.pos == posi:
			
			return
	for i in done_nodes:
		if i.pos == posi:
			
			return
	
	var n = path_node.new()
	n.pos = posi
	n.parent = parent
	array.append(n)

func iteration()->bool:
	if new_nodes.is_empty():
		return false
	
	
	var lcostNode = new_nodes[0]
	var lowestCost = 1000000000.0
	for n in new_nodes:
		var c = n.cost(start_point,target_point)
		
		if c < lowestCost:
			lcostNode = n
			lowestCost = c
	
	done_nodes.append(lcostNode)
	
	#flat_plane
	add_node(lcostNode.pos+Vector3i.LEFT,lcostNode,new_nodes)
	add_node(lcostNode.pos+Vector3i.RIGHT,lcostNode,new_nodes)
	add_node(lcostNode.pos+Vector3i.FORWARD,lcostNode,new_nodes)
	add_node(lcostNode.pos+Vector3i.BACK,lcostNode,new_nodes)
	
	#steep_up
	add_node(lcostNode.pos+Vector3i.LEFT+Vector3i.UP,lcostNode,new_nodes)
	add_node(lcostNode.pos+Vector3i.RIGHT+Vector3i.UP,lcostNode,new_nodes)
	add_node(lcostNode.pos+Vector3i.FORWARD+Vector3i.UP,lcostNode,new_nodes)
	add_node(lcostNode.pos+Vector3i.BACK+Vector3i.UP,lcostNode,new_nodes)
	
	#steep_down
	add_node(lcostNode.pos+Vector3i.LEFT-Vector3i.UP,lcostNode,new_nodes)
	add_node(lcostNode.pos+Vector3i.RIGHT-Vector3i.UP,lcostNode,new_nodes)
	add_node(lcostNode.pos+Vector3i.FORWARD-Vector3i.UP,lcostNode,new_nodes)
	add_node(lcostNode.pos+Vector3i.BACK-Vector3i.UP,lcostNode,new_nodes)
	
	var id = new_nodes.find(lcostNode)
	new_nodes.remove_at(id)
	
	update_debug()
	
	lastNode = lcostNode
	
	if lcostNode.pos == Vector3i(target_point):
		return true
	
	return false
	
func generate_path():
	var path: Array[Vector3]
	
	var cur_node = lastNode
	var lowestDist = 10000000.0
	for n in done_nodes:
		var dist = target_point.distance_to(Vector3(n.pos))
		if dist < lowestDist:
			lowestDist = dist
			cur_node = n
	
	var a = 0
	var done:= false
	while !done:
		a+=1
		if a > max_iterations:break
		
		path.append(Vector3(cur_node.pos))
		
		if cur_node.parent: 
			cur_node = cur_node.parent
		else :
			done = true
	path.reverse()
	cur_path = path
	
	cur_agent.path = path
	cur_agent = null
	
	#if debug:print("path done size: ",path.size())
	iterating_navigation = false
	
	update_path_debug()
		

#AGENTS
func updating_agents():
	if !iterating_navigation and !agents.is_empty():
		if agents_cycle >= agents.size():
			agents_cycle = 0
		
		var agent = agents[agents_cycle]
		if Time.get_unix_time_from_system() - agent.last_update_time > nagigation_update_rate:
			cur_agent = agent
			agent.last_update_time = Time.get_unix_time_from_system()
			generate_navigation()
		
		agents_cycle += 1
		


#DEBUG
func update_debug():
	if !debug: return
	for c in get_children():
		c.queue_free()
	
	if !done_nodes.is_empty():
		for n in done_nodes:
			var mi = MeshInstance3D.new()
			mi.mesh = debug_mesh_done
			mi.position = Vector3(n.pos)-global_position+Vector3.ONE/2
			add_child(mi)
			mi.owner = self
			if n.parent: 
				mi.look_at(Vector3(n.parent.pos)+Vector3.ONE/2)
				mi.rotation_degrees.x = -90
	
	if !new_nodes.is_empty():
		for n in new_nodes:
			var mi = MeshInstance3D.new()
			mi.mesh = debug_mesh_new
			mi.position = Vector3(n.pos)-global_position+Vector3.ONE/2
			add_child(mi)
			mi.owner = self
			if n.parent: 
				mi.look_at(Vector3(n.parent.pos)+Vector3.ONE/2)
				mi.rotation_degrees.x = -90

func update_path_debug():
	if !debug_path:return
	for c in get_children():
		c.queue_free()
	
	var mi = MeshInstance3D.new()
	add_child(mi)
	
	var mesh = ImmediateMesh.new()
	
	mesh.surface_begin(Mesh.PRIMITIVE_POINTS)
	for p in cur_path:
		mesh.surface_add_vertex(p-mi.global_position+Vector3.ONE/2)
	mesh.surface_end()
	mesh.surface_set_material(0,path_debug_material)
	mi.mesh = mesh
	
	
