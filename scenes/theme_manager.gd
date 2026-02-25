extends Node

enum Mode { LIGHT, DARK, AMOLED }

@export var current_mode: Mode = Mode.DARK

# Farbtabellen für die Hintergründe
var bg_colors = {
	Mode.LIGHT: Color("f1ede4"),  # Klassisches 2048 Hellbeige
	Mode.DARK: Color("4d4d4d"),   # Mittleres Anthrazit Dunkelgrau
	Mode.AMOLED: Color("000000")  # Tiefschwarz
}

func _ready():
	apply_theme()

func apply_theme():
	# 1. Haupt-Hintergrund der Szene ändern
	# Wir suchen die "CanvasLayer" oder das Haupt-Node2D
	var root = get_tree().current_scene
	if root is Node2D:
		RenderingServer.set_default_clear_color(bg_colors[current_mode])
	
	# 2. Augabe
	print("Theme angewendet: ", Mode.keys()[current_mode])
