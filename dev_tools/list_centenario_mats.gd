@tool
extends SceneTree

func _init():
	var scene = load("res://models/lamborghini_centenario/centenario.tscn").instantiate()
	for mi in scene.find_children("*", "MeshInstance3D"):
		for s in range(mi.mesh.get_surface_count()):
			var m = mi.mesh.surface_get_material(s)
			if m:
				print(mi.name, " surf ", s, " mat: ", m.resource_name)
	quit(0)
