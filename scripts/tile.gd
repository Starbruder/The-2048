extends Node2D

var value: float = 2

func _ready() -> void:
	update_display()

func update_display() -> void:
	if not has_node("Label"): return
	var label = $Label
	
	if value < 1000000:
		label.text = str(int(value))
	else:
		var s_value = str(value)
		var _exp: int = 0
		var _dec: float = 0.0
		if "e" in s_value:
			var parts = s_value.split("e")
			_dec = float(parts[0])
			_exp = int(parts[1])
		else:
			var integer_part = s_value.split(".")[0]
			_exp = integer_part.length() - 1
			_dec = value / pow(10, _exp)
		label.text = "%1.2f e%d" % [_dec, _exp]

	update_appearance()

func update_appearance() -> void:
	var bg = $ColorRect
	var label = $Label
	
	# Farbtabelle für die Standardwerte
	var colors = {
		2: Color("eee4da"),
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
	
	var val_int = int(value)
	
	if colors.has(val_int):
		# Klassische 2048 Farben
		bg.color = colors[val_int]
		label.modulate = Color.BLACK if val_int <= 4 else Color.WHITE
	elif value < 1000000:
		# Bereich zwischen 2048 und 1 Million: Ein tiefes, "heißes" Rot
		bg.color = Color("3c3a32").lerp(Color("ff0000"), 0.2) 
		label.modulate = Color.WHITE
	else:
		# Wissenschaftliche Schreibweise: Epische Farben!
		# Wir nutzen den Exponenten, um die Farbe leicht zu verändern
		# So sieht e12 anders aus als e20.
		var s_value = str(value)
		var exponent = 0
		if "e" in s_value:
			exponent = int(s_value.split("e")[1])
		else:
			exponent = str(int(value)).length() - 1
			
		# Ein dunkles Violett, das mit höherem Exponenten bläulicher/heller wird
		var base_color = Color("4b0082") # Indigo
		bg.color = base_color.lightened(clamp(exponent / 50.0, 0.0, 0.5))
		
		# Optional: Goldener Rand oder Leuchten für e-Zahlen
		label.modulate = Color("ffd700") # Goldener Text für die "Götter-Zahlen"
