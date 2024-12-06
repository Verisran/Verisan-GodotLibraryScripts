#MIT License
#Copyright (c) 2024 Oskar D.
#https://github.com/Verisran/Verisan-GodotLibraryScripts

extends Node3D
class_name physics 

#Gets the look vector of camera
static func get_camera_ray(camera: Camera3D, mouse_pos: Vector2, length: float)->Array[Vector3]:
	var mouse_position: Vector2 = mouse_pos #get_viewport().get_mouse_position()
	var from: Vector3 = camera.project_ray_origin(mouse_position)
	var to: Vector3 = from + camera.project_ray_normal(mouse_position) * length
	return [from, to]

#simpler raycast
static func raycast(myself: Node3D, space_state: PhysicsDirectSpaceState3D, ray_from: Vector3, ray_to: Vector3, layers: int, bodies: bool = true, areas: bool = false)->Dictionary:
	if(space_state == null):
		space_state = myself.get_world_3d().direct_space_state
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(ray_from, ray_to, layers)
	query.set_collide_with_bodies(bodies)
	query.set_collide_with_areas(areas)
	var result: Dictionary = space_state.intersect_ray(query)
	return result

#Semi-Universal shape creation
##For SphereShape input "half_width" only
##For BoxShape3D input "half_width", "height", "depth" - (half_width is autmotatically doubled to be used as normal width)
##For CapsuleShape3D input "half_width" and "height" 
static func make_shape(shape: Shape3D, half_width: float, height: float = 0, depth: float = 0)->Shape3D:
	if(shape is SphereShape3D):
		shape.set_radius(half_width)
		return shape
		
	elif (shape is BoxShape3D):
		var made_size: Vector3 = Vector3(half_width*2, height, depth)
		shape.set_size(made_size)
		return shape
		
	elif (shape is CapsuleShape3D):
		shape.set_radius(half_width)
		shape.set_height(height)
		return shape
		
	elif (shape is CylinderShape3D):
		shape.set_radius(half_width)
		shape.set_height(height)
		return shape

	else: 
		print_debug("shape used in make_shape() is unsupported, returned null")
		return null

static func shape_cast(myself: Node3D, space_state: PhysicsDirectSpaceState3D, shape: Shape3D, layer: int)->Dictionary:
	if(space_state == null):
		space_state = myself.get_world_3d().direct_space_state
	var query: PhysicsShapeQueryParameters3D = PhysicsShapeQueryParameters3D.new()
	var set_shape: Shape3D = shape
	query.set_collision_mask(layer); query.set_shape(shape); query.set_transform(myself.transform); query.set_margin(0.01)
	
	var result: Array[Dictionary] = space_state.intersect_shape(query, 1)
	if(result.size() > 0):
		return result[0]
	else: 
		return {}

#specific casts
static func sphere_cast(myself: Node3D, radius: float, layer: int)->Dictionary: # Inconsistent when using run physics seperate thread 
	var space_state: PhysicsDirectSpaceState3D = myself.get_world_3d().direct_space_state
	var query: PhysicsShapeQueryParameters3D = PhysicsShapeQueryParameters3D.new()
	var shape: Shape3D = SphereShape3D.new()
	shape.set_radius(radius)
	query.set_collision_mask(layer); query.set_shape(shape); query.set_transform(myself.transform); query.set_margin(0.01)
	
	var result: Array[Dictionary] = space_state.intersect_shape(query, 1)
	if(result.size() > 0):
		return result[0]
	else: 
		return {}

static func cylinder_cast(myself: Node3D, radius: float, height:float, layer: int)->Dictionary: # Inconsistent when using run physics seperate thread
	var space_state: PhysicsDirectSpaceState3D = myself.get_world_3d().direct_space_state
	var query: PhysicsShapeQueryParameters3D = PhysicsShapeQueryParameters3D.new()
	var shape: Shape3D = CylinderShape3D.new()
	shape.set_radius(radius)
	shape.set_height(height)
	query.set_collision_mask(layer); query.set_shape(shape); query.set_transform(myself.transform); query.set_margin(0.01)
	
	var result: Array[Dictionary] = space_state.intersect_shape(query, 1)
	if(result.size() > 0):
		return result[0]
	else: 
		return {}
