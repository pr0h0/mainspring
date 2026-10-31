"""Procedural sound for Mainspring: clockwork effects, a music-box loop and a ticking ambience.

    python3 tools/gen_audio.py assets/audio

Writes mono 16-bit WAVs at 22.05 kHz.
"""
import os
import sys
import wave

import numpy as np
from scipy import signal

SR = 22050
OUT = sys.argv[1] if len(sys.argv) > 1 else "assets/audio"
os.makedirs(OUT, exist_ok=True)
rng = np.random.default_rng(11)


def t(dur):
    return np.arange(int(SR * dur)) / SR


def noise(dur):
    return rng.uniform(-1, 1, int(SR * dur))


def bp(x, lo, hi, order=2):
    b, a = signal.butter(order, [lo / (SR / 2), hi / (SR / 2)], btype="band")
    return signal.lfilter(b, a, x)


def lp(x, f, order=2):
    b, a = signal.butter(order, f / (SR / 2), btype="low")
    return signal.lfilter(b, a, x)


def hp(x, f, order=2):
    b, a = signal.butter(order, f / (SR / 2), btype="high")
    return signal.lfilter(b, a, x)


def dec(n, rate):
    return np.exp(-np.arange(n) / SR * rate)


def fade(x, ms=6):
    n = min(len(x) // 2, int(SR * ms / 1000))
    x = x.copy()
    x[:n] *= np.linspace(0, 1, n)
    x[-n:] *= np.linspace(1, 0, n)
    return x


def click(dur=0.03, lo=1500, hi=6000, rate=180):
    x = bp(noise(dur), lo, hi) * dec(int(SR * dur), rate)
    return x


def bell(freq, dur, bright=1.0, rate=4.0):
    tt = t(dur)
    x = np.zeros_like(tt)
    for mult, amp, r in [(1, 1.0, 1.0), (2.0, 0.5 * bright, 1.6), (3.01, 0.25 * bright, 2.4), (4.2, 0.15 * bright, 3.5)]:
        x += amp * np.sin(2 * np.pi * freq * mult * tt) * np.exp(-tt * rate * r)
    return x


def musicbox(freq, dur=1.6):
    tt = t(dur)
    x = np.sin(2 * np.pi * freq * tt) * np.exp(-tt * 3.0)
    x += 0.35 * np.sin(2 * np.pi * freq * 3.0 * tt) * np.exp(-tt * 9.0)
    x += 0.18 * np.sin(2 * np.pi * freq * 5.4 * tt) * np.exp(-tt * 16.0)
    att = min(len(x), int(SR * 0.003))
    x[:att] *= np.linspace(0, 1, att)
    return x


def place(buf, x, at):
    i = int(SR * at)
    end = min(len(buf), i + len(x))
    buf[i:end] += x[: end - i]


def write(name, x, gain=0.8):
    x = np.asarray(x, dtype=float)
    peak = np.max(np.abs(x)) or 1.0
    x = x / peak * gain
    data = (x * 32767).astype(np.int16)
    with wave.open(os.path.join(OUT, name + ".wav"), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(data.tobytes())


def hz(note):
    return 440.0 * 2 ** ((note - 69) / 12)


# --- effects -------------------------------------------------------------------------------

write("click", fade(click(0.04, 1200, 5000, 160) + 0.3 * bell(1800, 0.04, 0.3, 60)), 0.5)
write("tick", fade(click(0.05, 2000, 7000, 140)), 0.5)

tt = t(0.22)
f = 380 + 520 * (tt / 0.22) ** 0.6
boing = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-tt * 14) * (1 + 0.4 * np.sin(2 * np.pi * 38 * tt))
write("jump", fade(boing * 0.6 + 0.3 * click(0.22, 2500, 7000, 90)), 0.55)

thump = lp(noise(0.16), 400) * dec(int(SR * 0.16), 30) + 0.4 * click(0.16, 1500, 4000, 90)
write("land", fade(thump), 0.6)
write("thud", fade(lp(noise(0.25), 260) * dec(int(SR * 0.25), 18) + 0.6 * np.sin(2 * np.pi * 70 * t(0.25)) * dec(int(SR * 0.25), 20)), 0.8)

x = np.zeros(int(SR * 0.5))
place(x, click(0.03, 1000, 4500, 220), 0)
place(x, 0.5 * bell(hz(62), 0.5, 0.7, 5), 0.01)
write("plate_on", fade(x), 0.65)
x = np.zeros(int(SR * 0.25))
place(x, click(0.03, 2000, 6000, 260), 0)
place(x, 0.25 * bell(hz(69), 0.25, 0.5, 12), 0.01)
write("plate_off", fade(x), 0.45)

x = np.zeros(int(SR * 0.5))
for k in range(9):
    place(x, click(0.02, 900, 3800, 300) * (0.6 + 0.4 * rng.random()), 0.04 * k)
x += 0.5 * lp(noise(0.5), 180) * np.hanning(len(x))
write("door", fade(x), 0.7)

write("push", fade(bp(noise(0.16), 300, 1400) * np.hanning(int(SR * 0.16))), 0.5)
write("hiss", fade(hp(noise(0.8), 2500) * dec(int(SR * 0.8), 4) + 0.3 * bp(noise(0.8), 600, 1500) * dec(int(SR * 0.8), 6)), 0.6)

x = np.zeros(int(SR * 1.4))
place(x, bell(hz(84), 1.2, 1.0, 3), 0)
place(x, bell(hz(91), 1.2, 1.0, 3), 0.11)
write("cog", fade(x), 0.6)

x = np.zeros(int(SR * 2.6))
for i, n in enumerate([74, 77, 81, 86, 89]):
    place(x, musicbox(hz(n), 1.8), 0.12 * i)
place(x, 0.6 * bell(hz(62), 2.0, 0.6, 1.5), 0.6)
write("win", fade(x), 0.7)

# Unwind: a rushing sweep downwards with a ratchet that speeds up.
dur = 0.8
tt = t(dur)
sweep = np.zeros_like(tt)
nz = noise(dur)
for k in range(8):
    seg = slice(int(len(tt) * k / 8), int(len(tt) * (k + 1) / 8))
    c = 2400 - k * 260
    sweep[seg] = bp(nz, c * 0.7, c * 1.3)[seg]
sweep *= np.sin(np.pi * tt / dur) ** 1.5
x = sweep * 0.7
at = 0.0
gap = 0.07
while at < dur - 0.03:
    place(x, click(0.02, 1500, 6000, 320) * 0.8, at)
    at += gap
    gap = max(0.018, gap * 0.82)
x += 0.4 * np.sin(2 * np.pi * np.cumsum(600 - 400 * tt / dur) / SR) * np.sin(np.pi * tt / dur)
write("unwind", fade(x), 0.7)

x = np.zeros(int(SR * 0.3))
for k in range(4):
    place(x, click(0.02, 1500, 6000, 320), 0.05 * k)
x += 0.3 * np.sin(2 * np.pi * np.cumsum(300 + 500 * t(0.3) / 0.3) / SR) * np.hanning(len(x))
write("undo", fade(x), 0.55)

x = np.zeros(int(SR * 1.3))
at = 0.0
gap = 0.04
k = 0
while at < 1.15:
    place(x, click(0.025, 1200 - k * 20, 4500, 260), at)
    at += gap
    gap *= 1.14
    k += 1
place(x, 0.35 * bell(hz(50), 1.0, 0.4, 3), 0.9)
write("wind_down", fade(x), 0.6)

# --- music: a slow music box in D minor over a soft pad, 32 s loop -------------------------

bpm = 60
beat = 60.0 / bpm
bars = 8
total = bars * 4 * beat
music = np.zeros(int(SR * total) + SR * 2)
chords = [[50, 57, 62, 65], [46, 53, 58, 62], [48, 55, 60, 64], [45, 52, 57, 61],
          [50, 57, 62, 65], [43, 50, 55, 58], [45, 52, 57, 61], [50, 57, 62, 66]]
melody = [
    [74, None, 77, 76], [74, None, 72, 70], [72, None, 76, 74], [73, None, None, 69],
    [74, 77, 81, 79], [77, None, 74, 72], [73, 76, 79, 77], [74, None, None, None],
]
for b in range(bars):
    start = b * 4 * beat
    # pad
    pt = t(4 * beat + 1.0)
    pad = np.zeros_like(pt)
    for n in chords[b]:
        fr = hz(n)
        pad += np.sin(2 * np.pi * fr * pt + 0.3 * np.sin(2 * np.pi * 0.2 * pt)) * 0.25
        pad += 0.08 * np.sin(2 * np.pi * fr * 2.0 * pt)
    env = np.minimum(1, pt / 1.2) * np.minimum(1, np.maximum(0, (4 * beat + 1.0 - pt) / 1.2))
    place(music, lp(pad * env, 1200) * 0.35, start)
    # music box
    for i, n in enumerate(melody[b]):
        if n is not None:
            place(music, musicbox(hz(n), 2.4) * 0.55, start + i * beat)
        if i % 2 == 1:
            place(music, musicbox(hz(chords[b][2] + 12), 1.4) * 0.2, start + i * beat + beat * 0.5)
tail = music[int(SR * total):]
music = music[: int(SR * total)]
music[: len(tail)] += tail  # wrap the ringing tail into the start so it loops cleanly
write("music", music, 0.55)

# --- ambience: tick-tock, 4 s loop ----------------------------------------------------------

amb = lp(noise(4.0), 300) * 0.06
for k in range(8):
    place(amb, click(0.04, 2500 if k % 2 == 0 else 1800, 7000, 160) * 0.5, k * 0.5)
write("ambience", amb, 0.4)

# --- second act (appended so the sounds above stay byte-identical) ----------------------------

# A hand bell: bright strike with a shimmering tail.
x = np.zeros(int(SR * 2.0))
place(x, click(0.02, 3000, 8000, 300), 0)
for n, a in [(88, 1.0), (95, 0.5), (100, 0.25)]:
    place(x, a * bell(hz(n), 1.9, 1.2, 2.2) * (1 + 0.15 * np.sin(2 * np.pi * 6 * t(1.9))), 0.005)
write("chime", fade(x), 0.6)

# Release: the held echoes start again, a soft rising pair.
x = np.zeros(int(SR * 0.5))
place(x, 0.6 * bell(hz(81), 0.45, 0.4, 7), 0)
place(x, 0.6 * bell(hz(86), 0.4, 0.4, 7), 0.07)
write("release", fade(x), 0.45)

# The tower's minute hand dropping onto twelve.
x = np.zeros(int(SR * 0.9))
place(x, lp(noise(0.3), 500) * dec(int(SR * 0.3), 14), 0)
place(x, click(0.05, 600, 3000, 60) * 1.5, 0)
place(x, 0.8 * np.sin(2 * np.pi * 55 * t(0.8)) * dec(int(SR * 0.8), 6), 0)
place(x, 0.3 * bell(hz(45), 0.8, 0.3, 4), 0.01)
write("clunk", fade(x), 0.8)

# The great bells: a slow descending peal over a deep hum.
dur = 9.0
x = np.zeros(int(SR * dur))
peal = [74, 71, 67, 62, 74, 69, 67, 62, 71, 67, 62, 50]
for i, n in enumerate(peal):
    place(x, bell(hz(n), 3.0, 0.9, 1.2) * (0.9 if n > 55 else 1.4), 0.55 * i + 0.02 * rng.random())
place(x, 0.6 * bell(hz(38), dur - 0.5, 0.4, 0.5), 0.0)
write("bells", fade(x, 300), 0.75)

# Act II music: the same music box, now in D major and a little quicker.
bpm = 72
beat = 60.0 / bpm
bars = 8
total = bars * 4 * beat
music = np.zeros(int(SR * total) + SR * 2)
chords = [[50, 57, 62, 66], [47, 54, 59, 62], [43, 50, 55, 59], [45, 52, 57, 61],
          [50, 57, 62, 66], [43, 50, 55, 59], [45, 52, 57, 61], [50, 57, 62, 66]]
melody = [
    [74, 76, 78, None], [79, None, 78, 76], [74, None, 71, 74], [76, None, None, 73],
    [74, 78, 81, 83], [81, None, 79, 78], [76, 78, 79, 76], [74, None, None, None],
]
for b in range(bars):
    start = b * 4 * beat
    pt = t(4 * beat + 1.0)
    pad = np.zeros_like(pt)
    for n in chords[b]:
        fr = hz(n)
        pad += np.sin(2 * np.pi * fr * pt + 0.3 * np.sin(2 * np.pi * 0.2 * pt)) * 0.25
        pad += 0.08 * np.sin(2 * np.pi * fr * 2.0 * pt)
    env = np.minimum(1, pt / 1.2) * np.minimum(1, np.maximum(0, (4 * beat + 1.0 - pt) / 1.2))
    place(music, lp(pad * env, 1400) * 0.32, start)
    for i, n in enumerate(melody[b]):
        if n is not None:
            place(music, musicbox(hz(n), 2.2) * 0.55, start + i * beat)
        place(music, musicbox(hz(chords[b][(i % 3) + 1] + 12), 1.2) * 0.18, start + i * beat + beat * 0.5)
tail = music[int(SR * total):]
music = music[: int(SR * total)]
music[: len(tail)] += tail
write("music2", music, 0.55)

print("wrote", sorted(os.listdir(OUT)))
