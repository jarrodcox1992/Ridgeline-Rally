@tool
extends SceneTree

func _init():
	print("Testing audio generator at 44100 Hz...")
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = 44100.0
	gen.buffer_length = 0.1
	
	var player := AudioStreamPlayer.new()
	player.stream = gen
	root.add_child(player)
	player.play()
	
	var playback := player.get_stream_playback() as AudioStreamGeneratorPlayback
	if not playback:
		printerr("Failed to get AudioStreamGeneratorPlayback")
		quit(1)
		return
		
	print("Generator initialized successfully! Frames available: ", playback.get_frames_available())
	quit(0)
