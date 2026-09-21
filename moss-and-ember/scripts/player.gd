extends CharacterBody3D
## Third-person farmer: keyboard + mouse + touch, orbit camera, interaction.

const SPEED := 3.4
const SPRINT_SPEED := 5.4
const ACCEL := 12.0
const GRAVITY := 22.0
const CAMERA_DIST := 6.2
const PITCH_MIN := deg_to_rad(-58.0)
const PITCH_MAX := deg_to_rad(-10.0)
const INTERACT_RANGE := 2.6
const WORLD_LIMIT := 38.0

signal interactable_changed(node: Node)

var camera: Camera3D
var camera_yaw := 0.0  # start looking at the farm (north)
var camera_pitch := deg_to_rad(-26.0)

var interactables: Array = []
var current_interactable: Node = null

var touch_input := Vector2.ZERO
var _cam_rig: Node3D
var _body_root: Node3D
var _arm_l: Node3D
var _arm_r: Node3D
var _leg_l: Node3D
var _leg_r: Node3D
var _walk_t := 0.0
var _step_timer := 0.0
var _interact_anim := 0.0
var _mouse_cam := false
var _mouse_last := Vector2.ZERO
var _interact_held := false


func _ready() -> void:
	_build_rig()
	_build_character()

func _build_rig() -> void:
	_cam_rig = Node3D.new()
	_cam_rig.name = "CamRig"
	_cam_rig.position = Vector3(0, 1.4, 0)
	add_child(_cam_rig)
	camera = Camera3D.new()
	camera.name = "Camera"
	camera.fov = 62.0
	camera.position = Vector3(0, 0.35, CAMERA_DIST)
	_cam_rig.add_child(camera)

func _build_character() -> void:
	_body_root = Node3D.new()
	_body_root.name = "BodyRoot"
	add_child(_body_root)

	var skin := WorldBuilder.mat(Color(0.93, 0.76, 0.6), 0.7)
	var shirt := WorldBuilder.mat(Color(0.42, 0.55, 0.28), 0.9)
	var pants := WorldBuilder.mat(Color(0.35, 0.42, 0.55), 0.9)
	var hatm := WorldBuilder.mat(Color(0.95, 0.8, 0.35), 0.8)
	var eye := WorldBuilder.mat(Color(0.15, 0.13, 0.12), 0.4)

	# legs (pivots at hips)
	_leg_l = _limb_pivot(_body_root, Vector3(-0.13, 0.92, 0), pants, 0.12, 0.5)
	_leg_r = _limb_pivot(_body_root, Vector3(0.13, 0.92, 0), pants, 0.12, 0.5)
	# body
	var body := WorldBuilder.capsule(0.3, 0.8, shirt)
	body.position = Vector3(0, 1.3, 0)
	_body_root.add_child(body)
	# arms (pivots at shoulders)
	_arm_l = _limb_pivot(_body_root, Vector3(-0.4, 1.58, 0), shirt, 0.09, 0.5)
	_arm_r = _limb_pivot(_body_root, Vector3(0.4, 1.58, 0), shirt, 0.09, 0.5)
	# hands
	var hand_l := WorldBuilder.sphere(0.08, skin, 0.9)
	hand_l.position = Vector3(-0.4, 1.0, 0)
	_body_root.add_child(hand_l)
	var hand_r := WorldBuilder.sphere(0.08, skin, 0.9)
	hand_r.position = Vector3(0.4, 1.0, 0)
	_body_root.add_child(hand_r)
	# head
	var head := WorldBuilder.sphere(0.24, skin, 1.0)
	head.position = Vector3(0, 1.92, 0)
	_body_root.add_child(head)
	# eyes (front = +z)
	var eye_l := WorldBuilder.sphere(0.032, eye, 1.0)
	eye_l.position = Vector3(-0.09, 1.95, 0.21)
	_body_root.add_child(eye_l)
	var eye_r := WorldBuilder.sphere(0.032, eye, 1.0)
	eye_r.position = Vector3(0.09, 1.95, 0.21)
	_body_root.add_child(eye_r)
	# straw hat
	var brim := WorldBuilder.cylinder(0.44, 0.46, 0.05, hatm)
	brim.position = Vector3(0, 2.06, 0)
	_body_root.add_child(brim)
	var crown := WorldBuilder.cylinder(0.27, 0.3, 0.24, hatm)
	crown.position = Vector3(0, 2.18, 0)
	_body_root.add_child(crown)

func _limb_pivot(parent: Node3D, pivot_pos: Vector3, material: Material,
		radius: float, length: float) -> Node3D:
	var pivot := Node3D.new()
	pivot.position = pivot_pos
	parent.add_child(pivot)
	var mesh := WorldBuilder.capsule(radius, length, material)
	mesh.position = Vector3(0, -length * 0.5, 0)
	pivot.add_child(mesh)
	return pivot

# ------------------------------------------------------------ input -------
func set_touch_input(v: Vector2) -> void:
	touch_input = v

func rotate_camera(dx: float, dy: float) -> void:
	camera_yaw += dx * 0.0042
	camera_pitch = clampf(camera_pitch + dy * 0.0042, PITCH_MIN, PITCH_MAX)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		var vp_size := get_viewport().get_visible_rect().size
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				if mb.position.x > vp_size.x * 0.55:
					_mouse_cam = true
					_mouse_last = mb.position
			elif _mouse_cam:
				_mouse_cam = false
	elif event is InputEventMouseMotion and _mouse_cam:
		var mm := event as InputEventMouseMotion
		rotate_camera(mm.relative.x, mm.relative.y)
		_mouse_last = mm.position

# ------------------------------------------------------------ physics -----
func _physics_process(delta: float) -> void:
	# --- input direction
	var input_v := Vector2.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		input_v.y += 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		input_v.y -= 1.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		input_v.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		input_v.x += 1.0
	input_v += touch_input
	if input_v.length() > 1.0:
		input_v = input_v.normalized()
	var running: bool = Input.is_key_pressed(KEY_SHIFT)

	# --- camera orbit (keys)
	if Input.is_key_pressed(KEY_Q):
		camera_yaw -= 2.2 * delta
	if Input.is_key_pressed(KEY_E) and _interact_held == false:
		# E is interact; use Q/R or T for orbit fallback
		pass
	if Input.is_key_pressed(KEY_R):
		camera_yaw += 2.2 * delta
	_cam_rig.rotation.y = camera_yaw
	camera.rotation.x = camera_pitch

	# --- movement relative to camera
	var forward := Vector3(-sin(camera_yaw), 0, -cos(camera_yaw))
	var right := forward.cross(Vector3.UP)
	var move_dir := (forward * input_v.y + right * input_v.x)
	var speed: float = SPRINT_SPEED if running else SPEED
	var target_vel := Vector3.ZERO
	if move_dir.length() > 0.01:
		target_vel = move_dir.normalized() * speed
	velocity.x = lerpf(velocity.x, target_vel.x, minf(1.0, ACCEL * delta))
	velocity.z = lerpf(velocity.z, target_vel.z, minf(1.0, ACCEL * delta))
	velocity.y -= GRAVITY * delta
	if is_on_floor():
		velocity.y = maxf(velocity.y, 0.0)
	move_and_slide()

	# --- world bounds
	position.x = clampf(position.x, -WORLD_LIMIT, WORLD_LIMIT)
	position.z = clampf(position.z, -WORLD_LIMIT, WORLD_LIMIT)

	# --- facing + walk animation
	var moving: bool = velocity.x * velocity.x + velocity.z * velocity.z > 0.16
	if moving:
		var target_yaw := atan2(velocity.x, velocity.z)
		_body_root.rotation.y = lerp_angle(_body_root.rotation.y, target_yaw,
			minf(1.0, 12.0 * delta))
		_walk_t += delta * (SPEED if not running else SPRINT_SPEED) * 2.4
		var swing := sin(_walk_t) * (0.55 if not running else 0.8)
		_leg_l.rotation.x = swing
		_leg_r.rotation.x = -swing
		_arm_l.rotation.x = -swing * 0.8
		_arm_r.rotation.x = swing * 0.8
		_body_root.position.y = absf(sin(_walk_t)) * 0.05
		# footsteps
		_step_timer += delta
		var step_rate: float = 0.34 if running else 0.46
		if _step_timer > step_rate:
			_step_timer = 0.0
			AudioBus.play_sfx("step", -20.0)
	else:
		_walk_t = 0.0
		for part in [_leg_l, _leg_r, _arm_l, _arm_r]:
			part.rotation.x = lerpf(part.rotation.x, 0.0, minf(1.0, 10.0 * delta))
		_body_root.position.y = lerpf(_body_root.position.y, 0.0, minf(1.0, 10.0 * delta))

	# --- interact key (edge)
	var interact_down: bool = Input.is_key_pressed(KEY_E) or Input.is_key_pressed(KEY_SPACE)
	if interact_down and not _interact_held:
		try_interact()
	_interact_held = interact_down

	# --- interact animation
	if _interact_anim > 0.0:
		_interact_anim -= delta
		_arm_r.rotation.x = lerp(_arm_r.rotation.x, -1.9, minf(1.0, 18.0 * delta))
	else:
		pass

	# --- nearest interactable
	_find_interactable()

func _find_interactable() -> void:
	var best: Node = null
	var best_d := INTERACT_RANGE
	for n in interactables:
		if n == null or not is_instance_valid(n):
			continue
		if not (n as Node).has_method("is_interactable"):
			continue
		if not (n as Node).call("is_interactable"):
			continue
		var d: float = global_position.distance_to((n as Node3D).global_position)
		if d < best_d:
			best_d = d
			best = n
	if best != current_interactable:
		current_interactable = best
		interactable_changed.emit(best)

func try_interact() -> void:
	if current_interactable != null and is_instance_valid(current_interactable):
		_interact_anim = 0.3
		current_interactable.call("do_interact")

func update_prompt() -> void:
	# Re-emit the current target so the HUD label reflects fresh inventory
	# state (e.g. after buying/selling or planting).
	interactable_changed.emit(current_interactable)

func get_current_interactable_label() -> String:
	if current_interactable != null and is_instance_valid(current_interactable):
		return str(current_interactable.call("interact_label"))
	return ""
