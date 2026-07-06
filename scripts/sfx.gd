extends Node

const POOL_SIZE: int = 16
var players: Array[AudioStreamPlayer] = []
var next_player_index: int = 0

func _ready() -> void:
	for i: int in range(POOL_SIZE):
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		add_child(player)
		players.append(player)

func play(stream: AudioStream, pitch_variance: float = 0.0, volume: float = 1.0) -> void:
	if not stream:
		return
	var player: AudioStreamPlayer = players[next_player_index]
	next_player_index = (next_player_index + 1) % POOL_SIZE
	player.stream = stream
	player.volume_linear = volume
	if pitch_variance > 0.0:
		player.pitch_scale = randf_range(1.0 - pitch_variance, 1.0 + pitch_variance)
	else:
		player.pitch_scale = 1.0
	player.play()
