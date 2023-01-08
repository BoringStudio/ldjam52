extends Obstacle

const ObstacleType = preload("../../shared/obstacle_type.gd").ObstacleType

func _init().(_select_type()):
	pass

func _ready():
	pass


static func _select_type() -> int:
	return ObstacleType.Wood if randi() % 2 == 0 else ObstacleType.Metal
