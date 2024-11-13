extends Node

const landing_screen = preload("res://screens/landing/Landing.tscn")

func load_landing_screen():
	get_tree().root.add_child.call_deferred(landing_screen.instantiate())
