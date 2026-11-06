extends SceneTree
## One-off: bakes a natural walking pose of each realistic Ready Player Me avatar into a
## static ArrayMesh (with its textures) so the crowd can use real people cheaply.

var main: Node3D
var people := []
var t := 0.0
var spawned := false
var baked := false

func _make_walk(dst_skel: Skeleton3D, dst_path: NodePath) -> Animation:
	var src: Node3D = (load("res://models/city_hd/nathan.glb") as PackedScene).instantiate()
	root.add_child(src)
	var ssk: Skeleton3D = src.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
	var sap: AnimationPlayer = src.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer
	var a: Animation = sap.get_animation("Take 001").duplicate(true)
	for i in range(a.get_track_count()):
		var s := str(a.track_get_path(i))
		var idx := s.find(":")
		if idx < 0:
			continue
		var bi := ssk.find_bone(s.substr(idx + 1))
		if bi < 0:
			continue
		a.track_set_path(i, NodePath(str(dst_path) + ":" + dst_skel.get_bone_name(bi)))
	src.queue_free()
	return a

func _initialize() -> void:
	main = load("res://main.tscn").instantiate()
	root.add_child(main)

func _spawn() -> void:
	var cam := Camera3D.new()
	main.add_child(cam)
	cam.position = Vector3(0.0, 1.6, 8.0)
	cam.look_at(Vector3(0.0, 1.0, 0.0), Vector3.UP)
	cam.make_current()
	var names := ["claudia", "eric", "nathan", "carla"]
	for i in range(names.size()):
		var p: String = names[i]
		var inst: Node3D = (load("res://models/people_src/%s_low.glb" % p) as PackedScene).instantiate()
		main.add_child(inst)
		inst.position = Vector3(-6.0 + 4.0 * float(i), 0.22, 0.0)
		var sk: Skeleton3D = inst.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
		var mi: MeshInstance3D = inst.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D
		var ap := AnimationPlayer.new()
		inst.add_child(ap)
		ap.root_node = NodePath("..")
		var lib := AnimationLibrary.new()
		lib.add_animation("Walk", _make_walk(sk, inst.get_path_to(sk)))
		ap.add_animation_library("", lib)
		ap.play("Walk", -1, 0.85 + 0.09 * float(i))
		people.append({"name": p, "mi": mi, "ap": ap})

func _physics_process(delta: float) -> bool:
	t += delta
	if t > 2.0 and not spawned:
		spawned = true
		_spawn()
		t = 0.0
		return false
	if spawned and not baked and t > 0.7:
		baked = true
		for person in people:
			var mi: MeshInstance3D = person.mi
			var mesh = mi.bake_mesh_from_current_skeleton_pose()
			if mesh == null:
				print("BAKE FAILED ", person.name)
				continue
			for si in range(mesh.get_surface_count()):
				var mat := mi.mesh.surface_get_material(si)
				if mat:
					mesh.surface_set_material(si, mat)
			var path := "res://models/people/%s_pose.res" % person.name
			var err := ResourceSaver.save(mesh, path)
			print("BAKED ", person.name, " err=", err, " verts=", mesh.surface_get_array_len(0), " aabb=", mesh.get_aabb().size)
		quit()
	return false
