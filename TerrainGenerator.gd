
class_name TerrainGenerator

extends MultiMeshInstance2D
var main:Node
func set_node(node:MultiMeshInstance2D,_main:Node):
	multi_mesh_instance=node
	main=_main
@onready var multi_mesh_instance
# 地形数据结构
var terrain_data := []
var map_size: Vector2i
var tile_size: int
enum TERRAIN_TYPE {
	DEEP_SEA,
	SEA,
	SAND,
	GRASS,
	FOREST,
	MOUNTAIN,
	SNOW_MOUNTAIN
}

const TERRAIN_COLORS := {
	TERRAIN_TYPE.DEEP_SEA: Color("#1a237e"),
	TERRAIN_TYPE.SEA: Color("#1976d2"),
	TERRAIN_TYPE.SAND: Color("#ffe082"),
	TERRAIN_TYPE.GRASS: Color("#7cb342"),
	TERRAIN_TYPE.FOREST: Color("#2e7d32"),
	TERRAIN_TYPE.MOUNTAIN: Color("#757575"),
	TERRAIN_TYPE.SNOW_MOUNTAIN: Color("#fafafa")
}

# 场景中必须包含名为 MultiMeshInstance2D 的节点


func generate_terrain(noise: FastNoiseLite, _map_size: Vector2i, _tile_size: int, terrain_thresholds: Array,node) -> void:
	map_size = _map_size
	tile_size = _tile_size
	multi_mesh_instance=node
	# 初始化MultiMesh
	multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_2D
	multimesh.use_colors = true
	multimesh.mesh = create_tile_mesh(tile_size)
	multimesh.instance_count = map_size.x * map_size.y
	
	# 初始化地形数据
	terrain_data.resize(map_size.x)
	for x in map_size.x:
		terrain_data[x] = []
		terrain_data[x].resize(map_size.y)
		for y in map_size.y:
			var instance_index = calculate_instance_index(x, y)
			var noise_value = (noise.get_noise_2d(x, y) + 1.0) / 2.0
			var terrain_type = determine_terrain_type(noise_value, terrain_thresholds)
			
			# 存储地形数据
			terrain_data[x][y] = {
				"instance_index": instance_index,
				"terrain_type": terrain_type,
				"base_color": TERRAIN_COLORS[terrain_type]
			}
			
			# 设置实例属性
			set_instance_properties(x, y, instance_index, terrain_type)
	
	# 应用MultiMesh到场景
	multi_mesh_instance.multimesh = multimesh

# 创建瓦片网格
func create_tile_mesh(size: int) -> QuadMesh:
	var mesh = QuadMesh.new()
	mesh.size = Vector2(size, size)
	
	# 创建支持顶点颜色的材质
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	mesh.surface_set_material(0, material)
	
	return mesh

# 计算实例索引（行优先）
func calculate_instance_index(x: int, y: int) -> int:
	return x * map_size.y + y

# 确定地形类型
func determine_terrain_type(height: float, thresholds: Array) -> TERRAIN_TYPE:
	for i in thresholds.size() - 1:
		if height >= thresholds[i] and height < thresholds[i + 1]:
			return TERRAIN_TYPE.values()[i]
	return TERRAIN_TYPE.DEEP_SEA

# 设置实例属性
func set_instance_properties(x: int, y: int, index: int, terrain_type: TERRAIN_TYPE):
	var position = Vector2(
		x * tile_size + tile_size / 2.0,
		y * tile_size + tile_size / 2.0
	)
	multimesh.set_instance_transform_2d(index, Transform2D(0.0, position))
	multimesh.set_instance_color(index, TERRAIN_COLORS[terrain_type])

# 输入处理
func get_terrain_index_at_position(screen_pos: Vector2) -> int:
	var local_pos = self.global_transform.affine_inverse() * screen_pos
	var grid_x = floor(local_pos.x / tile_size)
	var grid_y = floor(local_pos.y / tile_size)
	
	if is_within_bounds(grid_x, grid_y):
		return calculate_instance_index(grid_x, grid_y)
	return -1

func index_to_grid(index: int) -> Vector2i:
	var x = index / map_size.y
	var y = index % map_size.y
	return Vector2i(x, y)


# 处理点击事件
func handle_click(event: InputEventMouseButton)->Dictionary:
	# 坐标转换
	var global_click_pos = event.position
	var local_click_pos = multi_mesh_instance.global_transform.affine_inverse() * global_click_pos
	
	# 计算网格坐标
	var grid_x = floor(local_click_pos.x / tile_size)
	var grid_y = floor(local_click_pos.y / tile_size)
	# 边界检查
	if is_within_bounds(grid_x, grid_y) :
		var data:={}
		data.merge(terrain_data[grid_x][grid_y])
		data.merge({"is_within_bounds"=true})
		data.merge({"pos_index":Vector2(grid_x, grid_y)})
		data.merge({"made":"world/TerrainGenerator"})
		main.data=data
		
		return data
	return {"is_within_bounds":false,"made":"world/TerrainGenerator"}


# 边界检查
func is_within_bounds(x: int, y: int) -> bool:
	return x >= 0 && y >= 0 && x < map_size.x && y < map_size.y
func get_terrain_data()->Array:
	return self.terrain_data
# ===== 新增交互相关属性和信号 =====
signal terrain_hovered(grid_pos: Vector2i)
signal terrain_clicked(grid_pos: Vector2i)
signal terrain_exited()

enum INTERACTION_STATE {
	NORMAL,
	HOVERED,
	PRESSED
}

var hovered_index := -1
var pressed_index := -1
var last_terrain_color: Color
var interaction_enabled := true

# ===== 修改输入处理逻辑 =====
func _input(event: InputEvent):
	if not interaction_enabled:
		return
	
	# 处理鼠标移动事件
	if event is InputEventMouseMotion:
		handle_hover(event)
	
	# 处理鼠标点击事件
	if event is InputEventMouseButton:
		if event.pressed:
			handle_press(event)
		else:
			handle_release()

# 处理悬停效果
func handle_hover(event: InputEventMouseMotion):
	var new_index = get_terrain_index_at_position(event.position)
	
	if new_index != hovered_index:
		# 清除旧的悬停效果
		if hovered_index != -1:
			reset_terrain_appearance(hovered_index)
			terrain_exited.emit()
		
		# 应用新悬停效果
		if new_index != -1:
			var grid_pos = index_to_grid(new_index)
			apply_hover_effect(new_index)
			terrain_hovered.emit(grid_pos)
		
		hovered_index = new_index

# 处理点击按下
func handle_press(event: InputEventMouseButton):
	if hovered_index != -1:
		pressed_index = hovered_index
		apply_press_effect(pressed_index)

# 处理点击释放
func handle_release():
	if pressed_index != -1:
		var grid_pos = index_to_grid(pressed_index)
		reset_terrain_appearance(pressed_index)
		apply_hover_effect(pressed_index)
		terrain_clicked.emit(grid_pos)
		pressed_index = -1

# ===== 交互视觉效果 =====
func apply_hover_effect(index: int):
	var original_color = multimesh.get_instance_color(index)
	multimesh.set_instance_color(index, original_color.lightened(0.2))
	last_terrain_color = original_color

func apply_press_effect(index: int):
	var original_color = multimesh.get_instance_color(index)
	multimesh.set_instance_color(index, original_color.darkened(0.2))

func reset_terrain_appearance(index: int):
	var original_data = terrain_data[index_to_grid(index).x][index_to_grid(index).y]
	multimesh.set_instance_color(index, original_data.base_color)
# ===== 新增交互控制方法 =====
func _enable_interaction():
	interaction_enabled = true
	set_process_input(true)
	if self is Control:
		mouse_filter = Control.MOUSE_FILTER_STOP
	else:
		# 对于Node2D需要手动处理
		set_process_unhandled_input(true)
		get_viewport().gui_disable_input = false

func disable_interaction():
	interaction_enabled = false
	if self is Control:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	else:
		set_process_unhandled_input(false)

func enable_interaction():
	_enable_interaction()
