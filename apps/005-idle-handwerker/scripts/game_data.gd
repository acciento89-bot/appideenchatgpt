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
		"location": "neighborhood",
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
		"location": "neighborhood",
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
		"location": "downtown",
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
		"location": "villa_district",
		"color": Color("6f8df6"),
	},
	{
		"id": "toilet",
		"title": "Spülkasten reparieren",
		"customer": "Praxis am Markt",
		"icon": "SP",
		"duration": 9.0,
		"reward": 215.0,
		"xp": 44,
		"level": 2,
		"location": "neighborhood",
		"color": Color("58b9d8"),
	},
	{
		"id": "radiator",
		"title": "Heizkörper erneuern",
		"customer": "Altbau Schillerstraße",
		"icon": "HK",
		"duration": 15.0,
		"reward": 440.0,
		"xp": 76,
		"level": 4,
		"location": "downtown",
		"color": Color("e1785f"),
	},
	{
		"id": "floor_heating",
		"title": "Fußbodenheizung prüfen",
		"customer": "Loftwerk GmbH",
		"icon": "FB",
		"duration": 18.0,
		"reward": 620.0,
		"xp": 94,
		"level": 5,
		"location": "downtown",
		"color": Color("d99754"),
	},
	{
		"id": "heatpump",
		"title": "Wärmepumpe in Betrieb nehmen",
		"customer": "Familie Winter",
		"icon": "WP",
		"duration": 26.0,
		"reward": 1250.0,
		"xp": 165,
		"level": 7,
		"location": "villa_district",
		"color": Color("54c7a2"),
	},
	{
		"id": "plant_room",
		"title": "Heizzentrale sanieren",
		"customer": "Residenz Bellevue",
		"icon": "HZ",
		"duration": 34.0,
		"reward": 2400.0,
		"xp": 250,
		"level": 9,
		"location": "villa_district",
		"color": Color("a079e8"),
	},
	{
		"id": "industrial",
		"title": "Industrieanlage warten",
		"customer": "Kraftwerk Technik AG",
		"icon": "IN",
		"duration": 48.0,
		"reward": 5200.0,
		"xp": 420,
		"level": 12,
		"location": "industrial_park",
		"color": Color("e0a83c"),
	},
]

const LOCATIONS: Array[Dictionary] = [
	{
		"id": "neighborhood",
		"title": "Nachbarschaft",
		"subtitle": "Kleine Reparaturen und erste Stammkunden",
		"level": 1,
		"multiplier": 1.0,
		"code": "01",
	},
	{
		"id": "downtown",
		"title": "Innenstadt",
		"subtitle": "Gewerbe, Altbau und anspruchsvolle Anlagen",
		"level": 3,
		"multiplier": 1.12,
		"code": "02",
	},
	{
		"id": "villa_district",
		"title": "Villenviertel",
		"subtitle": "Premiumkunden und komplette Modernisierungen",
		"level": 5,
		"multiplier": 1.28,
		"code": "03",
	},
	{
		"id": "industrial_park",
		"title": "Industriepark",
		"subtitle": "Großanlagen, Wartungsverträge und Top-Umsätze",
		"level": 12,
		"multiplier": 1.55,
		"code": "04",
	},
]

const DAILY_MISSIONS: Array[Dictionary] = [
	{"id": "jobs", "title": "Volle Auftragslage", "description": "3 Aufträge abschließen", "target": 3.0, "reward": 250.0, "metric": "jobs"},
	{"id": "earnings", "title": "Guter Umsatz", "description": "800 € verdienen", "target": 800.0, "reward": 350.0, "metric": "earnings"},
	{"id": "invest", "title": "In die Zukunft", "description": "2 Verbesserungen kaufen", "target": 2.0, "reward": 400.0, "metric": "upgrades"},
]

const ACHIEVEMENTS: Array[Dictionary] = [
	{"id": "first_ten", "title": "Zehn geschafft", "description": "10 Aufträge erledigen", "target": 10.0, "metric": "jobs", "reward": 300.0},
	{"id": "team_three", "title": "Kleine Mannschaft", "description": "3 Mitarbeiter beschäftigen", "target": 3.0, "metric": "team", "reward": 500.0},
	{"id": "earn_10k", "title": "Fünfstellig", "description": "10.000 € insgesamt verdienen", "target": 10000.0, "metric": "lifetime", "reward": 900.0},
	{"id": "streak_five", "title": "Läuft bei dir", "description": "Eine 5er-Auftragsserie erreichen", "target": 5.0, "metric": "streak", "reward": 450.0},
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
	var decimals := 2 if include_decimals else 0
	var number_format := "%." + str(decimals) + "f"
	var raw := (number_format % value).replace(".", ",")
	var parts := raw.split(",")
	var integer := parts[0]
	var formatted := ""
	while integer.length() > 3:
		formatted = "." + integer.substr(integer.length() - 3, 3) + formatted
		integer = integer.substr(0, integer.length() - 3)
	formatted = integer + formatted
	if parts.size() > 1:
		formatted += "," + parts[1]
	return formatted + " €"
