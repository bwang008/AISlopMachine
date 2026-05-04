extends Node

var spin_player: AudioStreamPlayer
var stop_player: AudioStreamPlayer
var win_player: AudioStreamPlayer
var coin_chime_player: AudioStreamPlayer

var is_payout_active: bool = false
var current_pitch: float = 0.8
var tick_timer: Timer

func _ready():
	# Create AudioStreamPlayers and load the synthetic audio files
	spin_player = AudioStreamPlayer.new()
	spin_player.stream = load("res://assets/audio/spin.wav")
	
	stop_player = AudioStreamPlayer.new()
	stop_player.stream = load("res://assets/audio/stop.wav")
	stop_player.volume_db = linear_to_db(0.5) # Sets volume to exactly 50%
	
	win_player = AudioStreamPlayer.new()
	win_player.stream = load("res://assets/audio/win.wav")
	
	coin_chime_player = AudioStreamPlayer.new()
	coin_chime_player.stream = load("res://assets/audio/coin_chime.wav")
	
	add_child(spin_player)
	add_child(stop_player)
	add_child(win_player)
	add_child(coin_chime_player)
	
	tick_timer = Timer.new()
	tick_timer.wait_time = 0.08
	tick_timer.timeout.connect(_on_tick_timer_timeout)
	add_child(tick_timer)
	
	# To add real sounds: 
	# 1. Click on SoundManager in the Autoload/Scene tree
	# 2. Assign .wav or .ogg files to the 'stream' property of these nodes
	# For now, we will just print to console to verify the logic works.
	
	EventManager.spin_started.connect(_on_spin_started)
	EventManager.reel_stopped.connect(_on_reel_stopped)
	EventManager.spin_stopped.connect(_on_spin_stopped)
	EventManager.win_calculated.connect(_on_win_calculated)
	EventManager.payout_started.connect(_on_payout_started)
	EventManager.payout_complete.connect(_on_payout_complete)

func _on_spin_started():
	print("[AUDIO] Playing Spin Loop")
	if spin_player.stream != null:
		spin_player.play()

func _on_reel_stopped(_reel_index: int, _final_symbols: Array):
	print("[AUDIO] Playing Reel Stop Thud")
	if stop_player.stream != null:
		stop_player.play()

func _on_spin_stopped():
	print("[AUDIO] Stopping Spin Loop")
	spin_player.stop()

func _on_win_calculated(amount: int, lines: Array):
	print("[AUDIO] Win Calculated Signal Received (Amount: ", amount, ")")

func play_line_beep(pitch: float = 1.0):
	if win_player.stream != null:
		win_player.pitch_scale = pitch
		win_player.play()

func _on_payout_started(amount: int):
	print("[AUDIO] Starting Score Tick-Up")
	is_payout_active = true
	current_pitch = 0.8
	tick_timer.start()

func _on_payout_complete():
	print("[AUDIO] Stopping Score Tick-Up")
	is_payout_active = false
	tick_timer.stop()
	
func _on_tick_timer_timeout():
	if is_payout_active and coin_chime_player.stream != null:
		coin_chime_player.pitch_scale = current_pitch
		coin_chime_player.play()
		current_pitch = min(current_pitch + 0.02, 1.4)

func play_sfx(_sfx_name: String):
	pass

func play_music(_music_name: String):
	pass
