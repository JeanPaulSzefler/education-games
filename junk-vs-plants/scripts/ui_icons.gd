class_name UiIcons
extends RefCounted

# Proste ikonki interfejsu rysowane w kodzie (Polygon2D/Line2D wewnatrz
# Control), bez dodatkowych plikow graficznych - jak animacje z rundy C.
# Kazda funkcja zwraca Control o rozmiarze size x size, ktory nie lapie
# klikniec (mouse_filter IGNORE), wiec mozna go wlozyc do przycisku.

const RUBY_COLOR := Color(0.85, 0.1, 0.3)
const RUBY_LIGHT_COLOR := Color(1.0, 0.45, 0.6)
const RUBY_DARK_COLOR := Color(0.55, 0.04, 0.18)

static func _box(size: float) -> Control:
	var c := Control.new()
	c.size = Vector2(size, size)
	c.custom_minimum_size = Vector2(size, size)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c

static func _poly(parent: Control, size: float, points: Array, color: Color) -> void:
	var p := Polygon2D.new()
	var pts := PackedVector2Array()
	for pt in points:
		pts.append(pt * size)
	p.polygon = pts
	p.color = color
	parent.add_child(p)

static func _line(parent: Control, size: float, points: Array, color: Color, width: float) -> void:
	var l := Line2D.new()
	for pt in points:
		l.add_point(pt * size)
	l.default_color = color
	l.width = width
	l.joint_mode = Line2D.LINE_JOINT_ROUND
	l.begin_cap_mode = Line2D.LINE_CAP_ROUND
	l.end_cap_mode = Line2D.LINE_CAP_ROUND
	parent.add_child(l)

# Rubin (waluta za wygrane poziomy).
static func ruby(size: float) -> Control:
	var c := _box(size)
	_poly(c, size, [Vector2(0.25, 0.12), Vector2(0.75, 0.12), Vector2(0.98, 0.38),
		Vector2(0.5, 0.94), Vector2(0.02, 0.38)], RUBY_COLOR)
	_poly(c, size, [Vector2(0.02, 0.38), Vector2(0.98, 0.38), Vector2(0.5, 0.94)], RUBY_DARK_COLOR)
	_poly(c, size, [Vector2(0.3, 0.38), Vector2(0.7, 0.38), Vector2(0.5, 0.94)], RUBY_COLOR)
	_poly(c, size, [Vector2(0.25, 0.12), Vector2(0.45, 0.12), Vector2(0.3, 0.38), Vector2(0.1, 0.32)], RUBY_LIGHT_COLOR)
	return c

# Otwarta ksiazka ("Opis gry").
static func book(size: float) -> Control:
	var c := _box(size)
	var cover := Color(0.45, 0.28, 0.12)
	var page := Color(0.97, 0.94, 0.85)
	var ink := Color(0.45, 0.45, 0.5)
	_poly(c, size, [Vector2(0.04, 0.2), Vector2(0.96, 0.2), Vector2(0.96, 0.86), Vector2(0.04, 0.86)], cover)
	_poly(c, size, [Vector2(0.08, 0.16), Vector2(0.48, 0.2), Vector2(0.48, 0.8), Vector2(0.08, 0.78)], page)
	_poly(c, size, [Vector2(0.52, 0.2), Vector2(0.92, 0.16), Vector2(0.92, 0.78), Vector2(0.52, 0.8)], page)
	for y in [0.32, 0.44, 0.56, 0.68]:
		_line(c, size, [Vector2(0.15, y), Vector2(0.41, y)], ink, max(1.5, size * 0.03))
		_line(c, size, [Vector2(0.59, y), Vector2(0.85, y)], ink, max(1.5, size * 0.03))
	return c

# Koszyk ("Sklep").
static func shop(size: float) -> Control:
	var c := _box(size)
	var handle := Color(0.5, 0.3, 0.12)
	_line(c, size, [Vector2(0.28, 0.44), Vector2(0.32, 0.22), Vector2(0.5, 0.12),
		Vector2(0.68, 0.22), Vector2(0.72, 0.44)], handle, max(2.0, size * 0.07))
	_poly(c, size, [Vector2(0.06, 0.4), Vector2(0.94, 0.4), Vector2(0.82, 0.9), Vector2(0.18, 0.9)], Color(0.85, 0.6, 0.25))
	var weave := Color(0.6, 0.38, 0.12)
	for x in [0.32, 0.5, 0.68]:
		_line(c, size, [Vector2(x, 0.44), Vector2(x, 0.86)], weave, max(1.5, size * 0.035))
	_line(c, size, [Vector2(0.1, 0.62), Vector2(0.9, 0.62)], weave, max(1.5, size * 0.035))
	return c

# Trojkat "graj" (wznowienie po pauzie).
static func play(size: float, color := Color(1, 1, 1)) -> Control:
	var c := _box(size)
	_poly(c, size, [Vector2(0.28, 0.16), Vector2(0.86, 0.5), Vector2(0.28, 0.84)], color)
	return c

# Dwie pionowe kreski "pauza".
static func pause(size: float, color := Color(1, 1, 1)) -> Control:
	var c := _box(size)
	_poly(c, size, [Vector2(0.24, 0.18), Vector2(0.42, 0.18), Vector2(0.42, 0.82), Vector2(0.24, 0.82)], color)
	_poly(c, size, [Vector2(0.58, 0.18), Vector2(0.76, 0.18), Vector2(0.76, 0.82), Vector2(0.58, 0.82)], color)
	return c

# Okragle tlo w stylu przyciskow sciezki - wspolne dla ikon na mapie.
static func round_style(color: Color, radius: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(radius)
	return sb

# Przycisk o jednolitym, zaokraglonym tle (jasniejszy pod kursorem, ciemniejszy
# po nacisnieciu, wyblakly gdy nieaktywny).
static func style_button(btn: Button, color: Color, radius: int) -> void:
	btn.add_theme_stylebox_override("normal", round_style(color, radius))
	btn.add_theme_stylebox_override("hover", round_style(color.lightened(0.1), radius))
	btn.add_theme_stylebox_override("pressed", round_style(color.darkened(0.15), radius))
	btn.add_theme_stylebox_override("disabled", round_style(color.lerp(Color(0.6, 0.6, 0.6), 0.6), radius))

# Ikona rosliny (PNG z PlantData.TYPES) w kwadracie icon_size x icon_size.
static func plant_icon(plant_idx: int, icon_size: float) -> TextureRect:
	var icon := TextureRect.new()
	icon.texture = load(PlantData.TYPES[plant_idx]["texture"])
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size = Vector2(icon_size, icon_size)
	icon.custom_minimum_size = Vector2(icon_size, icon_size)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return icon
