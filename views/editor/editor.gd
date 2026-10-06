class_name Editor
extends Node

signal tool_changed(tool: Tool)

@export var canvas: Canvas
@export var page_controls: PageControls
@export var playback_manager: PlaybackManager
@export var edit_extras: EditExtras
@export var toolset: Toolset

var project: Project
var current_page: Page
## Variables used for implementing undo
var _editing_project: Project
var _editing_tool: Tool
var _edit_snapshot: Dictionary
var current_tool: Tool:
	set(value):
		current_tool = value
		tool_changed.emit(value)


func _ready() -> void:
	canvas.canvas_input.connect(_handle_canvas_input)

	page_controls.menu_toggle.connect(edit_extras.open)
	page_controls.play_toggle.connect(
		func(): playback_manager.is_playing = !playback_manager.is_playing
	)
	page_controls.onion_skin_toggle.connect(canvas.toggle_onion_skin)


## Creates a blank project and loads into the editor.
func new_project() -> void:
	var blank_project = Project.new()
	blank_project.new_project(256, 192)
	load_project(blank_project)


## Loads a provided [param project] into the editor.
func load_project(p: Project) -> void:
	project = p
	page_controls.attach_project(project)
	canvas.attach_project(project)
	playback_manager.attach_project(project)
	edit_extras.attach_project(project)
	if project:
		project.get_page_by_index(0)


## Loads in a blank project
func unload_project() -> void:
	playback_manager.pause()
	load_project(null)


func _handle_canvas_input(event: InputEvent) -> void:
	if event is InputEventMouse:
		var canvas_pos = canvas.dynamic_node.get_local_mouse_position()
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT:
				# Saves the project state on mouse press for future undos
				# Calls the commit_edit() function in project.gd on mouse release
				if event.pressed and current_tool is Tool:
					# Save the current project state
					_editing_project = project
					_editing_tool = current_tool
					if _editing_project:
						_edit_snapshot = _editing_project.start_edit()
					else:
						_edit_snapshot = {}
					# Move the tool pointer down to show an edit is beginning
					_editing_tool.on_pointer_down(canvas_pos, canvas)
				
				# If mouse is released
				elif not event.pressed:
					# Finishes the tool interaction
					var tool
					if _editing_tool:
						tool = _editing_tool
					else:
						tool = current_tool
					if tool is Tool:
						await tool.on_pointer_up(canvas_pos, canvas)
					
					# Calls commit_edit() to save this state as an edit that can be undone
					if _editing_project and not _edit_snapshot.is_empty():
						_editing_project.commit_edit(_edit_snapshot, tool.name)
					_editing_project = null
					_editing_tool = null
					_edit_snapshot = {}
		
		elif event is InputEventMouseMotion:
			if current_tool is Tool:
				current_tool.on_pointer_move(canvas_pos, canvas)

## Function to trigger undo when Ctrl+Z or Cmd+Z (Mac) is input
func _unhandled_key_input(event: InputEvent) -> void:
	if (
		event is InputEventKey
		and event.pressed
		and not event.echo
		and event.keycode == KEY_Z
		and (event.ctrl_pressed or event.meta_pressed)
		and project
	):
		project.undo()
		get_viewport().set_input_as_handled()
