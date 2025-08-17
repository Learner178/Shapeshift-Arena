extends Area2D

@export var speed := 200.0
@export var damage := 10

var direction: Vector2 = Vector2.ZERO
var weapon_owner: Node = null  # Optional: helps avoid hitting the shooter
var ignore_time := 0.1

func _process(delta):
	position += Vector2.RIGHT.rotated(rotation) * speed * delta
	if not get_viewport_rect().has_point(global_position):
		queue_free()

func _physics_process(delta):   
	global_position += direction * speed * delta
	if ignore_time > 0:
		ignore_time -= delta

func _on_VisibilityNotifier2D_screen_exited():
	queue_free()

func _on_body_entered(body):
	if body == weapon_owner:
		return

	# Block bullet if it hits a BubbleShield
	if body.is_in_group("Shield"):
		queue_free()
		return

	
	if body == weapon_owner and ignore_time > 0:
		return  # Ignore hitting the shooter right after firing
	
	if body.is_in_group("Player") or body.is_in_group("Enemy"):
		if body.has_method("take_damage"):
			var dir = (body.global_position - global_position).normalized()
			body.take_damage(20, dir * 300) # 20 damage, knockback force
	queue_free()
