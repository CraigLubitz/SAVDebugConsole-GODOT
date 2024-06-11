#class_name has a weird issue,
# the name has to start/end with _
# there may be other solutions
class_name  _SAVDebugConsole
extends Node

enum LogLevel
{
	DEBUG,
	ERROR,
	INFO,
	VERBOSE,
	WARN
}

# call this to generate a GODOT Print message
static func Print(message: String, level: LogLevel = LogLevel.INFO,  stack: String = "") -> void:
	var unix_time : float = Time.get_unix_time_from_system()
	var unix_time_int : int = unix_time
	var dt : Dictionary = Time.get_datetime_dict_from_unix_time(unix_time)
	var ms : int = (unix_time - unix_time_int) * 1000.0
	var levelchar = "i"
	match level:
		LogLevel.DEBUG:
			levelchar = "d"
		LogLevel.ERROR:
			levelchar = "e"
		#LogLevel.INFO:
			#levelchar = "i"
		LogLevel.VERBOSE:
			levelchar = "v"
		LogLevel.WARN:
			levelchar = "w"
	var str : String = "%04d.%02d.%02d %02d:%02d:%02d:%03d " % [dt.year, dt.month, dt.day, dt.hour, dt.minute, dt.second, ms]
	str += levelchar.to_upper()
	str += " " + message + " " + stack
	print(str)
		
		
# call this to generate a logcat entry
static func Log(tag : String, message : String, level : LogLevel = LogLevel.INFO) -> void:
	var levelchar = "i"
	match level:
		LogLevel.DEBUG:
			levelchar = "d"
		LogLevel.ERROR:
			levelchar = "e"
		#LogLevel.INFO:
			#levelchar = "i"
		LogLevel.VERBOSE:
			levelchar = "v"
		LogLevel.WARN:
			levelchar = "w"
	var pid = OS.execute("log", ["-t", tag, "-p", levelchar, "--", message])
	#var pid = OS.execute("log", ["-t", "SAVDebugConsole", "TEST"])

# https://cs.android.com/android/platform/superproject/+/master:tools/tradefederation/core/src/com/android/tradefed/device/NativeDevice.java;drc=79f8a30e6c184438d765df1ebfd1dca33c4e6467;l=82
