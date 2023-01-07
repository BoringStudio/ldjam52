extends RigidBody

func _ready():
	pass


func _on_body_entered(body):
	print("ASDASD")
	if body is Obstacle:
		body.play_sound()
		print("ASDASD")
