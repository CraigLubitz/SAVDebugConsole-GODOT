@tool
extends Node

@export var console_entries_max : int = 100
@export var logcat : bool = false

var DebugConsoleScene : PackedScene  = preload("res://addons/SAVDebugConsole/DebugConsole.tscn")
var debugconsolescene

# Called when the node enters the scene tree for the first time.
func _enter_tree():
	if Engine.is_editor_hint():
		debugconsolescene = DebugConsoleScene.instantiate()
		add_child(debugconsolescene)
		debugconsolescene.set_owner(get_tree().get_edited_scene_root())
		#print("here DC_UI enter")

func _exit_tree():
	if debugconsolescene != null:
		debugconsolescene.queue_free()
