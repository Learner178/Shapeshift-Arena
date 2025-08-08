extends RigidBody2D

@export var move_force: float = 10000.0
@export var slide_force: float = 1000.0
@export var float_speed: float = 80.0
@export var jump_force: float = 650.0
@export var rocket_thrust: float = 1000.0
@export var bounce_force: float = 1.5

@onready var ground_check: Node2D = $GroundCheck
@onready var ray_ground: RayCast2D = $GroundCheck/RayCastGround
@onready var shape: CollisionShape2D = $CollisionShape2D
@onready var sprite: Sprite2D = $Pivot/Sprite2D
@onready var shapeshift_timer: Timer = $ShapeShiftTimer
@onready var decision_timer: Timer = $DecisionTimer
@onready var weapon_holder: Node = $WeaponHolder  # Assuming you have a WeaponHolder node
@onready var player = get_node("player")

var shapes = ["circle", "square", "capsule", "triangle", "rocket", "magnet", "hexagon", "helium"]
var current_shape = ""
var lock_body_rotation = false

var has_weapon: bool = false
var current_weapon = null
var held_weapon = null
var facing_right = true  # Update based on movement direction

# AI movement
var direction := 0
var jump_requested := false
var target_player : RigidBody2D = null
var target_gun : Node = null

func _ready():
    randomize()
    shapeshift()
    start_shapeshift_timer()
    decision_timer.start()

func _process(delta: float) -> void:
     if player != null:
        var direction = player.global_position - global_position
        rotation = direction.angle()

func _physics_process(delta):
    ground_check.rotation = -rotation

    if held_weapon:
        # Aim weapon at closest player
        update_target_player()
        aim_weapon_at_target(delta)

        # Decide whether to fire weapon (random chance or simple logic)
        if Input.is_action_pressed("attack") == false:
            # Simulate AI attack press (50% chance to shoot when facing target)
            if randi() % 100 < 30:
                if held_weapon:
                    held_weapon.fire()
    else:
        # Move towards the closest gun to pick it up
        update_target_gun()
        if target_gun:
            var to_gun = target_gun.global_position - global_position
            direction = sign(to_gun.x)

            # Simple jump logic if gun is significantly above
            if to_gun.y < -20 and ray_ground.is_colliding():
                jump_requested = true

            # Check distance to gun to pick it up
            if to_gun.length() < 20:
                pickup_weapon(target_gun)
                target_gun = null
                direction = 0
        else:
            # No gun found, fallback: move toward closest player
            update_target_player()
            if target_player:
                var to_player = target_player.global_position - global_position
                direction = sign(to_player.x)

                if to_player.y < -20 and ray_ground.is_colliding():
                    jump_requested = true
            else:
                direction = 0  # No target

    # Movement logic (same as player)
    match current_shape:
        "square", "triangle":
            if direction != 0 and ray_ground.is_colliding():
                apply_central_force(Vector2(direction * slide_force, 0))
            else:
                apply_central_force(Vector2(direction * slide_force * 0.5, 0))
            if jump_requested and ray_ground.is_colliding():
                apply_central_impulse(Vector2(0, -jump_force))
                rotate(deg_to_rad(360))
                jump_requested = false

        "circle", "hexagon", "capsule", "magnet":
            if direction != 0:
                apply_torque_impulse(direction * move_force * delta)
                linear_velocity.x += direction * 500.0 * delta
            if jump_requested and ray_ground.is_colliding():
                var multiplier = bounce_force if current_shape == "capsule" else 1.0
                apply_central_impulse(Vector2(0, -jump_force * multiplier))
                jump_requested = false
            if current_shape == "magnet":
                check_for_metal_surfaces()

        "rocket":
            var rocket_max_angle_deg = 80
            var rocket_tilt_speed = 60.0
            var rocket_upright_damping = 4.0

            if direction != 0:
                $Pivot.rotation_degrees += direction * rocket_tilt_speed * delta
                $Pivot.rotation_degrees = clamp($Pivot.rotation_degrees, -rocket_max_angle_deg, rocket_max_angle_deg)
            else:
                $Pivot.rotation = lerp($Pivot.rotation, 0.0, rocket_upright_damping * delta)

            if jump_requested:
                var thrust_dir = -$Pivot.transform.y.normalized()
                apply_central_impulse(thrust_dir * rocket_thrust * delta)
                jump_requested = false

        "helium":
            if direction != 0:
                apply_central_force(Vector2(direction * float_speed * 2.5, 0))
            apply_central_force(Vector2(0, -float_speed))

    if lock_body_rotation:
        rotation = 0
        angular_velocity = 0

func _on_decision_timer_timeout():
    # Timer callback to update AI decisions periodically
    if held_weapon == null:
        update_target_gun()
    update_target_player()

func update_target_player():
    var players = get_tree().get_nodes_in_group("Player")
    if players.size() == 0:
        target_player = null
        return

    var closest_player = null
    var closest_dist = 9999999
    for p in players:
        if p == self:
            continue
        var dist = global_position.distance_to(p.global_position)
        if dist < closest_dist:
            closest_dist = dist
            closest_player = p
    target_player = closest_player

func update_target_gun():
    var guns = []
    for gun in get_tree().get_nodes_in_group("Gun"):
        # Ignore guns already held by someone else
        if gun.weapon_owner == null:
            guns.append(gun)
    if guns.size() == 0:
        target_gun = null
        return

    var closest_gun = null
    var closest_dist = 9999999
    for g in guns:
        var dist = global_position.distance_to(g.global_position)
        if dist < closest_dist:
            closest_dist = dist
            closest_gun = g
    target_gun = closest_gun

func pickup_weapon(weapon):
    if held_weapon != null:
        return

    held_weapon = weapon
    weapon.weapon_owner = self
    weapon.get_parent().remove_child(weapon)
    $WeaponHolder.add_child(weapon)

    weapon.global_position = $WeaponHolder.global_position
    weapon.rotation = 0
    weapon.position = Vector2.ZERO  # Local to WeaponHolder

    if weapon.has_node("CollisionShape2D"):
        weapon.get_node("CollisionShape2D").disabled = true

func aim_weapon_at_target(delta):
    if not held_weapon or not target_player:
        return

    var to_target = target_player.global_position - held_weapon.global_position
    var desired_angle = to_target.angle()
    # Smoothly rotate weapon toward target
    held_weapon.rotation = lerp_angle(held_weapon.rotation, desired_angle, 5 * delta)

func check_for_metal_surfaces():
    # Implement magnet logic if needed
    pass

func shapeshift():
    var selected = shapes.pick_random()
    current_shape = selected

    match selected:
        "circle":
            shape.shape = CircleShape2D.new()
            sprite.texture = preload("res://Assets/Characters/football.png")
            sprite.scale = Vector2(0.025, 0.025)
            apply_physics_material(0.5, 0.2, 1.0, 0.0, 0.1)
            
            lock_body_rotation = false

        "square":
            var rect = RectangleShape2D.new()
            rect.extents = Vector2(10, 10)
            shape.shape = rect
            sprite.texture = preload("res://Assets/Characters/square.png")
            sprite.scale = Vector2(0.08, 0.08)
            apply_physics_material(0.4, 0.1, 1.0, 0.0, 0.2)
            
            lock_body_rotation = false

        "capsule":
            shape.shape = CapsuleShape2D.new()
            sprite.texture = preload("res://Assets/Characters/american-football.png")
            sprite.scale = Vector2(0.02, 0.02)
            sprite.rotation_degrees = 90
            apply_physics_material(0.4, 0.6, 1.0, 0.1, 0.2)
            
            lock_body_rotation = false

        "triangle":
            var tri = ConvexPolygonShape2D.new()
            tri.points = [Vector2(-12, 12), Vector2(0, -12), Vector2(12, 12)]
            shape.shape = tri
            sprite.texture = preload("res://Assets/Characters/triangle.png")
            sprite.scale = Vector2(0.03, 0.03)
            apply_physics_material(0.3, 0.2, 1.0, 0.0, 0.2) 
            
            lock_body_rotation = false

        "rocket":
            var rect = RectangleShape2D.new()
            rect.extents = Vector2(8, 16)
            shape.shape = rect
            sprite.texture = preload("res://Assets/Characters/rocket.png")
            sprite.scale = Vector2(0.05, 0.05)
            sprite.rotation_degrees = 0
            $Pivot.rotation = 0
            apply_physics_material(0.4, 0.2, 0.3, 1.0, 0.8)
            
            # Lock rotation for rocket only
            lock_body_rotation = true
            rotation = 0  # ensure upright
            angular_velocity = 0

        "hexagon":
            var hex = ConvexPolygonShape2D.new()
            var size = 12.0
            hex.points = [
                Vector2(size * cos(deg_to_rad(0)), size * sin(deg_to_rad(0))),
                Vector2(size * cos(deg_to_rad(60)), size * sin(deg_to_rad(60))),
                Vector2(size * cos(deg_to_rad(120)), size * sin(deg_to_rad(120))),
                Vector2(size * cos(deg_to_rad(180)), size * sin(deg_to_rad(180))),
                Vector2(size * cos(deg_to_rad(240)), size * sin(deg_to_rad(240))),
                Vector2(size * cos(deg_to_rad(300)), size * sin(deg_to_rad(300)))
            ]
            shape.shape = hex
            sprite.texture = preload("res://Assets/Characters/hexagon.png")
            sprite.rotation_degrees = 30
            sprite.scale = Vector2(0.05, 0.05)
            apply_physics_material(0.5, 0.2, 1.0, 0.0, 0.1)
            
            lock_body_rotation = false

        "magnet":
            shape.shape = CircleShape2D.new()
            sprite.texture = preload("res://Assets/Characters/magnet.png")
            sprite.scale = Vector2(0.12, 0.12)
            apply_physics_material(0.75, 0.1, 1.0, 0.0, 0.05)
            
            lock_body_rotation = false

        "helium":
            shape.shape = CircleShape2D.new()
            sprite.texture = preload("res://Assets/Characters/Balloon.png")
            sprite.scale = Vector2(0.14, 0.14)
            sprite.rotation_degrees = 0
            $Pivot.rotation = 0
            apply_physics_material(0.2, 0.1, 0.05, 0.2, 0.05)
            
            # Lock rotation to stay upright
            lock_body_rotation = true
            rotation = 0
            angular_velocity = 0   

    print("Shapeshifted into: ", selected)

func start_shapeshift_timer():
    shapeshift_timer.wait_time = 5.0
    shapeshift_timer.start()

func apply_physics_material(friction: float, bounce: float, gravity_scale := 1.0, linear_damp := 0.0, angular_damp := 0.0):
    var mat := PhysicsMaterial.new()
    mat.friction = friction
    mat.bounce = bounce
    physics_material_override = mat
    
    self.gravity_scale = gravity_scale
    self.linear_damp = linear_damp
    self.angular_damp = angular_damp
