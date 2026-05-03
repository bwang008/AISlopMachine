extends Node

enum GameState {
	IDLE,
	SPINNING,
	EVALUATING,
	PAYOUT
}

var current_state: GameState = GameState.IDLE
var credits: int = 1000
var bet_amount: int = 10

# 5 reels, 3 rows
const REELS_COUNT = 5
const ROWS_COUNT = 3

# The outcome of the current spin
# Represented as a 2D array: outcome[reel_index][row_index] = SlotSymbol
var current_outcome = []

# List of all available symbols to roll
# In a real game, this would be populated from resources
var available_symbols: Array[SlotSymbol] = []
var active_paylines: Array[Payline] = []

var pending_win_amount: int = 0
var pending_winning_lines: Array = []

func _ready():
	EventManager.spin_requested.connect(_on_spin_requested)
	EventManager.spin_stopped.connect(on_all_reels_stopped)
	
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
		
	if active_paylines.is_empty():
		var p1 = Payline.new()
		p1.positions.assign([Vector2(0, 0), Vector2(1, 0), Vector2(2, 0), Vector2(3, 0), Vector2(4, 0)])
		active_paylines.append(p1)
		var p2 = Payline.new()
		p2.positions.assign([Vector2(0, 1), Vector2(1, 1), Vector2(2, 1), Vector2(3, 1), Vector2(4, 1)])
		active_paylines.append(p2)
		var p3 = Payline.new()
		p3.positions.assign([Vector2(0, 2), Vector2(1, 2), Vector2(2, 2), Vector2(3, 2), Vector2(4, 2)])
		active_paylines.append(p3)

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

func _on_spin_requested():
	if current_state != GameState.IDLE:
		print("Cannot spin, state is not IDLE")
		return
	
	if credits < bet_amount:
		print("Not enough credits")
		return
		
	credits -= bet_amount
	EventManager.credits_updated.emit(credits)
	
	change_state(GameState.SPINNING)
	
	# Math-first RNG: Calculate the outcome instantly
	calculate_spin_outcome()
	EventManager.spin_started.emit()

func calculate_spin_outcome():
	current_outcome.clear()
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

func evaluate_wins():
	pending_win_amount = 0
	pending_winning_lines.clear()
	
	for payline in active_paylines:
		if payline.positions.size() == 0:
			continue
			
		var first_pos = payline.positions[0]
		var match_symbol = current_outcome[first_pos.x][first_pos.y]
		if match_symbol == null:
			continue
			
		var match_count = 1
		for i in range(1, payline.positions.size()):
			var pos = payline.positions[i]
			var symbol = current_outcome[pos.x][pos.y]
			if symbol != null and symbol.id == match_symbol.id:
				match_count += 1
			else:
				break
				
		# Need at least 3 matches from left to right to win
		if match_count >= 3:
			var win_amount = match_symbol.base_value * match_count * payline.multiplier
			pending_win_amount += win_amount
			pending_winning_lines.append(payline)
			print("Evaluated Win! Matched ", match_count, " ", match_symbol.id, "s for ", win_amount)
			
	if pending_win_amount > 0:
		print("Total pending win for spin: ", pending_win_amount)
	else:
		print("No pending win this spin.")

# Called by the visual slot machine when all reels have finished their stopping animations
func on_all_reels_stopped():
	if current_state == GameState.SPINNING:
		change_state(GameState.EVALUATING)
		
		# Now that reels stopped visually, broadcast the win to trigger visual highlights
		if pending_win_amount > 0:
			EventManager.win_calculated.emit(pending_win_amount, pending_winning_lines)
			
			# Add a small delay for dramatic effect before showing the credits
			await get_tree().create_timer(1.5).timeout
			
			change_state(GameState.PAYOUT)
			credits += pending_win_amount
			EventManager.credits_updated.emit(credits)
		
		# Go back to IDLE
		change_state(GameState.IDLE)
