extends Node

## TODO: Convert this into a GDExtension, as it'll run faster
# Magic function made by Gerblesh on github from https://github.com/godotengine/godot-proposals/issues/6389
func lerpi(origin: float, target: float, weight: float) -> float:
	target = floorf(target)
	origin = floorf(origin)
	var distance: float = ceilf(absf(target - origin) * weight)
	return move_toward(origin, target, distance)
