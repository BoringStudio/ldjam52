extends Spatial
class_name Game

export(PackedScene) var wheat: PackedScene
export(int) var width = 20
export(int) var height = 20
export(float) var cell_size = 1.0
export(int) var bpm = 103
export(float) var max_bit_offset = 0.1

var _start_timestamp: int = 0
var _start_delay: float = 0

onready var _field = $Field
onready var _music = $AudioStreamPlayer
onready var _period: float = 60.0 / bpm

func _ready():
	var top_left = Vector3(-width * cell_size / 2.0, 0, -height * cell_size / 2.0)
	for row in range(0, height):
		for col in range(0, width):
			var wheat_insance: Spatial = wheat.instance()
			wheat_insance.transform.origin = top_left + Vector3(col, 0, row) * cell_size
			_field.add_child(wheat_insance)

	_start_timestamp = Time.get_ticks_msec()
	_start_delay = AudioServer.get_time_to_next_mix() + AudioServer.get_output_latency()
	_music.play()


func delay_action(shift: float = 0.0, period_div: float = 1.0):
	var period = _period / period_div
	var time = (Time.get_ticks_msec() - _start_timestamp) / 1000.0
	time = max(0, time + shift - _start_delay)
	var offset_sec = period - fmod(time, period)
	if offset_sec > max_bit_offset and offset_sec < max_bit_offset * 4:
		yield(get_tree().create_timer(offset_sec - max_bit_offset), "timeout")
