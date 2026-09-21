extends Node
## GameState — global singleton: inventory, money, farm time, crop state, save/load.

signal money_changed(new_money: int)
signal inventory_changed()
signal time_changed(hour: float)
signal day_changed(new_day: int)
signal toast_requested(text: String)

const SAVE_PATH := "user://save.json"
const SECONDS_PER_DAY := 480.0  # one in-game day = 8 real minutes

# Crop catalog: [seed buy price, sell price, grow seconds]
const CROPS := {
	"wheat": {"buy": 5, "sell": 9, "grow": 120.0},
	"tomato": {"buy": 12, "sell": 24, "grow": 180.0},
	"pumpkin": {"buy": 25, "sell": 52, "grow": 260.0},
}

var paused := false  # true on the title screen; time stands still

var money: int = 25
var day: int = 1
var time_of_day: float = 0.0  # hours, 0 = 6:00 (sunrise), 24 = next sunrise
var seeds := {"wheat": 8, "tomato": 2, "pumpkin": 1}
var produce := {"wheat": 0, "tomato": 0, "pumpkin": 0}
var selected_seed: String = "wheat"

# crop_id -> [type, progress 0..1, planted_day]
var crops := {}
var _crop_id: int = 0

func _ready() -> void:
	randomize()
	randomize()  # second call is harmless; keeps intent explicit

func get_hour() -> float:
	return fmod(time_of_day, 24.0)

func _process(delta: float) -> void:
	if paused:
		return
	time_of_day += delta * (24.0 / SECONDS_PER_DAY)
	var hour := get_hour()
	var new_hour_band := int(hour / 6.0)
	# day flips when we wrap past 24 -> 0
	if time_of_day >= 24.0:
		time_of_day -= 24.0
		day += 1
		day_changed.emit(day)
		toast_requested.emit("Day %d" % day)
		AudioBus.play_sfx("day")
		_autosave()
	emit_signal("time_changed", hour)

func advance_time(delta: float) -> void:
	# Manual advance used by self-tests.
	time_of_day += delta * (24.0 / SECONDS_PER_DAY)
	if time_of_day >= 24.0:
		time_of_day -= 24.0
		day += 1
		day_changed.emit(day)

# ------------------------------------------------------------- inventory ---
func add_seed(type_: String, n: int) -> void:
	seeds[type_] = max(0, seeds.get(type_, 0) + n)
	inventory_changed.emit()

func spend_seed(type_: String) -> bool:
	if seeds.get(type_, 0) <= 0:
		return false
	seeds[type_] -= 1
	inventory_changed.emit()
	return true

func add_produce(type_: String, n: int) -> void:
	produce[type_] = produce.get(type_, 0) + n
	inventory_changed.emit()

func spend_produce(type_: String) -> bool:
	if produce.get(type_, 0) <= 0:
		return false
	produce[type_] -= 1
	inventory_changed.emit()
	return true

func buy(type_: String) -> bool:
	var cost: int = CROPS[type_]["buy"]
	if money < cost:
		AudioBus.play_sfx("error")
		toast_requested.emit("Not enough gold!")
		return false
	money -= cost
	money_changed.emit(money)
	add_seed(type_, 1)
	AudioBus.play_sfx("buy")
	return true

func sell(type_: String) -> bool:
	if not spend_produce(type_):
		AudioBus.play_sfx("error")
		return false
	money += int(CROPS[type_]["sell"])
	money_changed.emit(money)
	AudioBus.play_sfx("sell")
	return true

# ------------------------------------------------------------------ crops --
func plant_cell(cell_id: int, type_: String) -> bool:
	if crops.has(cell_id):
		return false
	if seeds.get(type_, 0) <= 0:
		return false
	_crop_id += 1
	crops[cell_id] = {"type": type_, "progress": 0.0, "id": _crop_id}
	spend_seed(type_)
	return true

func crop_info(cell_id: int) -> Dictionary:
	return crops.get(cell_id, {})

func is_ready(cell_id: int) -> bool:
	var c: Dictionary = crops.get(cell_id, {})
	if c.is_empty():
		return false
	return float(c["progress"]) >= 1.0

func harvest_cell(cell_id: int) -> Dictionary:
	var c: Dictionary = crops.get(cell_id, {})
	if c.is_empty() or float(c["progress"]) < 1.0:
		return {}
	var type_: String = c["type"]
	crops.erase(cell_id)
	add_produce(type_, 1)
	return {"type": type_, "value": int(CROPS[type_]["sell"])}

func grow_crops(delta: float) -> void:
	var dirty := false
	for cell_id in crops.keys():
		var c: Dictionary = crops[cell_id]
		var grow_time: float = CROPS[c["type"]]["grow"]
		c["progress"] = minf(float(c["progress"]) + delta / grow_time, 1.0)
		dirty = true
	if dirty:
		inventory_changed.emit()

# ------------------------------------------------------------------- save --
func new_game() -> void:
	money = 25
	day = 1
	time_of_day = 0.0
	seeds = {"wheat": 8, "tomato": 2, "pumpkin": 1}
	produce = {"wheat": 0, "tomato": 0, "pumpkin": 0}
	selected_seed = "wheat"
	crops.clear()
	_crop_id = 0
	money_changed.emit(money)
	inventory_changed.emit()
	day_changed.emit(day)
	_autosave()

func _autosave() -> void:
	save_game()

func save_game() -> void:
	var data := {
		"money": money,
		"day": day,
		"time_of_day": time_of_day,
		"seeds": seeds,
		"produce": produce,
		"selected_seed": selected_seed,
		"next_crop_id": _crop_id,
		"crops": {},
	}
	for cell_id in crops.keys():
		data["crops"][str(cell_id)] = crops[cell_id]
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data, "\t"))
		f.flush()

func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not f:
		return false
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return false
	var data: Dictionary = parsed
	money = int(data.get("money", 25))
	day = int(data.get("day", 1))
	time_of_day = float(data.get("time_of_day", 0.0))
	if data.has("seeds"):
		for k in (data["seeds"] as Dictionary).keys():
			seeds[k] = int((data["seeds"] as Dictionary)[k])
	if data.has("produce"):
		for k in (data["produce"] as Dictionary).keys():
			produce[k] = int((data["produce"] as Dictionary)[k])
	selected_seed = str(data.get("selected_seed", "wheat"))
	_crop_id = int(data.get("next_crop_id", 0))
	crops.clear()
	if data.has("crops"):
		for k in (data["crops"] as Dictionary).keys():
			crops[int(k)] = (data["crops"] as Dictionary)[k]
	money_changed.emit(money)
	inventory_changed.emit()
	day_changed.emit(day)
	return true

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
