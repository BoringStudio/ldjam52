extends Camera

export(float, 0, 1, 0.001) var translate_speed := 0.95

export(NodePath) var target: NodePath

export(float) var camera_distance = 20.0
export(float) var angle = 70.0

var _view_direction: Vector3
var _target_origin: Vector3

onready var _target: Spatial = get_node(target)

func _ready():
	_update_view_direction()
	_target_origin = _target.global_transform.origin
	self.global_transform.origin = _target_origin + _view_direction
	self.transform = self.transform.looking_at(_target_origin, Vector3.UP)


func _process(delta: float) -> void:
	var translate_factor := translate_speed * delta * 10
	var target_xform := _target.global_transform

	var local_transform_only_origin := Transform(Basis(), _target_origin)
	local_transform_only_origin = local_transform_only_origin.interpolate_with(target_xform, translate_factor)
	_target_origin = local_transform_only_origin.origin
	set_global_transform(Transform(self.global_transform.basis, _target_origin + _view_direction))


func _update_view_direction():
	_view_direction = Vector3.UP.rotated(Vector3.RIGHT, deg2rad(angle)).normalized() * camera_distance


# func _ready():
# 	pass


# func _physics_process(delta):
# 	var direction = Quat(Vector3.RIGHT, -deg2rad(angle)).xform(Vector3.BACK).normalized()
# 	var target_pos = lerp(_last_target_pos, _target.transform.origin, delta * 10)
# 	_last_target_pos = target_pos

# 	self.transform.origin = target_pos + direction * camera_distance
# 	self.transform = self.transform.looking_at(target_pos, Vector3.UP)
