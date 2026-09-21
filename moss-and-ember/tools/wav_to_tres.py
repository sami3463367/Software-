#!/usr/bin/env python3
"""Convert audio/*.wav into importer-free text resources (audio/*.tres).

Why: the Godot web runtime has no importers, so a raw .wav can only be loaded
through the editor-generated .godot/imported/*.w32 cache. Shipping the audio as
AudioStreamWAV text resources with base64 PCM data removes that dependency
entirely (Godot's VariantParser accepts PackedByteArray("<base64>")).

Usage: python3 tools/wav_to_tres.py
"""
import base64
import os
import struct
import sys
import wave

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
AUDIO = os.path.join(ROOT, "audio")

FORMAT_16BIT = 1
LOOP_FORWARD = 1


def wav_pcm(path):
    with wave.open(path, "rb") as w:
        if w.getsampwidth() != 2:
            raise SystemExit(f"{path}: only 16-bit PCM is supported")
        return w.readframes(w.getnframes()), w.getnchannels(), w.getframerate()


def to_tres(name: str, pcm: bytes, channels: int, mix_rate: int, loop: bool) -> str:
    b64 = base64.b64encode(pcm).decode("ascii")
    lines = [
        '[gd_resource type="AudioStreamWAV" format=3]',
        "",
        "[resource]",
        f'data = PackedByteArray("{b64}")',
        f"format = {FORMAT_16BIT}",
        f"mix_rate = {mix_rate}",
        f"stereo = {'true' if channels == 2 else 'false'}",
    ]
    if loop:
        frames = len(pcm) // (2 * channels)
        lines += [f"loop_mode = {LOOP_FORWARD}", "loop_begin = 0", f"loop_end = {frames}"]
    return "\n".join(lines) + "\n"


def main() -> int:
    if not os.path.isdir(AUDIO):
        raise SystemExit(f"no audio dir at {AUDIO}")
    count = 0
    for fname in sorted(os.listdir(AUDIO)):
        if not fname.endswith(".wav"):
            continue
        src = os.path.join(AUDIO, fname)
        dst = os.path.join(AUDIO, fname[:-4] + ".tres")
        pcm, channels, mix_rate = wav_pcm(src)
        loop = fname.startswith("music")
        with open(dst, "w", encoding="utf-8") as f:
            f.write(to_tres(fname, pcm, channels, mix_rate, loop))
        count += 1
        print(f"{fname:22} -> {os.path.basename(dst):22} {os.path.getsize(dst)/1024/1024:5.2f} MB"
              f"{'  [loop]' if loop else ''}")
    print(f"{count} resources written")
    return 0


if __name__ == "__main__":
    sys.exit(main())
