
extends Node3D

# Assign the SM_City model from your Office scene.
@export var city_backdrop: Node3D


func _ready() -> void:
	if not is_instance_valid(city_backdrop):
		push_error("BACKDROP: City model not assigned!")
		return

	make_unshaded(city_backdrop)


func make_unshaded(node: Node) -> void:

	# Find all meshes inside the city backdrop.
	if node is MeshInstance3D:

		var mesh_instance: MeshInstance3D = node

		# Allow sunlight to pass through.
		mesh_instance.cast_shadow = (
			GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		)

		if mesh_instance.mesh != null:

			for i in range(mesh_instance.mesh.get_surface_count()):

				# Get the existing material with its textures.
				var original_material: Material = (
					mesh_instance.get_active_material(i)
				)

				if original_material is BaseMaterial3D:

					# Make a separate copy so the
					# original imported GLB is unchanged.
					var new_material: BaseMaterial3D = (
						original_material.duplicate()
						as BaseMaterial3D
					)

					# Ignore lighting calculations.
					new_material.shading_mode = (
						BaseMaterial3D.SHADING_MODE_UNSHADED
					)

					# Apply only to this mesh instance.
					mesh_instance.set_surface_override_material(
						i,
						new_material
					)

				else:
					push_warning(
						"BACKDROP: Unsupported material on "
						+ str(mesh_instance.name)
					)

	# Process all children recursively.
	for child in node.get_children():
		make_unshaded(child)
