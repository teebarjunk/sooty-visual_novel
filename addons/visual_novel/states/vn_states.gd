@tool
extends Node

# flow state
var flow_history := []
var flow_visited := {}
var choice_history := {}

# captions
var caption_at: String = "bottom"
var caption_auto_clear: bool = true

# common
var time: DateTime = DateTime.new({weekday="sat"})
var start_time: int = 0 # seconds from DateTime
var play_time: int = 0 # seconds from DateTime
var _last_play_time: int = 0 # seconds
var score: int = 0

const F_GAME_STARTED: String = "_main/game_started"
const F_DIALOGUE_ENDED: String = "_main/dialogue_ended"
const F_FLOW_ENDED: String = "_main/flow_ended"

func _ready() -> void:
	Sooty.started.connect(_game_started)
	Sooty.actions.connect_methods(self, [advance_time])
	Sooty.dialogue.started.connect(_dialogue_started)
	Sooty.dialogue.ended.connect(_dialogue_ended)
	Sooty.dialogue.flow_started.connect(_flow_started)
	Sooty.dialogue.flow_ended.connect(_flow_ended)
	Sooty.dialogue.selected.connect(_selected)
	Sooty.saver.pre_save.connect(_pre_save)
	Sooty.saver.loaded.connect(_loaded)
	
func _pre_save():
	# update total time played
	var current_seconds := DateTime.create_from_current().get_total_seconds()
	play_time += (current_seconds - _last_play_time)
	_last_play_time = play_time

func _loaded():
	_last_play_time = DateTime.create_from_current().get_total_seconds()

func _game_started():
	if Sooty.dialogue.has_path(F_GAME_STARTED):
		play_time = 0
		_last_play_time = DateTime.create_from_current().get_total_seconds()
		Sooty.dialogue.goto(F_GAME_STARTED)
	else:
		push_error("There is no '%s' flow." % F_GAME_STARTED)

func _selected(id: String):
	UDict.tick(choice_history, id)

func _dialogue_started():
	flow_history.clear()

func _dialogue_ended():
	if len(flow_history) and flow_history[-1] != F_DIALOGUE_ENDED and Sooty.dialogue.can_goto(F_DIALOGUE_ENDED):
		Sooty.dialogue.stack(F_DIALOGUE_ENDED)

func _flow_started(flow: String):
	flow_history.append(flow)

func _flow_ended(flow: String):
	# tick number of times visited
	UDict.tick(flow_visited, flow)
	# goto the ending node
	if len(flow_history) and not flow_history[-1] in [F_DIALOGUE_ENDED, F_FLOW_ENDED] and Sooty.dialogue.can_goto(F_FLOW_ENDED):
		Sooty.dialogue.stack(F_FLOW_ENDED)

# output a property in a formatted way
func show(property: String) -> String:
	# TODO: format
	return "[b]%s[]" % Sooty.state._get(property)

func stutter(x: String) -> String:
	var parts := x.split(" ")
	for i in len(parts):
		if len(parts[i]) > 2:
			parts[i] = parts[i].substr(0, 1 if randf()>.5 else 2) + "-" + parts[i].to_lower()
	return " ".join(parts)

func commas(x: String) -> String:
	return UString.commas(UObject.get_operator_value(x))

func humanize(x: String) -> String:
	return UString.humanize(UObject.get_operator_value(x))

func plural(x: String, one: String = "%s", more: String = "%s's", none: String = "%s's") -> String:
	return UString.plural(UObject.get_operator_value(x), one, more, none)

func ordinal(x: String) -> String:
	return UString.ordinal(UObject.get_operator_value(x))

func capitalize(x: String) -> String:
	return str(x).capitalize()

func lowercase(x: String) -> String:
	return str(x).to_lower()

func uppercase(x: String) -> String:
	return str(x).to_upper()

# Cache the pick function so it doesn't give the same option too often.
# Still random, just not as boring.
var _pick_cache := {}
func pick(x):
	# if a dictionary? treat as weighted dict
	if x is Dictionary:
		return URand.pick_weighted(x)
	
	# cache a duplicate to be randomly picked from
	if not x in _pick_cache:
		_pick_cache[x] = x.duplicate()
		_pick_cache[x].shuffle()
	
	var got = _pick_cache[x].pop_back()
	
	if len(_pick_cache[x]) == 0:
		_pick_cache[x] = x.duplicate()
		_pick_cache[x].shuffle()
	
	return got

func test(s, ontrue: String = "yes", onfalse: String = "no"):
	return ontrue if s else onfalse

func advance_time(kwargs := {}):
	time.advance(kwargs)

