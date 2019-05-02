extends Control

var name_of_map := ''
var seed_nr := -1
var width := 0
var height := 0
var has_changed := false
var spread := 0.0

func _on_LineEdit_text_changed(new_text):
	name_of_map = new_text

func _on_Width_value_changed(value):
	width = value

func _on_Height_value_changed(value):
	height = value

func _on_SeedNr_text_changed(new_text):
	seed_nr = new_text.hash()

func _on_Button_pressed():
	has_changed = true

func _on_Spread_value_changed(value):
	spread = value
