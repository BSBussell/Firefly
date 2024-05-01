extends Node

var collected_jars = {}  # Dictionary to store the collected state of jars by their instance ID

func mark_jar_collected(jar_id):
	collected_jars[jar_id] = true

func is_jar_collected(jar_id):
	return collected_jars.has(jar_id) and collected_jars[jar_id]

func reset_jars():
	collected_jars = {}
