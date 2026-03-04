extends Node
func _ready() -> void:
	if not get_parent().get_parent().has_node("copyMultiplayer"): return
	$"../../copyMultiplayer".child_entered_tree.connect(func(x: Node):
		x.ready.connect(func(): if x is Area3D: on_joined(x)))

var models := {}
var models_all := []
func on_joined(controller: Area3D):
	models_all.append(controller)

var s1 := 1.
func _process(delta: float) -> void:
	s1 -= delta
	if s1 <= 0:
		s1 += 1
		validate()
		for controller in models_all:
			if controller.nickname:
				models[controller.nickname] = controller
				if ModelMover.instance.initial_setting and controller.nickname in ModelMover.instance.initial_setting.remote:
					var setting = ModelMover.instance.initial_setting.remote[controller.nickname]
					controller.global_position = Vector3(setting.position[0], setting.position[1], setting.position[2])
					controller.rotation.y = setting.rotation

func face_camera():
	validate()
	var pos3 := get_viewport().get_camera_3d().global_position
	var pos2 := Vector2(pos3.x, pos3.z)
	for model in models_all: 
		var target3: Vector3 = model.global_position
		var target2 := Vector2(target3.x, target3.z)
		model.rotation.y = -(PI / 2)-atan2(target2.y - pos2.y, target2.x - pos2.x)

func validate():
	models_all = models_all.filter(is_instance_valid)
	for k in models.keys(): if models[k] not in models_all: models.erase(k)

func copy_transforms() -> Dictionary:
	validate()
	var ret = {}
	for k in models:
		var pos = models[k].global_position
		ret[k] = { "position": [pos.x, pos.y, pos.z], "rotation": models[k].rotation.y }
	return ret

func load_transforms(data: Dictionary):
	validate()
	for k in data:
		if k not in models: continue
		models[k].global_position = Vector3(data[k].position[0], data[k].position[1], data[k].position[2])
		models[k].rotation.y = data[k].rotation
