@tool
extends Node3D
class_name Chunk

var blocks =[]

const chunk_size = Vector3i(8,8,8)

#var mesh = null
var voxel_material :Material
const TEXTURE_ATLAS_SCALE = Vector2i(8,4)

@onready var noise_texture = preload("res://entities/voxel_world/noise.tres")
# Called when the node enters the scene tree for the first time.


var thread = Thread.new()
func _ready():
	pass

func generate(noise):
	
	
	blocks = []
	blocks.resize(chunk_size.x)
	for x in chunk_size.x:
		blocks[x] = []
		blocks[x].resize(chunk_size.y)
		for y in chunk_size.y:
			blocks[x][y] = []
			blocks[x][y].resize(chunk_size.z)
			for z in chunk_size.z:
				generate_block(x,y,z,noise)

func generate_block(x,y,z,noise):
	var block_world_pos = Vector3(x,y,z) + position
	var s = noise.get_noise_2d(block_world_pos.x,block_world_pos.z)*16+8
	if block_world_pos.y < s:
		blocks[x][y][z] = 1
	else: if block_world_pos.y < s+1:
		blocks[x][y][z] = 4
	else:
		blocks[x][y][z] = 0
					
func update():
	
	for child in get_children():
		child.queue_free()
	
	
	
	var mesh_instance = ChunkMeshInstance.new() as MeshInstance3D
	
	var mesh = ImmediateMesh.new()
	mesh.clear_surfaces()
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)#triangles
	var willBake = false
	for x in chunk_size.x:
		for y in chunk_size.y:
			for z in chunk_size.z:
				if blocks[x][y][z] != 0:
					add_block(mesh,x,y,z)
					willBake = true
	
	if !willBake: return
	
	mesh.surface_end()
	mesh.surface_set_material(0,voxel_material)
	
	add_child(mesh_instance)
	mesh_instance.owner = self
	mesh_instance.mesh = mesh
	
	mesh_instance.create_trimesh_collision()

func add_block(mesh,x,y,z):
	var block = blocks[x][y][z]
	var pos = Vector3(x,y,z)
	if block == 0:
		return
		
	#FRONT
	if is_block_transparent(x,y,z-1):
		add_face(mesh,block,pos+Vector3.RIGHT,Vector3.LEFT,Vector3.UP,Vector3.FORWARD)
	
	#LEFT
	if is_block_transparent(x-1,y,z):
		add_face(mesh,block,pos,Vector3.BACK,Vector3.UP,Vector3.LEFT)
	
	#TOP
	if is_block_transparent(x,y+1,z):
		add_face(mesh,block,pos+Vector3.RIGHT+Vector3.UP,Vector3.LEFT,Vector3.BACK,Vector3.UP)
	
	#BACK
	if is_block_transparent(x,y,z+1):
		add_face(mesh,block,pos+Vector3.BACK,Vector3.RIGHT,Vector3.UP,Vector3.BACK)
	
	#RIGHT
	if is_block_transparent(x+1,y,z):
		add_face(mesh,block,pos+Vector3.BACK+Vector3.RIGHT,Vector3.FORWARD,Vector3.UP,Vector3.RIGHT)
	
	#BOTTOM
	if is_block_transparent(x,y-1,z):
		add_face(mesh,block,pos+Vector3.BACK+Vector3.RIGHT,Vector3.LEFT,Vector3.FORWARD,Vector3.DOWN)

func add_face(mesh,blockID,pos,xDir,yDir,normal):
	var x_uv_pos = 1.0/TEXTURE_ATLAS_SCALE.x*floor(blockID%TEXTURE_ATLAS_SCALE.x)-1
	var y_uv_pos = 1.0/TEXTURE_ATLAS_SCALE.y*floor(blockID/TEXTURE_ATLAS_SCALE.x)
	var uv_origin = Vector2(x_uv_pos,y_uv_pos)
	var hor_uv = 1.0/TEXTURE_ATLAS_SCALE.x
	var ver_uv = 1.0/TEXTURE_ATLAS_SCALE.y
	
	mesh.surface_set_normal(normal)
	mesh.surface_set_uv(uv_origin)
	mesh.surface_add_vertex(pos)

	mesh.surface_set_normal(normal)
	mesh.surface_set_uv(Vector2(0,ver_uv)+uv_origin)
	mesh.surface_add_vertex(pos+yDir)

	mesh.surface_set_normal(normal)
	mesh.surface_set_uv(Vector2(hor_uv,0)+uv_origin)
	mesh.surface_add_vertex(pos+xDir)
		
	
	mesh.surface_set_normal(normal)
	mesh.surface_set_uv(Vector2(0,ver_uv)+uv_origin)
	mesh.surface_add_vertex(pos+yDir)
	
	mesh.surface_set_normal(normal)
	mesh.surface_set_uv(Vector2(hor_uv,ver_uv)+uv_origin)
	mesh.surface_add_vertex(pos+yDir+xDir)
	
	mesh.surface_set_normal(normal)
	mesh.surface_set_uv(Vector2(hor_uv,0)+uv_origin)
	mesh.surface_add_vertex(pos+xDir)
		

func is_block_transparent(x,y,z):
	
	if x < 0 or x > chunk_size.x - 1:
		return true
	if y < 0 or y > chunk_size.y - 1:
		return true
	if z < 0 or z > chunk_size.z - 1:
		return true
		
	if blocks[x][y][z] == 0:
		return true
	return false
