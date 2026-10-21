class_name DispatchBoard
extends RefCounted

# A separate, bounded bonus channel. It never calls the manual-job economy.
const MAX_TASKS := 3
const MAX_HISTORY := 5
const OFFLINE_CAP := 28800.0
const STAFF := ["azubi", "monteur", "meisterin"]
const SPECIALIZATIONS := ["sanitaer", "heizung", "planung"]
const PACES := ["schnell", "normal", "sorgfalt"]
const ORDERS := [
	{"id": "armaturen", "title": "Sanitärkontrolle", "specialization": "sanitaer", "level": 1, "duration": 120.0, "base_reward": 35},
	{"id": "heizcheck", "title": "Heizungscheck", "specialization": "heizung", "level": 3, "duration": 240.0, "base_reward": 75},
	{"id": "planung", "title": "Material- und Terminplanung", "specialization": "planung", "level": 5, "duration": 360.0, "base_reward": 100},
]
var profiles := {"azubi": "sanitaer", "monteur": "heizung", "meisterin": "planung"}
var tasks: Array = []
var history: Array = []
var next_id := 1

func order_for(id: String) -> Dictionary:
	for order in ORDERS:
		if order.id == id: return order.duplicate(true)
	return {}

func quote(order_id: String, employee_id: String, pace: String, specialization: String) -> Dictionary:
	var order: Dictionary = order_for(order_id)
	if order.is_empty() or not employee_id in STAFF or not pace in PACES or not specialization in SPECIALIZATIONS:
		return {}
	var experience: int = {"azubi": 0, "monteur": 4, "meisterin": 8}[employee_id]
	var quality := clampi(72 + experience + (8 if order.specialization == specialization else 0) + int({"schnell": -12, "normal": 0, "sorgfalt": 8}[pace]), 50, 100)
	var duration := maxf(1.0, float(order.duration) * float({"schnell": 0.75, "normal": 1.0, "sorgfalt": 1.4}[pace]))
	return {"quality": quality, "duration": duration, "reward_cents": int(round(float(order.base_reward) * quality))}

func set_specialization(employee_id: String, specialization: String) -> bool:
	if not employee_id in STAFF or not specialization in SPECIALIZATIONS: return false
	profiles[employee_id] = specialization
	return true

func available(employee_id: String, employees: Dictionary) -> int:
	if not employee_id in STAFF: return 0
	var owned: Variant = employees.get(employee_id, 0)
	if not _integer(owned, 0, 1000000): return 0
	var busy := 0
	for task in tasks:
		if task.employee_id == employee_id: busy += 1
	return maxi(0, int(owned) - busy)

func assign(order_id: String, employee_id: String, pace: String, employees: Dictionary, level: int) -> String:
	var order: Dictionary = order_for(order_id)
	if tasks.size() >= MAX_TASKS or order.is_empty() or level < int(order.level) or available(employee_id, employees) < 1 or next_id >= 1000000000:
		return ""
	for task in tasks:
		if task.order_id == order_id: return ""
	var specialization: String = profiles.get(employee_id, "")
	var result: Dictionary = quote(order_id, employee_id, pace, specialization)
	if result.is_empty(): return ""
	var id := "dispatch-%d" % next_id
	next_id += 1
	result.merge({"id": id, "order_id": order_id, "employee_id": employee_id, "pace": pace, "specialization": specialization, "remaining": result.duration})
	tasks.append(result)
	return id

func advance(seconds: float) -> void:
	if not is_finite(seconds) or seconds < 0.0: return
	var elapsed := minf(seconds, OFFLINE_CAP)
	for task in tasks:
		task.remaining = maxf(0.0, float(task.remaining) - elapsed)

func collect(id: String) -> Dictionary:
	for index in range(tasks.size()):
		var task: Dictionary = tasks[index]
		if task.id != id or float(task.remaining) > 0.0: continue
		var receipt: Dictionary = task.duplicate(true)
		tasks.remove_at(index)
		history.push_front(receipt.duplicate(true))
		if history.size() > MAX_HISTORY: history.resize(MAX_HISTORY)
		return receipt
	return {}

func to_payload() -> Dictionary:
	return {"schema_version": 1, "profiles": profiles.duplicate(true), "next_id": next_id, "tasks": tasks.duplicate(true), "history": history.duplicate(true)}

static func _number(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value))

static func _integer(value: Variant, minimum: int, maximum: int) -> bool:
	return _number(value) and float(value) >= minimum and float(value) <= maximum and floor(float(value)) == float(value)

static func _record_id(value: Variant) -> int:
	if not value is String or not value.begins_with("dispatch-"): return 0
	var suffix: String = value.trim_prefix("dispatch-")
	if not suffix.is_valid_int() or suffix.length() > 9: return 0
	var number := int(suffix)
	return number if number > 0 and str(number) == suffix else 0

func _valid_record(record: Variant, completed: bool) -> bool:
	if not record is Dictionary or record.size() != 9: return false
	for key in ["id", "order_id", "employee_id", "pace", "specialization"]:
		if not record.get(key) is String: return false
	if _record_id(record.id) <= 0: return false
	var canonical: Dictionary = quote(record.order_id, record.employee_id, record.pace, record.specialization)
	if canonical.is_empty(): return false
	for key in ["quality", "duration", "reward_cents"]:
		if not _number(record.get(key)) or float(record[key]) != float(canonical[key]): return false
	if not _number(record.get("remaining")) or float(record.remaining) < 0.0 or float(record.remaining) > float(canonical.duration): return false
	return not completed or float(record.remaining) == 0.0

static func from_payload(value: Variant) -> Variant:
	if not value is Dictionary or value.size() != 5 or not _integer(value.get("schema_version"), 1, 1) or not _integer(value.get("next_id"), 1, 1000000000): return null
	if not value.get("profiles") is Dictionary or value.profiles.size() != 3 or not value.get("tasks") is Array or not value.get("history") is Array: return null
	if value.tasks.size() > MAX_TASKS or value.history.size() > MAX_HISTORY: return null
	for staff in STAFF:
		if not value.profiles.get(staff) in SPECIALIZATIONS: return null
	var board := DispatchBoard.new()
	var seen: Dictionary = {}
	var active_orders: Dictionary = {}
	for group in [value.tasks, value.history]:
		for record in group:
			if not board._valid_record(record, group == value.history): return null
			var number: int = _record_id(record.id)
			if number >= int(value.next_id) or seen.has(record.id): return null
			seen[record.id] = true
			if group == value.tasks:
				if active_orders.has(record.order_id): return null
				active_orders[record.order_id] = true
	board.profiles = value.profiles.duplicate(true)
	board.tasks = value.tasks.duplicate(true)
	board.history = value.history.duplicate(true)
	board.next_id = int(value.next_id)
	return board
