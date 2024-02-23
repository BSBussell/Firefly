extends Node


# Magic function made by Gerblesh on github from https://github.com/godotengine/godot-proposals/issues/6389
static func lerpi(origin: float, target: float, weight: float) -> float:
	target = floorf(target)
	origin = floorf(origin)
	var distance: float = ceilf(absf(target - origin) * weight)
	return move_toward(origin, target, distance)
