extends Node2D
class_name MapManager

# ===== 节点引用 =====
@onready var terrain: MultiMeshInstance2D = $terrain
@onready var counties: Node2D = $counties
var terraingenerator: TerrainGenerator = TerrainGenerator.new()
var countymanager: CountyManager = CountyManager.new()

# ===== 初始化 =====
func draw_terrain(noise:FastNoiseLite,map_size:Vector2,tile_size:int,terrain_thresholds:Array) -> void:
	terraingenerator.set_node($terrain,$"..")
	terraingenerator.generate_terrain(noise,map_size,tile_size,terrain_thresholds,$terrain)





# ===== 实例属性设置 =====
func set_terrain_instance(index: int, position: Vector2, color: Color) -> void:
	# 创建变换矩阵
	var transform := Transform2D()
	transform.origin = position
	
	# 设置实例属性
	terrain.multimesh.set_instance_transform_2d(index, transform)
	terrain.multimesh.set_instance_color(index, color)

# ===== 输入处理 =====
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		var data:Dictionary=terraingenerator.handle_click(event)
		if data.get("is_within_bounds",false):
			$"..".terrain($terrain.multimesh,data,event)
			



static func remap(value: float, from_min: float, from_max: float, to_min: float, to_max: float) -> float:
	return (value - from_min) * (to_max - to_min) / (from_max - from_min) + to_min

# ===== 自定义信号 =====
