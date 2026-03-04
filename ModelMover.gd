class_name ModelMover extends Mod_Base
static var instance: ModelMover
func _enter_tree() -> void: instance = self

var transform_overrides = {}
var lock_camera := false
var camera_speed := 1.0
var initial_setting
func _ready() -> void:
	add_tracked_setting("camera_speed", "Camera Speed")
	_add_config_button("Face Camera", face_camera)
	_add_config_button("Face Camera (Local)", face_camera_local)
	add_tracked_setting("lock_camera", "Lock Transforms")
	_add_config_button("Copy Setting", copy_setting_to_clipboard)
	_add_config_button("Load Setting", load_setting_from_clipboard)
	_add_config_button("Save as Default", save_as_default)

func load_after(_settings_old : Dictionary, _settings_new : Dictionary):
	if initial_setting == null:
		initial_setting = _settings_new.initial_setting
		if initial_setting: load_setting(initial_setting)

func scene_init(): 
	add_area()

func save_before(_settings_current: Dictionary):
	_settings_current.initial_setting = initial_setting
	
func _process(delta: float) -> void:
	var module := get_parent().get_node_or_null("copyMultiplayer")
	if module != null: module.can_move_players = not lock_camera
	if lock_camera: %UI_Root.dragging_camera = false
	
func _add_config_button(text, fn):
	var button : Button = Button.new()
	button.text = text
	get_settings_window().add_child(button)
	button.pressed.connect(fn)

func face_camera():
	face_camera_local()
	$MultiplayerSupport.face_camera()

func face_camera_local():
	print_log(["Facing Camera"])
	var pos3 := get_viewport().get_camera_3d().global_position
	var pos2 := Vector2(pos3.x, pos3.z)
	var target3: Vector3 = get_model().global_position
	var target2 := Vector2(target3.x, target3.z)
	var rotation_to = -(PI / 2)-atan2(target2.y - pos2.y, target2.x - pos2.x)
	local_area.reorient_model(rotation_to)

var local_area: DesyncController
func add_area():
	print_log(["Adding Area Element"])
	var skeleton = get_skeleton()
	var head       := DesyncController._get_bone_position(get_skeleton(), "Head")
	var left_foot  := DesyncController._get_bone_position(get_skeleton(), "LeftFoot")
	var right_foot := DesyncController._get_bone_position(get_skeleton(), "RightFoot")
	var shoulder   := DesyncController._get_bone_position(get_skeleton(), "LeftUpperArm")
	var avg_foot   := (left_foot + right_foot) / 2
	local_area = DesyncController.new()
	local_area.name = "MainModelDraggable"
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.height = (head.y - avg_foot.y) * 1.5
	capsule.radius = shoulder.x            * 1.75
	shape.shape = capsule
	local_area.add_child(shape)
	get_model().add_child(local_area)
	local_area.position = Vector3(0, 1, 0)
	local_area.adjust_shape_position()

func copy_setting_to_clipboard():
	var ret = copy_setting()
	DisplayServer.clipboard_set(JSON.stringify(ret))
	print_log(["Copied to Clipboard!"])

func copy_setting() -> Dictionary:
	var ret = {}
	var lp = local_area.global_position
	ret.local = { "position": [lp.x, lp.y, lp.z], "rotation": get_skeleton().global_rotation.y }
	var camera = get_viewport().get_camera_3d().get_parent()
	var cp = camera.global_position
	var cr = camera.rotation
	ret.camera = { "position": [cp.x, cp.y, cp.z], "rotation": [cr.x, cr.y, cr.z] }
	ret.remote = $MultiplayerSupport.copy_transforms()
	return ret

func load_setting_from_clipboard():
	var clip = DisplayServer.clipboard_get()
	var setting = JSON.parse_string(clip)
	if setting != null: 
		load_setting(setting)
		print_log(["Loaded from Clipboard!"])
	else: print_log(["Clipboard is not a valid settings file!"])

func load_setting(setting: Dictionary):
	local_area.move_model(Vector3(setting.local.position[0], setting.local.position[1], setting.local.position[2]) - local_area.global_position)
	local_area.reorient_model(setting.local.rotation)
	var camera = get_viewport().get_camera_3d().get_parent()
	camera.global_position = Vector3(setting.camera.position[0], setting.camera.position[1], setting.camera.position[2])
	camera.rotation = Vector3(setting.camera.rotation[0], setting.camera.rotation[1], setting.camera.rotation[2])
	$MultiplayerSupport.load_transforms(setting.remote)

func save_as_default():
	initial_setting = copy_setting()
	save_settings()
	print_log(["Saved as Default Setting!"])
	
