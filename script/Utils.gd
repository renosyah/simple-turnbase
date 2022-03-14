extends Node
class_name Utils

const FLOAT_EPSILON = 0.00001

static func compare_floats(a, b, epsilon = FLOAT_EPSILON) -> bool:
	return abs(a - b) <= epsilon
	
static func create_grid_name(_axial_coordinate : Vector2) -> String:
	return "GRID-"+ str(_axial_coordinate.x) +"-"+ str(_axial_coordinate.y)
	
	
enum {
	FORMAT_HOURS   = 1 << 0,
	FORMAT_MINUTES = 1 << 1,
	FORMAT_SECONDS = 1 << 2,
	FORMAT_DEFAULT = FORMAT_HOURS | FORMAT_MINUTES | FORMAT_SECONDS
}
	
static func format_time(time, format = FORMAT_DEFAULT, digit_format = "%02d", colon = " : "):
	var digits = []
	
	if format & FORMAT_HOURS:
		var hours = digit_format % [time / 3600]
		digits.append(hours)
	
	if format & FORMAT_MINUTES:
		var minutes = digit_format % [time / 60]
		digits.append(minutes)
	
	if format & FORMAT_SECONDS:
		var seconds = digit_format % [int(ceil(time)) % 60]
		digits.append(seconds)
	
	var formatted = String()
	
	for digit in digits:
		formatted += digit + colon
		
	if not formatted.empty():
		formatted = formatted.rstrip(colon)
		
	return formatted
	
	
	
static func draw_hexagon_points(size : int = 8) -> Array:
	var points = []
	for z in range(0, (2 * size) - 1):
		points += print_hex_line(z, size, z)
		
	var points_no_duplicate = []
	for i in points:
		if not is_in_array(i, points_no_duplicate):
			points_no_duplicate.append(i)
		
	return points_no_duplicate
	
static func is_in_array(obj : Dictionary, arr : Array) -> bool:
	for i in arr:
		if "{x}{y}".format(i["vector"]) == "{x}{y}".format(obj["vector"]):
			return true
			
	return false
	
static func print_hex_line(z, size : int,real_z: int) -> Array:
	var points = []
	if z >= size:
		z = 2 * size - 2 - z
		
	var start = size - z - 1;
	var end = start + size + z;
	
	for x in range(0, start):
		points.append({"type":0, "vector": {"x":x,"y":real_z}})
		
	var last_x = 0
	for x in range(start, end):
		points.append({"type":1, "vector": {"x":x,"y":real_z}})
		last_x = x
		
	var inc = 0;
	for j in range(start, end):
		points.append({"type":1, "vector": {"x":(last_x + inc),"y":real_z}})
		inc+=1
		
	return points
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
