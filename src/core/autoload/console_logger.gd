extends Node

static func has(variable: Variant, var_name: String) -> bool:
	if variable == null:
		var stack = get_stack()
		var caller_file = "Unknown"
		if stack.size() > 1:
			caller_file = stack[1].source.get_file().get_basename()
		
		push_error("%s: %s NOT ASSIGNED" % [caller_file, var_name])
		return false
	return true

static func print(message: String) -> void:
	var stack = get_stack()
	var caller_file = "Unknown"
	if stack.size() > 1:
		caller_file = stack[1].source.get_file().get_basename()

	print("[%s] %s" % [caller_file, message])
