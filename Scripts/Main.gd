extends StaticBody2D

const ENEMY_SIGNALER = preload("res://Scenes/EnemySignaler.tscn")

var enemies_left := 0
var wave := 1

var stage: int setget set_stage, get_stage

onready var player: KinematicBody2D = $Player

var item_choices = [Items.ItemReference, Items.ItemReference, Items.ItemReference]

signal spawned_enemy(enemy)
signal wave_begun(wave_idx)

func _ready():
	connect("wave_begun", self, "on_wave_begun")
	
	gen_random_spawn(randi()%3+2)

onready var spawnable_space: Vector2 = $BottomRight.position - $TopLeft.position
func gen_random_spawn(enemies: int, automatically_add_to_enemies_left := true):
	var xcoor: int = randi() % int(spawnable_space.x)
	var ycoor: int = randi() % int(spawnable_space.y)
	var randomized_spawn: Vector2 = $TopLeft.position + Vector2(xcoor, ycoor)
	
	var s = ENEMY_SIGNALER.instance()
	s.position = randomized_spawn
	add_child(s)
	s.get_node("AnimationPlayer").play("Dilate")
	
	yield(s.get_node("AnimationPlayer"), "animation_finished")
	
	s.queue_free()
	
	for i in range(enemies):
		if automatically_add_to_enemies_left:
			enemies_left += 1
		var e := get_random_enemy_per_weights().instance()
		e.position = randomized_spawn + Vector2((randi()%20*i)-10, (randi()%20)*i-10)
		e.get_node("InitParticles/SpawnParticles").position = randomized_spawn
		e.get_node("InitParticles/SpawnParticles").emitting = true
		e.get_node("InitParticles/SpawnParticles2").position = randomized_spawn
		e.get_node("InitParticles/SpawnParticles2").emitting = true
		e.connect("dead", self, "on_Enemy_dead")
		e.connect("dead", player, "on_Enemy_dead", [e])
		emit_signal("spawned_enemy", e)
		add_child(e)
		yield(get_tree().create_timer(0.2), "timeout")

func get_random_enemy_per_weights() -> PackedScene:
	var ENEMIES: Dictionary = Globals.ENEMY_POOL[get_stage()]
	
	if ENEMIES == null:
		printerr("Main.gd: ENEMIES_POOL not defined for stage " + str(get_stage()))
		breakpoint
	
	return Globals.parse_pool(ENEMIES)

func _process(delta: float) -> void:
	$ParallaxBackground/ParallaxLayer.motion_offset += Vector2(22, 18) * delta
	$ParallaxBackground/ParallaxLayer2.motion_offset += Vector2(15, 17) * delta
	
	$Camera2D.offset = Vector2(512, 300) + \
	(player.position - ($BottomRight.position - $TopLeft.position) / 2) / 20

func on_Enemy_dead():
	enemies_left -= 1
	if enemies_left == 0:
		wave += 1
		emit_signal("wave_begun", wave)

func on_wave_begun(_wave_idx: int):
	
	$WaveLabel.text = str(wave)
	
	var randomized_extra_enemies := randi() % int(min(wave, 4))
	var total_enemies := get_stage() * 2 + randomized_extra_enemies
	var placeoffs: int = clamp(randomized_extra_enemies, 1, 3) + wave / 4
	
	enemies_left += total_enemies
	for i in range(placeoffs):
		if i != 0 and i == placeoffs-1:
			gen_random_spawn(total_enemies/placeoffs + total_enemies % placeoffs, false)
		else:
			gen_random_spawn(total_enemies/placeoffs, false)
		yield(get_tree().create_timer(randi() % 3 + 2), "timeout") 

func set_stage(_val): pass
func get_stage() -> int:
	return 1 + (wave-1)/5
