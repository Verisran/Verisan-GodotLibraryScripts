extends Node

enum AddMode{
		AS_CHILD = 0,
		TO_POOL = 1
}

#--------------------------------------------------------------------
signal load_request_complete

func _ready() -> void:
	load_request_complete.connect(send_complete_request)

#Request fucntions
##request_path is the string path of the resource you wish to load and instance
##amount is how many copies you wish to instance at once
##return_loc is the node that the instances will be sent to
##add_mode, uses the add_mode enum, by default nodes are added as children, the secondary mode is only usable when the target node has a reference to the wep_manager
func request(request_path: String, amount: int, return_loc: Node, add_mode: AddMode = AddMode.AS_CHILD)->void:
	WorkerThreadPool.add_task(loader.bind(request_path, amount, return_loc, add_mode))

#Load function
##The function is used inside the WorkThreadPool, simply loads instantiates n amount of requested objects, emits load_request_complete when it finishes
func loader(req: String, req_amt: int, target: Node, add_mode: int)->void:
	var return_array: Array[Node]
	#pop request, amt, and target node to send instanced items to
	var requested_item: Resource = load(req)
	#instantiate by amt
	for j in range(req_amt):
		return_array.append(requested_item.instantiate())
	#Emits signal once complete
	call_deferred("emit_signal", "load_request_complete", return_array, target, add_mode)

#Add
##Connected to load_request_complete, sends the newly instanced nodes to their target location. I can be set to either add to child of target or to add to pool of wep_manager [wip]
func send_complete_request(items: Array[Node], add_target: Node, add_mode: int)->void:
	if(add_mode == AddMode.AS_CHILD):
		for item in items:
			add_target.add_child(item)
	elif(add_mode == AddMode.TO_POOL):
		print("'AddMode.TO_POOL' Doesnt Function at this moment")
		for item in items:
			pass
			#add_target.wep_manager.pool.append(item)
