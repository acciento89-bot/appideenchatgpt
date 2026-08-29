class_name GameData
extends RefCounted

const JOBS: Array[Dictionary] = [
	{
		"id": "tap",
		"title": "Tropfender Wasserhahn",
		"customer": "Familie Krüger",
		"icon": "W",
		"duration": 4.0,
		"reward": 75.0,
		"xp": 18,
		"level": 1,
		"color": Color("45c486"),
	},
	{
		"id": "drain",
		"title": "Abfluss verstopft",
		"customer": "Café Morgenrot",
		"icon": "A",
		"duration": 7.0,
		"reward": 145.0,
		"xp": 32,
		"level": 2,
		"color": Color("f3a950"),
	},
	{
		"id": "boiler",
		"title": "Heizung ohne Funktion",
		"customer": "Hausverwaltung Nord",
		"icon": "H",
		"duration": 12.0,
		"reward": 310.0,
		"xp": 58,
		"level": 3,
		"color": Color("ef6b62"),
	},
	{
		"id": "bath",
		"title": "Bad modernisieren",
		"customer": "Neubau am Park",
		"icon": "B",
		"duration": 20.0,
		"reward": 780.0,
		"xp": 110,
		"level": 5,
		"color": Color("6f8df6"),
	},
]

const UPGRADES: Array[Dictionary] = [
	{
		"id": "tools",
		"title": "Profi-Werkzeug",
		"description": "+20 % Auftragslohn je Stufe",
		"icon": "WK",
		"base_cost": 180.0,
		"growth": 1.72,
	},
	{
		"id": "van",
		"title": "Service-Transporter",
		"description": "+12 % schnellere Aufträge je Stufe",
		"icon": "TR",
		"base_cost": 420.0,
		"growth": 1.78,
	},
	{
		"id": "office",
		"title": "Digitales Büro",
		"description": "+25 % Mitarbeitereinnahmen je Stufe",
		"icon": "DB",
		"base_cost": 950.0,
		"growth": 1.84,
	},
]

const EMPLOYEES: Array[Dictionary] = [
	{
		"id": "azubi",
		"title": "Azubi Alex",
		"trade": "Sanitär",
		"income": 1.2,
		"base_cost": 350.0,
		"color": Color("55c890"),
	},
	{
		"id": "monteur",
		"title": "Monteur Mo",
		"trade": "Heizung",
		"income": 4.8,
		"base_cost": 1350.0,
		"color": Color("f2a649"),
	},
	{
		"id": "meisterin",
		"title": "Meisterin Mia",
		"trade": "Projektleitung",
		"income": 14.0,
		"base_cost": 4800.0,
		"color": Color("7591f7"),
	},
]

static func upgrade_cost(upgrade: Dictionary, current_level: int) -> float:
	return round(float(upgrade.base_cost) * pow(float(upgrade.growth), current_level))


static func employee_cost(employee: Dictionary, owned: int) -> float:
	return round(float(employee.base_cost) * pow(1.58, owned))


static func xp_for_level(level: int) -> int:
	return 80 + (level - 1) * 55


static func format_money(value: float, include_decimals := false) -> String:
	var decimals := 2 if include_decimals and value < 1000.0 else 0
	var number_format := "%." + str(decimals) + "f"
	var raw := (number_format % value).replace(".", ",")
	var parts := raw.split(",")
	var integer := parts[0]
	var formatted := ""
	while integer.length() > 3:
		formatted = "." + integer.right(3) + formatted
		integer = integer.left(integer.length() - 3)
	formatted = integer + formatted
	if parts.size() > 1:
		formatted += "," + parts[1]
	return formatted + " €"
