extends Node2D
class_name WinLineRenderer

func draw_win_line(positions: Array[Vector2], line_color: Color = Color(1, 0.8, 0.2, 1)):
	var line = Line2D.new()
	line.width = 6.0
	line.default_color = line_color
	line.material = CanvasItemMaterial.new()
	line.material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	
	for pos in positions:
		var col = pos.x
		var row = pos.y
		var x = col * 130 + 65
		var y = (row - 1) * 110 + 55
		line.add_point(Vector2(x, y))
		
	add_child(line)
	
	var tween = create_tween().set_loops()
	tween.tween_property(line, "modulate:a", 0.3, 0.4)
	tween.tween_property(line, "modulate:a", 1.0, 0.4)

func clear_lines():
	for child in get_children():
		child.queue_free()
