extends Node

var collected_jars = {}  # Dictionary to store the collected state of jars by their instance ID

func mark_jar_collected(jar_id):
	if not _loader.loading:
		collected_jars[jar_id] = true


# Also calculates the running tally of jars
func is_jar_collected(jar_id):
	return collected_jars.has(jar_id) and collected_jars[jar_id]


## Returns the number of found jars
func num_found_jars() -> int:

	return collected_jars.size()

## Clears the collected jars dict
func reset_jars():
	collected_jars.clear()
	print(collected_jars.size())