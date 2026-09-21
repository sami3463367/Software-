class_name WorldBuilder
extends RefCounted
## Builds the farm world from primitives (bright cartoon look, Style A).

# Palette
const GRASS := Color(0.45, 0.72, 0.32)
const GRASS_DARK := Color(0.36, 0.62, 0.26)
const DIRT := Color(0.47, 0.33, 0.2)
const DIRT_DARK := Color(0.4, 0.27, 0.16)
const WOOD := Color(0.62, 0.45, 0.27)
const WOOD_DARK := Color(0.5, 0.35, 0.2)
const BARN_RED := Color(0.78, 0.33, 0.25)
const BARN_ROOF := Color(0.55, 0.24, 0.18)
const WATER := Color(0.3, 0.62, 0.85)
const TRUNK := Color(0.5, 0.35, 0.22)
const LEAF := Color(0.32, 0.66, 0.3)
const LEAF_2 := Color(0.4, 0.74, 0.34)
const STONE := Color(0.62, 0.63, 0.6)
const PATH := Color(0.72, 0.62, 0.45)

static func mat(color: Color, roughness: float = 0.9, metallic: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = roughness
	m.metallic = metallic
	return m

static func box(size: Vector3, material: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	bm.material = material
	mi.mesh = bm
	return mi

static func sphere(radius: float, material: Material, squash: float = 1.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = radius
	sm.height = radius * 2.0 * squash
	sm.radial_segments = 20
	sm.rings = 10
	sm.material = material
	mi.mesh = sm
	return mi

static func cylinder(r_top: float, r_bottom: float, height: float, material: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = r_top
	cm.bottom_radius = r_bottom
	cm.height = height
	cm.radial_segments = 14
	cm.material = material
	mi.mesh = cm
	return mi

static func capsule(r: float, h: float, material: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CapsuleMesh.new()
	cm.radius = r
	cm.height = h
	cm.material = material
	mi.mesh = cm
	return mi

static func add_static_collision(node: Node3D, shape: Shape3D) -> void:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var cs := CollisionShape3D.new()
	cs.shape = shape
	body.add_child(cs)
	node.add_child(body)

# ---------------------------------------------------------------- world ---
static func build_world() -> Node3D:
	var root := Node3D.new()
	root.name = "World"

	# Ground
	var ground_mesh := PlaneMesh.new()
	ground_mesh.size = Vector2(90, 90)
	var ground := MeshInstance3D.new()
	ground.mesh = ground_mesh
	ground.mesh.material = mat(GRASS)
	root.add_child(ground)
	var ground_body := StaticBody3D.new()
	var ground_cs := CollisionShape3D.new()
	var ground_shape := BoxShape3D.new()
	ground_shape.size = Vector3(90, 1, 90)
	ground_cs.shape = ground_shape
	ground_cs.position = Vector3(0, -0.5, 0)
	ground_body.add_child(ground_cs)
	root.add_child(ground_body)

	# Rolling hills (walkable, decorative)
	root.add_child(_hill(Vector3(-24, 0, -16), 9.0, 3.0))
	root.add_child(_hill(Vector3(26, 0, 20), 11.0, 3.6))
	root.add_child(_hill(Vector3(22, 0, -26), 8.0, 2.6))

	# Pond
	root.add_child(_pond(Vector3(12, 0, -8)))

	# Barn
	root.add_child(_barn(Vector3(-11, 0, -5)))

	# Market stall (villager stands here)
	root.add_child(_stall(Vector3(0, 0, 16)))

	# Path from spawn (0,0,10) to the stall
	var path := box(Vector3(1.8, 0.04, 6.4), mat(PATH))
	path.position = Vector3(0, 0.02, 13.2)
	root.add_child(path)
	var path2 := box(Vector3(9.0, 0.04, 1.8), mat(PATH))
	path2.position = Vector3(-4.5, 0.02, 10.5)
	root.add_child(path2)

	# Trees around the edges
	var tree_spots := [
		Vector3(-16, 0, 8), Vector3(-14, 0, -12), Vector3(16, 0, 4),
		Vector3(18, 0, 10), Vector3(-20, 0, -4), Vector3(8, 0, -18),
		Vector3(-6, 0, 22), Vector3(24, 0, -4), Vector3(-26, 0, 14),
		Vector3(14, 0, 24),
	]
	for spot in tree_spots:
		root.add_child(_tree(spot))

	# Flowers
	var flower_colors := [Color(0.95, 0.55, 0.65), Color(0.98, 0.85, 0.4),
			Color(0.85, 0.6, 0.95), Color(0.98, 0.75, 0.35)]
	var rng := RandomNumberGenerator.new()
	rng.seed = 1234
	for i in 26:
		var pos := Vector3(rng.randf_range(-30, 30), 0, rng.randf_range(-30, 30))
		if absf(pos.x) < 8 and pos.z > -4 and pos.z < 12:
			continue  # keep the farm yard clear
		if Vector2(pos.x - 12, pos.z + 8).length() < 4.5:
			continue  # keep the pond clear
		root.add_child(_flower(pos, flower_colors[i % flower_colors.size()]))

	# Rocks
	for spot in [Vector3(-8, 0, 14), Vector3(6, 0, -14), Vector3(-22, 0, 2),
			Vector3(10, 0, 12), Vector3(2, 0, 26)]:
		var rock := sphere(rng.randf_range(0.3, 0.7), mat(STONE), 0.6)
		rock.position = spot + Vector3(0, 0.15, 0)
		root.add_child(rock)

	return root

# -------------------------------------------------------------- pieces ---
static func _hill(pos: Vector3, radius: float, height: float) -> Node3D:
	var hill := sphere(radius, mat(GRASS_DARK), height / radius)
	hill.position = pos
	var root := Node3D.new()
	root.add_child(hill)
	add_static_collision(root, _hill_shape(pos, radius, height))
	return root

static func _hill_shape(pos: Vector3, radius: float, height: float) -> Shape3D:
	# A box under the hill top so you can't walk through the side cheaply.
	var shape := BoxShape3D.new()
	shape.size = Vector3(radius * 1.4, height * 0.9, radius * 1.4)
	# Offset the collision body is handled by caller position.
	return shape

static func _pond(pos: Vector3) -> Node3D:
	var root := Node3D.new()
	var bank := cylinder(3.6, 3.6, 0.12, mat(GRASS_DARK))
	bank.position = Vector3(0, 0.02, 0)
	root.add_child(bank)
	var water := cylinder(3.2, 3.2, 0.06, mat(WATER, 0.25))
	water.position = Vector3(0, 0.06, 0)
	root.add_child(water)
	# lily pads
	for i in 3:
		var pad := cylinder(0.28, 0.28, 0.03, mat(LEAF_2, 0.6))
		var a := i * 2.1
		pad.position = Vector3(cos(a) * 1.6, 0.1, sin(a) * 1.4)
		root.add_child(pad)
	root.position = pos
	return root

static func _barn(pos: Vector3) -> Node3D:
	var root := Node3D.new()
	var walls := box(Vector3(6.0, 3.4, 4.4), mat(BARN_RED))
	walls.position = Vector3(0, 1.7, 0)
	root.add_child(walls)
	# roof: two slanted panels
	for s in [-1.0, 1.0]:
		var panel := box(Vector3(3.9, 0.14, 5.0), mat(BARN_ROOF))
		panel.position = Vector3(s * 0.95, 3.85, 0)
		panel.rotation.z = s * 0.62
		root.add_child(panel)
	# gable fill
	var gable := box(Vector3(0.1, 1.4, 4.4), mat(BARN_RED))
	gable.position = Vector3(2.0, 3.0, 0)
	root.add_child(gable)
	var gable2 := box(Vector3(0.1, 1.4, 4.4), mat(BARN_RED))
	gable2.position = Vector3(-2.0, 3.0, 0)
	root.add_child(gable2)
	# door
	var door := box(Vector3(1.3, 2.2, 0.1), mat(WOOD_DARK))
	door.position = Vector3(0, 1.1, 2.21)
	root.add_child(door)
	# glowing window (toggled at night)
	var window := box(Vector3(0.9, 0.9, 0.1), mat(Color(1.0, 0.85, 0.5)))
	window.position = Vector3(-1.5, 2.0, 2.21)
	window.name = "BarnWindow"
	root.add_child(window)
	root.add_child(_window_frame(window.position))
	# collision
	var shape := BoxShape3D.new()
	shape.size = Vector3(6.2, 4.2, 4.6)
	var body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	cs.shape = shape
	cs.position = Vector3(0, 2.1, 0)
	body.add_child(cs)
	root.add_child(body)
	root.position = pos
	return root

static func _window_frame(pos: Vector3) -> Node3D:
	var frame := box(Vector3(1.1, 1.1, 0.08), mat(WOOD_DARK, 0.8))
	frame.position = pos + Vector3(0, 0, -0.02)
	return frame

static func _stall(pos: Vector3) -> Node3D:
	var root := Node3D.new()
	# counter
	var counter := box(Vector3(2.6, 0.9, 1.1), mat(WOOD))
	counter.position = Vector3(0, 0.45, 0)
	root.add_child(counter)
	var counter_top := box(Vector3(2.9, 0.08, 1.4), mat(WOOD_DARK))
	counter_top.position = Vector3(0, 0.94, 0)
	root.add_child(counter_top)
	# posts
	for x in [-1.35, 1.35]:
		var post := cylinder(0.07, 0.07, 2.6, mat(WOOD_DARK))
		post.position = Vector3(x, 1.3, 0)
		root.add_child(post)
	# striped canopy (alternating slats for a cheap stripe effect)
	for i in 7:
		var slat := box(Vector3(0.42, 0.06, 1.7), mat(
			Color(0.95, 0.92, 0.85) if i % 2 == 0 else Color(0.85, 0.4, 0.32)))
		slat.position = Vector3(-1.26 + i * 0.42, 2.65, 0)
		slat.rotation.z = 0.0
	root.add_child(_stall_roof_bar())
	# goods on the counter: a basket of fruit
	var basket := cylinder(0.3, 0.22, 0.3, mat(WOOD, 0.7))
	basket.position = Vector3(0.8, 1.15, 0.2)
	root.add_child(basket)
	for i in 5:
		var fruit := sphere(0.09, mat([Color(0.9, 0.3, 0.25), Color(0.95, 0.7, 0.2)][i % 2]), 0.85)
		fruit.position = Vector3(0.8 + cos(i * 2.4) * 0.14, 1.3, 0.2 + sin(i * 2.4) * 0.14)
		root.add_child(fruit)
	# collision
	var shape := BoxShape3D.new()
	shape.size = Vector3(2.7, 1.0, 1.2)
	var body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	cs.shape = shape
	cs.position = Vector3(0, 0.5, 0)
	body.add_child(cs)
	root.add_child(body)
	root.position = pos
	return root

static func _stall_roof_bar() -> Node3D:
	var bar := box(Vector3(2.9, 0.1, 0.1), mat(WOOD_DARK))
	bar.position = Vector3(0, 2.65, 0.8)
	return bar

static func _tree(pos: Vector3) -> Node3D:
	var root := Node3D.new()
	var trunk := cylinder(0.14, 0.2, 1.5, mat(TRUNK))
	trunk.position = Vector3(0, 0.75, 0)
	root.add_child(trunk)
	var canopy1 := sphere(1.15, mat(LEAF), 0.85)
	canopy1.position = Vector3(0, 2.2, 0)
	root.add_child(canopy1)
	var canopy2 := sphere(0.8, mat(LEAF_2), 0.9)
	canopy2.position = Vector3(0.5, 2.8, 0.3)
	root.add_child(canopy2)
	var canopy3 := sphere(0.7, mat(LEAF_2), 0.9)
	canopy3.position = Vector3(-0.5, 2.7, -0.2)
	root.add_child(canopy3)
	# collision (just the trunk)
	var shape := CylinderShape3D.new()
	shape.radius = 0.35
	shape.height = 1.6
	var body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	cs.shape = shape
	cs.position = Vector3(0, 0.8, 0)
	body.add_child(cs)
	root.add_child(body)
	root.position = pos
	return root

static func _flower(pos: Vector3, color: Color) -> Node3D:
	var root := Node3D.new()
	var stem := cylinder(0.02, 0.03, 0.28, mat(LEAF, 0.7))
	stem.position = Vector3(0, 0.14, 0)
	root.add_child(stem)
	var bloom := sphere(0.07, mat(color, 0.5), 0.8)
	bloom.position = Vector3(0, 0.3, 0)
	root.add_child(bloom)
	root.position = pos
	return root
