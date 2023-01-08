tool
extends EditorPlugin

func _enter_tree():
	add_custom_type("Trail3D","ImmediateGeometry",preload("res://addons/Trail/trail_3d.gd"),preload("res://addons/Trail/trail3d_icon.svg"))
	pass

func _exit_tree():
	remove_custom_type("Trail3D")
	pass
