extends Node2D
class_name WorldGenerator

#region 新建代码区域
var state:GAME_STATE=GAME_STATE.unstart
enum GAME_STATE{
	unstart,
	start,
	willstart
}
var year =1
var month=1
var data_month=1
@onready var timer=$Timer
@export var terrain_thresholds: Array = [0, 0.3, 0.35, 0.4, 0.5, 0.7, 0.85]
@export var chunk_size := Vector2i(16, 16)      # 修复Vector2i初始化
@export var tile_size := 8                      
@export var load_radius := 3                    
var data:Dictionary={}
# 统一使用FastNoiseLite的正确名称（修复第38、40行）
var noise :FastNoiseLite= FastNoiseLite.new()
var country_noise := FastNoiseLite.new()
var rng := RandomNumberGenerator.new()

# 添加map_size声明（修复116、117行）
@export var map_size := Vector2i(240, 135)
var terrain_data:Array=[{}]
# 运行时数据
var active_chunks := {}
var countries := []
var player_last_chunk := Vector2i(-999, -999)
#endregion

func _ready() -> void:
	rng.seed = Time.get_unix_time_from_system()
	rng.state=-Time.get_unix_time_from_system()
	print(rng.randi())
	noise.noise_type=FastNoiseLite.TYPE_PERLIN
	noise.seed=rng.randi()
	
	$world.draw_terrain(noise,map_size,tile_size,terrain_thresholds)
	terrain_data=$world.terraingenerator.get_terrain_data()




func _process(delta: float) -> void:
	match state:
		GAME_STATE.start:
			$ui/CanvasLayer.visible=true
			$ui/CanvasLayer/PanelContainer/HBoxContainer/Label.text = "%d year %d" % [year, month]
#region 国家生成系统
func generate_countries(count: int) -> void:
	var points := generate_voronoi_points(count)
	# ...其余代码...

func generate_voronoi_points(count: int) -> Array:
	var points := []
	for i in count:
		# 修复Vector2i的初始化（第91行）
		points.append(Vector2(
			rng.randi_range(0, map_size.x * tile_size),
			rng.randi_range(0, map_size.y * tile_size)
		))
	return points
#endregion


func _on_start_ok_pressed() -> void:
	$ui/unstart.visible=false
	state=GAME_STATE.start
	timer.start()
	pass # Replace with function body.


func _on_unstart_on_pressed() -> void:
	$ui/unstart.visible=false
	pass # Replace with function body.


func _on_timer_timeout() -> void:
	if month==12:
		month=1
		year+=1
	else:
		month+=1
	data_month+=1
	pass # Replace with function body.
func _input(event: InputEvent) -> void:
	
	
	match state:
		GAME_STATE.unstart:
			data.merge($world.terraingenerator.handle_click(event))
			if data.get("made","null")=="world/TerrainGenerator" and data.get("is_within_bounds"):
				await get_tree().create_timer(0.1).timeout
				if state==GAME_STATE.unstart:
					$ui/unstart/choice.position=event.position
					$ui/unstart/choice.visible=true
					await get_tree().create_timer(1.5).timeout
					$ui/unstart/choice.visible=false
				else :
					$ui/unstart/WilStart.visible=true
					$ui/unstart/WilStart.position=event.position
					#$world/counties.create_county({"county_name":"夏","positions":[event.position],"regions":[{"area":2,"population":10,"color":Color.CORAL}]})
					timer.start(1)
		GAME_STATE.start:
			pass
