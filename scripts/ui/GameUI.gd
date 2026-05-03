extends CanvasLayer

@onready var spin_button: Button = $SpinButton
@onready var credits_label: Label = $CreditsLabel

var displayed_credits: int = 1000
var actual_credits: int = 1000

func _ready():
	spin_button.pressed.connect(_on_spin_pressed)
	EventManager.credits_updated.connect(_on_credits_updated)
	EventManager.state_changed.connect(_on_state_changed)
	EventManager.payout_started.connect(_on_payout_started)
	
	displayed_credits = GameManager.credits
	actual_credits = GameManager.credits
	_update_label(displayed_credits)

func _on_spin_pressed():
	EventManager.spin_requested.emit()

func _on_credits_updated(new_amount: int):
	actual_credits = new_amount
	if GameManager.current_state != GameManager.GameState.PAYOUT:
		displayed_credits = new_amount
		_update_label(displayed_credits)

func _on_payout_started(amount: int):
	var target_credits = actual_credits + amount
	var tween = create_tween()
	tween.tween_method(func(val): _update_label(val), displayed_credits, target_credits, 1.5).set_ease(Tween.EASE_OUT)
	tween.finished.connect(func():
		displayed_credits = target_credits
		EventManager.payout_complete.emit()
	)

func _update_label(val: int):
	credits_label.text = "Credits: " + str(val)

func _on_state_changed(new_state: int):
	if new_state == GameManager.GameState.IDLE:
		spin_button.disabled = false
	else:
		spin_button.disabled = true
