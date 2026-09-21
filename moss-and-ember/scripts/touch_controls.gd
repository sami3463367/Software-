extends Control
## Virtual joystick (left thumb) + camera drag (right side) + action button.
## Touch events only; mouse users use WASD + drag (handled by the player).

signal joystick_moved(v: Vector2)
signal camera_rotated(dx: float, dy: float)
signal action_pressed()

const JOY_RADIUS := 48.0
const ACTION_RADIUS := 40.0

var _joy_index: int = -1
var _joy_base := Vector2.ZERO
var _cam_index: int = -1
var _cam_last := Vector2.ZERO
var _action_index: int = -1
var _action_center := Vector2.ZERO
var _joy_knob := Vector2.ZERO
var _is_touch_device := false


func setup() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_PASS
	_update_action_center()

func _resized() -> void:
	_update_action_center()
	queue_redraw()

func _update_action_center() -> void:
	_action_center = size - Vector2(86, 116)

# ----------------------------------------------------------------- input ---
func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var t := event as InputEventScreenTouch
		_is_touch_device = true
		if t.pressed:
			if distance_to_center(t.position, _action_center) < ACTION_RADIUS:
				_action_index = t.index
				action_pressed.emit()
			elif t.position.x < size.x * 0.45:
				_joy_index = t.index
				_joy_base = t.position
				_joy_knob = Vector2.ZERO
				queue_redraw()
			elif t.position.x > size.x * 0.55:
				_cam_index = t.index
				_cam_last = t.position
		else:
			if t.index == _action_index:
				_action_index = -1
			if t.index == _joy_index:
				_joy_index = -1
				_joy_knob = Vector2.ZERO
				joystick_moved.emit(Vector2.ZERO)
				queue_redraw()
			if t.index == _cam_index:
				_cam_index = -1
	elif event is InputEventScreenDrag:
		var d := event as InputEventScreenDrag
		if d.index == _joy_index:
			var v := (d.position - _joy_base) / JOY_RADIUS
			if v.length() > 1.0:
				v = v.normalized()
			_joy_knob = v * JOY_RADIUS
			joystick_moved.emit(v)
			queue_redraw()
		elif d.index == _cam_index:
			camera_rotated.emit(d.position.x - _cam_last.x, d.position.y - _cam_last.y)
			_cam_last = d.position

func distance_to_center(a: Vector2, b: Vector2) -> float:
	return a.distance_to(b)

# ------------------------------------------------------------------ draw ---
func _draw() -> void:
	if not _is_touch_device:
		return
	# action button
	draw_circle(_action_center, ACTION_RADIUS, Color(1, 0.97, 0.9, 0.55))
	draw_arc(_action_center, ACTION_RADIUS, 0, TAU, 48, Color(0.23, 0.2, 0.15, 0.5), 3.0)
	var font := ThemeDB.fallback_font
	draw_string(font, _action_center + Vector2(-8, 10), "E",
		HORIZONTAL_ALIGNMENT_CENTER, -1, 26, Color(0.23, 0.2, 0.15, 0.8))
	# joystick
	if _joy_index >= 0:
		draw_circle(_joy_base, JOY_RADIUS, Color(1, 0.97, 0.9, 0.35))
		draw_arc(_joy_base, JOY_RADIUS, 0, TAU, 48, Color(0.23, 0.2, 0.15, 0.4), 3.0)
		draw_circle(_joy_base + _joy_knob, 22, Color(0.36, 0.68, 0.36, 0.8))
	# hints
	var hint_font := ThemeDB.fallback_font
	draw_string(hint_font, Vector2(14, size.y - 14),
		"left: move   ·   right: look   ·   E: interact",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(1, 1, 1, 0.45))
