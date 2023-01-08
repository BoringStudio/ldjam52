extends Spatial
class_name BeatIndicator

export(int) var ring_count: int = 1
export(float) var min_radius: float = 0.3
export(float) var max_radius: float = 2.0
export(float) var beat_range: float = 1.0
export(int) var nth_beat = 5;

var _rings: Array = []

onready var _rings_root: Node = $Rings
onready var _origin_ring: MeshInstance = $Rings/Ring
onready var _game: Game = get_tree().get_current_scene()

onready var _radius_step = (max_radius - min_radius) / ring_count

func _ready():
	self._rings.append(_origin_ring)

	var origin_ring_material = self._origin_ring.get_surface_material(0)
	for _i in range(1, ring_count):
		var new_ring = self._origin_ring.duplicate(DUPLICATE_USE_INSTANCING)
		new_ring.set_surface_material(0, origin_ring_material.duplicate())
		self._rings_root.add_child(new_ring)
		self._rings.append(new_ring)

	for i in range(0, self.ring_count):
		var ring = self._rings[i]
		var test = float(i + 1) / float(self.ring_count)
		print(test)
		_set_ring_props(ring, test, 0.1 / test, 1.0 - test)


func _process(_delta):
	var song_position = _game.song_position
	var beat_period = _game.beat_period
	song_position += beat_period * (1.0 - beat_range)
	var elapsed_beats = int(song_position / beat_period)
	var remaining = ((elapsed_beats + 1) * beat_period - song_position) / beat_period

	for i in range(0, self.ring_count):
		var ring = _rings[(elapsed_beats + i) % self.ring_count]
		var radius = min_radius + i * self._radius_step + (remaining * remaining) * self._radius_step
		var thickness = 0.1 / radius
		if i == 0 and _game.is_in_rhythm():
			thickness = 1.0

		_set_ring_props(ring, radius, thickness, (float(self.ring_count) - float(i) - remaining) / float(self.ring_count))


func _set_ring_props(ring: MeshInstance, radius: float, thickness: float, color_shift: float):
	ring.scale = Vector3(radius, 1, radius)
	var ring_material = ring.get_surface_material(0)
	ring_material.set_shader_param("thickness", thickness)
	ring_material.set_shader_param("color_shift", color_shift)
