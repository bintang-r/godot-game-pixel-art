extends CharacterBody2D

@export var walk_speed := 150.0
@export var run_speed := 250.0
@export var jump_force := -400.0

@export var dash_speed := 600.0
@export var dash_duration := 0.15
@export var dash_cooldown := 0.5

@export_range(0,1) var deceleration := 0.1
@export_range(0,1) var acceleration := 0.1
@export_range(0,1) var decelerate_on_jump_release := 0.5

# ANIMATION
@onready var animation_sprite: AnimatedSprite2D = $AnimatedSprite2D

# SOUND
@onready var sfx_jump: AudioStreamPlayer2D = $sfx_jump
@onready var music_01: AudioStreamPlayer2D = $music_01

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

var is_dashing := false
var dash_timer := 0.0
var dash_cooldown_timer := 0.0
var dash_direction := 0

func _ready():
	music_01.loop = true
	music_01.play()
	music_01.finished.connect(_on_music_finished)

func _on_music_finished():
	music_01.play()
	
func _physics_process(delta: float) -> void:

	# =============== DASH COOLDOWN ===============
	if dash_cooldown_timer > 0:
		dash_cooldown_timer -= delta

	# =============== DASH INPUT ===============
	if Input.is_action_just_pressed("dash") \
	and dash_cooldown_timer <= 0 \
	and not is_dashing:

		var dir = Input.get_axis("left", "right")
		
		# jika tidak tekan arah, dash ke arah posisi karakter menghadap
		if dir == 0:
			dir = -1 if animation_sprite.flip_h else 1

		start_dash(dir)

	# =============== DASH MODE ===============
	if is_dashing:
		process_dash(delta)
		return  # cegah movement/animasi normal


	# =============== GRAVITY ===============
	if not is_on_floor():
		velocity.y += gravity * delta

	# =============== JUMP ===============
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_force
		sfx_jump.play()

	# short hop
	if Input.is_action_just_released("jump") and velocity.y < 0:
		velocity.y *= decelerate_on_jump_release

	# =============== MOVEMENT ===============
	var current_speed = run_speed if Input.is_action_pressed("run") else walk_speed
	var direction = Input.get_axis("left", "right")

	if direction != 0:
		velocity.x = move_toward(velocity.x, direction * current_speed, current_speed * acceleration)
		animation_sprite.flip_h = direction < 0
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed * deceleration)

	# =============== ANIMATION CONTROLLER ===============
	# Prioritas animasi:
	# 1. Jump
	# 2. Walk
	# 3. Idle
	if not is_on_floor():
		animation_sprite.play("animation_jump")
	elif direction != 0:
		animation_sprite.play("animation_walk")
	else:
		animation_sprite.play("animation_idle")

	move_and_slide()

# ============================
# DASH FUNCTIONS
# ============================

func start_dash(dir: float) -> void:
	is_dashing = true
	dash_timer = dash_duration
	dash_cooldown_timer = dash_cooldown

	velocity.y = 0
	animation_sprite.play("animation_dash")
	animation_sprite.flip_h = dir < 0


func process_dash(delta: float) -> void:
	velocity.y = 0  # no gravity saat dash
	velocity.x = dash_direction * dash_speed

	dash_timer -= delta
	if dash_timer <= 0:
		is_dashing = false

	move_and_slide()
