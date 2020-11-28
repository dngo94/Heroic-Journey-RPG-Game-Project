extends Area2D

var player = null

func detected():
	return player != null
		
func _on_PlayerDectection_body_entered(body):
	player = body

func _on_PlayerDectection_body_exited(body):
	player = null
