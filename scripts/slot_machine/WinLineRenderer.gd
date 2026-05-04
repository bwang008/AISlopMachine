extends Node2D
class_name WinLineRenderer

func draw_win_line(positions: Array[Vector2], line_color: Color = Color(1, 0.8, 0.2, 1)):
	var line = Line2D.new()
	line.width = 6.0
	line.default_color = _get_line_color(positions)
	line.material = CanvasItemMaterial.new()
	line.material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	
	for pos in positions:
		var col = pos.x
		var row = pos.y
		var x = col * 130 + 65
		var y = row * 110 + 55
		line.add_point(Vector2(x, y))
		
	add_child(line)
	
	var tween = create_tween().set_loops()
	tween.tween_property(line, "modulate:a", 0.3, 0.4)
	tween.tween_property(line, "modulate:a", 1.0, 0.4)

func _get_line_color(positions: Array[Vector2]) -> Color:
	if positions.size() < 2:
		return Color("#00FF00")
		
	var is_horizontal = true
	var is_vertical = true
	var first_y = positions[0].y
	var first_x = positions[0].x
	
	for pos in positions:
		if pos.y != first_y:
			is_horizontal = false
		if pos.x != first_x:
			is_vertical = false
			
	if is_horizontal:
		return Color("#00FF00") # Green
	if is_vertical:
		return Color("#FFFF00") # Yellow
		
	var is_diag = true
	var diff_y = positions[1].y - positions[0].y
	var diff_x = positions[1].x - positions[0].x
	if diff_x == 0 or abs(diff_y) != abs(diff_x):
		is_diag = false
	else:
		var expected_slope = diff_y / diff_x
		for i in range(1, positions.size()):
			var cur_dy = positions[i].y - positions[i-1].y
			var cur_dx = positions[i].x - positions[i-1].x
			if cur_dx == 0 or cur_dy / cur_dx != expected_slope:
				is_diag = false
				break
				
	if is_diag:
		return Color("#FF0000") # Red
		
	# V-Shape / Inverted V-Shape or anything else
	return Color("#87CEEB") # Sky Blue

func clear_lines():
	for child in get_children():
		child.queue_free()
