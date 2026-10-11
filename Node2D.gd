extends Node2D

onready var sprite = $Sprite

func _ready():
    sprite.texture = load("res://icon.png")
    sprite.centered = true
    sprite.position = Vector2.ZERO
    sprite.scale = Vector2(1.2, 1.2)

func _process(delta):
    rotation += delta * 0.6
    position = Vector2(
        sin(OS.get_ticks_msec() * 0.001 * 1.5) * 120,
        cos(OS.get_ticks_msec() * 0.001 * 1.2) * 80
    )
