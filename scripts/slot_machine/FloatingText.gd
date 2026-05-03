extends Node2D
class_name FloatingText

func setup(text: String, start_pos: Vector2):
	position = start_pos
	var label = Label.new()
	label.text = text
	label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))
	label.add_theme_font_size_override("font_size", 32)
	label.add_theme_constant_override("outline_size", 4)
	
	# To center the label we can use grow_direction or just set position after layout
	# But Label.new() hasn't laid out yet, so we can just roughly center
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.position = Vector2(-50, -20)
	label.size = Vector2(100, 40)
	add_child(label)
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "position:y", position.y - 60, 1.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "modulate:a", 0.0, 1.5).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(queue_free)
