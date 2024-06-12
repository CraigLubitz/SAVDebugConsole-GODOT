@tool
extends CanvasLayer

##max number of entries in the list[br]
## - console_entries_max above 100 can cause performance issues[br]
## - must be an integer > 0
@export var console_entries_max : int = 100

##Switch between GODOT logs and logcat output[br]
## - True = logcat logs
@export var logcat : bool = false

##Additional variables to pass to logcat[br]
## - Default value ("-v, color, ") shows colored entries[br]
## - Example: [br]
##[b] [/b] [b] [/b] [b]-v, color, -s, SAVDebugConsole godot[/b]
@export var logcat_variables : String = ""

##Use logcat polling (slower
## - True = logcat polling
@export var logcat_polling : bool = false
