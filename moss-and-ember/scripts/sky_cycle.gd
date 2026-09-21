extends Node3D
## Day/night cycle: rotating sun, color-lerped sky, fog, stars.

signal night_level_changed(night: float)

const DAY_LEN := 24.0  # hours per cycle (time starts at 6:00)

var sun: DirectionalLight3D
var sky_mat: ProceduralSkyMaterial
var environment: Environment
var _stars: Array[MeshInstance3D] = []
var _last_night := -1.0

# sky key colors
const NIGHT_TOP := Color(0.02, 0.04, 0.1)
const NIGHT_HOR := Color(0.05, 0.08, 0.18)
const NIGHT_GND := Color(0.03, 0.05, 0.08)
const DUSK_TOP := Color(0.2, 0.25, 0.45)
const DUSK_HOR := Color(0.95, 0.6, 0.32)
const DUSK_GND := Color(0.42, 0.48, 0.38)
const DAY_TOP := Color(0.24, 0.5, 0.84)
const DAY_HOR := Color(0.72, 0.88, 1.0)
const DAY_GND := Color(0.55, 0.72, 0.45)


func _ready() -> void:
	sky_mat = ProceduralSkyMaterial.new()
	var sky := Sky.new()
	sky.sky_material = sky_mat
	environment = Environment.new()
	environment.background_mode = Environment.BG_SKY
	environment.sky = sky
	environment.fog_enabled = true
	environment.fog_density = 0.0028
	var we := WorldEnvironment.new()
	we.environment = environment
	add_child(we)

	sun = DirectionalLight3D.new()
	sun.name = "Sun"
	sun.shadow_enabled = true
	sun.light_energy = 1.15
	add_child(sun)

	# stars on a dome
	var star_mat := WorldBuilder.mat(Color.WHITE, 0.2)
	star_mat.emission_enabled = true
	star_mat.emission = Color(0.9, 0.95, 1.0)
	star_mat.emission_energy_multiplier = 1.4
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	for i in 90:
		var s := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = rng.randf_range(0.08, 0.2)
		sm.radial_segments = 6
		sm.rings = 4
		sm.material = star_mat
		s.mesh = sm
		var theta := rng.randf() * TAU
		var phi := rng.randf_range(0.15, 1.35)  # upper dome
		s.position = Vector3(
			cos(theta) * sin(phi), cos(phi), sin(theta) * sin(phi)) * 85.0
		s.visible = false
		add_child(s)
		_stars.append(s)

func _process(_delta: float) -> void:
	var hour: float = GameState.get_hour()
	# hour 0 == 6:00. Sun is up 6:00 -> 18:00.
	var sun_t: float = clampf((hour - 6.0) / 12.0, 0.0, 1.0)
	var elev: float = sin(sun_t * PI)  # 0..1..0 during the day
	var night: float = clampf(1.0 - elev * 3.2, 0.0, 1.0)

	# sky blend
	var top := _blend(night, elev)
	sky_mat.sky_top_color = top.top
	sky_mat.sky_horizon_color = top.hor
	sky_mat.ground_horizon_color = top.gnd
	sky_mat.ground_bottom_color = top.gnd.darkened(0.5)
	environment.fog_light_color = top.hor

	# sun direction: full circle over the day, moon opposite at night
	var ang := (hour - 6.0) / DAY_LEN * TAU
	var day_dir := Vector3(cos(deg_to_rad(58.0)) * sin(ang),
			sin(deg_to_rad(58.0) * elev + 0.06), cos(deg_to_rad(58.0)) * cos(ang))
	var moon_ang := ang + PI
	var moon_dir := Vector3(cos(0.5) * sin(moon_ang), sin(0.5), cos(0.5) * cos(moon_ang))
	var dir := day_dir.lerp(moon_dir, night).normalized()
	sun.position = dir * 60.0
	sun.look_at(Vector3.ZERO)
	sun.light_energy = lerpf(1.2, 0.32, night)
	sun.light_color = _sun_color(elev, night)

	for s in _stars:
		s.visible = night > 0.55

	if absf(night - _last_night) > 0.02 or _last_night < 0.0:
		_last_night = night
		night_level_changed.emit(night)

func _blend(night: float, elev: float) -> Dictionary:
	var top := NIGHT_TOP.lerp(DAY_TOP, clampf(elev / 0.35, 0.0, 1.0))
	var hor := NIGHT_HOR.lerp(DAY_HOR, clampf(elev / 0.35, 0.0, 1.0))
	var gnd := NIGHT_GND.lerp(DAY_GND, clampf(elev / 0.35, 0.0, 1.0))
	# dusk tint around sunrise/sunset
	if elev > 0.0 and elev < 0.4:
		var bell := 1.0 - absf(elev - 0.16) / 0.16
		bell = clampf(bell, 0.0, 1.0)
		top = top.lerp(DUSK_TOP, bell * 0.5)
		hor = hor.lerp(DUSK_HOR, bell * 0.7)
		gnd = gnd.lerp(DUSK_GND, bell * 0.4)
	return {"top": top, "hor": hor, "gnd": gnd}

func _sun_color(elev: float, night: float) -> Color:
	var day_c := Color(1.0, 0.97, 0.88)
	var dusk_c := Color(1.0, 0.62, 0.35)
	var night_c := Color(0.55, 0.62, 0.85)
	var c: Color = day_c
	if elev < 0.35:
		c = c.lerp(dusk_c, 1.0 - elev / 0.35)
	return c.lerp(night_c, night)
