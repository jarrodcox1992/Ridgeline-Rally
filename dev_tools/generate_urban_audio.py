#!/usr/bin/env python3
"""
Generates procedural 16-bit 44.1kHz stereo audio layers for Gritty Urban Noir soundscape:
- urban_ambient_canyon.wav: Continuous deep urban canyon ambience with distant city drone, wind, and city texture.
- subway_vent_hum.wav: 3D spatial low-frequency subway grate/vent hum and gentle steam hiss.
- el_train_pass.wav: Elevated railway girder reverberation and distant wheel squeal.
- city_siren_distant.wav: Eerie distant siren echoing off concrete and glass canyons.
"""

import math
import random
import struct
import wave

SAMPLE_RATE = 44100

def write_wav(path: str, samples_left: list, samples_right: list):
    with wave.open(path, 'wb') as wf:
        wf.setnchannels(2)
        wf.setsampwidth(2)
        wf.setframerate(SAMPLE_RATE)
        
        frames = bytearray()
        for l, r in zip(samples_left, samples_right):
            # Clamp to [-1.0, 1.0]
            cl = max(-1.0, min(1.0, l))
            cr = max(-1.0, min(1.0, r))
            il = int(cl * 32767.0)
            ir = int(cr * 32767.0)
            frames.extend(struct.pack('<hh', il, ir))
        wf.writeframes(frames)
    print(f"Generated: {path} ({len(samples_left) / SAMPLE_RATE:.2f}s)")

def generate_urban_canyon():
    # 8-second seamless looping stereo ambient drone
    duration = 8.0
    num_samples = int(duration * SAMPLE_RATE)
    left = [0.0] * num_samples
    right = [0.0] * num_samples
    
    random.seed(42)
    # Low frequency traffic drone (48Hz, 72Hz, 110Hz, 145Hz)
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        
        # Sub-bass city pulse
        sub = math.sin(2.0 * math.pi * 48.0 * t) * 0.22
        sub += math.sin(2.0 * math.pi * 72.5 * t) * 0.16
        sub += math.sin(2.0 * math.pi * 115.0 * t + 0.5) * 0.12
        
        # Slow canyon wind swell (0.15Hz - 0.3Hz)
        wind_mod = 0.5 + 0.5 * math.sin(2.0 * math.pi * 0.18 * t)
        wind_mod2 = 0.5 + 0.5 * math.sin(2.0 * math.pi * 0.25 * t + 1.2)
        
        # Filtered pink/brown noise for distance traffic roar
        noise_l = (random.random() * 2.0 - 1.0) * 0.08 * wind_mod
        noise_r = (random.random() * 2.0 - 1.0) * 0.08 * wind_mod2
        
        # Distant hollow acoustic reflection (canyon resonance)
        canyon_res = math.sin(2.0 * math.pi * 210.0 * t) * 0.04 * wind_mod
        
        # Subtle distant reverberated metallic tap / clatter at t=2.5s and t=6.0s
        clatter_l = 0.0
        clatter_r = 0.0
        if 2.4 < t < 2.8:
            dt = t - 2.4
            env = math.exp(-dt * 15.0)
            clatter_l = math.sin(2.0 * math.pi * 840.0 * dt) * 0.06 * env
        if 5.8 < t < 6.3:
            dt = t - 5.8
            env = math.exp(-dt * 12.0)
            clatter_r = math.sin(2.0 * math.pi * 680.0 * dt) * 0.05 * env
            
        l_val = (sub + canyon_res + noise_l + clatter_l) * 0.55
        r_val = (sub + canyon_res + noise_r + clatter_r) * 0.55
        
        # Soft seamless loop crossfade at ends
        fade_len = int(0.2 * SAMPLE_RATE)
        if i < fade_len:
            ramp = i / fade_len
            l_val *= ramp
            r_val *= ramp
        elif i > num_samples - fade_len:
            ramp = (num_samples - i) / fade_len
            l_val *= ramp
            r_val *= ramp
            
        left[i] = l_val
        right[i] = r_val
        
    write_wav("/Users/j/Documents/Ridgeline Rally/sounds/urban_ambient_canyon.wav", left, right)

def generate_subway_vent():
    # 5-second seamless loop for manholes & steam vents: low hum + gentle hiss
    duration = 5.0
    num_samples = int(duration * SAMPLE_RATE)
    left = [0.0] * num_samples
    right = [0.0] * num_samples
    
    random.seed(101)
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        
        # 60Hz mains motor drone + 120Hz harmonic
        hum = math.sin(2.0 * math.pi * 58.0 * t) * 0.32
        hum += math.sin(2.0 * math.pi * 116.0 * t) * 0.20
        hum += math.sin(2.0 * math.pi * 174.0 * t) * 0.09
        
        # Steam hiss (high-passed noise with soft pulsing)
        steam_pulse = 0.7 + 0.3 * math.sin(2.0 * math.pi * 1.8 * t)
        hiss = (random.random() * 2.0 - 1.0) * 0.16 * steam_pulse
        
        val = (hum + hiss) * 0.5
        left[i] = val
        right[i] = val
        
    write_wav("/Users/j/Documents/Ridgeline Rally/sounds/subway_vent_hum.wav", left, right)

def generate_el_train():
    # 6-second elevated train rumble and track clatter
    duration = 6.0
    num_samples = int(duration * SAMPLE_RATE)
    left = [0.0] * num_samples
    right = [0.0] * num_samples
    
    random.seed(77)
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        
        # Rhythmic clack-clack over rail expansion joints every 0.65 seconds
        clack_cycle = t % 0.65
        clack_env = math.exp(-clack_cycle * 22.0) if clack_cycle < 0.25 else 0.0
        clack = math.sin(2.0 * math.pi * 320.0 * t) * clack_env * 0.35
        
        # Heavy steel bridge girder resonance (82Hz)
        girder = math.sin(2.0 * math.pi * 82.0 * t) * 0.28
        
        # Wheel squeal high harmonic (1840Hz with vibrato)
        squeal_mod = 0.5 + 0.5 * math.sin(2.0 * math.pi * 3.5 * t)
        squeal = math.sin(2.0 * math.pi * (1840.0 + 80.0 * math.sin(t * 14.0)) * t) * 0.04 * squeal_mod
        
        l_val = (clack + girder + squeal) * 0.45
        r_val = (clack * 0.9 + girder + squeal * 1.1) * 0.45
        
        left[i] = l_val
        right[i] = r_val
        
    write_wav("/Users/j/Documents/Ridgeline Rally/sounds/el_train_pass.wav", left, right)

def generate_distant_siren():
    # 7-second distant emergency siren echoing in urban canyon
    duration = 7.0
    num_samples = int(duration * SAMPLE_RATE)
    left = [0.0] * num_samples
    right = [0.0] * num_samples
    
    phase = 0.0
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        
        # Siren wail sweeping between 620Hz and 940Hz with 4.5s cycle
        freq = 780.0 + 160.0 * math.sin(2.0 * math.pi * 0.42 * t)
        phase += 2.0 * math.pi * freq / SAMPLE_RATE
        
        # Distance air dampening and canyon echo (filtered square/sine wave)
        siren_raw = math.sin(phase) + 0.25 * math.sin(phase * 2.0)
        
        # Envelope: fades in from distance, peaks around 3.5s, then echoes out
        dist_env = math.sin(math.pi * (t / duration)) * 0.18
        
        # Left/Right delay for spatial canyon reflection (18ms delay in right ear)
        l_val = siren_raw * dist_env
        r_val = siren_raw * dist_env * 0.85
        
        left[i] = l_val
        right[i] = r_val
        
    write_wav("/Users/j/Documents/Ridgeline Rally/sounds/city_siren_distant.wav", left, right)

if __name__ == "__main__":
    generate_urban_canyon()
    generate_subway_vent()
    generate_el_train()
    generate_distant_siren()
    print("ALL URBAN AUDIO TRACKS GENERATED SUCCESSFULLY!")
