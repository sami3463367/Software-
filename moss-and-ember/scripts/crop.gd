extends Node3D
## One farm cell: grows a crop through 4 visual stages, plant/harvest on interact.

signal juice(color: Color, text: String)

var cell_id: int = -1

var _root: Node3D
var _stage := -1
var _ready_marker: MeshInstance3D
var _marker_t := 0.0
var _syncing := false

const WHEAT_GOLD := Color(0.93, 0.78, 0.3)
const TOMATO_RED := Color(0.86, 0.25, 0.2)
const PUMPKIN_ORANGE := Color(0.92, 0.5, 0.12)
const GREEN := Color(0.35, 0.68, 0.28)
const GREEN_DARK := Color(0.28, 0.55, 0.22)


func _ready() -> void:
	_root = Node3D.new()
	add_child(_root)
	_ready_marker = WorldBuilder.sphere(0.09, _marker_material(), 1.0)
	_ready_marker.visible = false
	add_child(_ready_marker)

func _marker_material() -> StandardMaterial3D:
	var m := WorldBuilder.mat(Color(1.0, 0.85, 0.2), 0.3)
	m.emission_enabled = true
	m.emission = Color(1.0, 0.8, 0.15)
	m.emission_energy_multiplier = 1.5
	return m

func sync_from_state() -> void:
	_syncing = true
	_stage = -1
	_process(0.0)
	_syncing = false

func _process(delta: float) -> void:
	var info: Dictionary = GameState.crop_info(cell_id)
	if info.is_empty():
		if _stage != -1:
			_stage = -1
			_rebuild()
		_ready_marker.visible = false
		return
	var p: float = float(info["progress"])
	var type_: String = info["type"]
	var stage: int
	if p >= 1.0:
		stage = 3
	elif p >= 0.66:
		stage = 2
	elif p >= 0.3:
		stage = 1
	else:
		stage = 0
	if stage != _stage:
		_stage = stage
		_rebuild(type_)
		if stage == 1 and not _syncing:
			AudioBus.play_sfx("pop", -14.0)
	# ready marker bob
	if p >= 1.0:
		_ready_marker.visible = true
		_marker_t += delta
		_ready_marker.position = Vector3(0, 0.85 + sin(_marker_t * 3.0) * 0.08, 0)
	else:
		_ready_marker.visible = false

# -------------------------------------------------------------- visuals ---
func _rebuild(type_: String = "") -> void:
	for child in _root.get_children():
		child.queue_free()
	if type_ == "" and _stage >= 0:
		type_ = str(GameState.crop_info(cell_id).get("type", ""))
	var stem := WorldBuilder.mat(GREEN, 0.8)
	var stem_dark := WorldBuilder.mat(GREEN_DARK, 0.8)
	match _stage:
		-1:
			pass  # empty tilled row (the farm draws it)
		0:
			# seed mound
			var mound := WorldBuilder.sphere(0.09,
				WorldBuilder.mat(Color(0.33, 0.22, 0.13), 1.0), 0.5)
			mound.position = Vector3(0, 0.02, 0)
			_root.add_child(mound)
			var seed := WorldBuilder.sphere(0.03,
				WorldBuilder.mat(Color(0.9, 0.82, 0.55), 0.6), 0.7)
			seed.position = Vector3(0, 0.06, 0)
			_root.add_child(seed)
		1:
			var sprout := WorldBuilder.cylinder(0.015, 0.03, 0.16, stem)
			sprout.position = Vector3(0, 0.08, 0)
			_root.add_child(sprout)
			for s in [-1.0, 1.0]:
				var leaf := WorldBuilder.sphere(0.05, stem_dark, 0.5)
				leaf.position = Vector3(s * 0.05, 0.14, 0)
				leaf.rotation.z = s * 0.9
				_root.add_child(leaf)
		2:
			var stalk := WorldBuilder.cylinder(0.02, 0.035, 0.42, stem)
			stalk.position = Vector3(0, 0.21, 0)
			_root.add_child(stalk)
			for i in 4:
				var leaf := WorldBuilder.sphere(0.07, stem_dark, 0.45)
				leaf.position = Vector3(
					cos(i * 1.6) * 0.08, 0.14 + i * 0.09, sin(i * 1.6) * 0.08)
				leaf.rotation.y = i * 1.6
				_root.add_child(leaf)
		3:
			_grown(type_, stem, stem_dark)

func _grown(type_: String, stem: Material, stem_dark: Material) -> void:
	match type_:
		"wheat":
			for i in 3:
				var stalk := WorldBuilder.cylinder(0.015, 0.02, 0.55, stem)
				stalk.position = Vector3(cos(i * 2.1) * 0.09, 0.27, sin(i * 2.1) * 0.09)
				stalk.rotation.z = cos(i * 2.1) * 0.12
				_root.add_child(stalk)
			for i in 3:
				var head := WorldBuilder.capsule(0.045, 0.16,
					WorldBuilder.mat(WHEAT_GOLD, 0.7))
				head.position = Vector3(
					cos(i * 2.1) * 0.09, 0.6, sin(i * 2.1) * 0.09)
				head.rotation.z = cos(i * 2.1) * 0.12
				_root.add_child(head)
		"tomato":
			var bush := WorldBuilder.sphere(0.24, stem_dark, 0.9)
			bush.position = Vector3(0, 0.24, 0)
			_root.add_child(bush)
			var bush2 := WorldBuilder.sphere(0.17, stem, 0.9)
			bush2.position = Vector3(0.08, 0.36, 0.05)
			_root.add_child(bush2)
			for i in 5:
				var tomato := WorldBuilder.sphere(0.055,
					WorldBuilder.mat(TOMATO_RED, 0.35), 0.9)
				var a := i * 2.3
				tomato.position = Vector3(cos(a) * 0.18, 0.2 + (i % 3) * 0.09, sin(a) * 0.18)
				_root.add_child(tomato)
		"pumpkin":
			var vine := WorldBuilder.sphere(0.16, stem_dark, 0.4)
			vine.position = Vector3(0, 0.08, 0)
			_root.add_child(vine)
			for i in 4:
				var leaf := WorldBuilder.sphere(0.07, stem, 0.4)
				leaf.position = Vector3(cos(i * 1.7) * 0.14, 0.07, sin(i * 1.7) * 0.14)
				_root.add_child(leaf)
			var pumpkin := WorldBuilder.sphere(0.17,
				WorldBuilder.mat(PUMPKIN_ORANGE, 0.5), 0.75)
			pumpkin.position = Vector3(0, 0.1, 0)
			_root.add_child(pumpkin)
			var neck := WorldBuilder.box(Vector3(0.05, 0.1, 0.05), stem_dark)
			neck.position = Vector3(0, 0.24, 0)
			_root.add_child(neck)
		_:
			pass

# ----------------------------------------------------------- interaction ---
func is_interactable() -> bool:
	return true

func interact_label() -> String:
	var info: Dictionary = GameState.crop_info(cell_id)
	if info.is_empty():
		if GameState.seeds.get(GameState.selected_seed, 0) > 0:
			return "Plant %s seed" % GameState.selected_seed
		return "No %s seeds — buy some at the stall" % GameState.selected_seed
	var p: float = float(info["progress"])
	if p >= 1.0:
		return "Harvest %s" % info["type"]
	return "Growing… %d%%" % int(p * 100.0)

func do_interact() -> void:
	var info: Dictionary = GameState.crop_info(cell_id)
	if info.is_empty():
		if GameState.plant_cell(cell_id, GameState.selected_seed):
			AudioBus.play_sfx("plant")
			juice.emit(Color(0.55, 0.4, 0.25), "")
			sync_from_state()
		else:
			AudioBus.play_sfx("error")
		return
	var p: float = float(info["progress"])
	if p >= 1.0:
		var result: Dictionary = GameState.harvest_cell(cell_id)
		if not result.is_empty():
			var color: Color = WHEAT_GOLD
			if result["type"] == "tomato":
				color = TOMATO_RED
			elif result["type"] == "pumpkin":
				color = PUMPKIN_ORANGE
			AudioBus.play_sfx("harvest")
			juice.emit(color, "+%dg" % result["value"])
			sync_from_state()
	else:
		AudioBus.play_sfx("pop", -10.0)
