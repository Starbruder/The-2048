extends Node2D

var value: float = 2

func _ready() -> void:
	update_display()

func update_display() -> void:
	if not has_node("Label"): return
	var label = $Label
	
	# Text-Logik (bleibt gleich)
	if value < 1000000:
		label.text = str(int(value))
	else:
		var s_value = str(value)
		var _exp = 0
		var _dec = 0.0
		if "e" in s_value:
			var parts = s_value.split("e")
			_dec = float(parts[0])
			_exp = int(parts[1])
		else:
			_exp = str(int(value)).length() - 1
			_dec = value / pow(10, _exp)
		label.text = "%1.2f e%d" % [_dec, _exp]

	update_appearance()

func update_appearance() -> void:
	var bg = $ColorRect
	var label = $Label

	# 1. Schriftgrößen-Logik (wie gehabt)
	var base_font_size = 60 
	var label_length = label.text.length()
	if label_length >= 9: base_font_size = 35
	elif label_length >= 6: base_font_size = 39
	elif label_length >= 5: base_font_size = 49
	label.add_theme_font_size_override("font_size", base_font_size)
	
	# 2. Exakte Farben aus Bild 1
	var colors = {
		2: Color("f7ebdd"),
		4: Color("ede0c8"),
		8: Color("f2b179"),
		16: Color("f59563"),
		32: Color("f67c5f"),
		64: Color("f65e3b"),
		128: Color("edcf72"),
		256: Color("edcc61"),
		512: Color("edc850"),
		1024: Color("edc53f"),
		2048: Color("edc22e")
	}
	
	var text_dark = Color("776e65") # Das typische dunkle 2048-Grau
	var val_int = int(value)
	
	if colors.has(val_int):
		bg.color = colors[val_int]
		label.modulate = text_dark if val_int <= 4 else Color.WHITE
	else:
		# Alles über 2048
		bg.color = Color("3c3a32") if value < 1000000 else Color("4b0082")
		label.modulate = Color("ffd700") if value >= 1000000 else Color.WHITE
	
	# 3. Bold-Effekt nur bei weißem/goldenen Text
	if label.modulate != text_dark:
		label.add_theme_constant_override("outline_size", int(base_font_size * 0.2))
		label.add_theme_color_override("font_outline_color", label.modulate)
	else:
		label.add_theme_constant_override("outline_size", 0)
