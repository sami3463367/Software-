extends CanvasLayer
## HUD + title screen + dialog + shop + toasts + floating combat text.

signal new_game_requested
signal continue_requested

const CREAM := Color(1.0, 0.97, 0.9)
const INK := Color(0.23, 0.2, 0.15)
const GREEN := Color(0.36, 0.68, 0.36)
const YELLOW := Color(0.95, 0.78, 0.28)

var camera: Camera3D = null

var _title_layer: Control
var _continue_btn: Button
var _hud: Control
var _gold_label: Label
var _day_label: Label
var _prompt_label: Label
var _mute_btn: Button
var _slots: Array[Button] = []
var _slot_counts: Array[Label] = []
var _dialog_panel: Panel
var _dialog_line: Label
var _shop_panel: Panel
var _shop_rows := {}
var _shop_gold: Label
var _toast_label: Label
var _toast_t := 0.0
var _floats: Array[Dictionary] = []
var _float_pool: Array[Label] = []
var _seed_types := ["wheat", "tomato", "pumpkin"]
var _seed_colors := {
	"wheat": Color(0.93, 0.78, 0.3),
	"tomato": Color(0.86, 0.25, 0.2),
	"pumpkin": Color(0.92, 0.5, 0.12),
}


func _ready() -> void:
	layer = 10
	_build_title()
	_build_hud()
	_build_dialog()
	_build_shop()
	_build_toast()
	_build_floats()
	_connect_state()

# ----------------------------------------------------------------- style ---
func _panel_style(bg: Color = CREAM, radius: int = 14,
		border: Color = Color(0.23, 0.2, 0.15, 0.35)) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(radius)
	sb.set_border_width_all(2)
	sb.border_color = border
	sb.set_content_margin_all(12)
	return sb

func _label(text: String, size: int, color: Color = INK, outline: int = 0) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if outline > 0:
		l.add_theme_constant_override("outline_size", outline)
		l.add_theme_color_override("font_outline_color", Color(0.1, 0.09, 0.06, 0.8))
	return l

func _button(text: String, size: int = 18, accent: Color = GREEN) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", size)
	b.add_theme_color_override("font_color", Color.WHITE)
	var normal := StyleBoxFlat.new()
	normal.bg_color = accent
	normal.set_corner_radius_all(10)
	normal.set_border_width_all(2)
	normal.border_color = Color(0.2, 0.18, 0.12, 0.4)
	normal.set_content_margin_all(8)
	var hover := normal.duplicate()
	hover.bg_color = accent.lightened(0.12)
	var pressed := normal.duplicate()
	pressed.bg_color = accent.darkened(0.12)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", pressed)
	return b

func _pin(c: Control, ax: float, ay: float,
		ox: float, oy: float, ow: float, oh: float) -> void:
	c.anchor_left = ax
	c.anchor_right = ax
	c.anchor_top = ay
	c.anchor_bottom = ay
	c.offset_left = ox
	c.offset_top = oy
	c.offset_right = ow
	c.offset_bottom = oh

# ----------------------------------------------------------------- title ---
func _build_title() -> void:
	_title_layer = Control.new()
	_title_layer.name = "TitleLayer"
	_title_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_title_layer)

	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.35, 0.62, 0.85)
	_title_layer.add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_title_layer.add_child(center)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	center.add_child(vbox)

	var title := _label("MOSS & EMBER", 64, Color.WHITE, 6)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	var sub := _label("a cozy farm in the valley", 22, Color(1.0, 0.97, 0.9, 0.95), 4)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(sub)

	var btn_box := VBoxContainer.new()
	btn_box.add_theme_constant_override("separation", 10)
	btn_box.custom_minimum_size = Vector2(300, 0)
	vbox.add_child(btn_box)
	var new_btn := _button("New Game", 24, GREEN)
	new_btn.pressed.connect(func() -> void: new_game_requested.emit())
	btn_box.add_child(new_btn)
	_continue_btn = _button("Continue", 24, YELLOW)
	_continue_btn.pressed.connect(func() -> void: continue_requested.emit())
	btn_box.add_child(_continue_btn)

	var footer := _label("slice 0.1  ·  built with Godot 4.7  ·  play in your browser",
		13, Color.WHITE, 3)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(footer)

# ------------------------------------------------------------------- hud ---
func _build_hud() -> void:
	_hud = Control.new()
	_hud.name = "Hud"
	_hud.set_anchors_preset(Control.PRESET_FULL_RECT)
	_hud.visible = false
	add_child(_hud)

	# top-left: gold + day
	var top_left := VBoxContainer.new()
	top_left.position = Vector2(16, 14)
	top_left.add_theme_constant_override("separation", 4)
	_hud.add_child(top_left)

	var gold_row := HBoxContainer.new()
	gold_row.add_theme_constant_override("separation", 8)
	top_left.add_child(gold_row)
	var coin := Control.new()
	coin.custom_minimum_size = Vector2(20, 20)
	var coin_sb := StyleBoxFlat.new()
	coin_sb.bg_color = YELLOW
	coin_sb.set_corner_radius_all(10)
	coin_sb.set_border_width_all(2)
	coin_sb.border_color = Color(0.5, 0.35, 0.08)
	coin.add_theme_stylebox_override("panel", coin_sb)
	gold_row.add_child(coin)
	_gold_label = _label("25", 22, INK, 3)
	gold_row.add_child(_gold_label)

	_day_label = _label("Day 1 · 6:00 AM", 17, INK, 3)
	top_left.add_child(_day_label)

	# top-right: mute
	_mute_btn = _button("M", 16, Color(0.55, 0.55, 0.6))
	_mute_btn.custom_minimum_size = Vector2(40, 34)
	_pin(_mute_btn, 1.0, 0.0, -56, 14, 0, 48)
	_mute_btn.pressed.connect(_on_mute)
	_hud.add_child(_mute_btn)

	# prompt (centered above the hotbar)
	_prompt_label = _label("", 20, Color.WHITE, 5)
	_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_pin(_prompt_label, 0.5, 1.0, -220, -160, 220, -120)
	_hud.add_child(_prompt_label)

	# hotbar (3 seed slots)
	var hotbar := HBoxContainer.new()
	hotbar.add_theme_constant_override("separation", 10)
	_pin(hotbar, 0.5, 1.0, -130, -96, 130, -10)
	_hud.add_child(hotbar)
	for i in _seed_types.size():
		var type_: String = _seed_types[i]
		var slot := Button.new()
		slot.custom_minimum_size = Vector2(76, 84)
		slot.name = "Slot%s" % type_
		var sb := _panel_style(Color(1, 0.98, 0.92), 12)
		slot.add_theme_stylebox_override("normal", sb)
		slot.add_theme_stylebox_override("hover", sb)
		slot.add_theme_stylebox_override("pressed", sb)
		slot.focus_mode = Control.FOCUS_NONE
		slot.pressed.connect(_on_slot_pressed.bind(i))
		hotbar.add_child(slot)
		_slots.append(slot)

		var dot := ColorRect.new()
		dot.custom_minimum_size = Vector2(18, 18)
		dot.color = _seed_colors[type_]
		dot.position = Vector2(29, 10)
		slot.add_child(dot)
		var nm := _label(type_.capitalize(), 14, INK)
		nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nm.set_anchors_preset(Control.PRESET_FULL_RECT)
		nm.offset_top = 32
		slot.add_child(nm)
		var cnt := _label("×0", 18, INK)
		cnt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cnt.set_anchors_preset(Control.PRESET_FULL_RECT)
		cnt.offset_top = 50
		slot.add_child(cnt)
		_slot_counts.append(cnt)
		var key_hint := _label(str(i + 1), 12, Color(0.23, 0.2, 0.15, 0.5))
		key_hint.position = Vector2(6, 2)
		slot.add_child(key_hint)

func _on_slot_pressed(i: int) -> void:
	GameState.selected_seed = _seed_types[i]
	AudioBus.play_sfx("click", -6.0)
	refresh_all()

func _on_mute() -> void:
	AudioBus.toggle_mute()
	_mute_btn.text = "M̶" if AudioBus.muted else "M"

# ---------------------------------------------------------------- dialog ---
func _build_dialog() -> void:
	_dialog_panel = Panel.new()
	_dialog_panel.add_theme_stylebox_override("panel", _panel_style(CREAM, 16))
	_pin(_dialog_panel, 0.5, 1.0, -330, -170, 330, -14)
	_dialog_panel.visible = false
	add_child(_dialog_panel)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dialog_panel.add_child(vbox)
	var name_l := _label("Pip the Neighbor", 18, GREEN)
	vbox.add_child(name_l)
	_dialog_line = _label("", 18, INK)
	_dialog_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_dialog_line)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	vbox.add_child(row)
	var shop_btn := _button("Open Shop", 18, YELLOW)
	shop_btn.pressed.connect(_open_shop)
	row.add_child(shop_btn)
	var close_btn := _button("Close", 18, Color(0.55, 0.55, 0.6))
	close_btn.pressed.connect(_close_dialog)
	row.add_child(close_btn)

# ------------------------------------------------------------------ shop ---
func _build_shop() -> void:
	_shop_panel = Panel.new()
	_shop_panel.add_theme_stylebox_override("panel", _panel_style(CREAM, 18))
	_pin(_shop_panel, 0.5, 0.5, -320, -185, 320, 185)
	_shop_panel.visible = false
	add_child(_shop_panel)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 10)
	_shop_panel.add_child(vbox)

	var header := HBoxContainer.new()
	vbox.add_child(header)
	var title := _label("Pip's Stall", 26, GREEN)
	header.add_child(title)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	_shop_gold = _label("", 20, INK)
	header.add_child(_shop_gold)

	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 18)
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(cols)

	var buy_col := VBoxContainer.new()
	buy_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buy_col.add_theme_constant_override("separation", 8)
	cols.add_child(buy_col)
	buy_col.add_child(_label("Buy seeds", 18, INK))
	var sell_col := VBoxContainer.new()
	sell_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sell_col.add_theme_constant_override("separation", 8)
	cols.add_child(sell_col)
	sell_col.add_child(_label("Sell harvest", 18, INK))

	for type_ in _seed_types:
		var buy_btn := _button("Buy %s — %dg" % [type_, GameState.CROPS[type_]["buy"]],
			16, GREEN)
		buy_btn.pressed.connect(_buy.bind(type_))
		buy_col.add_child(buy_btn)
		var sell_btn := _button("Sell %s — %dg" % [type_, GameState.CROPS[type_]["sell"]],
			16, YELLOW)
		sell_btn.pressed.connect(_sell.bind(type_))
		sell_col.add_child(sell_btn)
		_shop_rows[type_] = {"buy": buy_btn, "sell": sell_btn}

	var close_row := HBoxContainer.new()
	close_row.alignment = BoxContainer.ALIGNMENT_END
	vbox.add_child(close_row)
	var close_btn := _button("Close", 18, Color(0.55, 0.55, 0.6))
	close_btn.pressed.connect(_close_shop)
	close_row.add_child(close_btn)

# ----------------------------------------------------------------- toast ---
func _build_toast() -> void:
	_toast_label = _label("", 30, Color.WHITE, 6)
	_toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_pin(_toast_label, 0.5, 0.0, -220, 70, 220, 110)
	_toast_label.modulate.a = 0.0
	add_child(_toast_label)

# ---------------------------------------------------------------- floats ---
func _build_floats() -> void:
	for i in 8:
		var l := _label("", 20, Color.WHITE, 5)
		l.visible = false
		add_child(l)
		_float_pool.append(l)

func add_float(world_pos: Vector3, text: String, color: Color) -> void:
	if text == "" or camera == null:
		return
	var l: Label = null
	for cand in _float_pool:
		if not cand.visible:
			l = cand
			break
	if l == null:
		return
	l.text = text
	l.add_theme_color_override("font_color", color)
	l.visible = true
	_floats.append({"label": l, "pos": world_pos, "life": 1.4, "max": 1.4})

func show_toast(text: String) -> void:
	_toast_label.text = text
	_toast_t = 2.4

func set_prompt(node: Node) -> void:
	if node == null:
		_prompt_label.text = ""
		return
	_prompt_label.text = "[E]  %s" % node.call("interact_label")

# -------------------------------------------------------------- game flow ---
func show_title(has_save: bool) -> void:
	_title_layer.visible = true
	_hud.visible = false
	_continue_btn.disabled = not has_save

func hide_title() -> void:
	_title_layer.visible = false
	_hud.visible = true

func _open_shop() -> void:
	_close_dialog()
	_shop_panel.visible = true
	AudioBus.play_sfx("click")
	_refresh_shop()

func _close_shop() -> void:
	_shop_panel.visible = false
	AudioBus.play_sfx("click")

func _close_dialog() -> void:
	_dialog_panel.visible = false

func open_dialog(line: String) -> void:
	_dialog_line.text = line
	_dialog_panel.visible = true

func _buy(type_: String) -> void:
	if GameState.buy(type_):
		_refresh_shop()
		refresh_all()

func _sell(type_: String) -> void:
	if GameState.sell(type_):
		_refresh_shop()
		refresh_all()

func _refresh_shop() -> void:
	_shop_gold.text = "%d gold" % GameState.money
	for type_ in _seed_types:
		var row: Dictionary = _shop_rows[type_]
		row["buy"].disabled = GameState.money < int(GameState.CROPS[type_]["buy"])
		row["sell"].disabled = GameState.produce.get(type_, 0) <= 0

func refresh_all() -> void:
	if not is_inside_tree():
		return
	_gold_label.text = str(GameState.money)
	_day_label.text = "Day %d · %s" % [GameState.day, _clock(GameState.get_hour())]
	for i in _seed_types.size():
		var type_: String = _seed_types[i]
		_slot_counts[i].text = "×%d" % GameState.seeds.get(type_, 0)
		var selected: bool = GameState.selected_seed == type_
		var sb := _panel_style(
			Color(0.88, 0.96, 0.78) if selected else Color(1, 0.98, 0.92),
			12,
			GREEN if selected else Color(0.23, 0.2, 0.15, 0.35))
		_slots[i].add_theme_stylebox_override("normal", sb)
		_slots[i].add_theme_stylebox_override("hover", sb)
		_slots[i].add_theme_stylebox_override("pressed", sb)
	if _shop_panel.visible:
		_refresh_shop()

func _clock(hour: float) -> String:
	var h24: int = int(fmod(6.0 + hour, 24.0))
	var m: int = int(fmod(hour, 1.0) * 60.0)
	var ampm: String = "AM" if h24 < 12 else "PM"
	var h12: int = h24 % 12
	if h12 == 0:
		h12 = 12
	return "%d:%02d %s" % [h12, m, ampm]

# ----------------------------------------------------------------- state ---
func _connect_state() -> void:
	GameState.money_changed.connect(func(_m: int) -> void: refresh_all())
	GameState.inventory_changed.connect(func() -> void:
		refresh_all()
		_update_prompt())
	GameState.time_changed.connect(func(hour: float) -> void:
		_day_label.text = "Day %d · %s" % [GameState.day, _clock(hour)])
	GameState.day_changed.connect(func(_d: int) -> void: refresh_all())

func _update_prompt() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player and player.has_method("update_prompt"):
		player.update_prompt()

func _process(delta: float) -> void:
	# toast
	if _toast_t > 0.0:
		_toast_t -= delta
		_toast_label.modulate.a = clampf(_toast_t / 0.5, 0.0, 1.0)
	else:
		_toast_label.modulate.a = 0.0
	# floating text
	if _floats.is_empty() or camera == null:
		return
	var i := _floats.size() - 1
	while i >= 0:
		var f: Dictionary = _floats[i]
		f["life"] = float(f["life"]) - delta
		if float(f["life"]) <= 0.0:
			(f["label"] as Label).visible = false
			_floats.remove_at(i)
		else:
			f["pos"] = (f["pos"] as Vector3) + Vector3(0, 0.8 * delta, 0)
			var screen_pos: Vector2 = camera.unproject_position(f["pos"] as Vector3)
			(f["label"] as Label).position = screen_pos - (f["label"] as Label).size / 2.0
			(f["label"] as Label).modulate.a = clampf(float(f["life"]) / 0.6, 0.0, 1.0)
		i -= 1
