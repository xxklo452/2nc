extends Node2D
var speed:float=10
var v:Vector2
# 添加加速度和摩擦力
var acceleration: float = 2000  # 加速度（像素/秒²）
var friction: float = 1800      # 摩擦力（像素/秒²）

func _physics_process(delta: float) -> void:
	var input_dir := Input.get_vector("left", "right", "fron", "back")
	var target_velocity = input_dir.normalized() * speed
	
	# 带加速度的移动
	if input_dir.length() > 0:
		v = v.move_toward(target_velocity, acceleration * delta)
	else:
		v = v.move_toward(Vector2.ZERO, friction * delta)
	
	position += v * delta
