extends "res://Scripts/WeaponBase.gd"

@export var bullet_scene: PackedScene
@export var aim_delay := 0.2  # Delay between aim updates
@export var max_shots := 5

var target_enemy: Node2D = null
var shots_fired := 0
var aim_timer := 0.0

func _ready():
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
        rotation = dir.angle()

func update_target():
    var candidates = get_tree().get_nodes_in_group("Player") + get_tree().get_nodes_in_group("Enemies")
    candidates = candidates.filter(func(c): return c != weapon_owner)
    if candidates.is_empty():
        target_enemy = null
        return
    target_enemy = candidates.min_by(func(e): return global_position.distance_to(e.global_position))


func fire():
    if not can_fire or weapon_owner == null or bullet_scene == null:
        print("not shot")
        return

    var direction = Vector2.RIGHT.rotated(global_rotation)
    var spawn_pos = global_position + direction * 20

    var bullet = bullet_scene.instantiate()
    bullet.global_position = spawn_pos
    bullet.rotation = global_rotation
    bullet.direction = direction
    bullet.weapon_owner = weapon_owner

    get_parent().add_child(bullet)
    print("shot")
    can_fire = false
    $FireCooldownTimer.start()
    shots_fired += 1

    if shots_fired >= max_shots:
        if weapon_owner:
            weapon_owner.has_weapon = false
            weapon_owner.current_weapon = null
        queue_free()

func _on_FireCooldownTimer_timeout():
    can_fire = true
    
func _on_body_entered(body: Node2D) -> void:
    if body.is_in_group("Player") and not body.has_weapon:
        body.pickup_weapon(self)
        
    
