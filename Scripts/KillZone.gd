# KillZone.gd
extends Area2D

func _on_body_entered(body):
	if body.has_method("on_eliminated"):
		body.on_eliminated()
	print("eliminated")
	
