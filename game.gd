extends Spatial

export(PackedScene) var wheat: PackedScene
export(int) var width = 20
export(int) var height = 20
export(float) var cell_size = 1.0

onready var _field = $Field


func _ready():
	var top_left = Vector3(-width * cell_size / 2.0, 0, -height * cell_size / 2.0)
	for row in range(0, height):
		for col in range(0, width):
			var wheat_insance: Spatial = wheat.instance()
			wheat_insance.transform.origin = top_left + Vector3(col, 0, row) * cell_size
			_field.add_child(wheat_insance)
