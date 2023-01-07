extends Area

func _ready():
	pass # Replace with function body.


func _on_body_entered(body):
	if body is RigidBody:
		self.queue_free()
