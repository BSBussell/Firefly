extends UiComponent
class_name TotalJarCounter

@export var CONTAINER: Control
@export var LEVEL_COUNTER: Label 
@export var GAME_COUNTER: Label
@export var COUNTER_ANIMATOR: AnimationPlayer
@export var ANIMATION_TIMER: Timer
@export var LEVEL_GLITTER: CPUParticles2D
@export var TOTAL_GLITTER: CPUParticles2D

@export var shine_color: Color

var out: bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	
	# Get all the jars in the level that are not blue
	var yellow_jars: Array = _jar_tracker.filter(func (value): 
		
		var level_match: bool = value["level_id"] == _globals.ACTIVE_LEVEL.id
		var is_yellow: bool = value["blue"] == false
		return level_match and is_yellow
		
	)
	
	var jar_max: int = yellow_jars.size()
	var collected: int = _jar_tracker.num_found_jars(_globals.ACTIVE_LEVEL.id)
	
	LEVEL_COUNTER.text = "%d/%d" % [jar_max, collected]
	
	
	
func process_jars(jars: Array):
	var yellow_collected = 0
	var blue_collected = 0
	var yellow_total = 0
	var blue_total = 0

	for jar in jars:
		if jar["blue"]:
			blue_total += 1
			if jar["nabbed"]:
				blue_collected += 1
		else:
			yellow_total += 1
			if jar["nabbed"]:
				yellow_collected += 1
		
	return [yellow_total, yellow_collected, blue_total, blue_collected]

	
func update_labels() -> void:
	
	var level_jars: Array = _jar_tracker.get_level_jars(_globals.ACTIVE_LEVEL.id)
	var processed_totals: Array = process_jars(level_jars)
	
	
	var yellow_collected: int = processed_totals[1]
	var yellow_max: int = processed_totals[0]
	var blue_collected: int = processed_totals[3]
	var blue_max: int = processed_totals[2]

	var total_collected: int = processed_totals[1] + processed_totals[3]
	
	## Effects
	
	# If the number of collected yellow jars
	if yellow_collected >= yellow_max:
		LEVEL_COUNTER.add_theme_color_override("font_color", shine_color)
	else:
		LEVEL_COUNTER.remove_theme_color_override("font_color")
		
	if blue_collected >= blue_max:
		LEVEL_GLITTER.emitting = true
		LEVEL_GLITTER.resolution_update()
	else:
		LEVEL_GLITTER.emitting = false
	
	LEVEL_COUNTER.text = "%d/%d" % [total_collected, yellow_max]
	
	
	# Game - Wide label
	var all_jars: Array = _jar_tracker.known_jars.values()
	processed_totals = process_jars(all_jars)
	
	
	yellow_collected = processed_totals[1]
	yellow_max = processed_totals[0]
	blue_collected = processed_totals[3]
	blue_max = processed_totals[2]

	total_collected = processed_totals[1] + processed_totals[3]
	
	## Effects
	
	# If we got all the yellows turn yellow
	if yellow_collected >= yellow_max:
		GAME_COUNTER.add_theme_color_override("font_color", shine_color)
	else:
		GAME_COUNTER.remove_theme_color_override("font_color")
		
	# If we got all the blues sparkle
	if blue_collected >= blue_max:
		TOTAL_GLITTER.emitting = true
		TOTAL_GLITTER.resolution_update()
	else:
		TOTAL_GLITTER.emitting = false
	
	# Display Text
	GAME_COUNTER.text = "%d/%d" % [total_collected, yellow_max]
	
	
func show_counter():
	
	
	update_labels()
	
	
	if not out:
		play_show()
		out = true

func hide_counter(time: float = 3.0):
	ANIMATION_TIMER.start(time)

func _on_hide_timer_timeout():
	out = false
	play_hide()

## Ensures that on animation playing we don't teleport pos
func play_show():
	
	var current_pos = CONTAINER.anchor_left  
	COUNTER_ANIMATOR.get_animation("Show").track_set_key_value(0, 0, current_pos)
	COUNTER_ANIMATOR.play("Show")
	
## Ensures that on animation playing we don't teleport pos
func play_hide():
	var current_pos = CONTAINER.anchor_left
	COUNTER_ANIMATOR.get_animation("Hide").track_set_key_value(0, 0, current_pos)
	COUNTER_ANIMATOR.play("Hide")
	
