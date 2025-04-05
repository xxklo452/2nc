# CountyManager.gd
extends Node
class_name CountyManager

# 配置常量
const BATCH_SIZE = 5000
const COUNTY_SCENE = preload("res://County.gd")

# 核心数据
var counties = []          # 存储所有County实例
var active_batches = []     # 当前可用的渲染批次

func _ready():
	# 初始化首个批次
	_add_new_batch()

# 基础接口 --------------------------------------------------
func create_county(data: Dictionary) -> County:
	var new_county = COUNTY_SCENE.new()
	new_county.initialize(data)
	_assign_render_target(new_county)
	counties.append(new_county)
	add_child(new_county)
	return new_county

func remove_county(county: County) -> void:
	if county in counties:
		_recycle_render_slot(county)
		counties.erase(county)
		county.queue_free()

# 渲染管理 --------------------------------------------------
func _assign_render_target(county: County) -> void:
	# 获取可用批次
	var batch = active_batches[-1] 
	if batch.used >= BATCH_SIZE:
		batch = _add_new_batch()
	
	# 分配实例ID
	county.multimesh_id = batch.used
	county.multimesh_instance = batch.instance
	batch.used += 1

func _add_new_batch() -> Dictionary:
	var new_mmi = MultiMeshInstance2D.new()
	new_mmi.multimesh = _create_multimesh()
	add_child(new_mmi)
	
	var new_batch = {
		"instance": new_mmi,
		"used": 0
	}
	active_batches.append(new_batch)
	return new_batch

func _create_multimesh() -> MultiMesh:
	var mm = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_2D
	mm.mesh = QuadMesh.new()
	mm.instance_count = BATCH_SIZE
	return mm

func _recycle_render_slot(county: County) -> void:
	# 简单实现：不做实时回收，重置整个批次
	county.multimesh_instance.multimesh = null
	active_batches[-1].used -= 1

# 数据持久化 ------------------------------------------------
func save_game() -> Dictionary:
	var data = []
	for c in counties:
		data.append({
			"config": c.get_config(),
			"position": {"x": c.position.x, "y": c.position.y}
		})
	return {"counties": data}

func load_game(save_data: Dictionary) -> void:
	clear_all()
	for entry in save_data.get("counties", []):
		var county = create_county(entry.config)
		county.position = Vector2(entry.position.x, entry.position.y)

func clear_all() -> void:
	for c in counties:
		remove_county(c)
	active_batches.clear()

# 性能优化 --------------------------------------------------
func update_all_transforms() -> void:
	for county in counties:
		county.update_transform()
