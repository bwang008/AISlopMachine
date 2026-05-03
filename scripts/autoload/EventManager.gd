extends Node

# Signals for slot machine events
signal spin_requested
signal spin_started
signal spin_stopped
signal reel_stopped(reel_index: int)
signal win_calculated(amount: int)
signal credits_updated(new_amount: int)
signal state_changed(new_state: int)
