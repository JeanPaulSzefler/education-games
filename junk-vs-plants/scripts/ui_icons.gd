class_name UiIcons
extends RefCounted

# Proste ikonki interfejsu rysowane w kodzie (Polygon2D/Line2D wewnatrz
# Control) - jak animacje z rundy C. Gdy w grze jest gotowa grafika
# (GRAFIKI_PROMPTY_5.md), funkcja zwraca ja zamiast rysunku.
# Kazda funkcja zwraca Control o rozmiarze size x size, ktory nie lapie
# klikniec (mouse_filter IGNORE), wiec mozna go wlozyc do przycisku.

const RUBY_COLOR := Color(0.85, 0.1, 0.3)
const RUBY_LIGHT_COLOR := Color(1.0, 0.45, 0.6)
const RUBY_DARK_COLOR := Color(0.55, 0.04, 0.18)

const CHEST_TEXTURE := "res://assets/sprites/ui/chest.png"
const COIN_TEXTURE := "res://assets/sprites/ui/plant_coin.png"
const RUBY_TEXTURE := "res://assets/sprites/ui/ruby.png"
const BOOK_TEXTURE := "res://assets/sprites/ui/book.png"
const SHOP_TEXTURE := "res://assets/sprites/ui/shop_basket.png"
const SAPLING_TEXTURE := "res://assets/sprites/ui/sapling.png"
const STAR_TEXTURE := "res://assets/sprites/ui/event_star.png"
const BEE_TEXTURE := "res://assets/sprites/ui/bee.png"
const PADLOCK_TEXTURE := "res://assets/sprites/ui/padlock.png"
const SOIL_TEXTURE := "res://assets/sprites/ui/soil_plot.png"
const FOG_TEXTURE := "res://assets/sprites/ui/fog.png"

const TINT_SHADER_CODE := """
shader_type canvas_item;
uniform vec3 tint;
void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	float gray = dot(tex.rgb, vec3(0.3, 0.59, 0.11));
	COLOR = vec4(min(vec3(gray) * tint * 1.5, vec3(1.0)), tex.a);
}
"""

const GRAY_SHADER_CODE := """
shader_type canvas_item;
void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	float gray = dot(tex.rgb, vec3(0.3, 0.59, 0.11));
	COLOR = vec4(vec3(gray), tex.a);
}
"""

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
	var file_icon := _texture_icon(RUBY_TEXTURE, size)
	if file_icon != null:
		return file_icon
	var c := _box(size)
	_poly(c, size, [Vector2(0.25, 0.12), Vector2(0.75, 0.12), Vector2(0.98, 0.38),
		Vector2(0.5, 0.94), Vector2(0.02, 0.38)], RUBY_COLOR)
	_poly(c, size, [Vector2(0.02, 0.38), Vector2(0.98, 0.38), Vector2(0.5, 0.94)], RUBY_DARK_COLOR)
	_poly(c, size, [Vector2(0.3, 0.38), Vector2(0.7, 0.38), Vector2(0.5, 0.94)], RUBY_COLOR)
	_poly(c, size, [Vector2(0.25, 0.12), Vector2(0.45, 0.12), Vector2(0.3, 0.38), Vector2(0.1, 0.32)], RUBY_LIGHT_COLOR)
	return c

# Otwarta ksiazka ("Opis gry").
static func book(size: float) -> Control:
	var file_icon := _texture_icon(BOOK_TEXTURE, size)
	if file_icon != null:
		return file_icon
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
	var file_icon := _texture_icon(SHOP_TEXTURE, size)
	if file_icon != null:
		return file_icon
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

# Ta sama ikona bez koloru - roslina odblokowana, ale jej ikonka gracza jeszcze nie.
static func plant_icon_gray(plant_idx: int, icon_size: float) -> TextureRect:
	var icon := plant_icon(plant_idx, icon_size)
	var shader := Shader.new()
	shader.code = GRAY_SHADER_CODE
	var material := ShaderMaterial.new()
	material.shader = shader
	icon.material = material
	return icon

# Rysunek rosliny w jednym kolorze - zachowuje kontury i cienie oryginalu.
static func plant_icon_tinted(plant_idx: int, icon_size: float, tint: Color) -> TextureRect:
	var icon := plant_icon(plant_idx, icon_size)
	var shader := Shader.new()
	shader.code = TINT_SHADER_CODE
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("tint", Vector3(tint.r, tint.g, tint.b))
	icon.material = material
	return icon

# Sadzonka: dwa listki na lodyzce.
static func sapling(size: float) -> Control:
	var file_icon := _texture_icon(SAPLING_TEXTURE, size)
	if file_icon != null:
		return file_icon
	var c := _box(size)
	_line(c, size, [Vector2(0.5, 0.9), Vector2(0.5, 0.48)], Color(0.3, 0.55, 0.2), max(3.0, size * 0.07))
	_poly(c, size, [Vector2(0.5, 0.52), Vector2(0.2, 0.42), Vector2(0.12, 0.18), Vector2(0.4, 0.26)], Color(0.45, 0.8, 0.3))
	_poly(c, size, [Vector2(0.5, 0.46), Vector2(0.8, 0.36), Vector2(0.88, 0.12), Vector2(0.6, 0.2)], Color(0.35, 0.7, 0.25))
	_poly(c, size, [Vector2(0.3, 0.9), Vector2(0.7, 0.9), Vector2(0.62, 0.8), Vector2(0.38, 0.8)], Color(0.45, 0.3, 0.16))
	return c

# Gwiazdka (wydarzenia).
static func star(size: float) -> Control:
	var file_icon := _texture_icon(STAR_TEXTURE, size)
	if file_icon != null:
		return file_icon
	var c := _box(size)
	var points := []
	for i in range(10):
		var radius := 0.46 if i % 2 == 0 else 0.2
		points.append(Vector2(0.5, 0.52) + Vector2.from_angle(TAU * i / 10.0 - PI / 2.0) * radius)
	_poly(c, size, points, Color(0.98, 0.8, 0.2))
	return c

# Pszczolka: zolto-czarny brzuszek i dwa skrzydelka.
static func bee(size: float) -> Control:
	var file_icon := _texture_icon(BEE_TEXTURE, size)
	if file_icon != null:
		return file_icon
	var c := _box(size)
	var wing := Color(0.85, 0.95, 1.0, 0.85)
	_poly(c, size, [Vector2(0.34, 0.42), Vector2(0.2, 0.12), Vector2(0.46, 0.2), Vector2(0.52, 0.4)], wing)
	_poly(c, size, [Vector2(0.52, 0.4), Vector2(0.6, 0.12), Vector2(0.82, 0.22), Vector2(0.66, 0.44)], wing)
	_poly(c, size, [Vector2(0.14, 0.58), Vector2(0.28, 0.4), Vector2(0.72, 0.4), Vector2(0.9, 0.58), Vector2(0.72, 0.78), Vector2(0.28, 0.78)], Color(0.98, 0.8, 0.15))
	var stripe := Color(0.12, 0.1, 0.08)
	for x in [0.36, 0.56]:
		_poly(c, size, [Vector2(x, 0.4), Vector2(x + 0.1, 0.4), Vector2(x + 0.1, 0.78), Vector2(x, 0.78)], stripe)
	_poly(c, size, [Vector2(0.2, 0.5), Vector2(0.25, 0.5), Vector2(0.25, 0.56), Vector2(0.2, 0.56)], stripe)
	return c

# Grafika z pliku, gdy juz jest w grze; inaczej null (patrz chest, plant_coin).
static func _texture_icon(path: String, size: float) -> TextureRect:
	if not ResourceLoader.exists(path):
		return null
	var icon := TextureRect.new()
	icon.texture = load(path)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size = Vector2(size, size)
	icon.custom_minimum_size = Vector2(size, size)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return icon

# Tlo pola w ogrodzie i kafelek mgly: null, dopoki nie ma grafiki (wtedy gra
# uzywa jednolitego koloru).
static func soil_plot(plot_size: Vector2) -> TextureRect:
	var icon := _texture_icon(SOIL_TEXTURE, plot_size.x)
	if icon != null:
		icon.size = plot_size
		icon.custom_minimum_size = plot_size
		icon.stretch_mode = TextureRect.STRETCH_SCALE
	return icon

static func fog_tile(size: float) -> TextureRect:
	var icon := _texture_icon(FOG_TEXTURE, size)
	if icon != null:
		icon.stretch_mode = TextureRect.STRETCH_SCALE
	return icon

# Skrzynia z nagrodami.
static func chest(size: float) -> Control:
	var file_icon := _texture_icon(CHEST_TEXTURE, size)
	if file_icon != null:
		return file_icon
	var c := _box(size)
	var wood := Color(0.62, 0.38, 0.16)
	var band := Color(0.92, 0.72, 0.2)
	_poly(c, size, [Vector2(0.08, 0.46), Vector2(0.92, 0.46), Vector2(0.92, 0.9), Vector2(0.08, 0.9)], wood)
	_poly(c, size, [Vector2(0.08, 0.42), Vector2(0.16, 0.2), Vector2(0.84, 0.2), Vector2(0.92, 0.42)], wood.lightened(0.15))
	_poly(c, size, [Vector2(0.06, 0.4), Vector2(0.94, 0.4), Vector2(0.94, 0.5), Vector2(0.06, 0.5)], band)
	_poly(c, size, [Vector2(0.42, 0.36), Vector2(0.58, 0.36), Vector2(0.58, 0.62), Vector2(0.42, 0.62)], band.darkened(0.2))
	return c

# Roslimoneta (waluta ze skrzyn i gier zespolowych).
static func plant_coin(size: float) -> Control:
	var file_icon := _texture_icon(COIN_TEXTURE, size)
	if file_icon != null:
		return file_icon
	var c := _box(size)
	var points := []
	var inner := []
	for i in range(20):
		var dir := Vector2.from_angle(TAU * i / 20.0)
		points.append(Vector2(0.5, 0.5) + dir * 0.46)
		inner.append(Vector2(0.5, 0.5) + dir * 0.36)
	_poly(c, size, points, Color(0.8, 0.58, 0.1))
	_poly(c, size, inner, Color(0.98, 0.82, 0.25))
	_poly(c, size, [Vector2(0.5, 0.24), Vector2(0.68, 0.46), Vector2(0.5, 0.74), Vector2(0.32, 0.46)], Color(0.3, 0.68, 0.22))
	return c

# Klodka (ikonka rosliny, ktorej gracz jeszcze nie odblokowal).
static func padlock(size: float) -> Control:
	var file_icon := _texture_icon(PADLOCK_TEXTURE, size)
	if file_icon != null:
		return file_icon
	var c := _box(size)
	_line(c, size, [Vector2(0.3, 0.46), Vector2(0.3, 0.28), Vector2(0.4, 0.14), Vector2(0.6, 0.14),
		Vector2(0.7, 0.28), Vector2(0.7, 0.46)], Color(0.3, 0.3, 0.32), max(3.0, size * 0.09))
	_poly(c, size, [Vector2(0.16, 0.44), Vector2(0.84, 0.44), Vector2(0.84, 0.92), Vector2(0.16, 0.92)], Color(0.85, 0.65, 0.2))
	_poly(c, size, [Vector2(0.44, 0.58), Vector2(0.56, 0.58), Vector2(0.56, 0.78), Vector2(0.44, 0.78)], Color(0.3, 0.22, 0.1))
	return c
