extends Area2D

@export var speed := 200.0
@export var damage := 10
var direction: Vector2 = Vector2.ZERO
var weapon_owner: Node = null  # Optional: helps avoid hitting the shooter

func _process(delta):
    position += Vector2.RIGHT.rotated(rotation) * speed * delta
    if not get_viewport_rect().has_point(global_position):
        queue_free()

func _physics_process(delta):   
    global_position += direction * speed * delta

func _on_VisibilityNotifier2D_screen_exited():
    queue_free()

func _on_body_entered(body):
    if body.is_in_group("Enemies"):
        # You can add damage logic here
        queue_free()
