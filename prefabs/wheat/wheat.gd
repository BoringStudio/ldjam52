extends Area

export(AudioStream) var sound: AudioStream

var _collided: bool = false

onready var _meshes = $Meshes
onready var _audio = $AudioStreamPlayer3D
onready var _particles = $Particles
onready var _game: Game = get_tree().get_current_scene()

func _ready():
	_audio.connect("finished", self, "_on_sound_finished")
	_meshes.transform = _meshes.transform.rotated(Vector3.UP, deg2rad(90 * (randi() % 4)))


func _on_body_entered(body):
	if _collided:
		return

	if body is RigidBody:
		_collided = true
		_game.add_wheat_score()
		_audio.play()
		_meshes.visible = false
		_particles.emitting = true


func _on_sound_finished():
	self.queue_free()
