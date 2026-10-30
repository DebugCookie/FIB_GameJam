
extends DirectionalLight3D


# ==========================================
# GAME REFERENCE
# ==========================================

@export var office_scene: Node3D


# ==========================================
# SUN MOVEMENT
# ==========================================

@export_group("Sun Movement")

# Vertical movement (X axis)
@export var morning_angle: float = -15.0
@export var evening_angle: float = -165.0

# Horizontal movement (Y axis)
# Offsets from the light's Y rotation in the editor
@export var morning_y_offset: float = -35.0
@export var evening_y_offset: float = 35.0

var base_y_angle: float = 0.0


# ==========================================
# SUN COLORS
# ==========================================

@export_group("Sun Colors")

@export var morning_color: Color = Color(1.0, 0.65, 0.38)
@export var midday_color: Color = Color(1.0, 0.96, 0.88)
@export var evening_color: Color = Color(1.0, 0.37, 0.20)


# ==========================================
# SUN BRIGHTNESS
# ==========================================

@export_group("Sun Brightness")

@export var morning_energy: float = 0.5
@export var midday_energy: float = 1.4
@export var evening_energy: float = 0.2


# ==========================================
# INITIALIZATION
# ==========================================

func _ready() -> void:

	# Remember the original horizontal rotation
	base_y_angle = rotation_degrees.y

	if not is_instance_valid(office_scene):
		push_warning("SUN: Assign Office Scene in Inspector.")
		return

	update_sun(0.0)


# ==========================================
# UPDATE EVERY FRAME
# ==========================================

func _process(_delta: float) -> void:

	if not is_instance_valid(office_scene):
		return

	var total_time: float = float(
		office_scene.get("total_day_seconds")
	)

	var remaining_time: float = float(
		office_scene.get("time_remaining_seconds")
	)

	if total_time <= 0.0:
		return

	var progress: float = clampf(
		(total_time - remaining_time) / total_time,
		0.0,
		1.0
	)

	update_sun(progress)


# ==========================================
# UPDATE SUN ROTATION, COLOR AND BRIGHTNESS
# ==========================================

func update_sun(progress: float) -> void:

	# ROTATION X + Y

	var angles: Vector3 = rotation_degrees

	# Vertical movement
	angles.x = lerpf(
		morning_angle,
		evening_angle,
		progress
	)

	# Horizontal movement
	angles.y = base_y_angle + lerpf(
		morning_y_offset,
		evening_y_offset,
		progress
	)

	# Apply both rotations together
	rotation_degrees = angles


	# COLOR AND BRIGHTNESS

	if progress <= 0.5:

		var t: float = progress * 2.0

		light_color = morning_color.lerp(
			midday_color,
			t
		)

		light_energy = lerpf(
			morning_energy,
			midday_energy,
			t
		)

	else:

		var t: float = (progress - 0.5) * 2.0

		light_color = midday_color.lerp(
			evening_color,
			t
		)

		light_energy = lerpf(
			midday_energy,
			evening_energy,
			t
		)
