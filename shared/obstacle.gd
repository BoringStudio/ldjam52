extends StaticBody
class_name Obstacle

var _obstacle_type: int
var _sound: AudioStream

func _init(type: int):
	self._obstacle_type = type
	_sound = preload("../../shared/obstacle_type.gd").get_sound(type)
	assert(_sound != null, "sound not found")


func play_sound():
	var audio = AudioStreamPlayer3D.new()
	self.add_child(audio)
	audio.stream = _sound
	audio.max_distance = 200
	audio.unit_size = 20
	audio.attenuation_filter_db = -0.1
	audio.play()
	yield(audio, "finished")
	audio.queue_free()
