extends KinematicBody2D
class_name Actor

var velocity := Vector2()

export var max_hp := 100 
var hp := max_hp

export var stun_duration := 0.05

export var bullet = preload("res://Scenes/Bullets/StraightBullet.tscn")
export var shot_amount    := 1
export var shot_fan_range := PI/4
export var aim_speed      := 300
export var shot_cooldown  := 0.5 setget set_shot_cooldown
export var shot_cooldown_multiplier := 1.0 setget set_shot_cooldown_multiplier
export var shot_modulate  := Color("ffffff")

export var trail_length := 100
export var thrust_length := 6

export var max_speed := 300 
export var acceleration := 20

#time it takes to refresh status effect checks and update status effects
const status_effect_callback_time = 1.0
var status_effects_to_time := {}

var items := []

func add_item(item):
	
	if item is GDScript:
		item = item.new(self)
	if has_item(item):
		item._init2(self)
	
	
	update_health()
	update_xp()
	
	items.append(item)

func has_item(item) -> bool:
	for held_item in items:
		if held_item._metadata().id == item._metadata().id:
			return true
	return false

func shoot():
	var b_list = []
	
	for i in range(shot_amount):
		var b_inst: Bullet = bullet.instance()
		b_inst.position = position
		b_list.append(b_inst)
	
	for item in items:
		item._on_shot(b_list)
	
	return b_list

func apply_status_effect(effect, duration: float):
	if not effect in Globals.STATUS_EFFECTS.values():
		printerr("Effect "+str(effect)+" does not exist in Globals.STATUS_EFFECTS")
	
	status_effects_to_time[effect] = duration
	
	var t = Timer.new()
	get_tree().get_root().add_child(t)
	t.connect("timeout", self, "on_Effects_update", [effect, t])
	t.start(status_effect_callback_time)

func on_Effects_update(effect, timer):
	print(effect)
	var duration: float = status_effects_to_time[effect]
	duration -= status_effect_callback_time
	
	match effect:
		Globals.STATUS_EFFECTS.PoisionAcid:
			take_damage(10)
			update_health()
	
	if duration < 0:
		status_effects_to_time.erase(effect)
		timer.queue_free()


func update_health():pass
func update_xp():pass
func take_damage(val):pass

func set_shot_cooldown(val):
	shot_amount = val
func set_shot_cooldown_multiplier(val):
	shot_cooldown_multiplier = val
