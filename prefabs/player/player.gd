extends KinematicBody

export(float) var movement_speed: float = 15.0
export(float) var dash_speed: float = 40.0
export(float) var dash_duration: float = 0.15
export(float) var dash_interval: float = 0.1
export(float) var sickle_impulse: float = 30.0
export(NodePath) var camera: NodePath
export(PackedScene) var sickle: PackedScene

var _view_target: Vector3
var _prev_direction: Vector3
var _remaining_dash: float = -dash_interval
var _sickle: RigidBody
var _jumping: bool = false
var _throwing: bool = false

onready var _camera: Camera = get_node(camera)
onready var _socket: Spatial = $Socket
onready var _audio: AudioStreamPlayer3D = $AudioStreamPlayer3D

onready var _sound_throw: AudioStream = preload("../../audio/throw.mp3");
onready var _sound_dash: AudioStream = preload("../../audio/dash.mp3");

onready var _game: Game = get_tree().get_current_scene()

func _ready():
	_update_view_target(get_viewport().get_mouse_position())


func _input(event):
	if event is InputEventMouseMotion:
		_update_view_target(event.position)
	elif event.is_action_pressed("dash"):
		if _jumping:
			return

		if _remaining_dash <= -dash_interval:
			_jumping = true

			var action = _game.delay_action(0.1)
			if action is GDScriptFunctionState:
				yield(action, "completed")

			_play_sound(_sound_dash)
			_remaining_dash = dash_duration
			if is_zero_approx(_prev_direction.length_squared()):
				_prev_direction = (_view_target - self.transform.origin).normalized()
			else:
				_prev_direction = _prev_direction.normalized()
			_jumping = false
	elif event.is_action_pressed("throw"):
		if _throwing:
			return
		_throwing = true

		if _sickle != null:
			_sickle.queue_free()

		var action = _game.delay_action()
		if action is GDScriptFunctionState:
			yield(action, "completed")

		_play_sound(_sound_throw)

		_sickle = sickle.instance()
		_sickle.transform.origin = _socket.global_transform.origin
		get_tree().root.add_child(_sickle)

		var impulse_direction = (_view_target - self.transform.origin).normalized()
		_sickle.apply_impulse(Vector3.ZERO, impulse_direction.normalized() * sickle_impulse)
		_throwing = false


func _process(_delta):
	self.transform = self.transform.looking_at(_view_target, Vector3.UP)


func _physics_process(delta):
	if _remaining_dash > 0.001:
		var _vel = self.move_and_slide(_prev_direction * dash_speed)
		_remaining_dash -= delta
	else:
		if _remaining_dash > -dash_interval:
			_remaining_dash -= delta

		var direction = _get_direction()
		if not is_zero_approx(direction.length_squared()):
			direction = direction.normalized() * movement_speed

			if not is_zero_approx(_prev_direction.length_squared()):
				direction = lerp(_prev_direction, direction, delta * 10)

		_prev_direction = direction

		var _vel = self.move_and_slide(direction)


func _play_sound(sound: AudioStream):
	var audio = _audio.duplicate(DUPLICATE_USE_INSTANCING)
	self.add_child(audio)
	audio.stream = sound
	audio.play()
	yield(audio, "finished")
	audio.queue_free()


func _get_direction():
	return Vector3(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		0,
		Input.get_action_strength("move_back") - Input.get_action_strength("move_forward")
	)


func _update_view_target(mouse_position: Vector2):
	var camera_from = _camera.project_ray_origin(mouse_position)
	var camera_to = _camera.project_ray_normal(mouse_position)

	var normal = Vector3.UP

	var t = -normal.dot(camera_from) / normal.dot(camera_to)

	_view_target = camera_from + t * camera_to
