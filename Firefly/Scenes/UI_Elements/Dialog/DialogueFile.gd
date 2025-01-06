class_name DialogueData
extends Resource

@export var identifier: String = "change_this"

## The first thing that will be said
@export_multiline var initial_dialogue: Array[String] = ["Dummy Text Here"]

## The second thing that will be said
@export_multiline var follow_up_dialogue: Array[String] = ["Summarize what was said above but exasperated"]

## If finishing this dialogue should cause victory
@export var victory_dialogue: bool = false
