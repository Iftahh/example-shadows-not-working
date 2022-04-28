extends Spatial
tool   # "tool" allows seeing the generated mesh in the editor

const X_DIM = 300
const Y_DIM = 60
const Z_DIM = 300

export var ground_material: Material
export var wall_material: Material

export var ground_texture_scale := 0.05
export var wall_texture_scale := 0.05

var ground_st = SurfaceTool.new()
var wall_st = SurfaceTool.new()

export var noise: OpenSimplexNoise

var mesh_instance

enum {
	LOW,
	HIGH,
	VERY_HIGH,
}

func tile_level(x,y):
	if x <= 3 and y <= 0:
		return VERY_HIGH  # mark 0,0 corner facing X axis - to easily find direction
		
	if x > 50 and y > 100 and x < 150 and y < 150:
		return HIGH
		
	if x > 220 and y > 150 and x < 260 and y < 180:
		return HIGH
	return LOW

func _ready():
	create_3d_level(X_DIM, Y_DIM, Z_DIM)

func _enter_tree():
	create_3d_level(X_DIM, Y_DIM, Z_DIM)
	


func _on_RegenerateButton_pressed():
	create_3d_level(X_DIM, Y_DIM, Z_DIM)


func create_3d_level(x_dim, y_dim, z_dim):
	ground_st.clear()
	wall_st.clear()
	ground_st.begin(Mesh.PRIMITIVE_TRIANGLES)
	wall_st.begin(Mesh.PRIMITIVE_TRIANGLES)
	ground_st.add_smooth_group(true)
	wall_st.add_smooth_group(true)
	
	
	for z in Z_DIM:
		for x in X_DIM:
			create_block(x,z)


	var mesh = Mesh.new()
	ground_st.index()
	ground_st.generate_normals()
	ground_st.generate_tangents()
	ground_st.set_material(ground_material)
	ground_st.commit(mesh)
	
	wall_st.index()
	wall_st.generate_normals()
	wall_st.generate_tangents()
	wall_st.set_material(wall_material)
	wall_st.commit(mesh)
#
	if mesh_instance != null:
		mesh_instance.call_deferred("queue_free")
		mesh_instance = null
		
	mesh_instance = MeshInstance.new()
	mesh_instance.translation = Vector3(-X_DIM/2, 0, -Z_DIM/2)
	
	mesh_instance.set_mesh(mesh)
	#mesh_instance.create_trimesh_collision()
	add_child(mesh_instance)
	


func create_wall_if_needed(x,y, dir, this_block_level, other_block_level):
	if other_block_level < this_block_level:
		# create a wall to the left
		create_wall(x,y, dir, other_block_level, this_block_level)

func create_block(x,y):
	var block_level = tile_level(x,y)
	
	create_wall_if_needed(x,y, LEFT, block_level, tile_level(x-1, y))
	create_wall_if_needed(x,y, RIGHT, block_level, tile_level(x+1, y))
	create_wall_if_needed(x,y, FRONT, block_level, tile_level(x, y+1))
	create_wall_if_needed(x,y, BACK, block_level, tile_level(x, y-1))
	
	create_ground(x,y, block_level) 
	

func uvs_from_3d(dir, x,y,z):
	if dir == FRONT:
		return [
			Vector2(x, y), Vector2(x+1, y+1)
		]
	if dir == BACK:
		return [
			Vector2(x+1, y), Vector2(x, y+1)
		]
		
	if dir == LEFT:
		return [
			Vector2(z, y), Vector2(z+1, y+1)
		]
		
	if dir == RIGHT:
		return [
			 Vector2(z+1, y), Vector2(z, y+1)
		]
	if dir == TOP:
		return [Vector2(x,y), Vector2(x+1, y+1)]
	return [
		Vector2(x+1,y), Vector2(x, y+1)
	]


const wall_noise_scale = Vector3(2.5, 10.0, 2.5)
const ground_noise_scale = Vector3(0.5, 10.0, 0.5)

func create_wall(x,y, dir, level_start, level_end):
	var height_start = level_start*10
	var height_end = level_end*10
	for h in range(height_start, height_end+1):
		var uvs = uvs_from_3d(dir, x,h,y)
		create_face(
			wall_st,
			dir,
			Vector3(x, h, y),
			uvs[0] * wall_texture_scale,
			uvs[1] * wall_texture_scale,
			ground_noise_scale if h==height_end else wall_noise_scale,
			ground_noise_scale if h==height_start else wall_noise_scale	
		)
	
func create_ground(x,y, level):
	create_face(
		ground_st,
		TOP,
		Vector3(x, level*10, y),
		Vector2(x+1, y) * ground_texture_scale,
		Vector2(x, y+1) * ground_texture_scale,
		ground_noise_scale, ground_noise_scale
	)
	
	
# based on https://github.com/xen-42/Simplified-godot-voxel-terrain/blob/main/Chunk.gd
const vertices = [
	Vector3(0, 0, 0), #0
	Vector3(1, 0, 0), #1
	Vector3(0, 1, 0), #2
	Vector3(1, 1, 0), #3
	Vector3(0, 0, 1), #4
	Vector3(1, 0, 1), #5
	Vector3(0, 1, 1), #6
	Vector3(1, 1, 1)  #7
]

const TOP = [6, 2, 3, 7]
const BOTTOM = [5, 1, 0, 4]
const RIGHT = [3, 1, 5, 7]
const BACK = [2, 0, 1, 3]

const LEFT = [6, 4, 0, 2]
const FRONT = [7, 5, 4, 6]

func small_3d_noise(location: Vector3, cube_vertex: Vector3, scale_if_top: Vector3, scale_if_bottom: Vector3) -> Vector3:
	var scale = scale_if_bottom if cube_vertex.y == 0 else scale_if_top
	var loc_vertex = location+cube_vertex
	return loc_vertex+Vector3(
		noise.get_noise_3dv(loc_vertex) * scale.x,
		noise.get_noise_3dv(loc_vertex + Vector3(9,9,9)) * scale.y,
		noise.get_noise_3dv(loc_vertex + Vector3(-9,-9,-9)) * scale.z
	)
		

func create_face(st: SurfaceTool, dir, position: Vector3, uv_x1y1: Vector2, uv_x2y2: Vector2, 
				top_vertex_noise_scale:Vector3,  bottom_vertex_noise_scale: Vector3):
	var a = vertices[dir[0]]
	var b = vertices[dir[1]]
	var c = vertices[dir[2]]
	var d = vertices[dir[3]]
	
	var uv_a = uv_x2y2
	var uv_b = Vector2(uv_x2y2.x, uv_x1y1.y)
	var uv_c = uv_x1y1
	var uv_d = Vector2(uv_x1y1.x, uv_x2y2.y) 
	
	a = small_3d_noise(position, a, top_vertex_noise_scale, bottom_vertex_noise_scale)
	b = small_3d_noise(position, b, top_vertex_noise_scale, bottom_vertex_noise_scale)
	c = small_3d_noise(position, c, top_vertex_noise_scale, bottom_vertex_noise_scale)
	d = small_3d_noise(position, d, top_vertex_noise_scale, bottom_vertex_noise_scale)
	st.add_triangle_fan(([a, b, c]), ([uv_a, uv_b, uv_c]))
	st.add_triangle_fan(([a, c, d]), ([uv_a, uv_c, uv_d]))
	

