extends Control

func _on_Button_pressed():
	Autoload.disc_count = int($SpinBox.get_line_edit().text)
	get_tree().change_scene("res://Main.tscn")


func _on_Info_pressed():
		get_tree().change_scene("res://Creditos.tscn")

func _on_Exit_pressed():
	get_tree().quit()
