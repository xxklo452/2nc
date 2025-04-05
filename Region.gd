# Region.gd
extends Node2D
class_name Region

# ===== 网格坐标系统 =====
var grid_positions: Array[Vector2i] = []:
	set(value):
		grid_positions = value
		grid_positions_changed.emit()

var color: Color = Color.WHITE:
	set(value):
		color = value
		visual_changed.emit()

var population: float = 0.0:
	set(value):
		population = max(value, 0.0)
		visual_changed.emit()

# ===== 信号系统 =====
signal grid_positions_changed
signal visual_changed

# ===== 序列化 =====
func serialize() -> Dictionary:
	return {
		"color": color.to_html(),
		"population": population,
		"grid_positions": grid_positions.map(func(p): return {"x": p.x, "y": p.y})
	}

static func deserialize(data: Dictionary) -> Region:
	var region = Region.new()
	region.color = Color(data.get("color", "#ffffff"))
	region.population = data.get("population", 0.0)
	region.grid_positions = data.get("grid_positions", []).map(
		func(p): return Vector2i(p.x, p.y)
	)
	return region

# ===== 工具方法 =====
func world_positions(tile_size: int) -> Array[Vector2]:
	return grid_positions.map(func(p): return Vector2(p) * tile_size)
