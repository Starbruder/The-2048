extends Node2D

# Der aktuelle Wert der Kachel
var value: float = 2

func _ready() -> void:
	update_display()

func update_display() -> void:
	if not has_node("Label"):
		return
		
	var label = $Label
	
	# Kleine Zahlen normal anzeigen
	if value < 1000000:
		label.text = str(int(value))
	else:
		# Deine E+X Logik
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

		# Formatierung auf 2 Nachkommastellen
		label.text = "%1.2f e%d" % [_dec, _exp]

	update_appearance()

func update_appearance() -> void:
	var bg = $ColorRect

	# Wir wandeln den float-Wert hier in einen int um
	var value_int = int(value)
	
	# Ein einfaches Dictionary für die klassischen Farben
	var colors = {
		2: Color("eee4da"),
		4: Color("ede0c8"),
		8: Color("f2b179"),
		16: Color("f59563"),
		32: Color("f67c5f")
	}
	
	if colors.has(value_int):
		bg.color = colors[value_int]
		$Label.modulate = Color.BLACK # Text wieder dunkel machen für helle Kacheln
	else:
		# Für deine "unendlichen" Zahlen nehmen wir ein edles Dunkelgrau oder Gold
		bg.color = Color("3c3a32") 
		$Label.modulate = Color.WHITE # Text auf dunklem Grund weiß machen
