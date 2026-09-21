extends Node3D
## Pip the farmer's neighbor — stands at the stall, offers lines and the shop.

signal dialog_requested(line: String)

const LINES := [
	"Well met, farmer! The crops look lively today.",
	"Wheat sells for 9 gold. Pumpkins fetch 52 — the town bakes them all autumn.",
	"My grandmother always said: a farm in bloom is a fortune growing.",
	"Try the tomato seeds — sweet as honey, they say.",
	"Stay for supper if you're not in a hurry. The barn's always warm.",
]

var _line_i := 0
var _body_root: Node3D
var _t := 0.0


func _ready() -> void:
	_build()

func _build() -> void:
	_body_root = Node3D.new()
	add_child(_body_root)
	var skin := WorldBuilder.mat(Color(0.87, 0.68, 0.52), 0.7)
	var tunic := WorldBuilder.mat(Color(0.3, 0.45, 0.65), 0.9)
	var apron := WorldBuilder.mat(Color(0.9, 0.86, 0.75), 0.9)
	var hair := WorldBuilder.mat(Color(0.3, 0.22, 0.16), 0.8)
	var eye := WorldBuilder.mat(Color(0.15, 0.13, 0.12), 0.4)

	var body := WorldBuilder.capsule(0.3, 0.9, tunic)
	body.position = Vector3(0, 1.25, 0)
	_body_root.add_child(body)
	var apron_box := WorldBuilder.box(Vector3(0.42, 0.55, 0.1), apron)
	apron_box.position = Vector3(0, 1.05, 0.24)
	_body_root.add_child(apron_box)
	for s in [-1.0, 1.0]:
		var arm := WorldBuilder.capsule(0.09, 0.55, tunic)
		arm.position = Vector3(s * 0.4, 1.2, 0)
		arm.rotation.z = s * 0.15
		_body_root.add_child(arm)
		var hand := WorldBuilder.sphere(0.08, skin, 0.9)
		hand.position = Vector3(s * 0.45, 0.85, 0)
		_body_root.add_child(hand)
	for s in [-1.0, 1.0]:
		var leg := WorldBuilder.capsule(0.11, 0.5, WorldBuilder.mat(Color(0.3, 0.28, 0.25), 0.9))
		leg.position = Vector3(s * 0.13, 0.45, 0)
		_body_root.add_child(leg)
	var head := WorldBuilder.sphere(0.24, skin, 1.0)
	head.position = Vector3(0, 1.95, 0)
	_body_root.add_child(head)
	var hair_cap := WorldBuilder.sphere(0.25, hair, 0.75)
	hair_cap.position = Vector3(0, 2.06, -0.04)
	_body_root.add_child(hair_cap)
	for s in [-1.0, 1.0]:
		var e := WorldBuilder.sphere(0.03, eye, 1.0)
		e.position = Vector3(s * 0.09, 1.97, 0.21)
		_body_root.add_child(e)
	# smile
	var smile := WorldBuilder.box(Vector3(0.1, 0.02, 0.02), eye)
	smile.position = Vector3(0, 1.87, 0.22)
	_body_root.add_child(smile)

func _physics_process(delta: float) -> void:
	_t += delta
	_body_root.position.y = sin(_t * 1.8) * 0.03
	# face the player when they are near
	var player := get_tree().get_first_node_in_group("player")
	if player:
		var d: float = global_position.distance_to(player.global_position)
		if d < 6.0:
			var dir: Vector3 = player.global_position - global_position
			var target_yaw := atan2(dir.x, dir.z)
			_body_root.rotation.y = lerp_angle(_body_root.rotation.y, target_yaw, 0.1)

# ----------------------------------------------------------- interaction ---
func is_interactable() -> bool:
	return true

func interact_label() -> String:
	return "Talk to Pip"

func do_interact() -> void:
	_line_i = (_line_i + 1) % LINES.size()
	AudioBus.play_sfx("click")
	dialog_requested.emit(LINES[_line_i])
