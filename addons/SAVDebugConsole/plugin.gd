# https://www.youtube.com/watch?v=Irqlylvy2kk

@tool
extends EditorPlugin

func _enter_tree():
	## Initialization of the plugin goes here.
	## Add the new type with a name, a parent type, a script and an icon.
	#add_custom_type("SAVDebugConsole", "Node2D", preload("res://addons/SAVDebugConsole/SAVDebugConsole.gd"), preload("icon.png"))
	add_custom_type("SAVDebugConsole", "CanvasLayer", preload("res://addons/SAVDebugConsole/scripts/SAVDebugConsole.gd"), preload("icon.png"))

func _exit_tree():
	## Clean-up of the plugin goes here.
	## Always remember to remove it from the engine when deactivated.
	remove_custom_type("SAVDebugConsole")
