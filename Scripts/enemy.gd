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

var shapes = ["circle", "square", "capsule", "triangle", "rocket", "magnet", "hexagon", "helium"]
var current_shape = ""
var lock_body_rotation = false

# AI movement
var direction := 0
var jump_requested := false
var target_player : RigidBody2D = null

func _ready():
	randomize()
	shapeshift()
	start_shapeshift_timer()
	decision_timer.start()

func _physics_process(delta):
	ground_check.rotation = -rotation

	if target_player:
		var to_player = target_player.global_position - global_position
		direction = sign(to_player.x)

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

		"helium":
			if direction != 0:
				apply_central_force(Vector2(direction * float_speed * 2.5, 0))
			apply_central_force(Vector2(0, -float_speed))

	if lock_body_rotation:
		rotation = 0
		angular_velocity = 0

func _on_decision_timer_timeout():
	var players = get_tree().get_nodes_in_group("Player")

	if players.size() > 0:
		var closest_player = players[0]
		var closest_distance = global_position.distance_to(players[0].global_position)

		for i in range(1, players.size()):
			var p = players[i]
			var dist = global_position.distance_to(p.global_position)
			if dist < closest_distance:
				closest_distance = dist
				closest_player = p

		target_player = closest_player

		if target_player:
			var dx = target_player.global_position.x - global_position.x
			var dy = target_player.global_position.y - global_position.y

			direction = sign(dx)

			# Jump more often if the player is above
			if dy < -20:  # Player is significantly higher up
				jump_requested = randf() < 0.8
			elif abs(dy) < 50:
				jump_requested = randf() < 0.3
			else:
				jump_requested = false



func find_target_player():
	var players = get_tree().get_nodes_in_group("Player")
	var closest_distance = INF
	target_player = null

	for p in players:
		if not p or not p.is_inside_tree():
			continue
		var d = global_position.distance_to(p.global_position)
		if d < closest_distance:
			closest_distance = d
			target_player = p

func should_jump_to_reach(player):
	if not player:
		return false
	# Basic check: if player is higher and close horizontally
	var horizontal_distance = abs(player.global_position.x - global_position.x)
	var vertical_difference = player.global_position.y - global_position.y
	return horizontal_distance < 100 and vertical_difference < -20 and ray_ground.is_colliding()

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
			lock_body_rotation = true
			rotation = 0
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
			lock_body_rotation = true
			rotation = 0
			angular_velocity = 0

	print("Enemy shapeshifted into: ", selected)

func start_shapeshift_timer():
	shapeshift_timer.wait_time = 5.0
	shapeshift_timer.start()

func _on_shape_shift_timer_timeout():
	shapeshift()
	start_shapeshift_timer()

func check_for_metal_surfaces():
	# Placeholder for future magnet logic
	pass

func apply_physics_material(friction: float, bounce: float, gravity_scale := 1.0, linear_damp := 0.0, angular_damp := 0.0):
	var mat := PhysicsMaterial.new()
	mat.friction = friction
	mat.bounce = bounce
	physics_material_override = mat
	self.gravity_scale = gravity_scale
	self.linear_damp = linear_damp
	self.angular_damp = angular_damp
	
