extends Node

enum GameState {
	IDLE,
	SPINNING,
	REEL_STOPPING,
	WIN_EVALUATION,
	PAYOUT
}

var current_state: GameState = GameState.IDLE
var credits: int = 1000
var bet_amount: int = 10
var current_presentation_pause: float = 1.5

# 5 reels, 3 rows
const REELS_COUNT = 5
const ROWS_COUNT = 3

# The outcome of the current spin
# Represented as a 2D array: outcome[reel_index][row_index] = SlotSymbol
var current_outcome = []

# List of all available symbols to roll
# In a real game, this would be populated from resources
var available_symbols: Array[SlotSymbol] = []
var active_patterns: Array[SlotPattern] = []

var pending_win_amount: int = 0
var pending_winning_lines: Array = []
var reels_stopped_count: int = 0

func _ready():
	EventManager.spin_stopped.connect(on_all_reels_stopped)
	EventManager.reel_stopped.connect(_on_reel_stopped)
	EventManager.payout_complete.connect(_on_payout_complete)
	
	# For testing: setup dummy symbols and paylines if empty
	if available_symbols.is_empty():
		var s_cherry = SlotSymbol.new()
		s_cherry.id = "cherry"
		s_cherry.base_value = 10
		s_cherry.texture = load_texture("res://assets/graphics/cherry.jpg")
		available_symbols.append(s_cherry)
		
		var s_lemon = SlotSymbol.new()
		s_lemon.id = "lemon"
		s_lemon.base_value = 20
		s_lemon.texture = load_texture("res://assets/graphics/lemon.jpg")
		available_symbols.append(s_lemon)
		
		var s_bell = SlotSymbol.new()
		s_bell.id = "bell"
		s_bell.base_value = 40
		s_bell.texture = load_texture("res://assets/graphics/bell.jpg")
		available_symbols.append(s_bell)
		
		var s_horseshoe = SlotSymbol.new()
		s_horseshoe.id = "horseshoe"
		s_horseshoe.base_value = 80
		s_horseshoe.texture = load_texture("res://assets/graphics/horseshoe.jpg")
		available_symbols.append(s_horseshoe)
		
		var s_seven = SlotSymbol.new()
		s_seven.id = "seven"
		s_seven.base_value = 150
		s_seven.texture = load_texture("res://assets/graphics/seven.jpg")
		available_symbols.append(s_seven)
		
		var s_clover = SlotSymbol.new()
		s_clover.id = "clover"
		s_clover.base_value = 500
		s_clover.texture = load_texture("res://assets/graphics/clover.jpg")
		available_symbols.append(s_clover)
		
	if active_patterns.is_empty():
		# --- Horizontal Patterns (3, 4, 5 in a row) ---
		for row in range(3):
			for match_len in range(3, 6):
				for start_col in range(6 - match_len):
					var p = SlotPattern.new()
					p.pattern_name = "H Row%d Col%d-%d" % [row, start_col, start_col + match_len - 1]
					if match_len == 5:
						p.pattern_name = "H Row%d JACKPOT" % row
					var pos_arr = []
					for i in range(match_len):
						pos_arr.append(Vector2(start_col + i, row))
					p.positions.assign(pos_arr)
					p.min_match = match_len
					p.multiplier = pow(2, match_len - 3) # 1x, 2x, 4x
					active_patterns.append(p)
		
		# --- Vertical Patterns (3 in a row) ---
		for col in range(5):
			var p = SlotPattern.new()
			p.pattern_name = "V Col%d" % col
			p.positions.assign([
				Vector2(col, 0),
				Vector2(col, 1),
				Vector2(col, 2)
			])
			p.min_match = 3
			p.multiplier = 1.0
			active_patterns.append(p)
		
		# --- Diagonal & V-Shape Patterns ---
		# Basic Diagonal Down
		for start_col in range(3):
			var p = SlotPattern.new()
			p.pattern_name = "Diag↘ Col%d" % start_col
			p.positions.assign([Vector2(start_col, 0), Vector2(start_col + 1, 1), Vector2(start_col + 2, 2)])
			p.min_match = 3
			p.multiplier = 1.0
			active_patterns.append(p)
			
		# Basic Diagonal Up
		for start_col in range(3):
			var p = SlotPattern.new()
			p.pattern_name = "Diag↗ Col%d" % start_col
			p.positions.assign([Vector2(start_col, 2), Vector2(start_col + 1, 1), Vector2(start_col + 2, 0)])
			p.min_match = 3
			p.multiplier = 1.0
			active_patterns.append(p)
			
		# V-Shape (Jackpot 5-length)
		var p_v1 = SlotPattern.new()
		p_v1.pattern_name = "V-Shape JACKPOT"
		p_v1.positions.assign([Vector2(0,0), Vector2(1,1), Vector2(2,2), Vector2(3,1), Vector2(4,0)])
		p_v1.min_match = 5
		p_v1.multiplier = 5.0
		active_patterns.append(p_v1)
		
		var p_v2 = SlotPattern.new()
		p_v2.pattern_name = "Inv V-Shape JACKPOT"
		p_v2.positions.assign([Vector2(0,2), Vector2(1,1), Vector2(2,0), Vector2(3,1), Vector2(4,2)])
		p_v2.min_match = 5
		p_v2.multiplier = 5.0
		active_patterns.append(p_v2)

	# Generate an initial state so the slot machine isn't empty on startup
	calculate_spin_outcome()

func load_texture(path: String) -> Texture2D:
	var global_path = ProjectSettings.globalize_path(path)
	var img = Image.load_from_file(global_path)
	if img != null:
		return ImageTexture.create_from_image(img)
	else:
		print("Failed to load image from absolute path: ", global_path)
		return null

func change_state(new_state: GameState):
	current_state = new_state
	EventManager.state_changed.emit(new_state)

func request_spin(forced_outcome: int = 0, presentation_pause: float = 1.5):
	if current_state != GameState.IDLE:
		print("Cannot spin, state is not IDLE")
		return
	
	if credits < bet_amount:
		print("Not enough credits")
		return
		
	credits -= bet_amount
	EventManager.credits_updated.emit(credits)
	
	change_state(GameState.SPINNING)
	reels_stopped_count = 0
	current_presentation_pause = presentation_pause
	
	# Math-first RNG: Calculate the outcome instantly
	calculate_spin_outcome(forced_outcome)
	EventManager.spin_started.emit()

func calculate_spin_outcome(forced_outcome: int = 0):
	current_outcome.clear()
	
	if forced_outcome != 0:
		_rig_outcome(forced_outcome)
	else:
		# Fill the 5x3 grid
		for x in range(REELS_COUNT):
			var column = []
			for y in range(ROWS_COUNT):
				if available_symbols.size() > 0:
					column.append(available_symbols.pick_random())
				else:
					column.append(null)
			current_outcome.append(column)

	# Evaluate wins instantly in memory
	evaluate_wins()

func _rig_outcome(forced_outcome: int):
	var win_symbol = available_symbols[available_symbols.size() - 1] if available_symbols.size() > 0 else null
	var lose_symbol = available_symbols[0] if available_symbols.size() > 0 else null
	
	for x in range(REELS_COUNT):
		var column = []
		for y in range(ROWS_COUNT):
			column.append(lose_symbol)
		current_outcome.append(column)
		
	if win_symbol == null: return
	
	match forced_outcome:
		1: # "Force Horizontal 3"
			current_outcome[0][1] = win_symbol
			current_outcome[1][1] = win_symbol
			current_outcome[2][1] = win_symbol
		2: # "Force Vertical 4"
			for y in range(ROWS_COUNT):
				current_outcome[0][y] = win_symbol
		3: # "Force Diagonal 5"
			for i in range(min(REELS_COUNT, 5)):
				current_outcome[i][i % ROWS_COUNT] = win_symbol
		4: # "Force V-Shape"
			for i in range(min(REELS_COUNT, 5)):
				var y = i if i <= 2 else (4 - i)
				current_outcome[i][y] = win_symbol
		5: # "Force Jackpot"
			for x in range(REELS_COUNT):
				for y in range(ROWS_COUNT):
					current_outcome[x][y] = win_symbol

func evaluate_wins():
	pending_win_amount = 0
	pending_winning_lines.clear()
	
	var raw_winning_lines = []
	for pattern in active_patterns:
		if pattern.positions.size() == 0:
			continue
			
		var first_pos = pattern.positions[0]
		var match_symbol = current_outcome[first_pos.x][first_pos.y]
		if match_symbol == null:
			continue
			
		var match_count = 1
		for i in range(1, pattern.positions.size()):
			var pos = pattern.positions[i]
			var symbol = current_outcome[pos.x][pos.y]
			if symbol != null and symbol.id == match_symbol.id:
				match_count += 1
			else:
				break
				
		if match_count >= pattern.min_match:
			var win_amount = int(match_symbol.base_value * match_count * pattern.multiplier)
			raw_winning_lines.append({
				"pattern": pattern,
				"win_amount": win_amount,
				"match_count": match_count,
				"symbol_id": match_symbol.id
			})
			
	# Filter out subset patterns to prevent double counting
	for i in range(raw_winning_lines.size()):
		var is_subset = false
		var line_a = raw_winning_lines[i]
		var pos_a = line_a["pattern"].positions.slice(0, line_a["match_count"])
		
		for j in range(raw_winning_lines.size()):
			if i == j: continue
			var line_b = raw_winning_lines[j]
			var pos_b = line_b["pattern"].positions.slice(0, line_b["match_count"])
			
			if pos_a.size() < pos_b.size():
				var all_in_b = true
				for p in pos_a:
					if not p in pos_b:
						all_in_b = false
						break
				if all_in_b:
					is_subset = true
					break
					
		if not is_subset:
			pending_winning_lines.append(line_a)
			pending_win_amount += line_a["win_amount"]
			print("Evaluated Win! %s: Matched %d %ss for %d" % [line_a["pattern"].pattern_name, line_a["match_count"], line_a["symbol_id"], line_a["win_amount"]])
			
	if pending_win_amount > 0:
		print("Total pending win for spin: ", pending_win_amount)
	else:
		print("No pending win this spin.")

func _on_reel_stopped(reel_index: int, _final_symbols: Array):
	if current_state == GameState.SPINNING or current_state == GameState.REEL_STOPPING:
		change_state(GameState.REEL_STOPPING)
		reels_stopped_count += 1
		if reels_stopped_count >= REELS_COUNT:
			EventManager.spin_stopped.emit()

# Called by the visual slot machine when all reels have finished their stopping animations
func on_all_reels_stopped():
	if current_state == GameState.REEL_STOPPING:
		change_state(GameState.WIN_EVALUATION)
		
		if pending_win_amount > 0:
			EventManager.win_calculated.emit(pending_win_amount, pending_winning_lines)
			
			# Wait for all lines to be presented sequentially with accelerating pauses
			var wait_time = 0.0
			var current_pause = current_presentation_pause
				
			for i in range(pending_winning_lines.size()):
				wait_time += current_pause
				current_pause = max(0.4, current_pause * 0.7)
			if wait_time <= 0: wait_time = 1.5
			await get_tree().create_timer(wait_time).timeout
			
			change_state(GameState.PAYOUT)
			EventManager.payout_started.emit(pending_win_amount)
		else:
			# No win, go back to IDLE
			change_state(GameState.IDLE)

func _on_payout_complete():
	credits += pending_win_amount
	EventManager.credits_updated.emit(credits)
	change_state(GameState.IDLE)
