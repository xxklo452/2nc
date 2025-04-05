# County.gd
extends Node2D
class_name County

# ===== 配置参数 =====
@export var tile_size: int = 32
@export var border_width: float = 2.0

# ===== 渲染系统 =====
@onready var multimesh_instance: MultiMeshInstance2D = $MultiMeshInstance2D
var multimesh: MultiMesh:
	get: return multimesh_instance.multimesh

# ===== 区域管理 =====
var regions: Array[Region] = []
var region_tile_map: Dictionary = {}  # {Vector2i: Region}

# ===== 初始化 =====
func _ready() -> void:
	_init_multimesh()
	refresh_all_regions()

func _init_multimesh() -> void:
	multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_2D
	multimesh.mesh = _create_tile_mesh()
	multimesh_instance.multimesh = multimesh

func _create_tile_mesh() -> QuadMesh:
	var mesh = QuadMesh.new()
	mesh.size = Vector2.ONE * (tile_size - border_width)
	return mesh

# ===== 区域管理 =====
func add_region(region: Region) -> void:
	regions.append(region)
	_connect_region_signals(region)
	update_region(region)

func remove_region(region: Region) -> void:
	regions.erase(region)
	_disconnect_region_signals(region)
	refresh_all_regions()

func _connect_region_signals(region: Region) -> void:
	region.grid_positions_changed.connect(update_region.bind(region))
	region.visual_changed.connect(update_region_visual.bind(region))

func _disconnect_region_signals(region: Region) -> void:
	region.grid_positions_changed.disconnect(update_region.bind(region))
	region.visual_changed.disconnect(update_region_visual.bind(region))

# ===== 渲染更新 =====
func update_region(region: Region) -> void:
	# 清除旧位置
	var old_positions = region_tile_map.keys().filter(
		func(p): return region_tile_map[p] == region
	)
	for pos in old_positions:
		region_tile_map.erase(pos)
	
	# 添加新位置
	for pos in region.grid_positions:
		if region_tile_map.has(pos):
			push_warning("Tile conflict at %s" % pos)
		region_tile_map[pos] = region
	
	refresh_all_regions()

func update_region_visual(region: Region) -> void:
	var start_idx = _get_region_start_index(region)
	var world_positions = region.world_positions(tile_size)
	
	for i in range(world_positions.size()):
		var idx = start_idx + i
		var transform = Transform2D.IDENTITY.translated(world_positions[i])
		multimesh.set_instance_transform_2d(idx, transform)
		multimesh.set_instance_color(idx, region.color)

func refresh_all_regions() -> void:
	# 生成所有有效网格位置
	var all_positions = region_tile_map.keys()
	multimesh.instance_count = all_positions.size()
	
	# 设置实例属性
	for i in range(all_positions.size()):
		var pos = all_positions[i]
		var region = region_tile_map[pos]
		var world_pos = Vector2(pos) * tile_size
		
		multimesh.set_instance_transform_2d(i, Transform2D.IDENTITY.translated(world_pos))
		multimesh.set_instance_color(i, region.color)
		multimesh.set_instance_custom_data(i, Color(region.population / 1000.0, 0, 0, 1))

# ===== 点击检测 =====
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		var grid_pos = _screen_to_grid(event.position)
		if region_tile_map.has(grid_pos):
			var region = region_tile_map[grid_pos]
			_handle_region_click(region, grid_pos)

func _screen_to_grid(screen_pos: Vector2) -> Vector2i:
	var local_pos = multimesh_instance.get_global_transform().affine_inverse() * screen_pos
	return Vector2i(local_pos / tile_size)

# ===== 辅助方法 =====
func _get_region_start_index(region: Region) -> int:
	var all_positions = region_tile_map.keys()
	for i in range(all_positions.size()):
		if region_tile_map[all_positions[i]] == region:
			return i
	return -1

func _handle_region_click(region: Region, grid_pos: Vector2i) -> void:
	print("Clicked on region '%s' at grid %s" % [region.name, grid_pos])
	# 在此处添加点击处理逻辑
