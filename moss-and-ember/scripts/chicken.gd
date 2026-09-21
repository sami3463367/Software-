extends Node3D
## A farm chicken: idle, peck, wander, flee, and pettable.

signal juice_requested(pos: Vector3, color: Color, text: String)

const CENTER := Vector3(0, 0, 1.5)
const AREA_X := 5.5
const AREA_Z := 4.5

var _state := "idle"
var _state_t := 1.0
var _target := Vector3.ZERO
var _body_root: Node3D
var _head: Node3D
var _t := 0.0
var _hop := 0.0


func _ready() -> void:
	_build()
	_target = global_position

func _build() -> void:
	_body_root = Node3D.new()
	add_child(_body_root)
	var white := WorldBuilder.mat(Color(0.97, 0.96, 0.92), 0.8)
	var red := WorldBuilder.mat(Color(0.85, 0.25, 0.2), 0.5)
	var yellow := WorldBuilder.mat(Color(0.95, 0.75, 0.2), 0.5)
	var body := WorldBuilder.sphere(0.2, white, 0.9)
	body.position = Vector3(0, 0.32, 0)
	_body_root.add_child(body)
	var tail := WorldBuilder.sphere(0.09, white, 0.7)
	tail.position = Vector3(0, 0.4, -0.18)
	tail.rotation.x = 0.7
	_body_root.add_child(tail)
	_head = Node3D.new()
	_head.position = Vector3(0, 0.45, 0.14)
	_body_root.add_child(_head)
	var skull := WorldBuilder.sphere(0.1, white, 0.9)
	skull.position = Vector3(0, 0.06, 0.05)
	_head.add_child(skull)
	var beak := WorldBuilder.cylinder(0.03, 0.015, 0.09, yellow)
	beak.position = Vector3(0, 0.04, 0.16)
	beak.rotation.x = PI / 2.0
	_head.add_child(beak)
	var comb := WorldBuilder.box(Vector3(0.04, 0.07, 0.05), red)
	comb.position = Vector3(0, 0.16, 0.03)
	_head.add_child(comb)
	for s in [-1.0, 1.0]:
		var wattle := WorldBuilder.sphere(0.03, red, 1.2)
		wattle.position = Vector3(s * 0.04, -0.02, 0.12)
		_head.add_child(wattle)
	for s in [-1.0, 1.0]:
		var foot := WorldBuilder.cylinder(0.02, 0.02, 0.14, yellow)
		foot.position = Vector3(s * 0.08, 0.06, 0)
		_body_root.add_child(foot)

func _physics_process(delta: float) -> void:
	_t += delta
	_state_t -= delta
	# hop decay
	if _hop > 0.0:
		_hop = maxf(0.0, _hop - delta * 2.2)
	_body_root.position.y = sin(_t * 10.0) * 0.015 + _hop * 0.25 * sin(_hop * PI)

	var player := get_tree().get_first_node_in_group("player")
	var player_pos := Vector3.ZERO
	if player:
		player_pos = player.global_position
	var d_player: float = global_position.distance_to(player_pos)

	# flee when the player gets close
	if _state != "flee" and player != null and d_player < 1.4:
		_state = "flee"
		_state_t = 1.0
		_target = global_position + (global_position - player_pos).normalized() * 2.5
		AudioBus.play_sfx("cluck")

	match _state:
		"idle":
			# gentle waddle in place
			_head.rotation.x = sin(_t * 2.0) * 0.1
			if _state_t <= 0.0:
				if randf() < 0.45:
					_state = "peck"
					_state_t = randf_range(0.7, 1.4)
				else:
					_state = "wander"
					_state_t = 4.0
					_target = _random_spot()
		"peck":
			_head.rotation.x = 0.7 + sin(_t * 9.0) * 0.25
			if _state_t <= 0.0:
				_state = "idle"
				_state_t = randf_range(1.0, 3.0)
		"wander":
			var dir := _target - global_position
			dir.y = 0.0
			if dir.length() > 0.15:
				dir = dir.normalized()
				global_position += dir * 0.8 * delta
				_face(dir)
			else:
				_state = "idle"
				_state_t = randf_range(1.0, 3.0)
			_head.rotation.x = sin(_t * 6.0) * 0.15
		"flee":
			var dir := _target - global_position
			dir.y = 0.0
			if dir.length() > 0.1 or _state_t > 0.0:
				if dir.length() > 0.05:
					global_position += dir.normalized() * 2.4 * delta
					_face(dir)
			if _state_t <= 0.0:
				_state = "idle"
				_state_t = randf_range(2.0, 4.0)
			_head.rotation.x = 0.2
	# keep inside the yard
	global_position.x = clampf(global_position.x, -AREA_X, AREA_X)
	global_position.z = clampf(global_position.z, CENTER.z - AREA_Z, CENTER.z + AREA_Z)

func _random_spot() -> Vector3:
	return Vector3(
		randf_range(-AREA_X + 0.5, AREA_X - 0.5), 0,
		CENTER.z + randf_range(-AREA_Z + 0.5, AREA_Z - 0.5))

func _face(dir: Vector3) -> void:
	var target_yaw := atan2(dir.x, dir.z)
	_body_root.rotation.y = lerp_angle(_body_root.rotation.y, target_yaw, 0.2)

# ----------------------------------------------------------- interaction ---
func is_interactable() -> bool:
	return true

func interact_label() -> String:
	return "Pet the chicken"

func do_interact() -> void:
	AudioBus.play_sfx("cluck")
	AudioBus.play_sfx("pet")
	_hop = 1.0
	_state = "idle"
	_state_t = 2.0
	juice_requested.emit(global_position + Vector3(0, 0.5, 0),
		Color(0.95, 0.55, 0.7), "♥")
