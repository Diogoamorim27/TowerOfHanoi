extends Sprite

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	
	
func _input(event):
	self.position = get_global_mouse_position()
