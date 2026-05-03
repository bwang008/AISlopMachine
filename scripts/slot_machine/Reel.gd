extends Node2D
class_name Reel

var target_symbols: Array = []
var spinning: bool = false
var sprites: Array[Sprite2D] = []
var spin_speed: float = 1800.0

func _ready():
	# Create 4 sprites (1 extra for seamless wrap-around at the top)
	for i in range(4):
		var sprite = Sprite2D.new()
		sprite.position = Vector2(0, (i - 1) * 110) # -110, 0, 110, 220
		sprite.scale = Vector2(0.08, 0.08)
		add_child(sprite)
		sprites.append(sprite)

func _process(delta):
	if spinning:
		for sprite in sprites:
			sprite.position.y += spin_speed * delta
			if sprite.position.y >= 330: # Moved past the bottom row (220)
				sprite.position.y -= 440 # Wrap to the top (-110)
				# Randomize texture as it blurs past
				if GameManager.available_symbols.size() > 0:
					sprite.texture = GameManager.available_symbols.pick_random().texture

func set_initial_symbols(outcome_symbols: Array):
	for i in range(4):
		sprites[i].position = Vector2(0, (i - 1) * 110)
		if i > 0 and i <= outcome_symbols.size():
			if outcome_symbols[i-1] != null:
				sprites[i].texture = outcome_symbols[i-1].texture
				sprites[i].modulate = Color(1, 1, 1, 1.0)
			else:
				sprites[i].texture = null

func start_spin():
	spinning = true
	for sprite in sprites:
		sprite.modulate = Color(1, 1, 1, 1.0) # Reset any previous dims

func stop_spin(outcome_symbols: Array):
	spinning = false
	target_symbols = outcome_symbols
	
	for i in range(4):
		# Assign the final mathematical textures
		if i > 0 and i <= outcome_symbols.size():
			if outcome_symbols[i-1] != null:
				sprites[i].texture = outcome_symbols[i-1].texture
			else:
				sprites[i].texture = null
		
		# Snap sprite slightly above final position
		var final_y = (i - 1) * 110
		sprites[i].position = Vector2(0, final_y - 80)
		
		# Animate down into place with a rubberband back-bounce
		var tween = create_tween()
		tween.tween_property(sprites[i], "position:y", final_y, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func dim_all():
	for i in range(1, 4):
		var tween = create_tween()
		tween.tween_property(sprites[i], "modulate", Color(0.3, 0.3, 0.3, 1.0), 0.3)

func highlight_symbol(row_index: int):
	# row_index is 0, 1, 2. But our visible sprites are indices 1, 2, 3.
	var sprite = sprites[row_index + 1]
	
	var tween = create_tween()
	# Restore color and pulse scale
	tween.tween_property(sprite, "modulate", Color(1.2, 1.2, 1.2, 1.0), 0.2)
	tween.tween_property(sprite, "scale", Vector2(0.1, 0.1), 0.2)
	tween.tween_property(sprite, "scale", Vector2(0.08, 0.08), 0.2)
