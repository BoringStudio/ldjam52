extends StaticBody
class_name Obstacle


func play_sound():
	var audio = AudioStreamPlayer3D.new()
	self.add_child(audio)
	audio.stream = preload("../../shared/obstacle_type.gd").get_sound(randi() % 3 + 1)
	audio.max_distance = 200
	audio.unit_size = 20
	audio.attenuation_filter_db = -0.1
	audio.play()
	yield(audio, "finished")
	audio.queue_free()
