extends Control

@onready var coin_label = $CoinLabel

func _ready():
	update_coin_display()

func update_coin_display():
	coin_label.text = "🪙 " + str(CoinManager.coins)
