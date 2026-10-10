extends Node2D

const VIEW_WIDTH = 1280
const VIEW_HEIGHT = 720
const PLAYER_SPEED = 260
const ENEMY_SPEED = 120
const PLAYER_RADIUS = 18
const ENEMY_RADIUS = 16
const PICKUP_RADIUS = 12
const WIN_GOAL = 10

var player = null
var score = 0
var lives = 5
var time_left = 45.0
var hit_cooldown = 0.0
var game_finished = false

var pickups = []
var enemies = []

var score_label = null
var lives_label = null
var timer_label = null
var status_label = null

func _ready():
	randomize()
	build_hud()
	setup_player()
	spawn_pickup()
	spawn_pickup()
	spawn_enemy()
	spawn_enemy()
	update_hud()

func _process(delta):
	if game_finished:
		if Input.is_key_pressed(KEY_R):
			restart_game()
		return

	time_left -= delta
	if time_left <= 0.0:
		finish_game("Время закончилось! Нажмите R, чтобы начать заново.")
		return

	handle_player_movement()
	update_enemy_positions(delta)
	update_pickups()
	update_hud()

func build_hud():
	score_label = Label.new()
	score_label.rect_position = Vector2(20, 20)
	score_label.text = "Счёт: 0"
	add_child(score_label)

	lives_label = Label.new()
	lives_label.rect_position = Vector2(20, 50)
	lives_label.text = "Жизни: 5"
	add_child(lives_label)

	timer_label = Label.new()
	timer_label.rect_position = Vector2(20, 80)
	timer_label.text = "Время: 45.0"
	add_child(timer_label)

	status_label = Label.new()
	status_label.rect_position = Vector2(20, 110)
	status_label.text = "Собери 10 кристаллов и не дай врагам вас догнать!"
	add_child(status_label)

func setup_player():
	if is_instance_valid(player):
		remove_child(player)
		player.queue_free()

	player = KinematicBody2D.new()
	player.name = "Player"
	player.position = Vector2(VIEW_WIDTH * 0.5, VIEW_HEIGHT * 0.5)

	var collision = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = PLAYER_RADIUS
	collision.shape = circle
	player.add_child(collision)

	var visual = Polygon2D.new()
	visual.polygon = make_circle_points(PLAYER_RADIUS, 32)
	visual.color = Color(0.25, 0.9, 0.7)
	player.add_child(visual)

	add_child(player)

func spawn_pickup():
	var pickup = Node2D.new()
	pickup.name = "Pickup"
	pickup.position = random_position_in_bounds(30)

	var poly = Polygon2D.new()
	poly.polygon = PoolVector2Array([
		Vector2(0, -PICKUP_RADIUS),
		Vector2(PICKUP_RADIUS, 0),
		Vector2(0, PICKUP_RADIUS),
		Vector2(-PICKUP_RADIUS, 0)
	])
	poly.color = Color(1.0, 0.85, 0.25)
	pickup.add_child(poly)

	add_child(pickup)
	pickups.append(pickup)

func spawn_enemy():
	if enemies.size() >= 8:
		return

	var enemy = KinematicBody2D.new()
	enemy.name = "Enemy"
	enemy.position = random_spawn_edge_position()

	var collision = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = ENEMY_RADIUS
	collision.shape = circle
	enemy.add_child(collision)

	var visual = Polygon2D.new()
	visual.polygon = make_circle_points(ENEMY_RADIUS, 24)
	visual.color = Color(1.0, 0.35, 0.35)
	enemy.add_child(visual)

	add_child(enemy)
	enemies.append(enemy)

func random_position_in_bounds(margin):
	return Vector2(
		rand_range(margin, VIEW_WIDTH - margin),
		rand_range(margin, VIEW_HEIGHT - margin)
	)

func random_spawn_edge_position():
	var edge = randi() % 4
	var pos = Vector2.ZERO
	match edge:
		0:
			pos = Vector2(rand_range(0.0, VIEW_WIDTH), -50.0)
		1:
			pos = Vector2(VIEW_WIDTH + 50.0, rand_range(0.0, VIEW_HEIGHT))
		2:
			pos = Vector2(rand_range(0.0, VIEW_WIDTH), VIEW_HEIGHT + 50.0)
		3:
			pos = Vector2(-50.0, rand_range(0.0, VIEW_HEIGHT))
	return pos

func make_circle_points(radius, segments):
	var points = PoolVector2Array()
	for i in range(segments):
		var angle = TAU * float(i) / float(segments)
		points.append(Vector2(cos(angle) * radius, sin(angle) * radius))
	return points

func handle_player_movement():
	var direction = Vector2.ZERO
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		direction.x -= 1.0
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		direction.x += 1.0
	if Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W):
		direction.y -= 1.0
	if Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S):
		direction.y += 1.0

	if direction.length() > 0.0:
		direction = direction.normalized()
		player.move_and_slide(direction * PLAYER_SPEED)
	else:
		player.move_and_slide(Vector2.ZERO)

	player.position.x = clamp(player.position.x, PLAYER_RADIUS, VIEW_WIDTH - PLAYER_RADIUS)
	player.position.y = clamp(player.position.y, PLAYER_RADIUS, VIEW_HEIGHT - PLAYER_RADIUS)

func update_enemy_positions(delta):
	hit_cooldown = max(hit_cooldown - delta, 0.0)

	for enemy in enemies:
		if enemy == null or !is_instance_valid(enemy):
			continue

		var direction = (player.position - enemy.position).normalized()
		enemy.move_and_slide(direction * ENEMY_SPEED)

		if enemy.position.distance_to(player.position) < PLAYER_RADIUS + ENEMY_RADIUS + 8.0:
			if hit_cooldown <= 0.0:
				lives -= 1
				hit_cooldown = 0.7
				status_label.text = "Попадание! Осталось жизней: %d" % lives
				if lives <= 0:
					finish_game("Ты проиграл! Нажмите R, чтобы сыграть снова.")
					return

func update_pickups():
	for pickup in pickups:
		if pickup == null or !is_instance_valid(pickup):
			continue

		if pickup.position.distance_to(player.position) < PLAYER_RADIUS + PICKUP_RADIUS + 8.0:
			score += 1
			status_label.text = "Кристалл собран! Осталось: %d" % (WIN_GOAL - score)
			remove_child(pickup)
			pickup.queue_free()
			pickups.erase(pickup)
			spawn_pickup()
			if score % 3 == 0:
				spawn_enemy()
			if score >= WIN_GOAL:
				finish_game("Победа! Ты собрал 10 кристаллов! Нажмите R, чтобы сыграть снова.")
				return

func update_hud():
	score_label.text = "Счёт: %d" % score
	lives_label.text = "Жизни: %d" % lives
	timer_label.text = "Время: %.1f" % max(time_left, 0.0)

func finish_game(message):
	game_finished = true
	if score >= WIN_GOAL:
		status_label.text = "Победа! Ты собрал 10 кристаллов! Нажмите R, чтобы сыграть снова."
	else:
		status_label.text = message

func restart_game():
	for pickup in pickups:
		if is_instance_valid(pickup):
			remove_child(pickup)
			pickup.queue_free()
	for enemy in enemies:
		if is_instance_valid(enemy):
			remove_child(enemy)
			enemy.queue_free()

	pickups.clear()
	enemies.clear()
	if is_instance_valid(player):
		remove_child(player)
		player.queue_free()

	score = 0
	lives = 5
	time_left = 45.0
	hit_cooldown = 0.0
	game_finished = false

	setup_player()
	spawn_pickup()
	spawn_pickup()
	spawn_enemy()
	spawn_enemy()
	status_label.text = "Новая игра! Собери 10 кристаллов и беги от врагов."
	update_hud()
