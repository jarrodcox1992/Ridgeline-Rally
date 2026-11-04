#!/usr/bin/env python3
"""
Downloads and unpacks a 3D model from Sketchfab using the Sketchfab API.
Reads SKETCHFAB_API_TOKEN securely from environment or ~/.env.
"""

import sys
import os
import json
import urllib.request
import zipfile
from pathlib import Path

PRESETS = {
    "centenario": {
        "uid": "d679af35b5694301a185c7454a700c73",
        "name": "lamborghini_centenario",
        "label": "Lamborghini Centenario LP-770-4",
    },
    "senna": {
        "uid": "ea3e43a6eb004853a87fe9c58422eb96",
        "name": "mclaren_senna",
        "label": "McLaren Senna Free",
    },
    "sf90": {
        "uid": "2c80c667232544649328cf3589921bcd",
        "name": "ferrari_sf90",
        "label": "2023 Ferrari SF90 XX Stradale",
    },
    "huracan": {
        "uid": "1d3809ea5a6749d9864ec4c32511d716",
        "name": "lamborghini_huracan_tt",
        "label": "Lamborghini Huracan Twin Turbo [LOST]",
    },
    "f40": {
        "uid": "52a66c41cfcd4f999fb1b1c49bf24d70",
        "name": "ferrari_f40",
        "label": "Ferrari F40",
    },
}

def get_token() -> str:
    token = os.environ.get("SKETCHFAB_API_TOKEN")
    if token:
        return token.strip()
    env_path = Path.home() / ".env"
    if env_path.exists():
        with open(env_path, "r", encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if line.startswith("SKETCHFAB_API_TOKEN="):
                    return line.split("=", 1)[1].strip().strip('"').strip("'")
    return ""

def fetch_model_info(uid: str):
    url = f"https://api.sketchfab.com/v3/models/{uid}"
    req = urllib.request.Request(url, headers={"User-Agent": "RidgelineRally/1.0"})
    with urllib.request.urlopen(req) as resp:
        return json.loads(resp.read().decode())

def download_model(uid: str, target_dir: Path, token: str):
    info = fetch_model_info(uid)
    print(f"Model: {info.get('name')} by {info.get('user', {}).get('displayName')}")
    print(f"Faces: {info.get('faceCount'):,} | License: {info.get('license', {}).get('label')}")

    url = f"https://api.sketchfab.com/v3/models/{uid}/download"
    req = urllib.request.Request(url, headers={
        "Authorization": f"Token {token}",
        "User-Agent": "RidgelineRally/1.0"
    })
    
    try:
        with urllib.request.urlopen(req) as resp:
            download_data = json.loads(resp.read().decode())
    except urllib.error.HTTPError as e:
        if e.code == 401:
            print("ERROR: Unauthorized (401). Invalid or missing Sketchfab API token.")
        elif e.code == 403:
            print("ERROR: Forbidden (403). The model might not be downloadable or download limit reached.")
        else:
            print(f"ERROR: Sketchfab API responded with HTTP {e.code}: {e.reason}")
        sys.exit(1)

    download_url = None
    fmt = "gltf"
    if "gltf" in download_data and download_data["gltf"].get("url"):
        download_url = download_data["gltf"]["url"]
        fmt = "gltf"
    elif "glb" in download_data and download_data["glb"].get("url"):
        download_url = download_data["glb"]["url"]
        fmt = "glb"
    elif "source" in download_data and download_data["source"].get("url"):
        download_url = download_data["source"]["url"]
        fmt = "source"
    else:
        print(f"ERROR: No downloadable gltf/glb format available for this model: {download_data}")
        sys.exit(1)

    print(f"Downloading {fmt.upper()} archive from Sketchfab...")
    target_dir.mkdir(parents=True, exist_ok=True)
    zip_path = target_dir / f"{target_dir.name}.zip"

    dl_req = urllib.request.Request(download_url, headers={"User-Agent": "RidgelineRally/1.0"})
    with urllib.request.urlopen(dl_req) as dl_resp, open(zip_path, "wb") as out_file:
        total_size = int(dl_resp.headers.get("content-length", 0))
        downloaded = 0
        while True:
            chunk = dl_resp.read(64 * 1024)
            if not chunk:
                break
            out_file.write(chunk)
            downloaded += len(chunk)
            if total_size > 0:
                pct = (downloaded / total_size) * 100
                mb_down = downloaded / (1024 * 1024)
                mb_total = total_size / (1024 * 1024)
                print(f"\rProgress: {pct:5.1f}% [{mb_down:.1f} MB / {mb_total:.1f} MB]", end="", flush=True)
    print("\nDownload finished. Extracting archive...")

    with zipfile.ZipFile(zip_path, "r") as zip_ref:
        zip_ref.extractall(target_dir)

    print(f"Extracted to: {target_dir}")
    
    # Check for scene.gltf or scene.bin
    files = list(target_dir.glob("*"))
    print("Files extracted:")
    for f in files:
        print(f" - {f.name} ({f.stat().st_size} bytes)")
        
    return info

def main():
    if len(sys.argv) < 2:
        print("Usage: python3 download_sketchfab.py <preset_name_or_uid> [output_subdir]")
        print("Available presets:", ", ".join(PRESETS.keys()))
        sys.exit(1)

    token = get_token()
    if not token:
        print("ERROR: SKETCHFAB_API_TOKEN is not set in environment or ~/.env")
        sys.exit(2)

    arg = sys.argv[1].lower()
    if arg in PRESETS:
        preset = PRESETS[arg]
        uid = preset["uid"]
        folder_name = preset["name"]
    else:
        uid = sys.argv[1]
        folder_name = sys.argv[2] if len(sys.argv) > 2 else f"model_{uid[:8]}"

    target_dir = Path("/Users/j/Documents/Ridgeline Rally/models") / folder_name
    info = download_model(uid, target_dir, token)
    print(f"\nSuccessfully downloaded and unpacked {info.get('name')} into {target_dir}")

if __name__ == "__main__":
    main()
