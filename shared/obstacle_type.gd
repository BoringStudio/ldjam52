enum ObstacleType {
    Player = 0,
    Wood = 1,
    Wall = 2,
    Metal = 3,
}

static func get_sound(item: int):
	match item:
		0:
			return load("res://audio/hit_player.mp3")
		1:
			return load("res://audio/hit_wood.mp3")
		2:
			return load("res://audio/hit_wall.mp3")
		3:
			return load("res://audio/hit_metal.mp3")
		_:
			return null
