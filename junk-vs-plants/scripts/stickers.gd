class_name Stickers
extends RefCounted

# Naklejki albumu (AddonData.album_stickers): "p<i>" roslina, "e<i>" smieciostwor,
# "b<i>" boss, "bee" pszczolka. Rysunek to grafika postaci w zlotej ramce.

const ENEMY_TEXTURES := [
	"res://assets/sprites/enemies/bottle.png",
	"res://assets/sprites/enemies/can.png",
	"res://assets/sprites/enemies/cardboard_golem.png",
	"res://assets/sprites/enemies/sponge.png",
]

static func title(sticker: String) -> String:
	if sticker == "bee":
		return Lang.t("sticker_bee")
	var idx := sticker.substr(1).to_int()
	match sticker[0]:
		"p":
			return PlantData.name_of(idx)
		"e":
			return Lang.t("enemy_%d" % idx)
		_:
			return BossData.name_of(idx)

static func icon(sticker: String, size: float) -> Control:
	var frame := Panel.new()
	frame.size = Vector2(size, size)
	frame.custom_minimum_size = frame.size
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := UiIcons.round_style(Color(1.0, 0.97, 0.88), int(size / 6.0))
	sb.set_border_width_all(maxi(2, int(size / 20.0)))
	sb.border_color = Color(0.9, 0.7, 0.15)
	frame.add_theme_stylebox_override("panel", sb)
	var inner: Control
	if sticker == "bee":
		inner = UiIcons.bee(size * 0.8)
	else:
		var path := ""
		var idx := sticker.substr(1).to_int()
		match sticker[0]:
			"p":
				path = PlantData.TYPES[idx]["texture"]
			"e":
				path = ENEMY_TEXTURES[idx]
			_:
				path = BossData.TYPES[idx]["texture"]
		var tex := TextureRect.new()
		tex.texture = load(path)
		tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex.size = Vector2(size, size) * 0.8
		tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
		inner = tex
	inner.position = Vector2(size, size) * 0.1
	frame.add_child(inner)
	return frame
