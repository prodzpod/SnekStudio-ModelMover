extends Node
var rotate := false
var current_vector := Vector3.ZERO
var dutch := 0.
func _physics_process(delta: float) -> void:
	current_vector.x = (1 if Input.is_key_pressed(KEY_RIGHT) else 0) - (1 if Input.is_key_pressed(KEY_LEFT) else 0)
	current_vector.y = (1 if Input.is_key_pressed(KEY_E) else 0) - (1 if Input.is_key_pressed(KEY_Q) else 0)
	current_vector.z = (1 if Input.is_key_pressed(KEY_DOWN) else 0) - (1 if Input.is_key_pressed(KEY_UP) else 0)
	rotate = Input.is_key_pressed(KEY_SHIFT)
	if ModelMover.instance.lock_camera: return
	var camera := get_viewport().get_camera_3d().get_parent()
	if rotate: 
		if current_vector.y > 0: dutch = 0
		else: dutch += ModelMover.instance.camera_speed * delta * current_vector.x
	else: 
		if Input.is_key_pressed(KEY_X): camera.global_position.x = 0
		if Input.is_key_pressed(KEY_Y): camera.global_position.y = 0
		if Input.is_key_pressed(KEY_Z): camera.global_position.z = 0
		camera.global_position += ModelMover.instance.camera_speed * delta * ((camera.global_transform.basis.x * current_vector.x) + (camera.global_transform.basis.y * current_vector.y) + (camera.global_transform.basis.z * current_vector.z))
func _process(delta: float) -> void:
	get_viewport().get_camera_3d().get_parent().rotation.z = dutch
