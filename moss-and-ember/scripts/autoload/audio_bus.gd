extends Node
## AudioBus — music + one-shot sfx. All audio is procedurally generated.

var music_player: AudioStreamPlayer
var _sfx_players: Array[AudioStreamPlayer] = []
var _sfx_index: int = 0
var muted: bool = false

const SFX_NAMES := [
	"click", "plant", "harvest", "buy", "sell", "cluck",
	"step", "pop", "day", "error", "pet",
]

func _ready() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.name = "MusicPlayer"
	add_child(music_player)
	var stream := load("res://audio/music_main.wav")
	if stream:
		if stream is AudioStreamWAV:
			(stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
		music_player.stream = stream
		music_player.volume_db = -16.0
		music_player.play()
	for i in 8:
		var p := AudioStreamPlayer.new()
		p.name = "Sfx%d" % i
		add_child(p)
		_sfx_players.append(p)

func _process(_delta: float) -> void:
	# Re-trigger music if the browser suspended the audio context before
	# first user gesture (common on mobile).
	if muted == false and music_player.stream != null and not music_player.playing:
		music_player.play()

func play_sfx(which: String, volume_db: float = 0.0) -> void:
	if muted:
		return
	var path := "res://audio/sfx_%s.wav" % which
	if not ResourceLoader.exists(path):
		return
	var p: AudioStreamPlayer = _sfx_players[_sfx_index]
	_sfx_index = (_sfx_index + 1) % _sfx_players.size()
	p.stream = load(path)
	p.volume_db = volume_db
	p.play()

func toggle_mute() -> void:
	muted = not muted
	music_player.volume_db = -80.0 if muted else -16.0
