class_name Lang
extends RefCounted

# Jezyki gry. Teksty sa w plikach scripts/i18n/*.gd jako
# "klucz": [pl, en, es, fr, de, pt, uk] - w kolejnosci CODES. Brakujace
# tlumaczenie zastepuje tekst polski, a brakujacy klucz - sam klucz.
# Jezyk wybiera gracz w ustawieniach; jest zapisany osobno dla kazdego konta.

const CODES := ["pl", "en", "es", "fr", "de", "pt", "uk"]
const NAMES := ["Polski", "English", "Español", "Français", "Deutsch", "Português", "Українська"]
const SOURCES := [
	preload("res://scripts/i18n/core.gd"),
	preload("res://scripts/i18n/game.gd"),
	preload("res://scripts/i18n/menus.gd"),
	preload("res://scripts/i18n/content.gd"),
	preload("res://scripts/i18n/addons.gd"),
	preload("res://scripts/i18n/guide.gd"),
	preload("res://scripts/i18n/quiz.gd"),
]

static var current := 0
static var _table := {}

static func _ensure_table() -> void:
	if not _table.is_empty():
		return
	for source in SOURCES:
		_table.merge(source.STRINGS)

static func t(key: String) -> String:
	_ensure_table()
	var entry = _table.get(key)
	if entry == null:
		return key
	if current < entry.size() and entry[current] != "":
		return entry[current]
	return entry[0]

# Tekst z wartosciami wstawionymi w miejsca %d i %s (w kolejnosci args).
static func f(key: String, args) -> String:
	return t(key) % args

static func has(key: String) -> bool:
	_ensure_table()
	return _table.has(key)

static func code() -> String:
	return CODES[current]

# Ustawia jezyk po kodzie (np. "en"); nieznany kod nic nie zmienia.
static func set_code(lang_code: String) -> void:
	var idx := CODES.find(lang_code)
	if idx >= 0:
		current = idx

# Jezyk telefonu, jesli gra go zna; inaczej polski.
static func device_code() -> String:
	var device := OS.get_locale_language()
	return device if CODES.has(device) else "pl"

static func all_keys() -> Array:
	_ensure_table()
	return _table.keys()
