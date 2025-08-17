extends Node2D

@export var shield_duration := 5.0
var weapon_owner: Node2D = null

func _ready():
	add_to_group("Pickup")
	$Area2D.body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("Player") or body.is_in_group("Enemy"):
		if body.has_weapon:
			return
		weapon_owner = body
		body.has_weapon = true
		body.current_weapon = self

		# Attach shield to player
		get_parent().remove_child(self)
		weapon_owner.add_child(self)
		position = Vector2.ZERO

		# Change collision to block bullets (active mode)
		$Area2D.collision_layer = 4  # Example: Active Shields
		$Area2D.collision_mask = 8   # Example: Bullets

		# Optional: make owner invincible
		if weapon_owner.has_method("set_invincible"):
			weapon_owner.set_invincible(true)

		# Start removal timer
		var timer = Timer.new()
		timer.wait_time = shield_duration
		timer.one_shot = true
		timer.timeout.connect(_on_shield_timeout)
		weapon_owner.add_child(timer)
		timer.start()

func _on_shield_timeout():
	if is_instance_valid(weapon_owner) and weapon_owner.has_method("set_invincible"):
		weapon_owner.set_invincible(false)
	if is_instance_valid(weapon_owner):
		weapon_owner.has_weapon = false
		weapon_owner.current_weapon = null
	queue_free()
