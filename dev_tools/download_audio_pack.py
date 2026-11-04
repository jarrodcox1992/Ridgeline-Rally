#!/usr/bin/env python3
import urllib.request
import os
import sys

SOUNDS_DIR = "/Users/j/Documents/Ridgeline Rally/sounds"
os.makedirs(SOUNDS_DIR, exist_ok=True)

DOWNLOADS = {
    # Multi-RPM engine loops (domasx2, CC0)
    "engine_loop_0.wav": "https://opengameart.org/sites/default/files/loop_0.wav",
    "engine_loop_1.wav": "https://opengameart.org/sites/default/files/loop_1_0.wav",
    "engine_loop_2.wav": "https://opengameart.org/sites/default/files/loop_2_0.wav",
    "engine_loop_3.wav": "https://opengameart.org/sites/default/files/loop_3_0.wav",
    "engine_loop_4.wav": "https://opengameart.org/sites/default/files/loop_4_0.wav",
    "engine_loop_5.wav": "https://opengameart.org/sites/default/files/loop_5_0.wav",
    
    # Engine decel and limiter (Bungee, MIT)
    "engine_decel.wav": "https://raw.githubusercontent.com/LeonManiora/bungee-engine-audio/main/addons/bungee/sounds/Vehicles/BaseCar/dcc.wav",
    "engine_limiter.wav": "https://raw.githubusercontent.com/LeonManiora/bungee-engine-audio/main/addons/bungee/sounds/Vehicles/BaseCar/limit.wav",

    # Tire sounds
    "tire_screech.wav": "https://opengameart.org/sites/default/files/tires_squal_loop.wav",
    "tire_scrub.wav": "https://raw.githubusercontent.com/LeonManiora/bungee-engine-audio/main/addons/bungee/sounds/Effects/skid/skid_00Road.wav",

    # Transmission whine and shifts
    "gear_whine.wav": "https://raw.githubusercontent.com/LeonManiora/bungee-engine-audio/main/addons/bungee/sounds/Effects/Whine/whine_00.wav",
    "gear_shift_up.wav": "https://raw.githubusercontent.com/LeonManiora/bungee-engine-audio/main/addons/bungee/sounds/Effects/ShiftUp/shiftup_00.wav",
    "gear_shift_down.wav": "https://raw.githubusercontent.com/LeonManiora/bungee-engine-audio/main/addons/bungee/sounds/Effects/ShiftDown/shiftdown_00.wav",

    # Turbo and BOV
    "turbo_bov.wav": "https://raw.githubusercontent.com/LeonManiora/bungee-engine-audio/main/addons/bungee/sounds/Effects/BOV/bov_00.wav",
    "turbo_whistle.wav": "https://raw.githubusercontent.com/LeonManiora/bungee-engine-audio/main/addons/bungee/sounds/Effects/Turbo/wis_00.wav",

    # Metal impacts
    "impact_heavy.wav": "https://opengameart.org/sites/default/files/bong1.wav",
    "impact_thud.wav": "https://opengameart.org/sites/default/files/thud2.wav",
    "impact_clink.wav": "https://opengameart.org/sites/default/files/clink1_0.wav",
}

# Backfire pops 1-9
for i in range(1, 10):
    name = f"backfire_{i}.wav"
    url = f"https://raw.githubusercontent.com/LeonManiora/bungee-engine-audio/main/addons/bungee/sounds/Effects/Backfire/backfire_-0{i}.wav"
    DOWNLOADS[name] = url

headers = {"User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)"}

for filename, url in DOWNLOADS.items():
    filepath = os.path.join(SOUNDS_DIR, filename)
    if os.path.exists(filepath) and os.path.getsize(filepath) > 1000:
        print(f"Already exists: {filename} ({os.path.getsize(filepath)} bytes)")
        continue
    print(f"Downloading {filename} from {url}...")
    req = urllib.request.Request(url, headers=headers)
    try:
        with urllib.request.urlopen(req, timeout=15) as resp, open(filepath, "wb") as f:
            f.write(resp.read())
        print(f"Saved {filename}: {os.path.getsize(filepath)} bytes")
    except Exception as e:
        print(f"Failed to download {filename}: {e}", file=sys.stderr)

print("Audio pack download complete!")
