extends Control

var name_for_map := ''
var has_changed := false

func _on_LineEdit_text_changed(new_text):
	name_for_map = new_text
	has_changed = true