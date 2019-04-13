extends Control

var map_name := ''
var width := 0
var height := 0
var octaves := 1
var period := 20.0
var persistence := 0.8
var seed_nr := -1
var has_changed := false

func _on_Width_value_changed(value):
	width = value

func _on_Height_value_changed(value):
	height = value

func _on_Octave_value_changed(value):
	octaves = value

func _on_Period_value_changed(value):
	period = value

func _on_Persistence_value_changed(value):
	persistence = value

func _on_Name_text_changed(new_text):
	map_name = new_text

func _on_Button_pressed():
	has_changed = true

func _on_SeedLine_text_changed(new_text):
	seed_nr = new_text.hash()
