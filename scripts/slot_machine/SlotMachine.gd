extends Node2D

@export_enum("None", "Force Horizontal 3", "Force Vertical 4", "Force Diagonal 5", "Force V-Shape", "Force Jackpot") var debug_force_outcome: int = 0
@export var debug_presentation_pause: float = 1.5

var reels: Array[Reel] = []
var win_line_renderer: WinLineRenderer

func _ready():
	EventManager.spin_requested.connect(_on_ui_spin_requested)
	EventManager.spin_started.connect(on_spin_started)
	EventManager.win_calculated.connect(on_win_calculated)
	
	# Create background for the slot board
	var bg = ColorRect.new()
	bg.color = Color(0.1, 0.1, 0.1, 1.0) # Dark gray background
	bg.position = Vector2(-65, -82)
	bg.size = Vector2(650, 495)
	add_child(bg)
	
	# Create a clipping container for the reels
	var clip_container = Control.new()
	clip_container.clip_contents = true
	clip_container.position = Vector2(-65, -82)
	clip_container.size = Vector2(650, 495)
	add_child(clip_container)
	
	win_line_renderer = WinLineRenderer.new()
	win_line_renderer.position = Vector2(-65, -82) # Same as clipping container, so local coords match
	add_child(win_line_renderer)
	
	# Spawn 5 reels inside the clipping container
	for i in range(5):
		var reel = Reel.new()
		reel.reel_index = i
		# Position relative to clip_container (which is at -65, -82)
		reel.position = Vector2(i * 130 + 65, 82)
		clip_container.add_child(reel)
		reels.append(reel)
		
	# Add separating lines
	for i in range(1, 5):
		var line = ColorRect.new()
		line.color = Color(0.3, 0.3, 0.3, 1.0) # Line color
		line.position = Vector2(i * 130 - 65 - 2, -82) 
		line.size = Vector2(4, 495)
		add_child(line)

	# Add outer border
	var border = ReferenceRect.new()
	border.position = Vector2(-65, -82)
	border.size = Vector2(650, 495)
	border.editor_only = false
	border.border_color = Color(0.8, 0.6, 0.1, 1.0) # Golden border
	border.border_width = 5.0
	add_child(border)
	
	# Populate initial symbols so the board isn't blank
	# We use call_deferred to ensure GameManager has fully populated current_outcome
	call_deferred("_populate_initial_reels")

func _on_ui_spin_requested():
	GameManager.request_spin(debug_force_outcome, debug_presentation_pause)

func _populate_initial_reels():
	var outcome = GameManager.current_outcome
	if outcome.size() == reels.size():
		for i in range(reels.size()):
			reels[i].set_initial_symbols(outcome[i])

func on_spin_started():
	if win_line_renderer != null:
		win_line_renderer.clear_lines()
		
	# Start visual spin for all reels
	for reel in reels:
		reel.reset_visuals()
		reel.start_spin()
	
	# Simulate spin duration
	await get_tree().create_timer(2.0).timeout
	stop_reels()

func stop_reels():
	# Retrieve the pre-calculated outcome from GameManager
	var outcome = GameManager.current_outcome
	
	# Stop each reel sequentially with its respective outcome column
	for i in range(reels.size()):
		var reel_outcome = outcome[i]
		reels[i].stop_spin(reel_outcome)
		await get_tree().create_timer(0.3).timeout # Sequential stop delay
		
	# EventManager.spin_stopped is emitted by GameManager when all reels stop

func on_win_calculated(amount: int, winning_lines: Array):
	# Sort the queue of winning lines by pattern length (ascending)
	winning_lines.sort_custom(func(a, b): return a["match_count"] < b["match_count"])
	
	var current_pause = debug_presentation_pause
	var pitch = 1.0
	
	# Present them sequentially
	for win_data in winning_lines:
		# Dim all symbols first before showing each line
		for reel in reels:
			reel.dim_all()
			
		var pattern: SlotPattern = win_data["pattern"]
		var win_val: int = win_data["win_amount"]
		var match_count: int = win_data["match_count"]
		
		# Draw win line
		if win_line_renderer != null:
			win_line_renderer.draw_win_line(pattern.positions)
			
		# Highlight matched symbols
		for i in range(match_count):
			var pos = pattern.positions[i]
			reels[pos.x].highlight_symbol(pos.y)
			
		# Spawn floating text at center of the match
		var center_index = match_count / 2
		var center_pos = pattern.positions[center_index]
		var screen_pos = _get_symbol_world_position(center_pos.x, center_pos.y)
		
		var ft = FloatingText.new()
		add_child(ft)
		ft.setup("+" + str(win_val), screen_pos)
		
		var gb = GoldBurst.new()
		gb.position = screen_pos
		add_child(gb)
		
		# Play beep with increasing pitch
		if SoundManager.has_method("play_line_beep"):
			SoundManager.play_line_beep(pitch)
		
		# Wait for the calculated duration
		await get_tree().create_timer(current_pause).timeout
		
		# Accelerate for the next pattern
		current_pause = max(0.4, current_pause * 0.7)
		pitch = min(2.5, pitch * 1.1)
		
		# Hide the line for the next pattern
		if win_line_renderer != null:
			win_line_renderer.clear_lines()

func _get_symbol_world_position(col: int, row: int) -> Vector2:
	var x = col * 130.0
	var y = row * 165.0
	return Vector2(x, y)

func _unhandled_input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_T:
		if GameManager.current_state == GameManager.GameState.IDLE:
			_debug_force_pattern()

func _debug_force_pattern():
	print("[DEBUG] Forcing test pattern via T key...")
	
	var forced = debug_force_outcome
	if forced == 0:
		forced = 5 # Default to Jackpot if set to None
		
	# Pass the parameters up to the global GameManager
	GameManager.request_spin(forced, debug_presentation_pause)
