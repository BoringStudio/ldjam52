extends Spatial
class_name Game

export(PackedScene) var wheat: PackedScene
export(int) var width = 20
export(int) var height = 20
export(float) var cell_size = 1.0
export(int) var bpm = 103
export(float) var max_bit_offset = 0.1
export(float) var score_per_wheat = 10.0
export(float) var timeout = 120.0

var song_position: float = 0 setget , _get_song_position
onready var beat_period: float = 60.0 / bpm

var _start_timestamp: int = 0
var _start_delay: float = 0
var _score: float = 0
var _min_score: float = width * height * score_per_wheat

onready var _field = $Field
onready var _music = $AudioStreamPlayer
onready var _progress_bar = $GUI/ProgressBarRoot/ProgressBar
onready var _time_label = $GUI/CenterContainer/Timer

func _ready():
	var top_left = Vector3(-width * cell_size / 2.0, 0, -height * cell_size / 2.0)
	for row in range(0, height):
		for col in range(0, width):
			var wheat_insance: Spatial = wheat.instance()
			wheat_insance.transform.origin = top_left + Vector3(col, 0, row) * cell_size
			_field.add_child(wheat_insance)

	_start_timestamp = Time.get_ticks_usec()
	_start_delay = AudioServer.get_time_to_next_mix() + AudioServer.get_output_latency()
	_music.play()


func delay_action(shift: float = 0.0, period_div: float = 1.0):
	var offset_sec = _compute_song_offset(shift, period_div)
	if offset_sec > max_bit_offset and offset_sec < max_bit_offset * 4:
		yield(get_tree().create_timer(offset_sec - max_bit_offset), "timeout")


func is_in_rhythm(shift: float = 0.0, period_div: float = 1.0, margin: float = 0.1) -> bool:
	return _compute_song_offset(shift, period_div) < margin


func add_wheat_score():
	_add_score(score_per_wheat)


func _add_score(score_to_add: int):
	_score += score_to_add
	_progress_bar.value = 100.0 * _score / _min_score


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
