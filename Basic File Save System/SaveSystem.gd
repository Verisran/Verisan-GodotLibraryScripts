extends Node

@onready var window: Window = get_tree().root
var save_path: String = "user://default_preset.save"
var preset_selection: int

#DATA
var General: GeneralSet = preload("res://Autoloads/Settings/DefaultSets/DefaultGeneral.tres")
var Graphics: GraphicsSet = preload("res://Autoloads/Settings/DefaultSets/DefaultGraphics.tres")
var Binds: Dictionary = build_bind_dict()

#Save state
var settings_applied: bool = true
var do_rebind: bool = false

#--------------------------------Select Set--------------------------------#
func select_graphics_preset(setPath: String = "default")->void:
	if(setPath == "default"):
		Graphics = load("res://Autoloads/Settings/DefaultGraphics.tres")
	Graphics = load(setPath)

#Check if property exists, needed if new settings are to be added
func check_exists(property: String)->bool:
	if(property in General or property in Graphics):
		return true
	return false
#----------------------------READ, APPLY DATA------------------------------#
#General
func app_sens(sens_owner: Node3D)->void:
	sens_owner.set_sens(General.sens)

func app_fov(fov_owner: Node3D)->void:
	fov_owner.base_fov = General.fov

#Graphics
func app_window_res(setto: Vector2i = Graphics.window_res)->void:
	Graphics.window_res = setto
	#set pixel size of window
	DisplayServer.window_set_size(Graphics.window_res)

func app_fullscreen(setto: bool = Graphics.fullscreen)->void:
	Graphics.fullscreen = setto
	if(Graphics.fullscreen):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func app_fps_max(setto: int = Graphics.fps)->void:
	Graphics.fps = setto
	Engine.set_max_fps(Graphics.fps)
	
func app_scale_mode(setto: int = Graphics.scale_mode)->void:
	Graphics.scale_mode = setto
	match Graphics.scale_mode:
		0: 
			window.set_scaling_3d_mode(Viewport.SCALING_3D_MODE_BILINEAR)
		1:
			window.set_scaling_3d_mode(Viewport.SCALING_3D_MODE_FSR2)

func app_res_scale(setto: float = Graphics.res_scale)->void:
	Graphics.res_scale = setto
	window.set_scaling_3d_scale(Graphics.res_scale)

#Get Binds
# GODOT 4.4 will be adding Static typed Dicts, Dictionary[String, InputEvent], not too important
##Automatically creates dictionary from input map excluding any "ui" prefixed inputs, will store both InputEventKey and InputEventMouseButton
func build_bind_dict()->Dictionary:
	var bind_dict: Dictionary
	for action:String in InputMap.get_actions():
		if(!action.contains("ui")):
			for a_bind:InputEvent in InputMap.action_get_events(action):
				if(a_bind is InputEventKey):
					bind_dict.get_or_add(action, a_bind)
				elif(a_bind is InputEventMouseButton):
					bind_dict.get_or_add(action, a_bind)
	return bind_dict
	
#-----------------------------SAVE & LOAD-----------------------------#
##Saves to file path
func save_settings(path: String = save_path)->void:
	var save_file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	save_file.store_var(General, true)
	save_file.store_var(Graphics, true)
	save_file.store_var(build_bind_dict(), true)

##Reads settings and adds to data, 
func read_settings(path: String = save_path)->Dictionary: 
	if(FileAccess.file_exists(path)):
		var file: FileAccess = FileAccess.open(path, FileAccess.READ)
		General = file.get_var(true)
		Graphics = file.get_var(true)
		return file.get_var(true)
	return {}

#--------------------------------BINDS--------------------------------#
var current_button: BindButton
var can_rebind: bool = true
#prepares for binding
func pre_rebind(button: BindButton)->void:
	if(can_rebind): #makes sure bind delay timer is stopped
		current_button = button #gets a reference to the current button
		button.set_text("Press a key...")
		settings_applied = false
		do_rebind = true #sets flag for input to be recorded

func get_input_to_bind(event: InputEvent)->void:
	if(event is InputEventKey and event.pressed):
		if(event.keycode != KEY_ESCAPE): # Exclude Escape Key from keybinds
			rebind_action(current_button, event.keycode, 1)
			rebind_delay()
			do_rebind = false
	elif(event is InputEventMouseButton and event.get_button_index() != 0):
		rebind_action(current_button, event.get_button_index(), 2)
		rebind_delay()
		do_rebind = false

func rebind_action(target_button: BindButton, new_key: int, mode: int)->void:
	InputMap.action_erase_events(target_button.action_name)
	var new_bind: InputEventKey = InputEventKey.new()
	var new_mouse: InputEventMouseButton = InputEventMouseButton.new()
	match mode:
		1: #Handles Key inputs
			if(new_key == 8388607): #FIX FOR UK KEYBOARD LAYOUT RETURNING (UNKOWN) FOR QuoteLeft
				new_key = 96
			new_bind.keycode = new_key #as InputEventKey
			InputMap.action_add_event(target_button.action_name, new_bind)
			target_button.set_text(rename_btn(target_button.action_name, new_bind.as_text_keycode()) )
			current_button = null
		2: #Handles mouse button inputs
			new_mouse.set_button_index(new_key)
			InputMap.action_add_event(target_button.action_name, new_mouse)
			target_button.set_text(rename_btn(target_button.action_name, str("Mouse", new_mouse.get_button_index()) ) )
			current_button = null

func rename_btn(button_action:String, bind: String)->String: #Rename helper
	return button_action + ": " + bind

func rebind_delay()->void:
	can_rebind = false
	var timer: SceneTreeTimer = get_tree().create_timer(0.2)
	await timer.timeout
	can_rebind = true
