class_name GameData
extends RefCounted

const JOBS: Array[Dictionary] = [
	{
		"id": "tap",
		"title": "Tropfender Wasserhahn",
		"customer": "Familie Krüger",
		"icon": "W",
		"duration": 15.0,
		"cooldown": 20.0,
		"reward": 75.0,
		"xp": 18,
		"level": 1,
		"location": "neighborhood",
		"color": Color("45c486"),
	},
	{
class_name GameData
extends RefCounted

const JOBS: Array[Dictionary] = [
	{
		"id": "tap",
		"title": "Tropfender Wasserhahn",
		"customer": "Familie Krüger",
		"icon": "W",
		"duration": 15.0,
		"cooldown": 20.0,
		"reward": 75.0,
		"xp": 18,
		"level": 1,
		"location": "neighborhood",
		"color": Color("35b9e6"),
	},
	{
		"id": "drain",
		"title": "Abfluss verstopft",
		"customer": "Café Morgenrot",
		"icon": "A",
		"duration": 30.0,
		"cooldown": 45.0,
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
		"duration": 60.0,
		"cooldown": 90.0,
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
		"duration": 150.0,
		"cooldown": 300.0,
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
		"duration": 40.0,
		"cooldown": 60.0,
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
		"duration": 75.0,
		"cooldown": 120.0,
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
		"duration": 90.0,
		"cooldown": 150.0,
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
		"duration": 180.0,
		"cooldown": 360.0,
		"reward": 1250.0,
		"xp": 165,
		"level": 7,
		"location": "villa_district",
		"color": Color("3aa7d8"),
	},
	{
		"id": "plant_room",
		"title": "Heizzentrale sanieren",
		"customer": "Residenz Bellevue",
		"icon": "HZ",
		"duration": 300.0,
		"cooldown": 600.0,
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
		"duration": 480.0,
		"cooldown": 900.0,
		"reward": 5200.0,
		"xp": 420,
		"level": 12,
		"location": "industrial_park",
		"color": Color("e0a83c"),
	},
	{
		"id": "school_heating",
		"title": "Schulheizung modernisieren",
		"customer": "Stadtwerke Bildungsbau",
		"icon": "GP",
		"duration": 900.0,
		"cooldown": 1800.0,
		"reward": 6800.0,
		"xp": 520,
		"level": 8,
		"reputation": 220,
		"major": true,
		"location": "downtown",
		"color": Color("edbd4f"),
	},
	{
		"id": "villa_energy",
		"title": "Villa energetisch sanieren",
		"customer": "Architekturbüro Kronberg",
		"icon": "GP",
		"duration": 1200.0,
		"cooldown": 2700.0,
		"reward": 11500.0,
		"xp": 760,
		"level": 10,
		"reputation": 380,
		"major": true,
		"location": "villa_district",
		"color": Color("e4c166"),
	},
	{
		"id": "production_hall",
		"title": "Produktionshalle umrüsten",
		"customer": "Rheinwerk Produktion",
		"icon": "GP",
		"duration": 1800.0,
		"cooldown": 3600.0,
		"reward": 22000.0,
		"xp": 1200,
		"level": 14,
		"reputation": 750,
		"major": true,
		"location": "industrial_park",
		"color": Color("dcab45"),
	},
	{
		"id": "clinic_energy_center",
		"title": "Klinik-Energiezentrale erneuern",
		"customer": "Klinikum West",
		"icon": "GP",
		"duration": 2700.0,
		"cooldown": 7200.0,
		"reward": 48000.0,
		"xp": 2100,
		"level": 18,
		"reputation": 1200,
		"major": true,
		"location": "industrial_park",
		"color": Color("f0c85c"),
	},
	{"id":"hotel_wing","title":"Hoteltrakt kernsanieren","customer":"Grand Hotel Elbe","icon":"HT","duration":3600.0,"cooldown":10800.0,"reward":76000.0,"xp":2800,"level":20,"reputation":1800,"major":true,"location":"harbor","color":Color("35a7d6")},
	{"id":"harbor_heat","title":"Hafenlager beheizen","customer":"Nordkai Logistik","icon":"HL","duration":2100.0,"cooldown":5400.0,"reward":34000.0,"xp":1550,"level":18,"location":"harbor","color":Color("4fb2cf")},
	{"id":"ship_service","title":"Schiffsanlage warten","customer":"Hanseatic Marine","icon":"SM","duration":3000.0,"cooldown":7200.0,"reward":58000.0,"xp":2300,"level":22,"reputation":2300,"major":true,"location":"harbor","color":Color("3987c6")},
	{"id":"airport_terminal","title":"Terminaltechnik erneuern","customer":"Airport Services","icon":"AT","duration":5400.0,"cooldown":14400.0,"reward":130000.0,"xp":4300,"level":26,"reputation":3500,"major":true,"location":"airport","color":Color("8c9df0")},
	{"id":"hangar_climate","title":"Hangarklima optimieren","customer":"AeroTech GmbH","icon":"HG","duration":3300.0,"cooldown":9000.0,"reward":82000.0,"xp":3000,"level":25,"location":"airport","color":Color("7888dc")},
	{"id":"data_center","title":"Rechenzentrum kühlen","customer":"Cloudwerk Europe","icon":"DC","duration":7200.0,"cooldown":21600.0,"reward":240000.0,"xp":6800,"level":31,"reputation":6200,"major":true,"location":"tech_park","color":Color("b56be8")},
	{"id":"research_lab","title":"Forschungslabor ausstatten","customer":"NovaLab Institute","icon":"FL","duration":6000.0,"cooldown":18000.0,"reward":185000.0,"xp":5600,"level":29,"location":"tech_park","color":Color("a36ee4")},
	{"id":"district_network","title":"Fernwärmenetz ausbauen","customer":"Metropol Energie","icon":"FN","duration":10800.0,"cooldown":28800.0,"reward":520000.0,"xp":12000,"level":38,"reputation":12000,"major":true,"location":"metropolis","color":Color("ef8a55")},
	{"id":"skyline_tower","title":"Skyline-Tower versorgen","customer":"Kronberg Development","icon":"ST","duration":14400.0,"cooldown":43200.0,"reward":950000.0,"xp":19000,"level":42,"reputation":18000,"major":true,"location":"metropolis","color":Color("f1b84a")},
]

const REVIEW_TEXTS: Dictionary = {
	"excellent": ["Außergewöhnlich sauber gearbeitet – klare Empfehlung!", "Perfekte Ausführung und ein sehr professionelles Team.", "Schnell, zuverlässig und besser als erwartet."],
	"good": ["Gute Arbeit, wir sind zufrieden.", "Termin und Ausführung haben gepasst.", "Ordentlich erledigt – gerne wieder."],
	"mixed": ["Das Ergebnis stimmt, bei den Details ist noch Luft nach oben.", "Insgesamt okay, die Ausführung könnte sorgfältiger sein.", "Auftrag erledigt, aber nicht ganz ohne Nacharbeit."],
}

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
	{"id":"harbor","title":"Hafenquartier","subtitle":"Logistik, Hotels und maritime Großanlagen","level":18,"multiplier":1.72,"code":"05"},
	{"id":"airport","title":"Flughafencity","subtitle":"Terminals, Hangars und internationale Kunden","level":25,"multiplier":1.94,"code":"06"},
	{"id":"tech_park","title":"Technologiepark","subtitle":"Labore, Rechenzentren und Präzisionstechnik","level":29,"multiplier":2.18,"code":"07"},
	{"id":"metropolis","title":"Metropole","subtitle":"Stadtweite Netze und die größten Bauprojekte","level":38,"multiplier":2.55,"code":"08"},
]

const DAILY_MISSIONS: Array[Dictionary] = [
	{"id": "jobs", "title": "Volle Auftragslage", "description": "5 Aufträge abschließen", "target": 5.0, "reward": 250.0, "metric": "jobs"},
	{"id": "earnings", "title": "Guter Umsatz", "description": "1.500 € verdienen", "target": 1500.0, "reward": 350.0, "metric": "earnings"},
	{"id": "invest", "title": "In die Zukunft", "description": "3 Verbesserungen kaufen", "target": 3.0, "reward": 400.0, "metric": "upgrades"},
	{"id": "streak", "title": "Zuverlässige Woche", "description": "Eine 4er-Auftragsserie erreichen", "target": 4.0, "reward": 300.0, "metric": "streak"},
	{"id": "quality", "title": "Saubere Arbeit", "description": "Mindestens 85 % Qualität erreichen", "target": 85.0, "reward": 325.0, "metric": "quality"},
	{"id":"jobs_long","title":"Langer Arbeitstag","description":"12 Aufträge abschließen","target":12.0,"reward":850.0,"metric":"jobs"},
	{"id":"earnings_big","title":"Umsatzkönig","description":"15.000 € verdienen","target":15000.0,"reward":1200.0,"metric":"earnings"},
]

const ACHIEVEMENTS: Array[Dictionary] = [
	{"id": "first_ten", "title": "Zehn geschafft", "description": "10 Aufträge erledigen", "target": 10.0, "metric": "jobs", "reward": 300.0},
	{"id": "team_three", "title": "Kleine Mannschaft", "description": "3 Mitarbeiter beschäftigen", "target": 3.0, "metric": "team", "reward": 500.0},
	{"id": "earn_10k", "title": "Fünfstellig", "description": "10.000 € insgesamt verdienen", "target": 10000.0, "metric": "lifetime", "reward": 900.0},
	{"id": "streak_five", "title": "Läuft bei dir", "description": "Eine 5er-Auftragsserie erreichen", "target": 5.0, "metric": "streak", "reward": 450.0},
	{"id": "first_contract", "title": "Fester Partner", "description": "Ersten Stammkundenvertrag abschließen", "target": 1.0, "metric": "contracts", "reward": 650.0},
	{"id": "reputation_350", "title": "In aller Munde", "description": "350 Reputation erreichen", "target": 350.0, "metric": "reputation", "reward": 1250.0},
	{"id": "first_major", "title": "Große Baustelle", "description": "Erstes Großprojekt abschließen", "target": 1.0, "metric": "major", "reward": 1800.0},
	{"id": "quality_master", "title": "Qualitätsbetrieb", "description": "Eine Kundenbewertung von 4,8 erreichen", "target": 4.8, "metric": "rating", "reward": 2400.0},
	{"id": "jobs_25", "title": "Gut gebucht", "description": "25 Aufträge erledigen", "target": 25.0, "metric": "jobs", "reward": 750.0},
	{"id": "jobs_75", "title": "Volle Bücher", "description": "75 Aufträge erledigen", "target": 75.0, "metric": "jobs", "reward": 2200.0},
	{"id": "team_six", "title": "Einsatzgruppe", "description": "6 Mitarbeiter beschäftigen", "target": 6.0, "metric": "team", "reward": 1400.0},
	{"id": "team_twelve", "title": "Montageteam", "description": "12 Mitarbeiter beschäftigen", "target": 12.0, "metric": "team", "reward": 3600.0},
	{"id": "earn_50k", "title": "Solider Betrieb", "description": "50.000 € insgesamt verdienen", "target": 50000.0, "metric": "lifetime", "reward": 2500.0},
	{"id": "earn_250k", "title": "Handwerks-Imperium", "description": "250.000 € insgesamt verdienen", "target": 250000.0, "metric": "lifetime", "reward": 8500.0},
	{"id": "reputation_700", "title": "Industrie-Partner", "description": "700 Reputation erreichen", "target": 700.0, "metric": "reputation", "reward": 3200.0},
	{"id": "reputation_1200", "title": "Überregional gefragt", "description": "1.200 Reputation erreichen", "target": 1200.0, "metric": "reputation", "reward": 6000.0},
	{"id": "major_three", "title": "Großprojekt-Profi", "description": "3 Großprojekte abschließen", "target": 3.0, "metric": "major", "reward": 5000.0},
	{"id": "streak_ten", "title": "Unaufhaltsam", "description": "Eine 10er-Auftragsserie erreichen", "target": 10.0, "metric": "streak", "reward": 2800.0},
	{"id":"jobs_150","title":"Dauerbrenner","description":"150 Aufträge erledigen","target":150.0,"metric":"jobs","reward":6000.0},
	{"id":"jobs_300","title":"Volle Auftragsbücher","description":"300 Aufträge erledigen","target":300.0,"metric":"jobs","reward":15000.0},
	{"id":"jobs_750","title":"Handwerkslegende","description":"750 Aufträge erledigen","target":750.0,"metric":"jobs","reward":40000.0},
	{"id":"earn_1m","title":"Erste Million","description":"1.000.000 € insgesamt verdienen","target":1000000.0,"metric":"lifetime","reward":30000.0},
	{"id":"earn_10m","title":"Bauimperium","description":"10.000.000 € insgesamt verdienen","target":10000000.0,"metric":"lifetime","reward":120000.0},
	{"id":"team_25","title":"Großbetrieb","description":"25 Mitarbeiter beschäftigen","target":25.0,"metric":"team","reward":18000.0},
	{"id":"team_50","title":"Unternehmensgruppe","description":"50 Mitarbeiter beschäftigen","target":50.0,"metric":"team","reward":50000.0},
	{"id":"rep_2500","title":"Landesweit gefragt","description":"2.500 Ruf erreichen","target":2500.0,"metric":"reputation","reward":16000.0},
	{"id":"rep_7500","title":"Branchenname","description":"7.500 Ruf erreichen","target":7500.0,"metric":"reputation","reward":45000.0},
	{"id":"major_10","title":"Projektgigant","description":"10 Großprojekte abschließen","target":10.0,"metric":"major","reward":25000.0},
	{"id":"major_25","title":"Infrastruktur-Profi","description":"25 Großprojekte abschließen","target":25.0,"metric":"major","reward":80000.0},
	{"id":"streak_25","title":"Perfekter Lauf","description":"Eine 25er-Serie erreichen","target":25.0,"metric":"streak","reward":15000.0},
	{"id":"mastery_1","title":"Meisterbrief","description":"Ersten Meisterpunkt verdienen","target":1.0,"metric":"mastery","reward":5000.0},
	{"id":"prestige_3","title":"Dritte Generation","description":"Dreimal neu gründen","target":3.0,"metric":"prestige","reward":25000.0},
	{"id":"prestige_10","title":"Handwerksdynastie","description":"Zehnmal neu gründen","target":10.0,"metric":"prestige","reward":100000.0},
]

const JOB_EVENTS: Array[Dictionary] = [
	{
		"id": "express",
		"title": "Express-Auftrag",
		"description": "Der Kunde braucht sofort Hilfe.",
		"reward_multiplier": 1.35,
		"duration_multiplier": 0.72,
		"xp_multiplier": 1.15,
		"code": "EX",
	},
	{
		"id": "premium_material",
		"title": "Premium-Material",
		"description": "Hochwertige Teile erhöhen den Auftragswert.",
		"reward_multiplier": 1.55,
		"duration_multiplier": 1.18,
		"xp_multiplier": 1.25,
		"code": "PM",
	},
	{
		"id": "recommendation",
		"title": "Kundenempfehlung",
		"description": "Gute Arbeit spricht sich herum.",
		"reward_multiplier": 1.2,
		"duration_multiplier": 1.0,
		"xp_multiplier": 1.75,
		"code": "KE",
	},
]

const CONTRACTS: Array[Dictionary] = [
	{"id": "property_service", "title": "Hausverwaltungs-Service", "client": "Hausverwaltung Nord", "description": "Regelmäßige Kleinreparaturen in Mietobjekten", "level": 3, "reputation": 35, "payout": 180.0, "interval": 1800.0, "code": "HV"},
	{"id": "gastronomy_service", "title": "Gastro-Wartungsvertrag", "client": "Morgenrot Gastronomie", "description": "Sanitär- und Heizungsbereitschaft für drei Filialen", "level": 5, "reputation": 110, "payout": 520.0, "interval": 2400.0, "code": "GW"},
	{"id": "premium_estates", "title": "Premium-Objektbetreuung", "client": "Residenz Bellevue", "description": "Exklusive Anlagenbetreuung im Villenviertel", "level": 8, "reputation": 260, "payout": 1450.0, "interval": 3600.0, "code": "PO"},
	{"id": "industrial_maintenance", "title": "Industrie-Rahmenvertrag", "client": "Kraftwerk Technik AG", "description": "Langfristige Wartung kritischer Großanlagen", "level": 12, "reputation": 600, "payout": 4800.0, "interval": 5400.0, "code": "IR"},
]

const REPUTATION_RANKS: Array[Dictionary] = [
	{"title": "Neuer Betrieb", "minimum": 0, "code": "R1"},
	{"title": "Lokaler Profi", "minimum": 50, "code": "R2"},
	{"title": "Gefragter Meisterbetrieb", "minimum": 150, "code": "R3"},
	{"title": "Regionale Größe", "minimum": 350, "code": "R4"},
	{"title": "Industrie-Partner", "minimum": 700, "code": "R5"},
	{"title":"Überregional gefragt","minimum":1800,"code":"R6"},
	{"title":"Infrastruktur-Profi","minimum":5000,"code":"R7"},
	{"title":"Handwerkslegende","minimum":12000,"code":"R8"},
]

const TEAM_RANKS: Array[Dictionary] = [
	{"title": "Solo-Betrieb", "minimum": 0, "quality_bonus": 0, "code": "T1"},
	{"title": "Erstes Team", "minimum": 1, "quality_bonus": 1, "code": "T2"},
	{"title": "Einsatzgruppe", "minimum": 3, "quality_bonus": 2, "code": "T3"},
	{"title": "Starker Betrieb", "minimum": 6, "quality_bonus": 3, "code": "T4"},
	{"title": "Großes Montageteam", "minimum": 12, "quality_bonus": 5, "code": "T5"},
	{"title":"Großbetrieb","minimum":25,"quality_bonus":7,"code":"T6"},
	{"title":"Unternehmensgruppe","minimum":50,"quality_bonus":10,"code":"T7"},
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
		"title": "Azubi",
		"trade": "Sanitär",
		"income": 0.08,
		"base_cost": 350.0,
		"color": Color("35b9e6"),
	},
	{
		"id": "monteur",
		"title": "Monteur",
		"trade": "Heizung",
		"income": 0.32,
		"base_cost": 1350.0,
		"color": Color("f2a649"),
	},
	{
		"id": "meisterin",
		"title": "Meisterin",
		"trade": "Projektleitung",
		"income": 1.1,
		"base_cost": 4800.0,
		"color": Color("7591f7"),
	},
]

static func upgrade_cost(upgrade: Dictionary, current_level: int) -> float:
	return round(float(upgrade.base_cost) * pow(float(upgrade.growth), current_level))


static func employee_cost(employee: Dictionary, owned: int) -> float:
	return round(float(employee.base_cost) * pow(1.52, owned))


static func xp_for_level(level: int) -> int:
	var completed_levels := level - 1
	return 140 + completed_levels * 90 + completed_levels * completed_levels * 8


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
		"id": "drain",
		"title": "Abfluss verstopft",
		"customer": "Café Morgenrot",
		"icon": "A",
		"duration": 30.0,
		"cooldown": 45.0,
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
		"duration": 60.0,
		"cooldown": 90.0,
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
		"duration": 150.0,
		"cooldown": 300.0,
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
		"duration": 40.0,
		"cooldown": 60.0,
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
		"duration": 75.0,
		"cooldown": 120.0,
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
		"duration": 90.0,
		"cooldown": 150.0,
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
		"duration": 180.0,
		"cooldown": 360.0,
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
		"duration": 300.0,
		"cooldown": 600.0,
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
		"duration": 480.0,
		"cooldown": 900.0,
		"reward": 5200.0,
		"xp": 420,
		"level": 12,
		"location": "industrial_park",
		"color": Color("e0a83c"),
	},
	{
		"id": "school_heating",
		"title": "Schulheizung modernisieren",
		"customer": "Stadtwerke Bildungsbau",
		"icon": "GP",
		"duration": 900.0,
		"cooldown": 1800.0,
		"reward": 6800.0,
		"xp": 520,
		"level": 8,
		"reputation": 220,
		"major": true,
		"location": "downtown",
		"color": Color("edbd4f"),
	},
	{
		"id": "villa_energy",
		"title": "Villa energetisch sanieren",
		"customer": "Architekturbüro Kronberg",
		"icon": "GP",
		"duration": 1200.0,
		"cooldown": 2700.0,
		"reward": 11500.0,
		"xp": 760,
		"level": 10,
		"reputation": 380,
		"major": true,
		"location": "villa_district",
		"color": Color("e4c166"),
	},
	{
		"id": "production_hall",
		"title": "Produktionshalle umrüsten",
		"customer": "Rheinwerk Produktion",
		"icon": "GP",
		"duration": 1800.0,
		"cooldown": 3600.0,
		"reward": 22000.0,
		"xp": 1200,
		"level": 14,
		"reputation": 750,
		"major": true,
		"location": "industrial_park",
		"color": Color("dcab45"),
	},
	{
		"id": "clinic_energy_center",
		"title": "Klinik-Energiezentrale erneuern",
		"customer": "Klinikum West",
		"icon": "GP",
		"duration": 2700.0,
		"cooldown": 7200.0,
		"reward": 48000.0,
		"xp": 2100,
		"level": 18,
		"reputation": 1200,
		"major": true,
		"location": "industrial_park",
		"color": Color("f0c85c"),
	},
	{"id":"hotel_wing","title":"Hoteltrakt kernsanieren","customer":"Grand Hotel Elbe","icon":"HT","duration":3600.0,"cooldown":10800.0,"reward":76000.0,"xp":2800,"level":20,"reputation":1800,"major":true,"location":"harbor","color":Color("48b9b0")},
	{"id":"harbor_heat","title":"Hafenlager beheizen","customer":"Nordkai Logistik","icon":"HL","duration":2100.0,"cooldown":5400.0,"reward":34000.0,"xp":1550,"level":18,"location":"harbor","color":Color("4fb2cf")},
	{"id":"ship_service","title":"Schiffsanlage warten","customer":"Hanseatic Marine","icon":"SM","duration":3000.0,"cooldown":7200.0,"reward":58000.0,"xp":2300,"level":22,"reputation":2300,"major":true,"location":"harbor","color":Color("3987c6")},
	{"id":"airport_terminal","title":"Terminaltechnik erneuern","customer":"Airport Services","icon":"AT","duration":5400.0,"cooldown":14400.0,"reward":130000.0,"xp":4300,"level":26,"reputation":3500,"major":true,"location":"airport","color":Color("8c9df0")},
	{"id":"hangar_climate","title":"Hangarklima optimieren","customer":"AeroTech GmbH","icon":"HG","duration":3300.0,"cooldown":9000.0,"reward":82000.0,"xp":3000,"level":25,"location":"airport","color":Color("7888dc")},
	{"id":"data_center","title":"Rechenzentrum kühlen","customer":"Cloudwerk Europe","icon":"DC","duration":7200.0,"cooldown":21600.0,"reward":240000.0,"xp":6800,"level":31,"reputation":6200,"major":true,"location":"tech_park","color":Color("b56be8")},
	{"id":"research_lab","title":"Forschungslabor ausstatten","customer":"NovaLab Institute","icon":"FL","duration":6000.0,"cooldown":18000.0,"reward":185000.0,"xp":5600,"level":29,"location":"tech_park","color":Color("a36ee4")},
	{"id":"district_network","title":"Fernwärmenetz ausbauen","customer":"Metropol Energie","icon":"FN","duration":10800.0,"cooldown":28800.0,"reward":520000.0,"xp":12000,"level":38,"reputation":12000,"major":true,"location":"metropolis","color":Color("ef8a55")},
	{"id":"skyline_tower","title":"Skyline-Tower versorgen","customer":"Kronberg Development","icon":"ST","duration":14400.0,"cooldown":43200.0,"reward":950000.0,"xp":19000,"level":42,"reputation":18000,"major":true,"location":"metropolis","color":Color("f1b84a")},
]

const REVIEW_TEXTS: Dictionary = {
	"excellent": ["Außergewöhnlich sauber gearbeitet – klare Empfehlung!", "Perfekte Ausführung und ein sehr professionelles Team.", "Schnell, zuverlässig und besser als erwartet."],
	"good": ["Gute Arbeit, wir sind zufrieden.", "Termin und Ausführung haben gepasst.", "Ordentlich erledigt – gerne wieder."],
	"mixed": ["Das Ergebnis stimmt, bei den Details ist noch Luft nach oben.", "Insgesamt okay, die Ausführung könnte sorgfältiger sein.", "Auftrag erledigt, aber nicht ganz ohne Nacharbeit."],
}

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
	{"id":"harbor","title":"Hafenquartier","subtitle":"Logistik, Hotels und maritime Großanlagen","level":18,"multiplier":1.72,"code":"05"},
	{"id":"airport","title":"Flughafencity","subtitle":"Terminals, Hangars und internationale Kunden","level":25,"multiplier":1.94,"code":"06"},
	{"id":"tech_park","title":"Technologiepark","subtitle":"Labore, Rechenzentren und Präzisionstechnik","level":29,"multiplier":2.18,"code":"07"},
	{"id":"metropolis","title":"Metropole","subtitle":"Stadtweite Netze und die größten Bauprojekte","level":38,"multiplier":2.55,"code":"08"},
]

const DAILY_MISSIONS: Array[Dictionary] = [
	{"id": "jobs", "title": "Volle Auftragslage", "description": "5 Aufträge abschließen", "target": 5.0, "reward": 250.0, "metric": "jobs"},
	{"id": "earnings", "title": "Guter Umsatz", "description": "1.500 € verdienen", "target": 1500.0, "reward": 350.0, "metric": "earnings"},
	{"id": "invest", "title": "In die Zukunft", "description": "3 Verbesserungen kaufen", "target": 3.0, "reward": 400.0, "metric": "upgrades"},
	{"id": "streak", "title": "Zuverlässige Woche", "description": "Eine 4er-Auftragsserie erreichen", "target": 4.0, "reward": 300.0, "metric": "streak"},
	{"id": "quality", "title": "Saubere Arbeit", "description": "Mindestens 85 % Qualität erreichen", "target": 85.0, "reward": 325.0, "metric": "quality"},
	{"id":"jobs_long","title":"Langer Arbeitstag","description":"12 Aufträge abschließen","target":12.0,"reward":850.0,"metric":"jobs"},
	{"id":"earnings_big","title":"Umsatzkönig","description":"15.000 € verdienen","target":15000.0,"reward":1200.0,"metric":"earnings"},
]

const ACHIEVEMENTS: Array[Dictionary] = [
	{"id": "first_ten", "title": "Zehn geschafft", "description": "10 Aufträge erledigen", "target": 10.0, "metric": "jobs", "reward": 300.0},
	{"id": "team_three", "title": "Kleine Mannschaft", "description": "3 Mitarbeiter beschäftigen", "target": 3.0, "metric": "team", "reward": 500.0},
	{"id": "earn_10k", "title": "Fünfstellig", "description": "10.000 € insgesamt verdienen", "target": 10000.0, "metric": "lifetime", "reward": 900.0},
	{"id": "streak_five", "title": "Läuft bei dir", "description": "Eine 5er-Auftragsserie erreichen", "target": 5.0, "metric": "streak", "reward": 450.0},
	{"id": "first_contract", "title": "Fester Partner", "description": "Ersten Stammkundenvertrag abschließen", "target": 1.0, "metric": "contracts", "reward": 650.0},
	{"id": "reputation_350", "title": "In aller Munde", "description": "350 Reputation erreichen", "target": 350.0, "metric": "reputation", "reward": 1250.0},
	{"id": "first_major", "title": "Große Baustelle", "description": "Erstes Großprojekt abschließen", "target": 1.0, "metric": "major", "reward": 1800.0},
	{"id": "quality_master", "title": "Qualitätsbetrieb", "description": "Eine Kundenbewertung von 4,8 erreichen", "target": 4.8, "metric": "rating", "reward": 2400.0},
	{"id": "jobs_25", "title": "Gut gebucht", "description": "25 Aufträge erledigen", "target": 25.0, "metric": "jobs", "reward": 750.0},
	{"id": "jobs_75", "title": "Volle Bücher", "description": "75 Aufträge erledigen", "target": 75.0, "metric": "jobs", "reward": 2200.0},
	{"id": "team_six", "title": "Einsatzgruppe", "description": "6 Mitarbeiter beschäftigen", "target": 6.0, "metric": "team", "reward": 1400.0},
	{"id": "team_twelve", "title": "Montageteam", "description": "12 Mitarbeiter beschäftigen", "target": 12.0, "metric": "team", "reward": 3600.0},
	{"id": "earn_50k", "title": "Solider Betrieb", "description": "50.000 € insgesamt verdienen", "target": 50000.0, "metric": "lifetime", "reward": 2500.0},
	{"id": "earn_250k", "title": "Handwerks-Imperium", "description": "250.000 € insgesamt verdienen", "target": 250000.0, "metric": "lifetime", "reward": 8500.0},
	{"id": "reputation_700", "title": "Industrie-Partner", "description": "700 Reputation erreichen", "target": 700.0, "metric": "reputation", "reward": 3200.0},
	{"id": "reputation_1200", "title": "Überregional gefragt", "description": "1.200 Reputation erreichen", "target": 1200.0, "metric": "reputation", "reward": 6000.0},
	{"id": "major_three", "title": "Großprojekt-Profi", "description": "3 Großprojekte abschließen", "target": 3.0, "metric": "major", "reward": 5000.0},
	{"id": "streak_ten", "title": "Unaufhaltsam", "description": "Eine 10er-Auftragsserie erreichen", "target": 10.0, "metric": "streak", "reward": 2800.0},
	{"id":"jobs_150","title":"Dauerbrenner","description":"150 Aufträge erledigen","target":150.0,"metric":"jobs","reward":6000.0},
	{"id":"jobs_300","title":"Volle Auftragsbücher","description":"300 Aufträge erledigen","target":300.0,"metric":"jobs","reward":15000.0},
	{"id":"jobs_750","title":"Handwerkslegende","description":"750 Aufträge erledigen","target":750.0,"metric":"jobs","reward":40000.0},
	{"id":"earn_1m","title":"Erste Million","description":"1.000.000 € insgesamt verdienen","target":1000000.0,"metric":"lifetime","reward":30000.0},
	{"id":"earn_10m","title":"Bauimperium","description":"10.000.000 € insgesamt verdienen","target":10000000.0,"metric":"lifetime","reward":120000.0},
	{"id":"team_25","title":"Großbetrieb","description":"25 Mitarbeiter beschäftigen","target":25.0,"metric":"team","reward":18000.0},
	{"id":"team_50","title":"Unternehmensgruppe","description":"50 Mitarbeiter beschäftigen","target":50.0,"metric":"team","reward":50000.0},
	{"id":"rep_2500","title":"Landesweit gefragt","description":"2.500 Ruf erreichen","target":2500.0,"metric":"reputation","reward":16000.0},
	{"id":"rep_7500","title":"Branchenname","description":"7.500 Ruf erreichen","target":7500.0,"metric":"reputation","reward":45000.0},
	{"id":"major_10","title":"Projektgigant","description":"10 Großprojekte abschließen","target":10.0,"metric":"major","reward":25000.0},
	{"id":"major_25","title":"Infrastruktur-Profi","description":"25 Großprojekte abschließen","target":25.0,"metric":"major","reward":80000.0},
	{"id":"streak_25","title":"Perfekter Lauf","description":"Eine 25er-Serie erreichen","target":25.0,"metric":"streak","reward":15000.0},
	{"id":"mastery_1","title":"Meisterbrief","description":"Ersten Meisterpunkt verdienen","target":1.0,"metric":"mastery","reward":5000.0},
	{"id":"prestige_3","title":"Dritte Generation","description":"Dreimal neu gründen","target":3.0,"metric":"prestige","reward":25000.0},
	{"id":"prestige_10","title":"Handwerksdynastie","description":"Zehnmal neu gründen","target":10.0,"metric":"prestige","reward":100000.0},
]

const JOB_EVENTS: Array[Dictionary] = [
	{
		"id": "express",
		"title": "Express-Auftrag",
		"description": "Der Kunde braucht sofort Hilfe.",
		"reward_multiplier": 1.35,
		"duration_multiplier": 0.72,
		"xp_multiplier": 1.15,
		"code": "EX",
	},
	{
		"id": "premium_material",
		"title": "Premium-Material",
		"description": "Hochwertige Teile erhöhen den Auftragswert.",
		"reward_multiplier": 1.55,
		"duration_multiplier": 1.18,
		"xp_multiplier": 1.25,
		"code": "PM",
	},
	{
		"id": "recommendation",
		"title": "Kundenempfehlung",
		"description": "Gute Arbeit spricht sich herum.",
		"reward_multiplier": 1.2,
		"duration_multiplier": 1.0,
		"xp_multiplier": 1.75,
		"code": "KE",
	},
]

const CONTRACTS: Array[Dictionary] = [
	{"id": "property_service", "title": "Hausverwaltungs-Service", "client": "Hausverwaltung Nord", "description": "Regelmäßige Kleinreparaturen in Mietobjekten", "level": 3, "reputation": 35, "payout": 180.0, "interval": 1800.0, "code": "HV"},
	{"id": "gastronomy_service", "title": "Gastro-Wartungsvertrag", "client": "Morgenrot Gastronomie", "description": "Sanitär- und Heizungsbereitschaft für drei Filialen", "level": 5, "reputation": 110, "payout": 520.0, "interval": 2400.0, "code": "GW"},
	{"id": "premium_estates", "title": "Premium-Objektbetreuung", "client": "Residenz Bellevue", "description": "Exklusive Anlagenbetreuung im Villenviertel", "level": 8, "reputation": 260, "payout": 1450.0, "interval": 3600.0, "code": "PO"},
	{"id": "industrial_maintenance", "title": "Industrie-Rahmenvertrag", "client": "Kraftwerk Technik AG", "description": "Langfristige Wartung kritischer Großanlagen", "level": 12, "reputation": 600, "payout": 4800.0, "interval": 5400.0, "code": "IR"},
]

const REPUTATION_RANKS: Array[Dictionary] = [
	{"title": "Neuer Betrieb", "minimum": 0, "code": "R1"},
	{"title": "Lokaler Profi", "minimum": 50, "code": "R2"},
	{"title": "Gefragter Meisterbetrieb", "minimum": 150, "code": "R3"},
	{"title": "Regionale Größe", "minimum": 350, "code": "R4"},
	{"title": "Industrie-Partner", "minimum": 700, "code": "R5"},
	{"title":"Überregional gefragt","minimum":1800,"code":"R6"},
	{"title":"Infrastruktur-Profi","minimum":5000,"code":"R7"},
	{"title":"Handwerkslegende","minimum":12000,"code":"R8"},
]

const TEAM_RANKS: Array[Dictionary] = [
	{"title": "Solo-Betrieb", "minimum": 0, "quality_bonus": 0, "code": "T1"},
	{"title": "Erstes Team", "minimum": 1, "quality_bonus": 1, "code": "T2"},
	{"title": "Einsatzgruppe", "minimum": 3, "quality_bonus": 2, "code": "T3"},
	{"title": "Starker Betrieb", "minimum": 6, "quality_bonus": 3, "code": "T4"},
	{"title": "Großes Montageteam", "minimum": 12, "quality_bonus": 5, "code": "T5"},
	{"title":"Großbetrieb","minimum":25,"quality_bonus":7,"code":"T6"},
	{"title":"Unternehmensgruppe","minimum":50,"quality_bonus":10,"code":"T7"},
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
		"title": "Azubi",
		"trade": "Sanitär",
		"income": 0.08,
		"base_cost": 350.0,
		"color": Color("55c890"),
	},
	{
		"id": "monteur",
		"title": "Monteur",
		"trade": "Heizung",
		"income": 0.32,
		"base_cost": 1350.0,
		"color": Color("f2a649"),
	},
	{
		"id": "meisterin",
		"title": "Meisterin",
		"trade": "Projektleitung",
		"income": 1.1,
		"base_cost": 4800.0,
		"color": Color("7591f7"),
	},
]

static func upgrade_cost(upgrade: Dictionary, current_level: int) -> float:
	return round(float(upgrade.base_cost) * pow(float(upgrade.growth), current_level))


static func employee_cost(employee: Dictionary, owned: int) -> float:
	return round(float(employee.base_cost) * pow(1.52, owned))


static func xp_for_level(level: int) -> int:
	var completed_levels := level - 1
	return 140 + completed_levels * 90 + completed_levels * completed_levels * 8


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
