#https://android.googlesource.com/platform/system/core/+/android-8.0.0_r3/logcat/logcat.cpp
extends Node

var console_entries_max : int = 100	#max number of nodes to create in  $ScrollContainer/VBoxContainer

var vbox: VBoxContainer
var scrollcontainer: ScrollContainer
var savdebugconsole
var log_file_path: String = "user://logs/godot.log"	# path to godot logs OR the proxy file
var log_file: FileAccess	# reference to the working log file
var log_file_valid: bool = false	# control method to prevent reading files and creating entries
var pid: int = 0	# process id of the running logcat proxy
var reposition_vertical_scroll_next_frame: bool = false	# indicates a scroll to bottom in needed
var filteron : bool = false # indicates the filter state, true = filtering

#LOGCAT
var islogcat = false;
var logcatvars = "";

#POLL
var lastlogentrystring = ""
var detla_last_logcat = 0
var polling = false;
var previousdt = Time.get_datetime_string_from_system()

func _ready():
	if Engine.is_editor_hint():
		return

	# set up refences 
	scrollcontainer = $MarginContainer/VBoxContainer/MainScrollContainer
	vbox = $MarginContainer/VBoxContainer/MainScrollContainer/MainVBoxContainer
	savdebugconsole = get_parent().get_parent()

	
	if savdebugconsole.logcat_polling != null and savdebugconsole.logcat_polling == true:
		polling = true;
	if savdebugconsole.logcat != null and savdebugconsole.logcat == true:
		islogcat = true;
	if savdebugconsole.logcat_variables != null:
		logcatvars = savdebugconsole.logcat_variables
		
	# console_entries_max
	if savdebugconsole.console_entries_max != null and savdebugconsole.console_entries_max > 0:
		console_entries_max = savdebugconsole.console_entries_max

	# for testing loging
	#_SAVDebugConsole.Print(str(savdebugconsole.console_entries_max))
	#_SAVDebugConsole.Print(savdebugconsole.logcat_variables)
	#_SAVDebugConsole.Log("SAVDebugConsole", savdebugconsole.logcat_variables)
	#_SAVDebugConsole.Log("SAVDebugConsole", "error", _SAVDebugConsole.LogLevel.ERROR)
	#_SAVDebugConsole.Log("SAVDebugConsole", "warn", _SAVDebugConsole.LogLevel.WARN)
	#_SAVDebugConsole.Log("SAVDebugConsole", "info", _SAVDebugConsole.LogLevel.INFO)
	#_SAVDebugConsole.Log("SAVDebugConsole", "debug", _SAVDebugConsole.LogLevel.DEBUG)
	#_SAVDebugConsole.Log("SAVDebugConsole", "VERBOSE", _SAVDebugConsole.LogLevel.VERBOSE)
	
	# not logcat
	if !islogcat:
		$MarginContainer/VBoxContainer/HBoxContainer/PrintTest.visible = true;
		_load() 
		return

	# logcat
	$MarginContainer/VBoxContainer/HBoxContainer/LogcatClear.visible = true;
	$MarginContainer/VBoxContainer/HBoxContainer/LogTest.visible = true;
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


var dt = ""
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if !log_file_valid:
		return;
	var thiscount = 0	# can be used to fine tune performance on larger logs
	# if there is new text in the log file, add a new entry
	while log_file_valid and log_file.get_position() < log_file.get_length():
		# do we need to trim the hierarchy to the console_entries_max
		if vbox.get_child_count() > console_entries_max + 1:
			vbox.remove_child(vbox.get_child(1))
		
		# get the next line in the log file
		var entry = log_file.get_line()
		
		# throw away dashed lines
		if entry.begins_with("-"):
			continue
			
		# create a label to hold it
		var RTL = RichTextLabel.new()
		# turn on color features
		RTL.bbcode_enabled = true
		# adjust the font
		RTL.add_theme_font_size_override("normal_font_size", 24)
		# add the entry
		RTL.text = entry
		RTL.fit_content = true
		# add to VBoxContainer
		vbox.add_child(RTL)

# !!!!!!!!!!!!!!!!having issues
		# Only if get_v_scroll_bar hasnt grown past the size or the scroll is already at the bottom,
			# add control and scroll bottom
		# https://forum.godotengine.org/t/auto-scroll-down-if-user-is-at-bottom-of-chat-but-if-they-are-not-display-a-scroll-down-button/7034
		#var scoll_rec_size = scrollcontainer.get_rect().size.y
		#var scoll_max_value = scrollcontainer.get_v_scroll_bar().max_value
		#var scoll_value = scrollcontainer.get_v_scroll_bar().value
		#if scoll_max_value < scoll_rec_size or scoll_max_value - scoll_rec_size  == scoll_value:
			#await get_tree().process_frame
			#vbox.get_parent().ensure_control_visible(RTL)

		thiscount += 1
		
		# check filter to set visibility
		if filteron:
			var filtertext : String = $MarginContainer/VBoxContainer/HBoxContainer/FilterText.text
			if  filtertext == "" or RTL.text.countn(filtertext, 0, 0) > 0:
				RTL.visible = true
				RTL.add_to_group("savdebugconsole_entryvisible")	#groups are quick and easy
			else:
				RTL.visible = false
			# display counts
			$MarginContainer/VBoxContainer/HBoxContainer/countof.text = str(get_tree().get_nodes_in_group("savdebugconsole_entryvisible").size()) + " of " + str(vbox.get_child_count())
		

		# handle logcat color
		# get the root of this control
		if islogcat and RTL.text.begins_with("\u001B"):
			if RTL.text.ends_with("[0m"):
				RTL.text = RTL.text.replace("[0m", "[/color]")
			if RTL.text.begins_with("\u001B[31m"):
				dt = RTL.text.replace("\u001B[31m", "")
				RTL.text = "[color=red]" + dt
			if RTL.text.begins_with("\u001B[32m"):
				dt = RTL.text.replace("\u001B[32m", "")
				RTL.text = "[color=green]" + dt
			if RTL.text.begins_with("\u001B[33m"):
				dt = RTL.text.replace("\u001B[33m", "")
				RTL.text = "[color=yellow]" + dt
			if RTL.text.begins_with("\u001B[34m"):
				dt = RTL.text.replace("\u001B[34m", "")
				RTL.text = "[color=blue]" + dt
			if RTL.text.begins_with("\u001B[39m"):
				dt = RTL.text.replace("\u001B[39m", "")
				RTL.text = dt

	if islogcat and polling:
		dt = dt.left(26)
		# get date time portion
# used 2 here, seems more responsive ** refactor
		if detla_last_logcat > 2 or lastlogentrystring != dt:
			#clip off the last 6 digits
			var usec = int(dt.right(6))
			# inc by 1
			usec += 1.0
			#if it crosssed 7 digits
			#trim 1st digit
			if usec > 999999:
				usec -= 1000000
# flag here, and add one to the date
			#convert dt
			var unixdatetime = Time.get_unix_time_from_datetime_string(dt)
			var converteddatetime = Time.get_datetime_string_from_unix_time(unixdatetime)
			# way to validate this happened
			if converteddatetime > previousdt and unixdatetime > 0:
				previousdt = converteddatetime
				lastlogentrystring = dt
			else:
				converteddatetime = previousdt
			converteddatetime = converteddatetime.replace("T", " ")
			converteddatetime += "." + str(usec)
			# use converteddatetime!
			var poll_variables = ["-v", "year usec color", "-d", "-t", converteddatetime, "-f",  log_file_path]
			if logcatvars.length() == 0:
				pid = OS.execute("logcat", poll_variables)
			else:
				poll_variables = Array(logcatvars.split(", ")) + poll_variables
				pid = OS.execute("logcat", poll_variables)
			detla_last_logcat = 0
		else:
			# check again every second
			detla_last_logcat += delta


# logcat specific load routine
func _load_logcat():
	# clean up old proxy file
	DirAccess.remove_absolute(log_file_path)
	# create new proxy file to display to user
	log_file = FileAccess.open(log_file_path, FileAccess.WRITE) # Open File
	log_file.store_line("Waiting on Logcat")
	log_file.close() # Close File
	
#POLL
	if polling:
		# use console_entries_max for initial load
		var poll_variables = ["-v", "year usec color", "-d", "-t", console_entries_max, "-f",  log_file_path]
		if logcatvars.length() == 0:
			pid = OS.execute("logcat", poll_variables)
		else:
			poll_variables = Array(logcatvars.split(", ")) + poll_variables
			pid = OS.execute("logcat", poll_variables)
		_load()
		detla_last_logcat = 0
		return

	# start logcat with output to our proxy file
	# Please note: ["-f",  log_file_path] at a minimum is required for SAVDebugConsole to function
	# get root 
	if logcatvars.length() == 0:
		pid = OS.create_process("logcat", ["-v", "color", "-T", console_entries_max, "-f",  log_file_path])
	else:
		var variables = Array(logcatvars.split(", ")) + ["-v", "color", "-T", console_entries_max, "-f",  log_file_path]
		pid = OS.create_process("logcat", variables)
	_SAVDebugConsole.Log("SAVDebugConsole", "PID=" + str(pid))

	# common load routine
	_load()


# common load routine
func _load():
	# open the godot log file or the logcat proxy file
	log_file = FileAccess.open(log_file_path, FileAccess.READ) # Open File
	if log_file != null:
		log_file_valid = true


func _on_print_pressed():
	_logWithTime("SAVDebugConsole - Test Message", false, true)

func _on_log_pressed():
	_logWithTime("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!", true)

# toggle filtering
func _on_filter_button_gui_input(event):
	# capture event on a label
	if (event is InputEventMouseButton && event.pressed && event.button_index == 1):
		# get reference to filter text
		var filtertext : TextEdit = $MarginContainer/VBoxContainer/HBoxContainer/FilterText
		filtertext.text = ""
		if filteron:
			filtertext.visible = false
			$MarginContainer/VBoxContainer/HBoxContainer/countof.visible = false
		else:
			$MarginContainer/VBoxContainer/HBoxContainer/countof.visible = true
			filtertext.visible = true
			filtertext.grab_focus()
		
		#toggle filter state	
		filteron = !filteron
		
		# reset all entries to visible
		for iteration in vbox.get_children():
			iteration.visible = true
			iteration.add_to_group("savdebugconsole_entryvisible")
		
		# update counts
		$MarginContainer/VBoxContainer/HBoxContainer/countof.text = str(get_tree().get_nodes_in_group("savdebugconsole_entryvisible").size()) + " of " + str(vbox.get_child_count())


# user changed the filter text
func _on_filter_text_text_changed():
		# get reference to filter text
	var filtertext : String = $MarginContainer/VBoxContainer/HBoxContainer/FilterText.text
	for iteration in vbox.get_children():
		if  filtertext == "" or iteration.text.countn(filtertext, 0, 0):
			iteration.visible = true
			iteration.add_to_group("savdebugconsole_entryvisible")
		else:
			iteration.visible = false
			iteration.remove_from_group("savdebugconsole_entryvisible")
	$MarginContainer/VBoxContainer/HBoxContainer/countof.text = str(get_tree().get_nodes_in_group("savdebugconsole_entryvisible").size()) + " of " + str(vbox.get_child_count())


# clear logcat button
func _on_logcat_clear_pressed():
	if polling:
		var exitcode = OS.execute("logcat", ["-c"])
		while vbox.get_child_count() > 1:
			vbox.remove_child(vbox.get_child(1))
		# re-load everything
		#_load_logcat()
		return
		
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


func _on_scoll_bottom_gui_input(event):
	if (event is InputEventMouseButton && event.pressed && event.button_index == 1):
		scrollcontainer.scroll_vertical = scrollcontainer.get_v_scroll_bar().max_value


# function to enhance godot logging
func _logWithTime(message : String, log : bool = false, stack : bool = false):
	var str = ""
	if stack:
		var temp_source = ""
		var temp_function = ""
		var temp_line = ""
		for stackentry in get_stack():
			for stackentrykey in stackentry:
				if stackentrykey == "source":
					temp_source = stackentry[stackentrykey]
				if stackentrykey == "function":
					temp_function = stackentry[stackentrykey]
				if stackentrykey == "line":
					temp_line = str(stackentry[stackentrykey])
			#str += " [bgcolor=DARK_GRAY]" + stackentrykey + "[/bgcolor]: "
			str += ", At Line: " + temp_line + " Function: " + temp_function + " in " + temp_source
	if !log:
		if stack:
			_SAVDebugConsole.Print(message, _SAVDebugConsole.LogLevel.DEBUG, str)
		else:
			_SAVDebugConsole.Print(message, _SAVDebugConsole.LogLevel.DEBUG, "")
	else:
		_SAVDebugConsole.Log("SAVDebugConsole", message, _SAVDebugConsole.LogLevel.DEBUG)


