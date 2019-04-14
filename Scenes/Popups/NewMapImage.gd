extends Control

var name_for_map := ''
var has_changed := false

func _on_LineEdit_text_changed(new_text):
	name_for_map = new_text

func _on_Button_pressed():
	has_changed = true
