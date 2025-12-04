@tool
extends EditorPlugin

func _enter_tree() -> void:
	print("[JoyConAndroid] Plugin loaded")

func _exit_tree() -> void:
	print("[JoyConAndroid] Plugin unloaded")
