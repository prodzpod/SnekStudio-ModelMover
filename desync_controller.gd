class_name DesyncController extends Area3D

# lifted from copymultiplayer
# modified handle_dragging so you can depth actually (idk how to pr a gitea please help)

func adjust_shape_position():
	var shape := get_child(0) as CollisionShape3D
	if shape == null: return
	var skeleton = ModelMover.instance.get_skeleton()
	var head       := _get_bone_position(skeleton, "Head")
	var left_foot  := _get_bone_position(skeleton, "LeftFoot")
	var right_foot := _get_bone_position(skeleton, "RightFoot")
	var avg_foot   := (left_foot + right_foot) / 2
	shape.global_position = global_position - Vector3(0, (shape.shape as CapsuleShape3D).height / 2, 0) + (head + avg_foot) / 2

static func _get_bone_position(skeleton: Skeleton3D, bone_name: String) -> Vector3:
	var idx  := skeleton.find_bone(bone_name)
	var pose := skeleton.get_bone_global_pose(idx)
	return pose.origin

var is_dragging := false
var drag_current: Vector3

func _input_event(
	_camera: Node, event: InputEvent,
	pos: Vector3, _normal: Vector3, _idx: int
) -> void:
	if (not ModelMover.instance.lock_camera
			&& event is InputEventMouseButton
			&& event.button_index == MOUSE_BUTTON_LEFT
			&& event.pressed):
		is_dragging  = true
		drag_current = pos

func _unhandled_input(event: InputEvent) -> void:
	if (is_dragging
			&& event is InputEventMouseButton
			&& event.button_index == MOUSE_BUTTON_LEFT
			&& not event.pressed):
		is_dragging = false
		get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	handle_dragging()
	adjust_shape_position()

func handle_dragging() -> void:
	if not is_dragging: return
	var camera := get_viewport().get_camera_3d()
	var mouse  := get_viewport().get_mouse_position()
	var origin := camera.project_ray_origin(mouse)
	var dir    := camera.project_ray_normal(mouse)
	var dirz := camera.global_basis.tdotz(dir)
	if dirz == 0: return
	var distance := camera.global_basis.tdotz(drag_current - origin) / dirz
	var target   := origin + dir * distance
	move_model(target - drag_current)
	drag_current = target

func reorient_model(rotation_offset: float):
	for child in ModelMover.instance.get_skeleton().get_children():
		if child is MeshInstance3D: child.rotation.y = rotation_offset

func move_model(offset: Vector3):
	var angle = ModelMover.instance.get_skeleton().global_rotation.y
	for child in ModelMover.instance.get_skeleton().get_children():
		if child is MeshInstance3D: child.position += offset.rotated(Vector3(0, 1, 0), -angle)
	position += offset
	
