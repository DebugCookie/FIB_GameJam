
extends Node3D
class_name JanitorController


# ==========================================
# SCENE REFERENCES
# ==========================================

@export_group("Scene References")

@export var janitor_visual: Node3D
@export var point_a: Marker3D
@export var point_b: Marker3D
@export var point_c: Marker3D
@export var door_pivot: Node3D

# Assigned by Character3D at runtime.
var bubble: Bubble3D = null


# ==========================================
# MOVEMENT
# ==========================================

@export_group("Movement")

@export var walk_speed: float = 1.5
@export var bob_height: float = 0.08
@export var bob_duration: float = 0.18
@export var pause_at_door: float = 0.2


# ==========================================
# DOOR
# ==========================================

@export_group("Door")

@export var door_open_angle: float = 90.0
@export var door_duration: float = 0.6


# ==========================================
# STATE
# ==========================================

enum State {
	IDLE,
	ENTERING,
	WAITING_FOR_DECISION,
	LEAVING
}

var state: State = State.IDLE

var visual_start_position: Vector3
var door_closed_rotation: Vector3

var is_walking: bool = false
var bob_time: float = 0.0

# Used to cancel older animation sequences.
var visit_generation: int = 0

var active_move_tween: Tween = null
var active_door_tween: Tween = null

signal visit_finished


# ==========================================
# INITIALIZATION
# ==========================================

func _ready() -> void:

	if janitor_visual:
		visual_start_position = janitor_visual.position

	if door_pivot:
		door_closed_rotation = door_pivot.rotation

	print("JANITOR: Controller ready.")


# ==========================================
# CONNECT CHARACTER BUBBLE
# ==========================================

func set_bubble(shared_bubble: Bubble3D) -> void:

	# Disconnect the previous bubble if needed.
	if is_instance_valid(bubble):

		if bubble.action_processed.is_connected(
			_on_idea_finished
		):
			bubble.action_processed.disconnect(
				_on_idea_finished
			)

		if bubble.bubble_expired.is_connected(
			_on_idea_finished
		):
			bubble.bubble_expired.disconnect(
				_on_idea_finished
			)

	bubble = shared_bubble

	if not is_instance_valid(bubble):
		push_error("JANITOR: Invalid Bubble3D.")
		return

	bubble.action_processed.connect(
		_on_idea_finished
	)

	bubble.bubble_expired.connect(
		_on_idea_finished
	)

	print("JANITOR: Bubble connected.")


# ==========================================
# BOBBING ANIMATION
# ==========================================

func _process(delta: float) -> void:

	if not is_walking:
		return

	if not is_instance_valid(janitor_visual):
		return

	bob_time += delta

	var safe_duration: float = maxf(
		bob_duration,
		0.05
	)

	var frequency: float = PI / safe_duration

	janitor_visual.position.y = (
		visual_start_position.y
		+ sin(bob_time * frequency) * bob_height
	)


# ==========================================
# START VISIT
# ==========================================

func start_visit(
	idea_text: String,
	impact: Dictionary
) -> void:

	if state != State.IDLE:
		print("JANITOR: Visit rejected, already busy.")
		return

	if not _references_ready():
		return

	visit_generation += 1
	var my_visit: int = visit_generation

	state = State.ENTERING

	bubble.hide_bubble()

	# 1. Move from A to B.
	print("JANITOR: Moving A to B")

	var reached: bool = await _move_to(
		point_b.global_position,
		my_visit
	)

	if not reached:
		return

	# 2. Open door.
	print("JANITOR: Opening door")

	var opened: bool = await _rotate_door(
		true,
		my_visit
	)

	if not opened:
		return

	await get_tree().create_timer(
		maxf(pause_at_door, 0.01),
		false
	).timeout

	if my_visit != visit_generation:
		return

	# 3. Move from B to C.
	print("JANITOR: Moving B to C")

	reached = await _move_to(
		point_c.global_position,
		my_visit
	)

	if not reached:
		return

	if my_visit != visit_generation:
		return

	# 4. Show the idea.
	state = State.WAITING_FOR_DECISION

	print("JANITOR: Showing idea: ", idea_text)

	bubble.setup_bubble(
		"Janitor",
		idea_text,
		impact
	)


# ==========================================
# EXACT MOVEMENT TO MARKER
# ==========================================

func _move_to(
	target: Vector3,
	my_visit: int
) -> bool:

	if not is_instance_valid(janitor_visual):
		return false

	if my_visit != visit_generation:
		return false

	# Reset bobbing before calculating movement.
	is_walking = false
	janitor_visual.position = visual_start_position

	# Preserve the working exact-position calculation.
	var offset: Vector3 = (
		target - janitor_visual.global_position
	)

	var destination: Vector3 = (
		global_position + offset
	)

	var distance: float = offset.length()

	if distance < 0.001:

		global_position += (
			target - janitor_visual.global_position
		)

		return true

	var duration: float = maxf(
		distance / maxf(walk_speed, 0.1),
		0.05
	)

	is_walking = true
	bob_time = 0.0

	active_move_tween = create_tween()

	active_move_tween.tween_property(
		self,
		"global_position",
		destination,
		duration
	).set_trans(Tween.TRANS_LINEAR)

	var completed: bool = await _wait_for_tween(
		active_move_tween,
		my_visit
	)

	if not completed:
		is_walking = false
		return false

	is_walking = false

	# Restore visual's original local position.
	janitor_visual.position = visual_start_position

	# Correct any tiny remaining positional error.
	global_position += (
		target - janitor_visual.global_position
	)

	print(
		"JANITOR: Destination reached. Error: ",
		janitor_visual.global_position.distance_to(target)
	)

	return true


# ==========================================
# DOOR ROTATION
# ==========================================

func _rotate_door(
	open: bool,
	my_visit: int
) -> bool:

	if not is_instance_valid(door_pivot):
		return false

	if my_visit != visit_generation:
		return false

	var target_rotation: Vector3 = (
		door_closed_rotation
	)

	if open:
		target_rotation.y += deg_to_rad(
			door_open_angle
		)

	active_door_tween = create_tween()

	active_door_tween.tween_property(
		door_pivot,
		"rotation",
		target_rotation,
		maxf(door_duration, 0.05)
	).set_trans(Tween.TRANS_SINE).set_ease(
		Tween.EASE_IN_OUT
	)

	return await _wait_for_tween(
		active_door_tween,
		my_visit
	)


# ==========================================
# WAIT FOR TWEEN OR CANCELLATION
# ==========================================

func _wait_for_tween(
	tween: Tween,
	my_visit: int
) -> bool:

	while tween.is_running():

		await get_tree().process_frame

		if my_visit != visit_generation:

			if tween.is_valid():
				tween.kill()

			return false

	return my_visit == visit_generation


# ==========================================
# IDEA FINISHED
# ==========================================

func _on_idea_finished(_impact: Dictionary) -> void:

	if state != State.WAITING_FOR_DECISION:
		return

	state = State.LEAVING

	_leave_office()


# ==========================================
# EXIT SEQUENCE
# ==========================================

func _leave_office() -> void:

	var my_visit: int = visit_generation

	bubble.hide_bubble()

	# 5. Move from C to B.
	print("JANITOR: Moving C to B")

	var reached: bool = await _move_to(
		point_b.global_position,
		my_visit
	)

	if not reached:
		return

	await get_tree().create_timer(
		maxf(pause_at_door, 0.01),
		false
	).timeout

	if my_visit != visit_generation:
		return

	# 6. Close door.
	print("JANITOR: Closing door")

	var closed: bool = await _rotate_door(
		false,
		my_visit
	)

	if not closed:
		return

	# 7. Return from B to A.
	print("JANITOR: Moving B to A")

	reached = await _move_to(
		point_a.global_position,
		my_visit
	)

	if not reached:
		return

	if my_visit != visit_generation:
		return

	state = State.IDLE

	print("JANITOR: Visit complete.")

	visit_finished.emit()


# ==========================================
# CANCEL VISIT
# Used when day ends or player loses.
# ==========================================

func cancel_visit() -> void:

	# Invalidates the previous animation sequence.
	visit_generation += 1

	# Stop movement animation.
	if active_move_tween != null:

		if active_move_tween.is_valid():
			active_move_tween.kill()

		active_move_tween = null

	# Stop door animation.
	if active_door_tween != null:

		if active_door_tween.is_valid():
			active_door_tween.kill()

		active_door_tween = null

	is_walking = false
	bob_time = 0.0

	# Restore sprite's normal local position.
	if is_instance_valid(janitor_visual):

		janitor_visual.position = visual_start_position

		# Return to Point A using the same
		# exact visual-origin alignment.
		if is_instance_valid(point_a):

			global_position += (
				point_a.global_position
				- janitor_visual.global_position
			)

	# Close the door immediately.
	if is_instance_valid(door_pivot):
		door_pivot.rotation = door_closed_rotation

	# Remove unfinished dialogue.
	if is_instance_valid(bubble):
		bubble.hide_bubble()

	state = State.IDLE


# ==========================================
# VALIDATE REFERENCES
# ==========================================

func _references_ready() -> bool:

	if not is_instance_valid(janitor_visual):
		push_error("JANITOR: Visual missing.")
		return false

	if not is_instance_valid(bubble):
		push_error("JANITOR: Bubble missing.")
		return false

	if not is_instance_valid(point_a):
		push_error("JANITOR: Point A missing.")
		return false

	if not is_instance_valid(point_b):
		push_error("JANITOR: Point B missing.")
		return false

	if not is_instance_valid(point_c):
		push_error("JANITOR: Point C missing.")
		return false

	if not is_instance_valid(door_pivot):
		push_error("JANITOR: Door missing.")
		return false

	return true
