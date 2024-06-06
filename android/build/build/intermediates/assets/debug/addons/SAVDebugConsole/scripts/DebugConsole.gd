extends Node

var console_entries_max : int = 100	#max number of nodes to create in  $ScrollContainer/VBoxContainer

var vbox: VBoxContainer
var scrollcontainer: ScrollContainer
var log_file_path: String = "user://logs/godot.log"	# path to godot logs OR the proxy file
var log_file: FileAccess	# reference to the working log file
var log_file_valid: bool = false	# control method to prevent reading files and creating entries
var pid: int = 0	# process id of the running logcat proxy
var reposition_vertical_scroll_next_frame: bool = false	# indicates a scroll to bottom in needed


# Called when the node enters the scene tree for the first time.

func _ready():
	if Engine.is_editor_hint():
#		print("here console")
		return
#		var debugconsolescene = SAVDebugConsoleScene.instantiate()
#		add_child(debugconsolescene)
#		debugconsolescene.set_owner(get_tree().get_edited_scene_root())
#		print("here")
	scrollcontainer = $MarginContainer/VBoxContainer/MainScrollContainer
	vbox = $MarginContainer/VBoxContainer/MainScrollContainer/MainVBoxContainer
	
	var canvaslayer = get_parent()
	var savdebugconsole = canvaslayer.get_parent()
	#var savdebugconsole = get_parent()
	# console_entries_max
	if savdebugconsole.console_entries_max != null and savdebugconsole.console_entries_max > 0:
		console_entries_max = savdebugconsole.console_entries_max
		
	if savdebugconsole.logcat == null or savdebugconsole.logcat == false:
		_load() 
		return
	
	$MarginContainer/VBoxContainer/HBoxContainer/LogcatClear.visible = true;
	$MarginContainer/VBoxContainer/HBoxContainer/PrintTestLogEntry.visible = false;
	log_file_path = ProjectSettings.globalize_path("user://logcat.txt")
	_load_logcat()


func _exit_tree():
	# tell _process to skip processing our stuff
	log_file_valid = false
	# kill the process from above
	OS.kill(pid)
	# wait for process to stop 
	while OS.is_process_running(pid):
		pass
	# close the proxy file	
	log_file.close() # Close File


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# this scrolls the $ScrollContainer to the bottom on the next frame after the node hierarchy is update
	if reposition_vertical_scroll_next_frame:
		reposition_vertical_scroll_next_frame = false
		scrollcontainer.scroll_vertical = scrollcontainer.get_v_scroll_bar().max_value
		
	var thiscount = 0	# can be used to fine tune performance on larger logs
	var savdebugconsole = get_parent()
	# if there is new text in the log file, add a new entry
	while thiscount < console_entries_max and log_file_valid and log_file.get_position() < log_file.get_length():
		# do we need to trim the hierarchy to the console_entries_max
		if vbox.get_child_count() > console_entries_max + 1:
			vbox.remove_child(vbox.get_child(1))
		
		# get the next line in the log file
		var entry = log_file.get_line()
		# create a label to hold it
		var RTL = RichTextLabel.new()
		# adjust the font
		RTL.add_theme_font_size_override("normal_font_size", 24)
		# add the entry
		RTL.text = entry
		RTL.fit_content = true
		# add to VBoxContainer
		vbox.add_child(RTL)
		thiscount += 1
		reposition_vertical_scroll_next_frame = true	# flag to cause scroll to bottom


# logcat specific load routine
func _load_logcat():
	# clean up old proxy file
	DirAccess.remove_absolute(log_file_path)
	# create new proxy file to display to user
	log_file = FileAccess.open(log_file_path, FileAccess.WRITE) # Open File
	log_file.store_line("Waiting on Logcat")
	log_file.close() # Close File

	# start logcat with output to our proxy file
	# Please note: ["-f",  log_file_path] at a minimum is required for SAVDebugConsole to function
	pid = OS.create_process("logcat", ["-f",  log_file_path])
	#pid = OS.create_process("logcat", ["-f",  log_file_path, "*:W"])	#filter to only warnings
	#_logWithTime(pid)
	
	# common load routine
	_load()


# common load routine
func _load():
	# open the godot log file or the logcat proxy file
	log_file = FileAccess.open(log_file_path, FileAccess.READ) # Open File
	if log_file != null:
		log_file_valid = true


func _on_button_pressed():
	_logWithTime("SAV Debug Console - Test Message", true)


# clear logcat button
func _on_logcat_clear_pressed():
	# tell _process to skip processing our stuff
	log_file_valid = false
	# kill the process from above
	OS.kill(pid)
	# wait for process to stop 
	while OS.is_process_running(pid):
		var x = 0
	# close the proxy file	
	log_file.close() # Close File
	# clear the logcat
	var exitcode = OS.execute("logcat", ["-c"])
	# remove any entries from the heirachy
	while vbox.get_child_count() > 1:
		vbox.remove_child(vbox.get_child(1))
	# re-load everything
	_load_logcat()


# function to enhance godot logging
func _logWithTime(message, stack = false):
	var unix_time: float = Time.get_unix_time_from_system()
	var unix_time_int: int = unix_time
	var dt: Dictionary = Time.get_datetime_dict_from_unix_time(unix_time)
	var ms: int = (unix_time - unix_time_int) * 1000.0
	var str := "%04d.%02d.%02d %02d:%02d:%02d:%03d " % [dt.year, dt.month, dt.day, dt.hour, dt.minute, dt.second, ms]
	print_debug(str, message)
	if (stack != null):
		print_stack( )
