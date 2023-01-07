extends RigidBody

var _colliding = false
var _last: Node

onready var _game: Game = get_tree().get_current_scene()


func _on_body_entered(body):
	if _colliding:
		return

	if body is Obstacle:
		if body == _last:
			return
		_last = body
		_colliding = true

		var action = _game.delay_action(0.0, 2.0)
		if action is GDScriptFunctionState:
			var velocity = self.linear_velocity
			self.linear_velocity = Vector3.ZERO
			yield(action, "completed")
			self.linear_velocity = velocity

		body.play_sound()

		_colliding = false
