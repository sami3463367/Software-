extends Node3D
## The farm: 3 plots x 4 cells. Owns the crop nodes and routes juice.

signal juice_requested(pos: Vector3, color: Color, text: String)

const PLOTS := 3
const CELLS_PER_PLOT := 4
const CELL_GAP := 1.2
const PLOT_GAP := 2.6

var cells: Array[Node3D] = []
var _cell_positions: Array[Vector3] = []


func _ready() -> void:
	_build_plots()

func _cell_world_pos(plot: int, cell: int) -> Vector3:
	var z: float = -1.0 + plot * PLOT_GAP
	var x: float = (cell - (CELLS_PER_PLOT - 1) / 2.0) * CELL_GAP
	return Vector3(x, 0, z)

func _build_plots() -> void:
	var wood := WorldBuilder.mat(WorldBuilder.WOOD, 0.85)
	var wood_dark := WorldBuilder.mat(WorldBuilder.WOOD_DARK, 0.85)
	var dirt := WorldBuilder.mat(WorldBuilder.DIRT, 1.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	for plot in PLOTS:
		var z: float = -1.0 + plot * PLOT_GAP
		# dirt bed
		var dirt_mesh := WorldBuilder.box(
			Vector3(CELLS_PER_PLOT * CELL_GAP + 0.3, 0.14, 1.5), dirt)
		dirt_mesh.position = Vector3(0, 0.09, z)
		add_child(dirt_mesh)
		# wooden frame
		var frame := WorldBuilder.box(
			Vector3(CELLS_PER_PLOT * CELL_GAP + 0.5, 0.2, 1.7), wood_dark)
		frame.position = Vector3(0, 0.07, z)
		add_child(frame)
		# tilled rows (subtle darker strips per cell)
		for cell in CELLS_PER_PLOT:
			var row := WorldBuilder.box(Vector3(CELL_GAP - 0.15, 0.03, 1.1),
				WorldBuilder.mat(Color(0.38, 0.26, 0.15), 1.0))
			var pos := _cell_world_pos(plot, cell)
			row.position = Vector3(pos.x, 0.17, pos.z)
			add_child(row)
	# NOTE: no collision on the beds — Godot 4 CharacterBody3D has no step
	# height, so the player simply walks over them (beds are only ~15 cm).

	# crop nodes (one per cell)
	var crop_scene := load("res://scenes/crop.tscn")
	var id := 0
	for plot in PLOTS:
		for cell in CELLS_PER_PLOT:
			var c: Node3D = crop_scene.instantiate()
			c.position = _cell_world_pos(plot, cell) + Vector3(0, 0.16, 0)
			add_child(c)
			c.cell_id = id
			c.juice.connect(_on_cell_juice.bind(id))
			cells.append(c)
			id += 1

func _on_cell_juice(color: Color, text: String, id: int) -> void:
	juice_requested.emit(cells[id].global_position + Vector3(0, 0.3, 0), color, text)

func get_interactables() -> Array:
	return cells

func apply_saved_crops() -> void:
	for c in cells:
		c.sync_from_state()
