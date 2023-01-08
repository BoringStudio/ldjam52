extends RigidBody
class_name Sickle

export(float) var max_velocity = 30.0

var _colliding = false
var _last: Node
var _remaining_bounces: int = 0;

onready var _game: Game = get_tree().get_current_scene()
onready var _collision_shape: CollisionShape = $CollisionShape
onready var _max_velocity_squared = max_velocity * max_velocity


func set_collision_disabled(collision_disabled: bool):
	_collision_shape.disabled = collision_disabled


func reset_bounces(amount: int):
	_remaining_bounces = amount


func should_retract() -> bool:
	return _remaining_bounces == 0


#func _physics_process(_delta):
	#if self.linear_velocity.length_squared() > _max_velocity_squared:
	# 	self.linear_velocity = self.linear_velocity.normalized() * max_velocity


func _on_body_entered(body):
	if _colliding:
		return

	if body is Obstacle:
		if body == _last:
			return
		_last = body
		_colliding = true
		if _remaining_bounces > 0:
			_remaining_bounces -= 1

		var action = _game.delay_action(0.0, 2.0)
		if action is GDScriptFunctionState:
			var velocity = self.linear_velocity
			self.linear_velocity = Vector3.ZERO
			yield(action, "completed")
			self.linear_velocity = velocity

		body.play_sound()

		_colliding = false


func _integrate_forces(state):
	var clamped_velocity = min(max_velocity, state.linear_velocity.length())
	state.linear_velocity = state.linear_velocity.normalized() * clamped_velocity
