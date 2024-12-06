extends Node
class_name SaveSys

#-----------------------------SETTING STORAGE-----------------------------#
static func build_general_dict(sens_var: float, fov_var: float)->Dictionary:
	return {"SensVar" = sens_var, "FovVar" = fov_var}

static func build_graphics_dict(window_res: Vector2, is_fullscreen: bool, fps_max: int, scale_mode: int, res_scale: float)->Dictionary:
	return {"WindowRes" = window_res, "IsFullscreen" = is_fullscreen, "FpsMax" = fps_max, "ScaleMode" = scale_mode, "ResScale" = res_scale}

# GODOT 4.4 will be adding Static typed Dicts, Dictionary[String, InputEvent], not too important
##Automatically creates dictionary from input map excluding any "ui" prefixed inputs, will store both InputEventKey and InputEventMouseButton
static func build_bind_dict()->Dictionary:
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
##Saves dictionaries to file path
static func save_settings(save_pth: String, general:Dictionary, binds:Dictionary, graphics:Dictionary)->void:
	var dict_array: Array[Dictionary] = [general, binds, graphics]
	var save_file: FileAccess = FileAccess.open(save_pth, FileAccess.WRITE)
	save_file.store_var(dict_array, true)

##Example access result = load_settings(save_path)
##result[0] will return the general dict, result[1] will return the binds dict, result[2] will return the graphics dict
##contents are accessed by using result['x'].get("'var_name'")
static func load_settings(save_pth: String)->Array[Dictionary]: 
	if(FileAccess.file_exists(save_pth)):
		var save_file: FileAccess = FileAccess.open(save_pth, FileAccess.READ)
		var file_content: Array[Dictionary]
		file_content = save_file.get_var(true) #gets the stored array containing each dictionary, prevents needing to read a sequence of variables
		return file_content 
	return [{}, {}, {}]
