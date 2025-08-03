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

var shapes = ["circle", "square", "capsule", "triangle", "rocket", "magnet", "hexagon", "helium"]
var current_shape = ""
var lock_body_rotation = false


func _ready():
    randomize()
    shapeshift()
    start_shapeshift_timer()

func _physics_process(delta):
    ground_check.rotation = -rotation

    var direction := 0
    if Input.is_action_pressed("move_left"):
        direction -= 1
    if Input.is_action_pressed("move_right"):
        direction += 1
        

    match current_shape:
        "square", "triangle":
            if direction != 0 and ray_ground.is_colliding():
                apply_central_force(Vector2(direction * slide_force, 0))
            else:
                apply_central_force(Vector2(direction * slide_force * 0.5,0))
            if Input.is_action_just_pressed("jump") and ray_ground.is_colliding():
                apply_central_impulse(Vector2(0, -jump_force))
                rotate(deg_to_rad(360))  # Full flip

        "circle", "hexagon":
            if direction != 0:
                apply_torque_impulse(direction * move_force * delta)
                # Add subtle linear push (ice-friendly)
                linear_velocity.x += direction * 500.0 * delta
            if Input.is_action_just_pressed("jump") and ray_ground.is_colliding():
                apply_central_impulse(Vector2(0, -jump_force))

        "capsule":
            if direction != 0:
                apply_torque_impulse(direction * move_force * delta)
                # Add subtle linear push (ice-friendly)
                linear_velocity.x += direction * 500.0 * delta
            if Input.is_action_just_pressed("jump") and ray_ground.is_colliding():
                apply_central_impulse(Vector2(0, -jump_force * bounce_force))

        "rocket":
                var rocket_max_angle_deg = 80
                var rocket_tilt_speed = 60.0
                var rocket_upright_damping = 4.0
                var rocket_thrust = 1000.0

                if direction != 0:
                    $Pivot.rotation_degrees += direction * rocket_tilt_speed * delta
                    $Pivot.rotation_degrees = clamp($Pivot.rotation_degrees, -rocket_max_angle_deg, rocket_max_angle_deg)
                else:
                    # Return to upright when idle
                    $Pivot.rotation = lerp($Pivot.rotation, 0.0, rocket_upright_damping * delta)

                # 2. Thrust in the tilted direction (UP relative to pivot)
                if Input.is_action_pressed("jump"):
                    var thrust_dir = -$Pivot.transform.y.normalized()  # Local UP direction
                    apply_central_impulse(thrust_dir * rocket_thrust * delta)


        "helium":
            if direction != 0:
                apply_central_force(Vector2(direction * float_speed * 2.5, 0))
            apply_central_force(Vector2(0, -float_speed))  # slow float up

        "magnet":
            if direction != 0:
                apply_torque_impulse(direction * move_force * delta)
                # Add subtle linear push (ice-friendly)
                linear_velocity.x += direction * 500.0 * delta
            if Input.is_action_just_pressed("jump") and ray_ground.is_colliding():
                apply_central_impulse(Vector2(0, -jump_force))
            check_for_metal_surfaces()
            
    if lock_body_rotation:
        rotation = 0
        angular_velocity = 0


func shapeshift():
    var selected = shapes.pick_random()
    current_shape = selected

    match selected:
        "circle":
            shape.shape = CircleShape2D.new()
            sprite.texture = preload("res://Assets/football.png")
            sprite.scale = Vector2(0.025, 0.025)
            apply_physics_material(0.5, 0.2, 1.0, 0.0, 0.1)
            
            lock_body_rotation = false

        "square":
            var rect = RectangleShape2D.new()
            rect.extents = Vector2(10, 10)
            shape.shape = rect
            sprite.texture = preload("res://Assets/square.png")
            sprite.scale = Vector2(0.08, 0.08)
            apply_physics_material(0.4, 0.1, 1.0, 0.0, 0.2)
            
            lock_body_rotation = false

        "capsule":
            shape.shape = CapsuleShape2D.new()
            sprite.texture = preload("res://Assets/american-football.png")
            sprite.scale = Vector2(0.02, 0.02)
            sprite.rotation_degrees = 90
            apply_physics_material(0.4, 0.6, 1.0, 0.1, 0.2)
            
            lock_body_rotation = false

        "triangle":
            var tri = ConvexPolygonShape2D.new()
            tri.points = [Vector2(-12, 12), Vector2(0, -12), Vector2(12, 12)]
            shape.shape = tri
            sprite.texture = preload("res://Assets/triangle.png")
            sprite.scale = Vector2(0.03, 0.03)
            apply_physics_material(0.3, 0.2, 1.0, 0.0, 0.2) 
            
            lock_body_rotation = false

        "rocket":
            var rect = RectangleShape2D.new()
            rect.extents = Vector2(8, 16)
            shape.shape = rect
            sprite.texture = preload("res://Assets/rocket.png")
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
            sprite.texture = preload("res://Assets/hexagon.png")
            sprite.rotation_degrees = 30
            sprite.scale = Vector2(0.05, 0.05)
            apply_physics_material(0.5, 0.2, 1.0, 0.0, 0.1)
            
            lock_body_rotation = false

        "magnet":
            shape.shape = CircleShape2D.new()
            sprite.texture = preload("res://Assets/magnet.png")
            sprite.scale = Vector2(0.03, 0.03)
            apply_physics_material(0.75, 0.1, 1.0, 0.0, 0.05)
            
            lock_body_rotation = false

        "helium":
            shape.shape = CircleShape2D.new()
            sprite.texture = preload("res://Assets/Balloon.png")
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

func _on_shape_shift_timer_timeout():
    shapeshift()
    start_shapeshift_timer()

func check_for_metal_surfaces():
    # Placeholder for magnet attraction logic
    # You can scan for metal-tagged areas using Area2D or RayCast2D
    pass
    
func apply_physics_material(friction: float, bounce: float, gravity_scale := 1.0, linear_damp := 0.0, angular_damp := 0.0):
    var mat := PhysicsMaterial.new()
    mat.friction = friction
    mat.bounce = bounce
    physics_material_override = mat
    
    self.gravity_scale = gravity_scale
    self.linear_damp = linear_damp
    self.angular_damp = angular_damp
