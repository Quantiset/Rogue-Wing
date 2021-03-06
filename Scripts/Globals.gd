extends Node

var player_scene := preload("res://Scenes/Players/Player.tscn")

var rng_seed := 69420
var randomize_seed := true

enum STATUS_EFFECTS {
	PoisionAcid
}

const BIT_WORLD = 0
const BIT_PLAYER = 1
const BIT_ENEMY = 2
const BIT_SCRAP = 3

# each pool for each stage. Initial key is the weight
const ENEMY_POOL = {
	1: {
		preload("res://Scenes/Enemies/StandardEnemy.tscn"): 5,
		preload("res://Scenes/Enemies/ExplodingEnemy.tscn"): 1,
		preload("res://Scenes/Enemies/BufferEnemy.tscn"): 1,
	},
	2: {
		preload("res://Scenes/Enemies/StandardEnemy.tscn"): 4,
		preload("res://Scenes/Enemies/ExplodingEnemy.tscn"): 2,
		preload("res://Scenes/Enemies/StandardTurret.tscn"): 1,
		preload("res://Scenes/Enemies/BufferEnemy.tscn"): 1,
	},
	3: {
		preload("res://Scenes/Enemies/StandardTurret.tscn"): 3,
		preload("res://Scenes/Enemies/ExplodingEnemy.tscn"): 2,
		preload("res://Scenes/Enemies/StandardDreadnought.tscn"): 2,
		preload("res://Scenes/Enemies/StandardEnemy.tscn"): 4,
		preload("res://Scenes/Enemies/BufferEnemy.tscn"): 1,
		preload("res://Scenes/Enemies/RocketTurret.tscn"): 1,
	},
	4: {
		preload("res://Scenes/Enemies/ExplodingEnemy.tscn"): 3,
		preload("res://Scenes/Enemies/StandardTurret.tscn"): 2,
		preload("res://Scenes/Enemies/StandardEnemy.tscn"): 2,
		preload("res://Scenes/Enemies/StandardDreadnought.tscn"): 5,
		preload("res://Scenes/Enemies/BufferEnemy.tscn"): 1,
	},
	5: {
		preload("res://Scenes/Enemies/ExplodingEnemy.tscn"): 1,
		preload("res://Scenes/Enemies/StandardTurret.tscn"): 5,
		preload("res://Scenes/Enemies/ExplodingDreadnought.tscn"): 1,
		preload("res://Scenes/Enemies/StandardDreadnought.tscn"): 7,
		preload("res://Scenes/Enemies/BufferEnemy.tscn"): 1,
	},
	6: {
		preload("res://Scenes/Enemies/RocketTurret.tscn"): 2,
		preload("res://Scenes/Enemies/ExplodingDreadnought.tscn"): 2,
		preload("res://Scenes/Enemies/StandardDreadnought.tscn"): 9,
		preload("res://Scenes/Enemies/BufferEnemy.tscn"): 2,
	}
}


const BOSS_STAGE := {
	null: preload("res://Scenes/Enemies/NormalBoss.tscn"),
	1: preload("res://Scenes/Enemies/NormalBoss.tscn"),
	2: preload("res://Scenes/Enemies/ShootAroundBoss.tscn"),
	3: preload("res://Scenes/Enemies/LaserBoss.tscn")
}


var RARITIES_PRICE := {
	Items.RARITIES.Common: 100,
	Items.RARITIES.Rare: 200,
	Items.RARITIES.Ultra: 400,
	Items.RARITIES.Legendary: 800,
}

var ITEM_POOL := {
	Items.HeatseekingMissiles: 6,
	Items.LeadTippedDarts: 10,
	Items.RefinedPlating: 10,
	Items.RubberBullets: 10,
	Items.DoubledMuzzle: 6,
	Items.Grenade: 10,
	Items.MachineGun: 3,
	Items.TeslaCoil: 6,
	Items.Shellshock: 10,
	Items.PoisionMixture: 10,
	Items.PanicButton: 5,
	Items.XPAbsorber: 10,
	Items.Scalar: 10,
	Items.Dicannon: 8,
}

var unlocked_ships := [0, 1, 2, 3]

func _ready():
	
	rng_seed = clamp(rng_seed, 0, 9999)
	
	if randomize_seed:
		randomize()
		rng_seed = randi()%10000
	
	seed(rng_seed)


func remove_particle(p: Particles2D):
	
	if not is_instance_valid(p): return
	
	var pp = p.global_position
	var pc = p.modulate
	var t = Timer.new()
	
	p.get_parent().remove_child(p)
	add_child(p)
	add_child(t)
	p.position = pp
	p.modulate = pc
	t.start(p.lifetime*(1+p.process_material.lifetime_randomness))
	t.connect("timeout", self, "queue_free_all", [[t, p]])

func remove_trail(t: Line2D, fade_duration := 1.0):
	var tw := Tween.new()
	t.get_parent().remove_child(t)
	add_child(t)
	t.add_child(tw)
	var ta := t.modulate
	ta.a = 0
	tw.interpolate_property(t, "modulate", t.modulate, ta, fade_duration, Tween.TRANS_LINEAR)
	tw.connect("tween_all_completed", self, "queue_free_all", [[t]])
	tw.start()


func queue_free_all(arr: Array):
	for obj in arr:
		if is_instance_valid(obj):
			obj.queue_free()

# returns an item in the pool with a
# {key: weight} dictionary
# is slower the more keys and weights that are present
func parse_pool(POOL: Dictionary):
	var num_sum := 0
	
	for i in POOL.values():
		num_sum += i
	
	var random_num: int = randi()%num_sum
	
	for pool_entry in POOL.keys():
		random_num -= POOL[pool_entry]
		if random_num < 0:
			return pool_entry

# mod shorthand
func spawn_item_at(item: GDScript, pos: Vector2):
	var i = preload("res://Scenes/Item.tscn").instance()
	i.position = pos
	i.type = item
	get_parent().call_deferred("add_child", i)

# gets closest enemy from a point in space.
# used for relocating a cursor to the nearest enemy
func get_closest_enemy_from(position: Vector2, exceptions = []):
	var enemies = get_tree().get_nodes_in_group("Enemy")
	
	for exception in exceptions:
		if exception in enemies:
			enemies.erase(exception)
	if enemies.size() == 0:
		return null
	
	var closest_enemy = enemies[0]
	for enemy in enemies:
		if (position - enemy.position).length() < (position - closest_enemy.position).length():
			closest_enemy = enemy
	
	return closest_enemy
