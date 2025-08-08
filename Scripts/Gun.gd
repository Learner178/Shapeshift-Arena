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
    # collect candidates (change group names here if your groups are different)
    var candidates := []
    candidates += get_tree().get_nodes_in_group("Player")
    candidates += get_tree().get_nodes_in_group("Enemy")

    # remove weapon owner and invalid nodes; ensure we only keep Node2D-like objects
    candidates = candidates.filter(func(c):
        return c != weapon_owner and is_instance_valid(c) and (c is Node2D)
    )

    if candidates.is_empty():
        target_enemy = null
        return

    # find the closest one manually (min_by replacement)
    var best : Node2D= null
    var best_dist := INF
    for c in candidates:
        var d := global_position.distance_to(c.global_position)
        if d < best_dist:
            best_dist = d
            best = c

    target_enemy = best

func fire():
    if not can_fire or weapon_owner == null or bullet_scene == null:
        print("not shot")
        return

    var direction = Vector2.RIGHT.rotated(global_rotation)

    # --- spawn position: prefer a Muzzle node, fallback to old offset ---
    var spawn_pos: Vector2
    if has_node("Muzzle"):
        spawn_pos = $Muzzle.global_position
    else:
        spawn_pos = global_position + direction * 20

    var bullet = bullet_scene.instantiate()

    # --- add bullet to the active scene safely (avoid get_tree().current_scene property misuse) ---
    var root_scene = get_tree().get_current_scene()
    if root_scene == null:
        root_scene = get_tree().get_root()
    root_scene.add_child(bullet)

    bullet.global_position = spawn_pos
    bullet.rotation = global_rotation
    bullet.direction = direction
    bullet.weapon_owner = weapon_owner

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
        
    
