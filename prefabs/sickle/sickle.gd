extends RigidBody
class_name Sickle

export(float) var max_velocity = 30.0

var _colliding = false
var _last: Node
var _remaining_bounces: int = 0;
var _spin_fast: bool = false

onready var _game: Game = get_tree().get_current_scene()
onready var _collision_shape: CollisionShape = $CollisionShape
onready var _max_velocity_squared = max_velocity * max_velocity
onready var _particles = $Particles


func set_collision_disabled(collision_disabled: bool):
	self.set_collision_mask_bit(2, not collision_disabled)


func reset_bounces(amount: int):
	_remaining_bounces = amount


func should_retract() -> bool:
	return _remaining_bounces == 0


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
			self._spin_fast = true
			yield(action, "completed")
			self.linear_velocity = velocity

		_spin_fast = false
		body.play_sound()
		
		var particles = _particles.duplicate(DUPLICATE_USE_INSTANCING)
		get_tree().get_current_scene().add_child(particles)
		particles.emitting = true
		particles.global_transform.origin = self.global_transform.origin

		_colliding = false
		
		yield(get_tree().create_timer(0.1), "timeout")
		particles.queue_free()


func _integrate_forces(state):
	var clamped_velocity = min(max_velocity, state.linear_velocity.length())
	state.linear_velocity = state.linear_velocity.normalized() * clamped_velocity

	state.angular_velocity = Vector3(0, 50 if _spin_fast else 20, 0)
