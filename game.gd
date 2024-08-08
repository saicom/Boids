extends Node2D

var boids = []
var quadtree = null

const BOID = preload("res://boid.tscn")


func _ready() -> void:
	var screen_rect = get_viewport_rect()
	quadtree = QuadTree.new(screen_rect, 10)
	
	for i in range(200):
		var boid_instance = BOID.instantiate()
		boid_instance.position = Vector2(randi() % int(screen_rect.size.x), randi() % int(screen_rect.size.y))
		add_child(boid_instance)
		boids.append(boid_instance)
		quadtree.insert(boid_instance)
		
func _physics_process(delta: float) -> void:
	for boid in boids:
		boid.set_target(get_global_mouse_position())
		boid.apply_behaviors(delta, quadtree)
