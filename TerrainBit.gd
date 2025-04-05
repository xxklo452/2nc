extends Node2D
class_name TerrainBit
#region 新建代码区域


var data={}
enum TERRAIN_TYPE {
	DEEP_SEA,
	SEA,
	SAND,
	GRASS,
	FOREST,
	MOUNTAIN,
	SNOW_MOUNTAIN
}






#endregion

#region 新建代码区域
func _init(data:Dictionary ) -> void:
	self.data=data

static func create(data:Dictionary) -> TerrainBit:
	return TerrainBit.new(data)

static func copy_from(existing: TerrainBit) -> TerrainBit:
	return TerrainBit.new(existing.data)


func _get_terrain_data() -> Dictionary:
	return data
signal terrain_data_changed(old_data: Dictionary, new_data: Dictionary)
func set_terrain_type(new_data: TERRAIN_TYPE) -> void:
	var old_data = self.data
	self.data = new_data
	emit_signal("terrain_data_changed", old_data, new_data)

#endregion
