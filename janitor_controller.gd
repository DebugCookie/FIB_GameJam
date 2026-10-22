
extends Node3D
class_name JanitorController

@export_group("Scene References")
@export var janitor_visual: Node3D
@export var point_b: Marker3D
@export var point_c: Marker3D
@export var door_pivot: Node3D

@export_group("Movement")
@export var walk_speed: float = 1.5
@export var bob_height: float = 0.08
@export var bob_duration: float = 0.18
@export var pause_at_door: float = 0.2

@export_group("Door")
@export var door_open_angle: float = 90.0
@export var door_duration: float = 0.6

enum State {
	IDLE,
	ENTERING,
	WAITING_FOR_DECISION,
	LEAVING
}

var state: State = State.IDLE

var bubble: Bubble3D = null
var start_position: Vector3
var visual_start_position: Vector3
var door_closed_rotation: Vector3

var is_walking: bool = false
var bob_time: float = 0.0

signal visit_finished


func _ready() -> void:
	start_position = global_position

	if janitor_visual:
		visual_start_position = janitor_visual.position

	if door_pivot:
		door_closed_rotation = door_pivot.rotation

	print("JANITOR: Controller ready")


# Assign the shared bubble at runtime
func set_bubble(shared_bubble: Bubble3D) -> void:
	if is_instance_valid(bubble):
		if bubble.action_processed.is_connected(_on_idea_finished):
			bubble.action_processed.disconnect(_on_idea_finished)
		if bubble.bubble_expired.is_connected(_on_idea_finished):
			bubble.bubble_expired.disconnect(_on_idea_finished)

	bubble = shared_bubble

	if not is_instance_valid(bubble):
		push_error("JANITOR: Invalid shared bubble")
		return

	bubble.action_processed.connect(_on_idea_finished)
	bubble.bubble_expired.connect(_on_idea_finished)

	print("JANITOR: Shared bubble connected")


func _process(delta: float) -> void:
	if not is_walking or not is_instance_valid(janitor_visual):
		return

	bob_time += delta

	var safe_duration: float = maxf(bob_duration, 0.05)
	var frequency: float = PI / safe_duration

	janitor_visual.position.y = (
		visual_start_position.y
		+ sin(bob_time * frequency) * bob_height
	)


func start_visit(idea_text: String, impact: Dictionary) -> void:
	print("JANITOR: Visit requested")

	if state != State.IDLE:
		return

	if not _references_ready():
		return

	state = State.ENTERING

	bubble.hide_bubble()

	print("JANITOR: Moving A to B")
	await _move_to(point_b.global_position)

	print("JANITOR: Opening door")
	await _rotate_door(true)

	await get_tree().create_timer(
		maxf(pause_at_door, 0.01)
	).timeout

	print("JANITOR: Entering office")
	await _move_to(point_c.global_position)

	print("JANITOR: Showing idea")
	state = State.WAITING_FOR_DECISION

	bubble.setup_bubble(
		"Janitor",
		idea_text,
		impact
	)



func _move_to(target: Vector3) -> void:
	if not is_instance_valid(janitor_visual):
		push_error("JANITOR: Visual node missing!")
		return

	# Calculate the difference between the visible sprite
	# and the marker's exact world position.
	var offset: Vector3 = target - janitor_visual.global_position

	# Move the parent by that same offset.
	var destination: Vector3 = global_position + offset

	var distance: float = offset.length()

	if distance < 0.001:
		print("JANITOR: Already at destination")
		return

	var duration: float = distance / maxf(walk_speed, 0.1)

	# Prevent extreme movement times without cutting movement short.
	duration = maxf(duration, 0.05)

	is_walking = true
	bob_time = 0.0

	var tween: Tween = create_tween()

	tween.tween_property(
		self,
		"global_position",
		destination,
		duration
	).set_trans(Tween.TRANS_LINEAR)

	await tween.finished

	is_walking = false

	# Reset bobbing offset.
	janitor_visual.position = visual_start_position

	# Final exact alignment:
	# Move the parent's origin so the visible sprite
	# finishes exactly at the marker.
	global_position += target - janitor_visual.global_position

	print(
		"JANITOR: Reached destination. Error: ",
		janitor_visual.global_position.distance_to(target)
	)


func _rotate_door(open: bool) -> void:
	var target_rotation: Vector3 = door_closed_rotation

	if open:
		target_rotation.y += deg_to_rad(door_open_angle)

	var tween: Tween = create_tween()
	tween.tween_property(
		door_pivot,
		"rotation",
		target_rotation,
		maxf(door_duration, 0.05)
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	await tween.finished


func _on_idea_finished(_impact: Dictionary) -> void:
	if state != State.WAITING_FOR_DECISION:
		return

	print("JANITOR: Idea finished")
	state = State.LEAVING

	_leave_office()


func _leave_office() -> void:
	bubble.hide_bubble()

	print("JANITOR: Moving C to B")
	await _move_to(point_b.global_position)

	await get_tree().create_timer(
		maxf(pause_at_door, 0.01)
	).timeout

	print("JANITOR: Closing door")
	await _rotate_door(false)

	print("JANITOR: Returning B to A")
	await _move_to(start_position)

	state = State.IDLE

	print("JANITOR: Visit complete")
	visit_finished.emit()


func _references_ready() -> bool:
	if not is_instance_valid(janitor_visual):
		push_error("JANITOR: Janitor Visual missing")
		return false

	if not is_instance_valid(bubble):
		push_error("JANITOR: Shared Bubble3D not connected")
		return false

	if not is_instance_valid(point_b):
		push_error("JANITOR: Point B missing")
		return false

	if not is_instance_valid(point_c):
		push_error("JANITOR: Point C missing")
		return false

	if not is_instance_valid(door_pivot):
		push_error("JANITOR: Door Pivot missing")
		return false

	return true
