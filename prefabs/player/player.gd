extends KinematicBody

enum ThrowState {
	None = 0,
	Preparing = 1,
	Throwing = 2,
	Thrown = 3,
}

enum OverlapState {
	None,
	Waiting,
	Hit,
}

export(float) var movement_speed: float = 15.0
export(float) var shift_speed: float = 25.0
export(float) var dash_speed: float = 40.0
export(float) var dash_duration: float = 0.15
export(float) var dash_interval: float = 0.1
export(float) var ricochet_velocity: float = 15.0
export(float) var max_sickle_impulse: float = 40.0
export(float) var margin: float = 0.15
export(float) var rhythm_margin: float = 0.2
export(PackedScene) var sickle: PackedScene

var _view_target: Vector3
var _prev_direction: Vector3
var _remaining_dash: float = -dash_interval
var _sickle: Sickle
var _jumping: bool = false
var _shift: bool = false
var _throw_state: int = ThrowState.None
var _overlap_state: int = OverlapState.None
var _time_since_prepare: float = 0.0
var _time_since_overlap: float = 0.0

onready var _camera: Camera = get_viewport().get_camera()
onready var _socket: Spatial = $Socket
onready var _audio: AudioStreamPlayer3D = $AudioStreamPlayer3D
onready var _blood_particles: Particles = $Blood

onready var _sound_throw: AudioStream = preload("../../audio/throw.mp3")
onready var _sound_dash: AudioStream = preload("../../audio/dash.mp3")
onready var _sound_damange: AudioStream = preload("../../audio/hit_player.mp3")
onready var _sound_bounce: AudioStream = preload("../../audio/hit_wall.mp3")
onready var _sound_rhythm_bounce: AudioStream = preload("../../audio/rhythm_bounce.mp3")

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

			var action = _game.delay_action(0, 2)
			if action is GDScriptFunctionState:
				yield(action, "completed")

			_play_sound(_sound_dash)
			_remaining_dash = dash_duration
			if is_zero_approx(_prev_direction.length_squared()):
				_prev_direction = _get_view_direction()
			else:
				_prev_direction = _prev_direction.normalized()
			_jumping = false
	elif event.is_action("shift"):
		_shift = event.is_pressed()
	elif event.is_action_pressed("throw"):
		if _throw_state != ThrowState.None:
			return

		_play_sound(_sound_throw)
		_throw_sickle(_time_since_overlap < margin)


func _process(delta):
	var forward = -_get_view_direction();
	var right = Vector3.UP.cross(forward)
	self.transform.basis.x = right
	self.transform.basis.z = forward

	if _overlap_state == OverlapState.Waiting and _throw_state == ThrowState.None:
		_time_since_overlap += delta
		if _time_since_overlap > margin:
			_overlap_state = OverlapState.Hit
			if _sickle_has_critical_velocity():
				_take_damage()
	elif _overlap_state == OverlapState.None and _throw_state == ThrowState.Preparing and _time_since_prepare < margin:
		_time_since_prepare += delta

	if is_instance_valid(_sickle) and _overlap_state == OverlapState.None and _throw_state == ThrowState.None:
		var sickle_to_player = self.global_transform.origin - _sickle.global_transform.origin
		sickle_to_player.y = 0.0
		_sickle.add_central_force(sickle_to_player.normalized() * (50 if _sickle.should_retract() else 30))

	if _remaining_dash > 0.001:
		var _vel = self.move_and_slide(_prev_direction * dash_speed)
		_remaining_dash -= delta
	else:
		if _remaining_dash > -dash_interval:
			_remaining_dash -= delta

		var direction = _get_direction()
		if not is_zero_approx(direction.length_squared()):
			var speed = shift_speed if _shift else movement_speed
			direction = direction.normalized() * speed

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


func _get_direction() -> Vector3:
	return Vector3(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		0,
		Input.get_action_strength("move_back") - Input.get_action_strength("move_forward")
	)


func _get_view_direction() -> Vector3:
	var direction = _view_target - self.transform.origin
	direction.y = 0.0
	return direction.normalized()


func _update_view_target(mouse_position: Vector2):
	var camera_from = _camera.project_ray_origin(mouse_position)
	var camera_to = _camera.project_ray_normal(mouse_position)

	var normal = Vector3.UP

	var t = -normal.dot(camera_from) / normal.dot(camera_to)

	_view_target = camera_from + t * camera_to


func _on_sickle_entered(body: Node):
	if is_instance_valid(_sickle) and body == _sickle:
		if _overlap_state == OverlapState.None:
			if _throw_state == ThrowState.None:
				_overlap_state = OverlapState.Waiting
				_time_since_overlap = 0.0
			elif _throw_state == ThrowState.Preparing:
				_overlap_state = OverlapState.Hit
				if _time_since_prepare < margin:
					_throw_sickle(true)
				else:
					_take_damage()
					_throw_sickle(false)


func _on_sickle_exited(body: Node):
	if is_instance_valid(_sickle) and body == _sickle:
		_overlap_state = OverlapState.None
		_throw_state = ThrowState.None


func _throw_sickle(bounce: bool):
	if _throw_state == ThrowState.Throwing or _throw_state == ThrowState.Thrown:
		return

	if _overlap_state == OverlapState.None and is_instance_valid(_sickle):
		_throw_state = ThrowState.None
		return

	_throw_state = ThrowState.Throwing

	# var action = _game.delay_action()
	# if action is GDScriptFunctionState:
	# 	yield(action, "completed")

	_play_sound(_sound_throw)

	if _sickle == null:
		_sickle = sickle.instance()
		get_tree().root.add_child(_sickle)
		bounce = false

	if not bounce:
		_sickle.linear_velocity = Vector3.ZERO
		_sickle.global_transform.origin = _socket.global_transform.origin

	var impulse_direction = _get_view_direction()
	var impulse = max_sickle_impulse;

	if _sickle_has_critical_velocity():
		#_sickle.linear_velocity = _sickle.linear_velocity.bounce(impulse_direction)
		_sickle.linear_velocity = impulse_direction * max(_sickle.linear_velocity.length(), max_sickle_impulse)
		_play_sound(_sound_bounce)
	else:
		_sickle.linear_velocity = Vector3.ZERO
		_sickle.apply_impulse(Vector3.ZERO, impulse_direction * impulse)

	if _game.is_in_rhythm(0.0, 1.0, rhythm_margin):
		_play_sound(_sound_rhythm_bounce)

	_sickle.reset_bounces(1)

	_throw_state = ThrowState.Thrown
	_time_since_prepare = 0.0
	_time_since_overlap = 0.0


func _take_damage():
	_play_sound(_sound_damange)
	var particles = _blood_particles.duplicate(DUPLICATE_USE_INSTANCING)
	self.add_child(particles)
	particles.emitting = true
	yield(get_tree().create_timer(0.2), "timeout")
	particles.queue_free()


func _sickle_has_critical_velocity() -> bool:
	return is_instance_valid(_sickle) and _sickle.linear_velocity.length_squared() > ricochet_velocity * ricochet_velocity
