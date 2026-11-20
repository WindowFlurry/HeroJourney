extends Node2D

# 区域环境音：北（鸟鸣）→ 中（风）→ 南（低频压迫感），随玩家位置平滑过渡。
# 第一次进入南区时给一次低频闷响 + 屏幕边缘暗角脉冲，不使用任何文字。

const STREAMS := {
	"north": preload("res://audio/ambient/ambient_birds.wav"),
	"mid": preload("res://audio/ambient/ambient_wind.wav"),
	"south": preload("res://audio/ambient/ambient_dread.wav"),
}
const VIGNETTE_TEXTURE: Texture2D = preload("res://graphics/fx/vignette.png")
const NORTH_BLEND := Vector2(560.0, 760.0)
const SOUTH_BLEND := Vector2(900.0, 1080.0)
const DANGER_Y := 1120.0
const SILENT_DB := -80.0

var _players := {}
var _player: Node2D
var _vignette: TextureRect
var _danger_seen := false


func _ready() -> void:
	add_to_group("Ambience")
	for key in STREAMS:
		var source := STREAMS[key] as AudioStreamWAV
		var stream: AudioStreamWAV = source.duplicate() as AudioStreamWAV
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = maxi(1, int(stream.get_length() * float(stream.mix_rate)))
		var p := AudioStreamPlayer.new()
		p.stream = stream
		p.bus = "SFX"
		p.volume_db = SILENT_DB
		add_child(p)
		p.play()
		p.finished.connect(p.play)
		_players[key] = p
	_build_vignette()
	_player = get_tree().get_first_node_in_group("Player") as Node2D


func _exit_tree() -> void:
	for key in _players:
		var p: AudioStreamPlayer = _players[key]
		if p != null and is_instance_valid(p):
			p.stop()
			p.stream = null
	_players.clear()


func _build_vignette() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 1
	add_child(layer)
	_vignette = TextureRect.new()
	_vignette.texture = VIGNETTE_TEXTURE
	_vignette.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_vignette.stretch_mode = TextureRect.STRETCH_SCALE
	_vignette.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_vignette.modulate.a = 0.0
	layer.add_child(_vignette)


func _process(delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("Player") as Node2D
		if _player == null:
			return
	var y := _player.global_position.y
	var t1 := _smoothstep(NORTH_BLEND.x, NORTH_BLEND.y, y)
	var t2 := _smoothstep(SOUTH_BLEND.x, SOUTH_BLEND.y, y)
	var smoothing := 1.0 - exp(-5.0 * delta)
	_set_gain("north", 1.0 - t1, smoothing)
	_set_gain("mid", t1 * (1.0 - t2), smoothing)
	_set_gain("south", t2, smoothing)

	if not _danger_seen and y >= DANGER_Y:
		_danger_seen = true
		_play_danger()


func _set_gain(key: String, gain: float, smoothing: float) -> void:
	var p: AudioStreamPlayer = _players[key]
	var target := linear_to_db(clampf(gain, 0.0001, 1.0))
	p.volume_db = lerpf(p.volume_db, target, smoothing)


func _play_danger() -> void:
	Sfx.play("danger", 1.0, -1.0)
	_vignette.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(_vignette, "modulate:a", 1.0, 0.16)
	tween.tween_property(_vignette, "modulate:a", 0.0, 1.5).set_delay(0.2)


func _smoothstep(edge0: float, edge1: float, x: float) -> float:
	var t := clampf((x - edge0) / (edge1 - edge0), 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)
