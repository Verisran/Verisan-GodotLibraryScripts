extends Node

@onready var window: Window = get_tree().root

#Settings path
const preset_save_path: String = "user://PresetSelection.save"
var preset_names: Array[String]
var preset_selection: int = 0:
	set(value):
		if(value == 0):
			disable_remove = true
		else:
			disable_remove = false
		preset_selection = value
var preset_name: String:
	get:
		return preset_names[preset_selection]
	set(value):
		preset_names[preset_selection] = value
var preset_path: String:
	get:
		return "user://" + preset_name + ".save"

var disable_remove: bool = false

#DATA
#Default Sets
const DEFAULT_GENERAL: GeneralSet = preload("res://Presets/DefaultGeneral.tres")
const DEFAULT_GRAPHICS: GraphicsSet = preload("res://Presets/DefaultGraphics.tres")
@onready var DEFAULT_BINDS: Dictionary = build_bind_dict()
#Active Sets
var General: GeneralSet = DEFAULT_GENERAL
var Graphics: GraphicsSet = DEFAULT_GRAPHICS
var Binds: Dictionary = DEFAULT_BINDS

#Save state
@warning_ignore("unused_signal")
signal applied_changed(value: bool)

var settings_applied: bool = true:
	set(value):
		if(value != settings_applied):
			emit_signal("applied_changed", value)
		settings_applied = value
var do_rebind: bool = false

func _ready() -> void:
	preset_selection_load()

#-----------------------------PRESETS-----------------------------#
func update_preset_list(target: OptionButton, first_load: bool = false)->void:
	target.clear()
	for item in preset_names:
		target.add_item(item)
	if(first_load):
		target.select(preset_selection)
	preset_selection_save()

#returns true if creation successful
func add_preset(preset: String)->bool:
	#if(preset_names.size() > 10):
	#	return false
	if(preset_names.has(preset)):
		return false
		#preset already exists
	preset_names.append(preset)
	preset_selection = preset_names.size()-1
	return true

func remove_selected_preset()->void:
	if(preset_selection == 0):
		return
	DirAccess.remove_absolute(preset_path)
	preset_names.remove_at(preset_selection)
	preset_selection = 0

#returns true if rename was successful
func rename_selected_preset(new_name: String)->bool:
	if(preset_names.has(new_name)):
		return false
		#preset already exists
	DirAccess.rename_absolute(preset_path, "user://" + new_name + ".save")
	preset_name = new_name
	return true

func select_preset(index: int)->void:
	preset_selection = index

#SAVE & LOAD
func preset_selection_save(create_default: bool = false)->void:
	#If selector file doesnt exist, create new default
	if(create_default):
		add_preset("DefaultPreset")
	var save_file: FileAccess = FileAccess.open(preset_save_path, FileAccess.WRITE)
	save_file.store_var(preset_names, true)
	save_file.store_var(preset_selection, true)
	

func preset_selection_load()->void:
	#If selector file doesnt exist, create new default
	if(!FileAccess.file_exists(preset_save_path)):
		preset_selection_save(true)
	var preset_file: FileAccess = FileAccess.open(preset_save_path, FileAccess.READ)
	preset_names = preset_file.get_var(true)
	preset_selection = preset_file.get_var(true)
	
#-----------------------------SETTINGS-----------------------------#
#SAVE & LOAD
##Saves to file path
func save_settings(save_defaults: bool = false, path: String = preset_path)->void:
	var save_file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if(save_defaults):
		print(DEFAULT_BINDS)
		save_file.store_var(DEFAULT_GENERAL, true)
		save_file.store_var(DEFAULT_GRAPHICS, true)
		save_file.store_var(DEFAULT_BINDS, true)
	else:
		save_file.store_var(General, true)
		save_file.store_var(Graphics, true)
		save_file.store_var(build_bind_dict(), true)
	preset_selection_save()

##Reads settings and adds to data, doubles as a check if file exists
func read_settings(path: String = preset_path)->void:
	if(FileAccess.file_exists(path)):
		Binds.clear()
		var file: FileAccess = FileAccess.open(path, FileAccess.READ)
		General = file.get_var(true)
		Graphics = file.get_var(true)
		Binds = file.get_var(true)

func read_default()->void:
	save_settings(true)

#--------------------------------Check--------------------------------#
#Check if property exists, needed if new settings are to be added
func check_exists(property: String)->bool:
	if(property in General or property in Graphics):
		return true
	return false

#----------------------------READ, APPLY DATA------------------------------#
#GENERAL
#Gameplay
func app_sens(sens_owner: Node3D)->void:
	sens_owner.set_sens(General.sens)

func app_fov(fov_owner: Node3D)->void:
	fov_owner.base_fov = General.fov

#Audio
func app_master_volume(volume: float = General.master_vol)->void:
	General.master_vol = volume
	AudioServer.set_bus_volume_db(AudioManager.AudioBus.Master, volume_helper(General.master_vol))
	AudioServer.set_bus_mute(AudioManager.AudioBus.Master, (volume <= 0))

func app_music_volume(volume: float = General.music_vol)->void:
	General.music_vol = volume
	AudioServer.set_bus_volume_db(AudioManager.AudioBus.Music, volume_helper(General.music_vol))
	AudioServer.set_bus_mute(AudioManager.AudioBus.Music, (volume <= 0))

func app_sfx_volume(volume: float = General.sfx_vol)->void:
	General.sfx_vol = volume
	AudioServer.set_bus_volume_db(AudioManager.AudioBus.SFX, volume_helper(General.sfx_vol))
	AudioServer.set_bus_mute(AudioManager.AudioBus.SFX, (volume <= 0))

func volume_helper(volume: float)->float:
	if(volume <= 0):
		return -60
	volume = linear_to_db(volume*0.01)
	return volume

#GRAPHICS
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
			if(new_key == 8388607): #TEMP FIX FOR UK KEYBOARD LAYOUT RETURNING (UNKOWN) FOR QuoteLeft
				new_key = 96
			@warning_ignore("int_as_enum_without_cast")
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
