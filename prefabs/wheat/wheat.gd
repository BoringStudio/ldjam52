extends Area

export(AudioStream) var sound: AudioStream

var _collided: bool = false

onready var _meshes = $Meshes
onready var _audio = $AudioStreamPlayer3D

func _ready():
	_audio.connect("finished", self, "_on_sound_finished")


func _on_body_entered(body):
	if _collided:
		return

	if body is RigidBody:
		_collided = true
		_audio.play()
		_meshes.visible = false


func _on_sound_finished():
	self.queue_free()
