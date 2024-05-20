extends Node

## TODO: Convert this into a GDExtension, as it'll run faster
# Magic function made by Gerblesh on github from https://github.com/godotengine/godot-proposals/issues/6389
func lerpi(origin: float, target: float, weight: float) -> float:
	target = floorf(target)
	origin = floorf(origin)
	var distance: float = ceilf(absf(target - origin) * weight)
	return move_toward(origin, target, distance)

func lerpiVec(origin: Vector2, target: Vector2, weight: float) -> Vector2:
	
	var smoothed_vector: Vector2 = Vector2.ZERO
	smoothed_vector.x = lerpi(origin.x, target.x, weight)
	smoothed_vector.y = lerpi(origin.y, target.y, weight)
	return smoothed_vector
