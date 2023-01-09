extends Spatial
class_name Game

enum State {
	Playing,
	Win,
	Dead,
}

export(PackedScene) var wheat: PackedScene
export(int) var width = 20
export(int) var height = 20
export(float) var cell_size = 1.0
export(int) var bpm = 103
export(float) var max_bit_offset = 0.1
export(float) var score_per_wheat = 10.0
export(float) var score_per_bounce = 100.0
export(float) var score_per_rhythm_bounce = 1000.0
export(float) var timeout = 120.0
export(int) var health = 5
export(float) var percentage = 0.9

var song_position: float = 0 setget , _get_song_position
onready var beat_period: float = 60.0 / bpm

var _start_timestamp: int = 0
var _start_delay: float = 0
var _score: float = 0
var _min_score: float = width * height * score_per_wheat
var _health: int = health
var _required_wheat: float = 0
var _gathared_wheat: int = 0
var _state: int = State.Playing

onready var _field = $Field
onready var _music = $AudioStreamPlayer
onready var _progress_bar = $GUI/ProgressBarRoot/ProgressBar
onready var _time_label = $GUI/Up/VBoxContainer/Timer
onready var _score_label = $GUI/Up/VBoxContainer/Score
onready var _ui_animation_player: AnimationPlayer = $GUI/Up/VBoxContainer/AnimationPlayer
onready var _health_bar = $GUI/Bottom/HBoxContainer
onready var _heart_icon = $GUI/Bottom/HBoxContainer/Heart

onready var _gui_root = $GUI
onready var _final_screen_root = $FinalScreen
onready var _final_screen_title = $FinalScreen/CenterContainer/VBoxContainer/Result
onready var _final_screen_score = $FinalScreen/CenterContainer/VBoxContainer/Score


func _ready():
	var top_left = Vector3(-width * cell_size / 2.0, 0, -height * cell_size / 2.0)
	for row in range(0, height):
		for col in range(0, width):
			var wheat_insance: Spatial = wheat.instance()
			wheat_insance.transform.origin = top_left + Vector3(col, 0, row) * cell_size
			_field.add_child(wheat_insance)
			_required_wheat += 1.0

	_required_wheat = _required_wheat * percentage

	_start_timestamp = Time.get_ticks_usec()
	_start_delay = AudioServer.get_time_to_next_mix() + AudioServer.get_output_latency()
	_music.play()
	_add_score(0, "add")

	for _i in range(1, _health):
		var heart = _heart_icon.duplicate(DUPLICATE_USE_INSTANCING)
		_health_bar.add_child(heart)


func _input(event):
	if event.is_action("retry") and _state != State.Playing:
		var scene = get_tree().current_scene
		for n in scene.get_children():
			scene.remove_child(n)
			n.queue_free()

		var _res = get_tree().reload_current_scene()


func delay_action(shift: float = 0.0, period_div: float = 1.0):
	var offset_sec = _compute_song_offset(shift, period_div)
	if offset_sec > max_bit_offset and offset_sec < max_bit_offset * 4:
		yield(get_tree().create_timer(offset_sec - max_bit_offset), "timeout")


func is_in_rhythm(shift: float = 0.0, period_div: float = 1.0, margin: float = 0.1) -> bool:
	return _compute_song_offset(shift, period_div) < margin


func add_wheat_score():
	_gathared_wheat += 1
	_add_score(score_per_wheat, "add")


func add_bounce_score():
	_add_score(score_per_bounce, "add_bounce")


func add_rhythm_bounce_score():
	_add_score(score_per_rhythm_bounce, "add_rhythm_bounce")


func take_damage() -> bool:
	if _health > 1:
		_health -= 1
		var last_heart = _health_bar.get_child(0)
		if is_instance_valid(last_heart):
			last_heart.queue_free()
		return false
	else:
		_finish_game(State.Dead)
		return true


func _add_score(score_to_add: int, animation: String):
	_score += score_to_add
	_progress_bar.value = _gathared_wheat * 100.0 / _required_wheat
	_score_label.text = "%d" % _score
	_ui_animation_player.play(animation)
	if _gathared_wheat >= _required_wheat:
		_finish_game(State.Win)


func _finish_game(state: int):
	if _state != State.Playing:
		return
	_state = state
	_gui_root.visible = false
	_final_screen_root.visible = true
	if state == State.Dead:
		_final_screen_title.text = "The sickle is not a toy!"
	else:
		_final_screen_title.text = "Nice!"
	_final_screen_score.text = "Score: %d (%d%%)" % [_score, _progress_bar.value]


func _physics_process(_delta):
	var offset = _get_song_position()
	var diff = timeout - offset
	if diff < 0:
		_time_label.text = "game over"
	else:
		var seconds = int(diff)
		_time_label.text = "%02d:%02d" % [(seconds / 60), (seconds % 60)]


func _compute_song_offset(shift: float, period_div: float) -> float:
	var adjusted_period = beat_period / period_div
	var time = (Time.get_ticks_usec() - _start_timestamp) / 1000000.0
	time = max(0, time + shift - _start_delay)
	return adjusted_period - fmod(time, adjusted_period)


func _get_song_position():
	var time = (Time.get_ticks_usec() - _start_timestamp) / 1000000.0
	return max(0, time - _start_delay)
