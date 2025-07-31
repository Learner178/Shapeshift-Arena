extends RigidBody2D

@export var torque_force: float = 20000.0
@export var jump_force: float = 450.0

@onready var ground_check: Node2D = $GroundCheck 
@onready var ray_ground: RayCast2D = $GroundCheck/RayCastGround
@onready var shape: CollisionShape2D = $CollisionShape2D
@onready var sprite: Sprite2D = $Sprite2D
@onready var shapeshift_timer: Timer = $ShapeShiftTimer

var shapes = ["circle", "square", "capsule", "triangle", "rocket", "magnet", "hexagon"]
var current_shape = ""

func _ready():
	randomize()
	shapeshift()
	start_shapeshift_timer()
	
func _physics_process(delta: float) -> void:
	
	ground_check.rotation = -rotation
	
	var direction := 0
	if Input.is_action_pressed("move_left"):
		direction -= 1
	if Input.is_action_pressed("move_right"):
		direction += 1

	if direction != 0:
		apply_torque_impulse(direction * torque_force * delta)

	if current_shape == "rocket":
	   if Input.is_action_pressed("jump"):
		apply_central_impulse(Vector2(0, -jump_force * delta))  # smooth flying
	else:
	   if Input.is_action_just_pressed("jump") and ray_ground.is_colliding():
		apply_central_impulse(Vector2(0, -jump_force)) # standard jumping
	

func shapeshift():
	var selected = shapes.pick_random()
	current_shape = shapes[randi() % shapes.size()]
	
	match selected:
		"circle":
			shape.shape = CircleShape2D.new()
			sprite.texture = preload("res://Assets/football.png")
			sprite.scale = Vector2(0.025, 0.025)
			sprite.rotation_degrees = 0
			self.physics_material_override = null
			
		"square":
			shape.shape = RectangleShape2D.new()
			shape.shape.extents = Vector2(10, 10)
			sprite.texture = preload("res://Assets/square.png")
			sprite.scale = Vector2(0.08, 0.08)
			sprite.rotation_degrees = 0
			self.physics_material_override = create_physics_material(0.9, 0.1)  # High mass, low bounce

		"capsule":
			shape.shape = CapsuleShape2D.new()
			sprite.texture = preload("res://Assets/american-football.png")
			sprite.scale = Vector2(0.02, 0.02)
			sprite.rotation_degrees = 90
			self.physics_material_override = create_physics_material(0.5, 0.6)  # Light and bouncy
			
		"triangle":
			shape.shape = ConvexPolygonShape2D.new()
			shape.shape.points = [Vector2(-10, 10), Vector2(0, -10), Vector2(10, 10)]
			sprite.texture = preload("res://Assets/triangle.png")
			sprite.scale = Vector2(0.03, 0.03)
			sprite.rotation_degrees = 0
			self.physics_material_override = create_physics_material(0.3, 0.2)  # Low friction, light bounce
			
		"rocket":
			shape.shape = RectangleShape2D.new()
			shape.shape.extents = Vector2(8, 16)
			sprite.texture = preload("res://Assets/rocket.png")
			sprite.scale = Vector2(0.05, 0.05)
			sprite.rotation_degrees = 0
			
		"hexagon":
			var hex = ConvexPolygonShape2D.new()
			var size = 12.0  # Radius of hexagon

			   # Points for a regular hexagon
			hex.points = [
				Vector2(size * cos(deg_to_rad(0)), size * sin(deg_to_rad(0))),
				Vector2(size * cos(deg_to_rad(60)), size * sin(deg_to_rad(60))),
				Vector2(size * cos(deg_to_rad(120)), size * sin(deg_to_rad(120))),
				Vector2(size * cos(deg_to_rad(180)), size * sin(deg_to_rad(180))),
				Vector2(size * cos(deg_to_rad(240)), size * sin(deg_to_rad(240))),
				Vector2(size * cos(deg_to_rad(300)), size * sin(deg_to_rad(300))),
			]
			shape.shape = hex
			sprite.texture = preload("res://Assets/hexagon.png")
			sprite.scale = Vector2(0.05, 0.05)
			sprite.rotation_degrees = 30
			self.physics_material_override = create_physics_material(0.4, 0.2)
			
			
		"magnet":
			shape.shape = CircleShape2D.new()
			sprite.texture = preload("res://Assets/magnet.png")
			sprite.scale = Vector2(0.03, 0.03)
			self.physics_material_override = create_physics_material(2.0, 0.0)  # Heavy, sticks

	print("Shapeshifted into: ", selected)  

func create_physics_material(friction: float, bounce: float) -> PhysicsMaterial:
	var mat = PhysicsMaterial.new()
	mat.friction = friction
	mat.bounce = bounce
	return mat


func start_shapeshift_timer():
	var next_time = 5.0
	shapeshift_timer.wait_time = next_time
	shapeshift_timer.start()


func _on_shape_shift_timer_timeout() -> void:
	shapeshift()
	start_shapeshift_timer() # Restart with new interval
