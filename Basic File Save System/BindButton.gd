extends Button
class_name BindButton

@export var action_name: String = ""
#@export var optionPanel: Panel

#Connect default on_button up signal to self to emit signal that passes self as parameter of any button
func _ready() -> void:
	var actions: Array[StringName] = InputMap.get_actions()
	if(actions.has(action_name) == false):
		set_text("Invalid Action")
		return
	var index: int = actions.find(action_name)
	set_text(actions[index])
	self.button_up.connect(GameSettings.pre_rebind.bind(self))
