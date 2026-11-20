extends Node

# 全局音效播放器：不依赖具体场景，任何脚本都可以调用 Sfx.play("hit")

const STREAMS := {
	"hit": preload("res://audio/sfx/hit.wav"),
	"hurt": preload("res://audio/sfx/hurt.wav"),
	"pickup": preload("res://audio/sfx/pickup.wav"),
	"craft": preload("res://audio/sfx/craft.wav"),
	"door": preload("res://audio/sfx/door.wav"),
	"warn": preload("res://audio/sfx/warn.wav"),
	"dash": preload("res://audio/sfx/dash.wav"),
	"sword": preload("res://audio/sfx/sword.wav"),
	"punch": preload("res://audio/sfx/punch.wav"),
	"charge": preload("res://audio/sfx/charge.wav"),
	"heal": preload("res://audio/sfx/heal.wav"),
	"enemy_strike": preload("res://audio/sfx/enemy_strike.wav"),
	"enemy_death": preload("res://audio/sfx/enemy_death.wav"),
	"crow": preload("res://audio/sfx/crow.wav"),
	"danger": preload("res://audio/sfx/danger.wav"),
}

const POOL_SIZE := 8
const VOLUME_DB := -7.0

var _players: Array[AudioStreamPlayer] = []
var _next := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.volume_db = VOLUME_DB
		p.bus = "SFX"
		add_child(p)
		_players.append(p)


func play(id: String, pitch: float = 1.0, volume_offset: float = 0.0) -> void:
	if DisplayServer.get_name() == "headless":
		return
	var stream: AudioStream = STREAMS.get(id, null)
	if stream == null:
		return
	var p := _players[_next]
	_next = (_next + 1) % _players.size()
	p.stream = stream
	p.pitch_scale = pitch
	p.volume_db = VOLUME_DB + volume_offset
	p.play()
