extends Node3D
## Main scene: builds the world, entities, UI, and wires the game loop.

var player: CharacterBody3D
var farm: Node3D
var chicken: Node3D
var villager: Node3D
var sky: Node3D
var ui: CanvasLayer
var touch: Control
var camera: Camera3D

var _barn_windows: Array[MeshInstance3D] = []
var _juice_nodes: Array[Dictionary] = []
var _juice_mesh: Mesh
var _game_started := false

func _ready() -> void:
	randomize()
	_add_world()
	_add_sky()
	_add_entities()
	_add_ui()
	_wire_signals()
	_juice_mesh = _make_juice_mesh()

	GameState.paused = true  # time stands still on the title screen
	player.set_physics_process(false)
	chicken.set_physics_process(false)
	villager.set_physics_process(false)

	if OS.get_cmdline_user_args().has("--self-test"):
		_self_test()
		return

	var has_save: bool = GameState.has_save()
	ui.show_title(has_save)

# ----------------------------------------------------------------- world ---
func _add_world() -> void:
	var world := WorldBuilder.build_world()
	add_child(world)
	for n in world.find_children("*", "MeshInstance3D", true, false):
		if n.name == "BarnWindow":
			_barn_windows.append(n)

func _add_sky() -> void:
	sky = Node3D.new()
	sky.name = "SkyCycle"
	sky.set_script(preload("res://scripts/sky_cycle.gd"))
	add_child(sky)

func _add_entities() -> void:
	farm = load("res://scenes/farm.tscn").instantiate()
	add_child(farm)
	farm.position = Vector3(0, 0, 0)

	chicken = load("res://scenes/chicken.tscn").instantiate()
	add_child(chicken)
	chicken.position = Vector3(2.5, 0, 2.0)

	villager = load("res://scenes/villager.tscn").instantiate()
	add_child(villager)
	villager.position = Vector3(0, 0, 15.0)

	player = load("res://scenes/player.tscn").instantiate()
	add_child(player)
	player.position = Vector3(0, 0, 10.0)
	player.add_to_group("player")
	camera = player.camera
	player.interactables = farm.get_interactables() + [chicken, villager]

func _add_ui() -> void:
	ui = CanvasLayer.new()
	ui.name = "UI"
	ui.set_script(preload("res://scripts/ui.gd"))
	add_child(ui)
	ui.camera = camera

	touch = Control.new()
	touch.name = "TouchControls"
	touch.set_script(preload("res://scripts/touch_controls.gd"))
	ui.add_child(touch)
	touch.setup()
	touch.joystick_moved.connect(player.set_touch_input)
	touch.camera_rotated.connect(player.rotate_camera)
	touch.action_pressed.connect(player.try_interact)

# --------------------------------------------------------------- signals ---
func _wire_signals() -> void:
	player.interactable_changed.connect(func(n): ui.set_prompt(n))
	farm.juice_requested.connect(_on_juice_requested)
	chicken.juice_requested.connect(_on_juice_requested)
	villager.dialog_requested.connect(ui.open_dialog)
	GameState.toast_requested.connect(ui.show_toast)
	sky.night_level_changed.connect(_on_night_level_changed)
	ui.new_game_requested.connect(_on_new_game)
	ui.continue_requested.connect(_on_continue)

func _on_night_level_changed(night: float) -> void:
	var glow: bool = night > 0.55
	for w in _barn_windows:
		var m: StandardMaterial3D = w.mesh.material
		m.emission_enabled = glow
		m.emission = Color(1.0, 0.8, 0.45)
		m.emission_energy_multiplier = 1.6 if glow else 0.0

func _on_new_game() -> void:
	GameState.new_game()
	_start_game()

func _on_continue() -> void:
	GameState.load_game()
	_start_game()

func _start_game() -> void:
	if _game_started:
		return
	_game_started = true
	GameState.paused = false
	player.set_physics_process(true)
	chicken.set_physics_process(true)
	villager.set_physics_process(true)
	farm.apply_saved_crops()
	ui.hide_title()
	ui.refresh_all()

# ----------------------------------------------------------------- juice ---
func _make_juice_mesh() -> Mesh:
	var sm := SphereMesh.new()
	sm.radius = 0.045
	sm.radial_segments = 8
	sm.rings = 6
	return sm

func _on_juice_requested(pos: Vector3, color: Color, text: String = "") -> void:
	_spawn_burst(pos, color)
	if text != "":
		ui.add_float(pos + Vector3(0, 0.6, 0), text, color)

func _spawn_burst(pos: Vector3, color: Color) -> void:
	var material := WorldBuilder.mat(color, 0.4)
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 0.6
	for i in 10:
		var mi := MeshInstance3D.new()
		mi.mesh = _juice_mesh
		mi.mesh.material = material
		mi.position = pos
		add_child(mi)
		var vel := Vector3(randf_range(-1.6, 1.6), randf_range(1.5, 3.4), randf_range(-1.6, 1.6))
		_juice_nodes.append({"node": mi, "vel": vel, "life": randf_range(0.35, 0.6)})

func _process(delta: float) -> void:
	if _juice_nodes.is_empty():
		return
	var i := _juice_nodes.size() - 1
	while i >= 0:
		var j: Dictionary = _juice_nodes[i]
		j["life"] = float(j["life"]) - delta
		if float(j["life"]) <= 0.0:
			j["node"].queue_free()
			_juice_nodes.remove_at(i)
		else:
			j["vel"] = (j["vel"] as Vector3) + Vector3(0, -9.8 * delta, 0)
			j["node"].position = (j["node"].position as Vector3) + (j["vel"] as Vector3) * delta
			j["node"].scale = Vector3.ONE * clampf(float(j["life"]) * 2.2, 0.1, 1.0)
		i -= 1

# -------------------------------------------------------------- self test ---
var _st := {"ok": true, "checks": 0, "fails": []}

func check(cond: bool, msg: String) -> void:
	_st["checks"] = int(_st["checks"]) + 1
	if not cond:
		_st["ok"] = false
		_st["fails"].append(msg)

func _self_test() -> void:
	_st = {"ok": true, "checks": 0, "fails": []}

	check(player != null, "player missing")
	check(farm != null, "farm missing")
	check(chicken != null, "chicken missing")
	check(villager != null, "villager missing")
	check(sky != null, "sky missing")
	check(ui != null, "ui missing")

	GameState.new_game()
	check(GameState.money == 25, "start money")
	check(GameState.seeds["wheat"] == 8, "start wheat seeds")

	check(GameState.plant_cell(0, "wheat"), "plant wheat")
	check(GameState.seeds["wheat"] == 7, "seed spent")
	check(GameState.plant_cell(1, "pumpkin"), "plant pumpkin")
	check(GameState.plant_cell(2, "tomato"), "plant tomato")
	check(not GameState.plant_cell(0, "tomato"), "double plant blocked")
	check(GameState.harvest_cell(2).is_empty(), "harvest before ready blocked")

	GameState.grow_crops(1000.0)
	check(GameState.is_ready(0), "wheat ready")
	check(GameState.is_ready(1), "pumpkin ready")
	check(GameState.is_ready(2), "tomato ready")
	var r: Dictionary = GameState.harvest_cell(0)
	check(r.get("type", "") == "wheat", "harvest wheat")
	check(GameState.produce["wheat"] == 1, "produce gained")
	check(GameState.crop_info(0).is_empty(), "cell cleared after harvest")
	check(GameState.harvest_cell(0).is_empty(), "double harvest blocked")

	var money_before: int = GameState.money
	check(GameState.buy("tomato"), "buy tomato")
	check(GameState.money == money_before - 12, "money spent")
	check(GameState.sell("wheat"), "sell wheat")
	check(GameState.money == money_before - 12 + 9, "money from sell")

	GameState.save_game()
	var day_saved: int = GameState.day
	GameState.day = 99
	GameState.load_game()
	check(GameState.day == day_saved, "save/load roundtrip")

	var day_before: int = GameState.day
	GameState.advance_time(GameState.SECONDS_PER_DAY * 1.1 * 24.0 / 24.0)
	check(GameState.day > day_before, "day advances")

	ui.refresh_all()
	if _st["ok"]:
		print("SELF-TEST PASS (%d checks)" % _st["checks"])
		get_tree().quit(0)
	else:
		for m in _st["fails"]:
			printerr("SELF-TEST FAIL: ", m)
		get_tree().quit(1)
