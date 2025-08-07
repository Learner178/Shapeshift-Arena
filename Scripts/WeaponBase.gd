extends Area2D

@export var fire_cooldown: float = 0.3
var weapon_owner: Node2D
var can_fire := true

func _ready():
	$FireCooldownTimer.wait_time = fire_cooldown
	$FireCooldownTimer.one_shot = true
	$FireCooldownTimer.timeout.connect(_on_fire_cooldown_timeout)

func _on_fire_cooldown_timeout():
	can_fire = true

func fire():
	# To be overridden in child weapons like Gun
	pass
