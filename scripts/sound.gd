extends RefCounted
class_name SpiderSound

const SAMPLE_RATE := 22050

static func make_chime(frequency: float, duration: float) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	var count := int(duration * SAMPLE_RATE)
	var pcm := PackedByteArray()
	pcm.resize(count * 2)
	for i in count:
		var t := float(i) / float(SAMPLE_RATE)
		var envelope := pow(1.0 - t / duration, 2.2)
		var fundamental := sin(TAU * frequency * t)
		var overtone := sin(TAU * frequency * 2.0 * t) * 0.22
		var sample := int(clampf((fundamental + overtone) * envelope * 0.32, -1.0, 1.0) * 32767.0)
		pcm.encode_s16(i * 2, sample)
	stream.data = pcm
	return stream

static func make_music_loop() -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	var duration := 8.0
	var count := int(duration * SAMPLE_RATE)
	var pcm := PackedByteArray()
	# Godot's WAV loop mixer can decode the frame at loop_end before wrapping.
	# Keep guard frames after the loop so Android never reads beyond this buffer.
	pcm.resize((count + 4) * 2)
	var notes := [261.63, 329.63, 392.0, 329.63, 293.66, 349.23, 392.0, 293.66]
	for i in count:
		var t := float(i) / SAMPLE_RATE
		var note_time := fmod(t, 1.0)
		var note: float = notes[mini(int(t), notes.size() - 1)]
		var pluck := sin(TAU * note * note_time) * exp(-note_time * 4.4) * 0.18
		var pad := (sin(TAU * 130.81 * t) + sin(TAU * 196.0 * t)) * 0.025
		var edge := minf(1.0, minf(t, duration - t) * 12.0)
		pcm.encode_s16(i * 2, int(clampf((pluck + pad) * edge, -1.0, 1.0) * 32767.0))
	for i in 4:
		pcm.encode_s16((count + i) * 2, pcm.decode_s16(i * 2))
	stream.data = pcm
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = count
	return stream
