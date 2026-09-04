extends Node

enum Location {
	FOREST,    
	MINE,      
	RIVER,   
	BATTLEFIELD
}

var current_location: Location = Location.FOREST
var player_stats: Dictionary = {
	"wood": 0,
	"stone": 0,
	"fish": 0,
	"gold": 0,
	"level": 1,
	"xp": 0
}

signal location_changed(new_location: Location)
signal resource_collected(resource: String, amount: int)

func change_location(new_location: Location):
	current_location = new_location
	location_changed.emit(new_location)

func collect_resource(resource: String, amount: int):
	player_stats[resource] = player_stats.get(resource, 0) + amount
	resource_collected.emit(resource, amount)
