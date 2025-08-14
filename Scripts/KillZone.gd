# KillZone.gd
extends Area2D

func _on_body_entered(body):
    if body.has_method("on_eliminated"):
        body.on_eliminated()
    print("eliminated")
    if body.is_in_group("Player") or body.is_in_group("Enemy"):
        if body.has_method("take_damage"):
            body.take_damage(body.max_health)  # Instant kill
