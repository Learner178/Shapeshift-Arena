extends "res://Scripts/WeaponBase.gd"

@export var bullet_scene: PackedScene
@export var aim_delay := 0.2  # Delay between aim updates
@export var max_shots := 5
@export var weapon_type: String = "pistol" # pistol, rifle, revolver, shotgun


var target_enemy: Node2D = null
var shots_fired := 0
var aim_timer := 0.0

# These will be set automatically based on weapon_type in _ready()
var fire_rate := 0.5
var damage := 10
var bullet_speed := 400
var spread := 0.0
var shots_per_fire := 1
var max_ammo := 6


func _ready():
	match weapon_type:
		"pistol":
			fire_rate = 0.5
			damage = 10
			bullet_speed = 700
			spread = 0.0
			shots_per_fire = 1
			max_ammo = 6
		"rifle":
			fire_rate = 0.1
			damage = 8
			bullet_speed = 900
			spread = 0.05
			shots_per_fire = 1
			max_ammo = 30
		"revolver":
			fire_rate = 0.6
			damage = 20
			bullet_speed = 650
			spread = 0.02
			shots_per_fire = 1
			max_ammo = 6
		"shotgun":
			fire_rate = 1.0
			damage = 6
			bullet_speed = 550
			spread = 0.2
			shots_per_fire = 5
			max_ammo = 2
	
	$AimTimer.wait_time = aim_delay
	$AimTimer.start()
	$FireCooldownTimer.wait_time = 0.5  # Cooldown after each shot
	can_fire = true

func _process(delta):
	if weapon_owner == null:
		return
		
	aim_timer -= delta
	if aim_timer <= 0:
		update_target()
		aim_timer = aim_delay

	if target_enemy:
		var dir = (target_enemy.global_position - global_position).normalized()
		global_rotation = dir.angle()

func update_target():
	var candidates := []

	# Only target the opposite team
	if weapon_owner.is_in_group("Player"):
		candidates += get_tree().get_nodes_in_group("Enemy")
	elif weapon_owner.is_in_group("Enemy"):
		candidates += get_tree().get_nodes_in_group("Player")

	# Remove invalid nodes just in case
	candidates = candidates.filter(func(c):
		return is_instance_valid(c) and (c is Node2D)
	)

	if candidates.is_empty():
		target_enemy = null
		return

	# Find the closest target
	var best: Node2D = null
	var best_dist := INF
	for c in candidates:
		var d := global_position.distance_to(c.global_position)
		if d < best_dist:
			best_dist = d
			best = c

	target_enemy = best

func fire():
	if not can_fire or weapon_owner == null or bullet_scene == null:
		return

	for i in range(shots_per_fire):
		var dir = Vector2.RIGHT.rotated(global_rotation)
		
		# Apply spread for multi-bullet weapons like shotgun
		if spread > 0.0:
			var spread_angle = randf_range(-spread, spread)
			dir = dir.rotated(spread_angle)
		
		# Spawn position from Muzzle if available
		var spawn_pos: Vector2
		if has_node("Muzzle"):
			spawn_pos = $Muzzle.global_position
		else:
			spawn_pos = global_position + dir * 20
		
		var bullet = bullet_scene.instantiate()
		bullet.global_position = spawn_pos
		bullet.rotation = dir.angle()
		bullet.direction = dir
		bullet.weapon_owner = weapon_owner
		bullet.speed = bullet_speed
		bullet.damage = damage
		
		var root_scene = get_tree().root.get_child(0)
		if root_scene:
			root_scene.add_child(bullet)

	can_fire = false
	$FireCooldownTimer.start()
	shots_fired += 1

	if shots_fired >= max_ammo:
		if weapon_owner:
			weapon_owner.has_weapon = false
			weapon_owner.current_weapon = null
		queue_free()


func _on_FireCooldownTimer_timeout():
	can_fire = true
	
func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player") and not body.has_weapon:
		body.pickup_weapon(self)
		
	
