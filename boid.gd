extends QuadTreeObj

var velocity = Vector2.ZERO
var max_speed = 200
var max_force = 10

var trace_target: Vector2

var perception_radius = 50
var separation_limit = 40

var separation_weight = 1.2
var alignment_weight = 1.0
var cohesion_weight = 1.0
var trace_weight = 0.0
var avoid_weight = 20

var space_state: PhysicsDirectSpaceState2D

func _ready() -> void:
	velocity = Vector2(randf() * max_speed, randf() * max_speed)
	rotation = velocity.angle()
	space_state = get_world_2d().direct_space_state
	
	var tween = create_tween().set_loops()
	tween.tween_property(self, "scale", Vector2(1.1, 1.1), 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "scale", Vector2(1, 1), 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
func steer_towards(sum: Vector2):
	var steer = sum.normalized() * max_speed - velocity
	return steer.limit_length(max_force)
	
func _align(neighbors):
	var sum = Vector2.ZERO
	var count = 0
	for other in neighbors:
		if other == self:
			continue
		var distance = position.distance_to(other.position)
		if distance > 0 and distance < perception_radius:
			sum += other.velocity
			count += 1
	if count > 0:
		sum /= count
		sum = steer_towards(sum)
	
	return sum
	
func _cohere(neighbors):
	var sum = Vector2.ZERO
	var count = 0
	for other in neighbors:
		if other == self:
			continue
		var distance = position.distance_to(other.position)
		if distance > 0 and distance < perception_radius:
			sum += other.position
			count += 1
	if count > 0:
		sum /= count
		sum = steer_towards(sum - position)
	
	return sum
	
func _separate(neighbors):
	var sum = Vector2.ZERO
	var count = 0
	for other in neighbors:
		if other == self:
			continue
		var distance = position.distance_to(other.position)
		if distance > 0 and distance < separation_limit:
			var diff = (position - other.position).normalized()
			diff /= distance
			sum += diff
			count += 1
	if count > 0:
		sum /= count
		sum = steer_towards(sum)
	
	return sum

func _trace():
	if trace_target == null:
		return Vector2.ZERO
	return steer_towards(trace_target - position)	

func _avoid():
	var steer = Vector2.ZERO
	var query = PhysicsRayQueryParameters2D.create(global_position, global_position + velocity.normalized() * 150)
	var result = space_state.intersect_ray(query)
	
	if result.size():
		#计算绕开的角度
		var dir = _calc_avoid_steer()
		steer = steer_towards(dir)
	
	return steer

func _calc_avoid_steer():
	var current_direction = velocity.normalized()
	var best_direction = current_direction
	var found = false
	var max_attempts = 10
	for i in range(max_attempts/2):
		for j in range(2):
			var d = 1 if j == 0 else -1
			var angle_offset = deg_to_rad(10 * d * i)
			var direction = current_direction.rotated(angle_offset)
			var query = PhysicsRayQueryParameters2D.create(global_position, global_position + direction * 150)
			var result = space_state.intersect_ray(query)
			
			if result.size() == 0:
				best_direction = direction
				found = true
				break
	
	if found:
		return best_direction
	else:
		return current_direction
	
func apply_behaviors(delta: float, quadtree: QuadTree):
	var nearby_boids = []
	var range = Rect2(position - Vector2(perception_radius, perception_radius), Vector2(perception_radius * 2, perception_radius * 2))
	quadtree.query(range, nearby_boids)
	
	var separation = _separate(nearby_boids) * separation_weight
	var alignment = _align(nearby_boids) * alignment_weight
	var cohesion = _cohere(nearby_boids) * cohesion_weight
	var trace = _trace() * trace_weight
	var avoid = _avoid() * avoid_weight
	
	var accelaration = separation + alignment + cohesion + trace + avoid
	velocity += accelaration
	velocity = velocity.limit_length(max_speed)
	position += velocity * delta
	if velocity.length() > 0:
		rotation = lerp_angle(rotation, velocity.angle(), PI/2*delta)
	
	wrap_screen()
	quadtree.remove(self)
	quadtree.insert(self)

func wrap_screen():
	var screen_size = get_viewport_rect().size
	position.x = wrapf(position.x, 0, screen_size.x)
	position.y = wrapf(position.y, 0, screen_size.y)
	
func set_target(target):
	trace_target = target
