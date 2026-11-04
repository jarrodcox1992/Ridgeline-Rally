extends SceneTree

func _initialize() -> void:
	print("--- TESTING SAMPLE AUDIO PACK ---")
	var engine_files := [
		"res://sounds/engine_loop_0.wav",
		"res://sounds/engine_loop_1.wav",
		"res://sounds/engine_loop_2.wav",
		"res://sounds/engine_loop_3.wav",
		"res://sounds/engine_loop_4.wav",
		"res://sounds/engine_loop_5.wav",
		"res://sounds/engine_decel.wav",
		"res://sounds/engine_limiter.wav",
		"res://sounds/tire_screech.wav",
		"res://sounds/tire_scrub.wav",
		"res://sounds/gear_whine.wav",
		"res://sounds/gear_shift_up.wav",
		"res://sounds/gear_shift_down.wav",
		"res://sounds/turbo_bov.wav",
		"res://sounds/turbo_whistle.wav",
		"res://sounds/impact_heavy.wav",
		"res://sounds/impact_thud.wav",
		"res://sounds/impact_clink.wav",
	]
	for path in engine_files:
		var stream := load(path) as AudioStreamWAV
		if not stream:
			printerr("FAILED to load: ", path)
			quit(1)
			return
		print("Loaded: %s (length=%.2fs, rate=%d, loop_mode=%d)" % [path.get_file(), stream.get_length(), stream.mix_rate, stream.loop_mode])

	for i in range(1, 10):
		var bf_path := "res://sounds/backfire_%d.wav" % i
		var bf := load(bf_path) as AudioStreamWAV
		if not bf:
			printerr("FAILED to load backfire: ", bf_path)
			quit(1)
			return
		print("Loaded backfire: backfire_%d.wav (length=%.2fs)" % [i, bf.get_length()])

	print("--- ALL SAMPLE AUDIO PACK ASSETS VERIFIED ---")
	quit(0)
