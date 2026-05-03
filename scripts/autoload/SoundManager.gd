extends Node

var spin_player: AudioStreamPlayer
var stop_player: AudioStreamPlayer
var win_player: AudioStreamPlayer

func _ready():
	# Create AudioStreamPlayers and load the synthetic audio files
	spin_player = AudioStreamPlayer.new()
	spin_player.stream = load("res://assets/audio/spin.wav")
	
	stop_player = AudioStreamPlayer.new()
	stop_player.stream = load("res://assets/audio/stop.wav")
	stop_player.volume_db = linear_to_db(0.5) # Sets volume to exactly 50%
	
	win_player = AudioStreamPlayer.new()
	win_player.stream = load("res://assets/audio/win.wav")
	
	add_child(spin_player)
	add_child(stop_player)
	add_child(win_player)
	
	# To add real sounds: 
	# 1. Click on SoundManager in the Autoload/Scene tree
	# 2. Assign .wav or .ogg files to the 'stream' property of these nodes
	# For now, we will just print to console to verify the logic works.
	
	EventManager.spin_started.connect(_on_spin_started)
	EventManager.reel_stopped.connect(_on_reel_stopped)
	EventManager.spin_stopped.connect(_on_spin_stopped)
	EventManager.win_calculated.connect(_on_win_calculated)

func _on_spin_started():
	print("[AUDIO] Playing Spin Loop")
	if spin_player.stream != null:
		spin_player.play()

func _on_reel_stopped(_reel_index: int):
	print("[AUDIO] Playing Reel Stop Thud")
	if stop_player.stream != null:
		stop_player.play()

func _on_spin_stopped():
	print("[AUDIO] Stopping Spin Loop")
	spin_player.stop()

func _on_win_calculated(amount: int, lines: Array):
	print("[AUDIO] Playing Win Fanfare (Amount: ", amount, ")")
	if win_player.stream != null:
		win_player.play()

func play_sfx(_sfx_name: String):
	pass

func play_music(_music_name: String):
	pass
