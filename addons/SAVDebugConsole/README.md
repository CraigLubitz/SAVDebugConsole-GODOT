# SAVDebugConsole-GODOT
---

&nbsp;

Runtime ("in app") Debug Console for GODOT

Works with both GODOT logs and Android Logcat output

SAV Debug Console is a flexible and light weight GDScript that creates a runtime debug console display that you can add to almost any GODOT application

Display at runtime ("in app") the log output from the print, print_debug and print_stack  methods or logcat

SAV Debug Console is a work in progress

GODOT Build 4.2

&nbsp;

# Features:
- GDScript supports all GODOT platforms
- Android support for logcat
- Clear logcat button
- Scrollable window
- Built in GODOT log entry generator
	- Entries are date and time stamped with milliseconds
	- Include Stack Trace
- Light weight and fast
- Easy to use and modfsify

&nbsp;

# Settings:
Console Entries Max : int = 100
- max number of entries in the list
	- console_entries_max above 100 can cause  performance issues
	- must be an integer > 0

Logcat : bool = false
- Switch between GODOT logs and logcat output
	- True = logcat logs

&nbsp;

# Known issues:

Some messages are displayed partially

Hard to scroll when new logcat entries cause scroll to the bottom

Unknown behavior if GODOT log rotates

Need logcat options available to the user
