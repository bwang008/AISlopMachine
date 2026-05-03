extends CanvasLayer

@onready var spin_button: Button = $SpinButton
@onready var credits_label: Label = $CreditsLabel

func _ready():
	spin_button.pressed.connect(_on_spin_pressed)
	EventManager.credits_updated.connect(_on_credits_updated)
	EventManager.state_changed.connect(_on_state_changed)
	
	_on_credits_updated(GameManager.credits)

func _on_spin_pressed():
	EventManager.spin_requested.emit()

func _on_credits_updated(new_amount: int):
	credits_label.text = "Credits: " + str(new_amount)

func _on_state_changed(new_state: int):
	if new_state == GameManager.GameState.IDLE:
		spin_button.disabled = false
	else:
		spin_button.disabled = true
