extends KinematicBody

enum ThrowState {
	None = 0,
	Preparing = 1,
	Throwing = 2,
	Thrown = 3,
}

export(float) var movement_speed: float = 15.0
export(float) var shift_speed: float = 25.0
export(float) var dash_speed: float = 40.0
export(float) var dash_duration: float = 0.15
export(float) var dash_interval: float = 0.1
export(float) var ricochet_velocity: float = 15.0
export(float) var min_sickle_impulse: float = 20.0
export(float) var max_sickle_impulse: float = 40.0
export(NodePath) var camera: NodePath
export(PackedScene) var sickle: PackedScene

var _view_target: Vector3
var _prev_direction: Vector3
var _remaining_dash: float = -dash_interval
var _sickle: Sickle
var _overlaps_sickle: bool = false
var _prev_sickle_velocity: Vector3 = Vector3.ZERO
var _jumping: bool = false
var _shift: bool = false
var _throw_state: int = ThrowState.None
var _prepared_force: float = 0.0
var _time_since_catch: float = 0.0
var _retracting = false

onready var _camera: Camera = get_node(camera)
onready var _socket: Spatial = $Socket
onready var _audio: AudioStreamPlayer3D = $AudioStreamPlayer3D

onready var _sound_throw: AudioStream = preload("../../audio/throw.mp3");
onready var _sound_dash: AudioStream = preload("../../audio/dash.mp3");
onready var _prepared_force_indicator: Spatial = $MeshInstance3

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
				_prev_direction = _get_view_direction()
			else:
				_prev_direction = _prev_direction.normalized()
			_jumping = false
	elif event.is_action("retract"):
		_retracting = event.is_pressed()
	elif event.is_action("shift"):
		_shift = event.is_pressed()
	elif event.is_action_pressed("throw"):
		if _throw_state != ThrowState.None:
			return

		if (_time_since_catch < 0.2 and _throw_state != ThrowState.Throwing and _throw_state != ThrowState.Thrown
			and _prev_sickle_velocity.length_squared() > ricochet_velocity * ricochet_velocity):
			var impulse_direction = _get_view_direction()
			_sickle.linear_velocity = _prev_sickle_velocity.bounce(impulse_direction)
			play_sound()
			_throw_state = ThrowState.Thrown
		else:
			_throw_state = ThrowState.Preparing
			_prepared_force = 0.0
	elif event.is_action_released("throw"):
		if _throw_state == ThrowState.Throwing or _throw_state == ThrowState.Thrown:
			return

		if not _overlaps_sickle and is_instance_valid(_sickle):
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
		_sickle.global_transform.origin = _socket.global_transform.origin

		var impulse_direction = _get_view_direction()
		var impulse = lerp(min_sickle_impulse, max_sickle_impulse, min(_prepared_force, 1.0));

		if _time_since_catch < 0.2 && _prev_sickle_velocity.length_squared() > ricochet_velocity * ricochet_velocity:
			_sickle.linear_velocity = _prev_sickle_velocity.bounce(impulse_direction)
			play_sound()
		else:
			_sickle.linear_velocity = Vector3.ZERO
			_sickle.apply_impulse(Vector3.ZERO, impulse_direction * impulse)

		_throw_state = ThrowState.Thrown


func _process(_delta):
	self.transform = self.transform.looking_at(_view_target, Vector3.UP)

func _physics_process(delta):
	var held_sickle = false
	if _throw_state == ThrowState.Preparing:
		_prepared_force = min(1.0, _prepared_force + delta * 2)
		if _overlaps_sickle and is_instance_valid(_sickle):
			_sickle.global_transform.origin = _socket.global_transform.origin
			held_sickle = true

	if is_instance_valid(_sickle):
		_time_since_catch += delta
		_sickle.set_collision_disabled(held_sickle)

	_update_prepared_force_indicator()

	if _retracting and _throw_state == ThrowState.None and is_instance_valid(_sickle):
		var sickle_to_player = self.global_transform.origin - _sickle.global_transform.origin
		sickle_to_player.y = 0.0
		_sickle.add_central_force(sickle_to_player.normalized() * 80)

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


func _update_prepared_force_indicator():
	if _throw_state == ThrowState.Preparing:
		_prepared_force_indicator.visible = true
		_prepared_force_indicator.scale = Vector3.ONE * _prepared_force
	else:
		_prepared_force_indicator.visible = false


func _on_sickle_entered(body: Node):
	if is_instance_valid(_sickle) and body == _sickle:
		if not _overlaps_sickle:
			_overlaps_sickle = true
			if _throw_state != ThrowState.Throwing and _throw_state != ThrowState.Thrown:
				_prev_sickle_velocity = _sickle.linear_velocity
				_sickle.linear_velocity = Vector3.ZERO
				_time_since_catch = 0


func _on_sickle_exited(body: Node):
	if is_instance_valid(_sickle) and body == _sickle:
		if _overlaps_sickle and _throw_state == ThrowState.Preparing:
			return

		_overlaps_sickle = false
		_throw_state = ThrowState.None


func play_sound():
	var audio = AudioStreamPlayer3D.new()
	self.add_child(audio)
	audio.stream = preload("../../audio/hit_wall.mp3")
	audio.max_distance = 200
	audio.unit_size = 20
	audio.attenuation_filter_db = -0.1
	audio.play()
	yield(audio, "finished")
	audio.queue_free()
