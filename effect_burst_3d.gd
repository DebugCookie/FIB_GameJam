
extends Marker3D
class_name EffectBurst3D

# Assign your five PNGs in the Inspector
@export var money_up_texture: Texture2D
@export var money_down_texture: Texture2D
@export var morale_up_texture: Texture2D
@export var morale_down_texture: Texture2D
@export var neutral_texture: Texture2D

# Animation settings
@export var icon_pixel_size: float = 0.005
@export var icon_scale: float = 1.0
@export var travel_height: float = 0.8
@export var horizontal_spread: float = 0.5
@export var animation_duration: float = 1.0


func play_effect(impact: Dictionary) -> void:
	var possible_icons: Array[Texture2D] = []

	var morale: int = int(impact.get("Moral", 0))
	var money: int = int(impact.get("Money", 0))

	# Choose textures based on the actual impact
	if morale > 0:
		possible_icons.append(morale_up_texture)
	elif morale < 0:
		possible_icons.append(morale_down_texture)

	if money > 0:
		possible_icons.append(money_up_texture)
	elif money < 0:
		possible_icons.append(money_down_texture)

	# Zero impact
	if possible_icons.is_empty():
		possible_icons.append(neutral_texture)

	# Remove missing textures
	possible_icons = possible_icons.filter(
		func(texture: Texture2D) -> bool:
			return texture != null
	)

	if possible_icons.is_empty():
		push_warning("No effect PNG textures assigned!")
		return

	# Always spawn exactly three icons
	var selected_icons: Array[Texture2D] = possible_icons.duplicate()

	while selected_icons.size() < 3:
		selected_icons.append(possible_icons.pick_random())

	selected_icons.shuffle()

	for i in range(3):
		spawn_icon(selected_icons[i], i)


func spawn_icon(texture: Texture2D, index: int) -> void:
	var sprite := Sprite3D.new()

	sprite.texture = texture
	sprite.pixel_size = icon_pixel_size
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.shaded = false
	sprite.no_depth_test = true
	sprite.transparent = true

	add_child(sprite)

	# Random starting position near marker
	var start_position := Vector3(
		randf_range(-0.15, 0.15),
		randf_range(-0.10, 0.10),
		0.0
	)

	sprite.position = start_position

	# Begin small
	sprite.scale = Vector3.ONE * 0.2 * icon_scale

	# Random outward movement
	var target_position := start_position + Vector3(
		randf_range(-horizontal_spread, horizontal_spread),
		travel_height + randf_range(-0.15, 0.15),
		0.0
	)

	var delay: float = float(index) * 0.1

	# Use a tween owned by this sprite
	var tween := sprite.create_tween()
	tween.set_parallel(true)

	# Float upward
	tween.tween_property(
		sprite,
		"position",
		target_position,
		animation_duration
	).set_delay(delay).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	# Pop outward
	tween.tween_property(
		sprite,
		"scale",
		Vector3.ONE * icon_scale,
		0.2
	).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# Fade away
	tween.tween_property(
		sprite,
		"modulate:a",
		0.0,
		0.5
	).set_delay(delay + 0.5)

	# Remove sprite after the animation
	tween.chain().tween_callback(sprite.queue_free)
