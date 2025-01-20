extends Node

signal load_request_complete

func _ready() -> void:
	load_request_complete.connect(call_complete_request)

#Request fucntions
##request_path is the string path of the resource you wish to load and instance
##amount is how many copies you wish to instance at once
##return_loc is the node that the instances will be sent to
##add_func is the callable that will recieve the request results as an Array[Node] and add_target
func request(request_path: String, amount: int, add_location: Node, add_func: Callable = default_add)->void:
	var task_id: int = WorkerThreadPool.add_task(loader.bind(request_path, amount, add_location, add_func))
	await load_request_complete
	WorkerThreadPool.wait_for_task_completion(task_id)
	
#Load function
##The function is used inside the WorkThreadPool, simply loads instantiates n amount of requested objects, emits load_request_complete when it finishes
func loader(req: String, req_amt: int, add_location: Node, add_func: Callable)->void:
	var return_array: Array[Node]
	#pop request, amt, and target node to send instanced items to
	var requested_item: Resource = load(req)
	#instantiate by amt
	for j in range(req_amt):
		return_array.append(requested_item.instantiate())
	#Emits signal once complete
	call_deferred("emit_signal", "load_request_complete", return_array, add_location, add_func)

#Add
##Connected to load_request_complete, sends the newly instanced nodes to their target location. I can be set to either add to child of target or to add to pool of wep_manager [wip]
func call_complete_request(items: Array[Node], add_location: Node, add_func: Callable)->void:
	#WorkerThreadPool.wait_for_task_completion()
	add_func.call(items, add_location)

func default_add(items: Array[Node], add_location: Node)->void:
	#Ensures runs on next frame only
	await get_tree().physics_frame
	for item in items:
		add_location.add_child(item)
