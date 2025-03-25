@tool
extends Node3D
class_name VoxelWorld

var chunks = []
@export var world_size: Vector3i = Vector3i(4,1,4)
@export var noise : FastNoiseLite
@export var voxel_material:Material
var chunk_pref = Chunk.new()
const SAVE_PATH = "res://save.tres"


@export var GENERATE:bool = false
@export var SAVE:bool = false
@export var LOAD:bool = false
# Called when the node enters the scene tree for the first time.
func _ready():
	
	if Engine.is_editor_hint():
		var save = ResourceLoader.load(SAVE_PATH) as VoxelWorldSave
		if save :
			load_world()
		return
	
	var save = ResourceLoader.load(SAVE_PATH) as VoxelWorldSave
	if save :
		load_world()
	else:
		generate()
	
	

func _exit_tree():
	if Engine.is_editor_hint(): return
	save_world()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if GENERATE :
		GENERATE = false
		generate()
		
	if SAVE :
		SAVE = false
		save_world()
	
	if LOAD :
		LOAD = false
		load_world()
	

func generate():
	for child in get_children():
		child.queue_free()
		
	chunks = []
	chunks.resize(world_size.x)
	for x in world_size.x:
		chunks[x] = []
		chunks[x].resize(world_size.y)
		for y in world_size.y:
			chunks[x][y] = []
			chunks[x][y].resize(world_size.z)
			for z in world_size.z:
				var pos = Vector3(x*Chunk.chunk_size.x,y*Chunk.chunk_size.y,z*Chunk.chunk_size.z)
				var clone = Chunk.new()
				
				clone.position = pos
				add_child(clone)
				clone.owner = self
				clone.voxel_material = voxel_material
				chunks[x][y][z] = clone as Chunk
				clone.generate(noise)
				clone.update()
				
func set_block(worldPos:Vector3i,newID:int,doUpdate:bool = true):
	#clamp world pos to grid 1x1x1
	#print("world_pos ",worldPos)
	
	#is out of world?
	if worldPos.x < 0 or worldPos.x > world_size.x*Chunk.chunk_size.x-1:return
	if worldPos.y < 0 or worldPos.y > world_size.y*Chunk.chunk_size.y-1:return
	if worldPos.z < 0 or worldPos.z > world_size.z*Chunk.chunk_size.z-1:return
	
	#get_chunk
	var chunk_pos:Vector3i = worldPos
	chunk_pos.x = chunk_pos.x/Chunk.chunk_size.x
	chunk_pos.y = chunk_pos.y/Chunk.chunk_size.y
	chunk_pos.z = chunk_pos.z/Chunk.chunk_size.z
	
	#print("chunk pos ",chunk_pos)
	var chunk = chunks[chunk_pos.x][chunk_pos.y][chunk_pos.z] as Chunk
	
	var block_pos = Vector3i(worldPos) - Vector3i(chunk.global_position)
	#print("block pos ",block_pos)
	chunk.blocks[block_pos.x][block_pos.y][block_pos.z] = newID
	if doUpdate:
		chunk.update()
		#var nav = get_parent_node_3d() as NavigationRegion3D
		#nav.bake_navigation_mesh()
	

func get_block(worldPos:Vector3i) -> int:
	#clamp world pos to grid 1x1x1
	#print("world_pos ",worldPos)
	
	#is out of world?
	if worldPos.x < 0 or worldPos.x > world_size.x*Chunk.chunk_size.x-1:return 0
	if worldPos.y < 0 or worldPos.y > world_size.y*Chunk.chunk_size.y-1:return 0
	if worldPos.z < 0 or worldPos.z > world_size.z*Chunk.chunk_size.z-1:return 0
	
	#get_chunk
	var chunk_pos:Vector3i = worldPos
	chunk_pos.x = chunk_pos.x/Chunk.chunk_size.x
	chunk_pos.y = chunk_pos.y/Chunk.chunk_size.y
	chunk_pos.z = chunk_pos.z/Chunk.chunk_size.z
	
	#print("chunk pos ",chunk_pos)
	var chunk = chunks[chunk_pos.x][chunk_pos.y][chunk_pos.z] as Chunk
	
	var block_pos = Vector3i(worldPos) - Vector3i(chunk.global_position)
	#print("block pos ",block_pos)
	return chunk.blocks[block_pos.x][block_pos.y][block_pos.z]
	
func save_world():
	var save = VoxelWorldSave.new()
	
	save.world_size = world_size
	
	save.chunks = []
	save.chunks.resize(world_size.x)
	for x in world_size.x:
		save.chunks[x] = []
		save.chunks[x].resize(world_size.y)
		for y in world_size.y:
			save.chunks[x][y] = []
			save.chunks[x][y].resize(world_size.z)
			for z in world_size.z:
				
				save.chunks[x][y][z] = chunks[x][y][z].blocks
	
	ResourceSaver.save(save,SAVE_PATH)
	print("WORLD SAVED PATH: ",SAVE_PATH)

func load_world():
	var save = ResourceLoader.load(SAVE_PATH) as VoxelWorldSave
	if !save : 
		print("NO SAVE FILE FINDED TO LOAD")
		return
	
	world_size = save.world_size
	
	for child in get_children():
		child.queue_free()
		
	chunks = []
	chunks.resize(world_size.x)
	for x in world_size.x:
		chunks[x] = []
		chunks[x].resize(world_size.y)
		for y in world_size.y:
			chunks[x][y] = []
			chunks[x][y].resize(world_size.z)
			for z in world_size.z:
				var pos = Vector3(x*Chunk.chunk_size.x,y*Chunk.chunk_size.y,z*Chunk.chunk_size.z)
				var clone = Chunk.new()
				
				clone.position = pos
				add_child(clone)
				clone.owner = self
				clone.voxel_material = voxel_material
				chunks[x][y][z] = clone as Chunk
				clone.blocks = save.chunks[x][y][z]
				clone.update()
