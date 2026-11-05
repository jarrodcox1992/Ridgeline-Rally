#!/usr/bin/env python3
"""
Downloads and compiles real-world public roads and highways from OpenStreetMap (ODbL)
into clean, continuous, driveable road track files for Ridgeline Rally.

Roads included:
1. California State Route 1 (Pacific Coast Highway - Big Sur & Bixby Bridge)
2. Passo dello Stelvio (Strada Statale 38 dello Stelvio - Italian Alps)
3. Tail of the Dragon (US Highway 129 Deals Gap - Great Smoky Mountains)
4. Transfăgărășan (Drumul Național 7C - Carpathian Mountains, Romania)
5. German Autobahn A95 (Bavarian Alpine Expressway - Starnberg/Loisachtal)
"""

import subprocess
import xml.etree.ElementTree as ET
import math
import os
import sys

TRACKS_DIR = "/Users/j/Documents/Ridgeline Rally/tracks"
os.makedirs(TRACKS_DIR, exist_ok=True)

def latlon_to_xy(lat, lon, lat0, lon0):
    R = 6371000.0
    rad = math.pi / 180.0
    x = R * (lon - lon0) * rad * math.cos(lat0 * rad)
    y = R * (lat - lat0) * rad
    return x, y

def fetch_osm_bbox(bbox, way_filter):
    url = f"https://api.openstreetmap.org/api/0.6/map?bbox={bbox}"
    res = subprocess.run(["curl", "-s", "-A", "RidgelineRally/1.0", url], capture_output=True)
    if res.returncode != 0 or not res.stdout:
        print(f"Error fetching bbox {bbox}")
        return []
    try:
        root = ET.fromstring(res.stdout)
    except Exception as e:
        print(f"Error parsing XML for bbox {bbox}: {e}")
        return []
    nodes = {n.get("id"): (float(n.get("lat")), float(n.get("lon"))) for n in root.findall("node")}
    ways = []
    for w in root.findall("way"):
        tags = {t.get("k"): t.get("v") for t in w.findall("tag")}
        if way_filter(tags):
            nds = [nd.get("ref") for nd in w.findall("nd")]
            coords = [nodes[nid] for nid in nds if nid in nodes]
            if len(coords) >= 2:
                ways.append({
                    "id": w.get("id"),
                    "name": tags.get("name", tags.get("ref", "")),
                    "coords": coords,
                    "tags": tags
                })
    return ways

def fetch_osm_way(way_id):
    url = f"https://api.openstreetmap.org/api/0.6/way/{way_id}/full"
    res = subprocess.run(["curl", "-s", "-A", "RidgelineRally/1.0", url], capture_output=True)
    if res.returncode != 0 or not res.stdout:
        return []
    try:
        root = ET.fromstring(res.stdout)
    except Exception as e:
        return []
    nodes = {n.get("id"): (float(n.get("lat")), float(n.get("lon"))) for n in root.findall("node")}
    w = root.find("way")
    if w is None:
        return []
    nds = [nd.get("ref") for nd in w.findall("nd")]
    return [nodes[nid] for nid in nds if nid in nodes]

def chain_ways(ways, max_gap_m=100.0):
    """Greedily chains ways together by matching closest endpoints."""
    if not ways:
        return []
    
    # Sort ways by size descending or pick longest way as root
    remaining = list(ways)
    longest_idx = max(range(len(remaining)), key=lambda i: len(remaining[i]["coords"]))
    current = remaining.pop(longest_idx)["coords"]
    
    def dist(c1, c2):
        dlat = (c1[0] - c2[0]) * 111000.0
        dlon = (c1[1] - c2[1]) * 111000.0 * math.cos(math.radians(c1[0]))
        return math.hypot(dlat, dlon)

    while remaining:
        best_dist = 1e9
        best_idx = -1
        best_reverse = False
        append_to_end = True

        for i, w in enumerate(remaining):
            wc = w["coords"]
            # Try connecting to current end
            d_end_start = dist(current[-1], wc[0])
            d_end_end = dist(current[-1], wc[-1])
            # Try connecting to current start
            d_start_end = dist(current[0], wc[-1])
            d_start_start = dist(current[0], wc[0])

            if d_end_start < best_dist:
                best_dist = d_end_start
                best_idx = i
                best_reverse = False
                append_to_end = True
            if d_end_end < best_dist:
                best_dist = d_end_end
                best_idx = i
                best_reverse = True
                append_to_end = True
            if d_start_end < best_dist:
                best_dist = d_start_end
                best_idx = i
                best_reverse = False
                append_to_end = False
            if d_start_start < best_dist:
                best_dist = d_start_start
                best_idx = i
                best_reverse = True
                append_to_end = False

        if best_idx >= 0 and best_dist < max_gap_m:
            chosen = remaining.pop(best_idx)["coords"]
            if best_reverse:
                chosen = chosen[::-1]
            if append_to_end:
                current.extend(chosen[1:] if best_dist < 5.0 else chosen)
            else:
                current = (chosen[:-1] if best_dist < 5.0 else chosen) + current
        else:
            break

    return current

def create_scenic_road_loop(surveyed_pts, offset_dist=32.0, turnaround_radius=30.0):
    """
    Creates a continuous driving corridor from surveyed open road waypoints:
    Outbound leg (surveyed road) -> Panoramic Turnaround Overlook -> Return Scenic Leg -> Base Junction Turnaround.
    Guarantees continuous, endless driving without hitting a dead end.
    """
    if len(surveyed_pts) < 10:
        return surveyed_pts
    
    n = len(surveyed_pts)
    outbound = list(surveyed_pts)
    
    # Calculate local normal vectors along the surveyed path
    normals = []
    for i in range(n):
        prev_p = outbound[max(0, i - 1)]
        next_p = outbound[min(n - 1, i + 1)]
        dx = next_p[0] - prev_p[0]
        dy = next_p[1] - prev_p[1]
        length = math.hypot(dx, dy)
        if length > 1e-4:
            nx = -dy / length
            ny = dx / length
        else:
            nx, ny = 0.0, 1.0
        normals.append((nx, ny))
    
    # Turnaround at the summit / scenic overlook
    end_p = outbound[-1]
    end_dir_x = outbound[-1][0] - outbound[-2][0]
    end_dir_y = outbound[-1][1] - outbound[-2][1]
    end_len = math.hypot(end_dir_x, end_dir_y) or 1.0
    fwd_x = end_dir_x / end_len
    fwd_y = end_dir_y / end_len
    right_x = -fwd_y
    right_y = fwd_x
    
    # Half-circle overlook loop at summit
    summit_loop = []
    steps = 14
    for s in range(1, steps + 1):
        angle = math.pi * (s / float(steps))
        # Center of turn is offset to the right by turnaround_radius
        cx = end_p[0] + right_x * (offset_dist * 0.5)
        cy = end_p[1] + right_y * (offset_dist * 0.5)
        rx = cx + math.cos(angle) * (-right_x * (offset_dist * 0.5)) + math.sin(angle) * (fwd_x * turnaround_radius)
        ry = cy + math.cos(angle) * (-right_y * (offset_dist * 0.5)) + math.sin(angle) * (fwd_y * turnaround_radius)
        summit_loop.append((rx, ry))
    
    # Return leg: parallel scenic return lane, offset on the opposite side of the road
    return_leg = []
    for i in range(n - 2, 0, -1):
        p = outbound[i]
        nx, ny = normals[i]
        # Smoothly varying offset to mimic natural mountain terrain
        local_offset = offset_dist * (1.0 + 0.15 * math.sin(i * 0.12))
        return_leg.append((p[0] + nx * local_offset, p[1] + ny * local_offset))
    
    # Base turnaround loop connecting back to start
    start_p = outbound[0]
    start_dir_x = outbound[1][0] - outbound[0][0]
    start_dir_y = outbound[1][1] - outbound[0][1]
    start_len = math.hypot(start_dir_x, start_dir_y) or 1.0
    sfwd_x = start_dir_x / start_len
    sfwd_y = start_dir_y / start_len
    sright_x = -sfwd_y
    sright_y = sfwd_x
    
    base_loop = []
    for s in range(1, steps):
        angle = math.pi * (s / float(steps))
        cx = start_p[0] + sright_x * (offset_dist * 0.5)
        cy = start_p[1] + sright_y * (offset_dist * 0.5)
        rx = cx - math.cos(angle) * (-sright_x * (offset_dist * 0.5)) - math.sin(angle) * (sfwd_x * turnaround_radius)
        ry = cy - math.cos(angle) * (-sright_y * (offset_dist * 0.5)) - math.sin(angle) * (sfwd_y * turnaround_radius)
        base_loop.append((rx, ry))
        
    return outbound + summit_loop + return_leg + base_loop

def resample_and_smooth(pts, target_spacing=8.0):
    if len(pts) < 3:
        return pts
    # Resample at target_spacing
    resampled = [pts[0]]
    for i in range(1, len(pts)):
        p0 = resampled[-1]
        p1 = pts[i]
        d = math.hypot(p1[0] - p0[0], p1[1] - p0[1])
        if d >= target_spacing:
            steps = max(1, int(d / target_spacing))
            for s in range(1, steps + 1):
                t = s / steps
                resampled.append((p0[0] + (p1[0] - p0[0]) * t, p0[1] + (p1[1] - p0[1]) * t))
    
    # Smooth with small 3-point Gaussian kernel
    smoothed = []
    n = len(resampled)
    for i in range(n):
        p_prev = resampled[(i - 1 + n) % n]
        p_curr = resampled[i]
        p_next = resampled[(i + 1) % n]
        sx = 0.25 * p_prev[0] + 0.5 * p_curr[0] + 0.25 * p_next[0]
        sy = 0.25 * p_prev[1] + 0.5 * p_curr[1] + 0.25 * p_next[1]
        smoothed.append((sx, sy))
    return smoothed

def save_csv(filename, pts, road_name, osm_source):
    # Center points
    min_x = min(p[0] for p in pts)
    max_x = max(p[0] for p in pts)
    min_y = min(p[1] for p in pts)
    max_y = max(p[1] for p in pts)
    cx = (min_x + max_x) * 0.5
    cy = (min_y + max_y) * 0.5
    
    path = os.path.join(TRACKS_DIR, filename)
    with open(path, "w") as f:
        f.write(f"# Ridgeline Rally - Real-World Public Open Road\n")
        f.write(f"# Road: {road_name}\n")
        f.write(f"# Source: OpenStreetMap ({osm_source})\n")
        f.write(f"# License: Open Data Commons Open Database License (ODbL) 1.0\n")
        f.write(f"# Total Waypoints: {len(pts)}\n")
        f.write(f"# x_m,y_m,w_tr_right_m,w_tr_left_m\n")
        for p in pts:
            # Shift to center
            x = p[0] - cx
            y = p[1] - cy
            # Standard highway lane half width 11.5m
            f.write(f"{x:.4f},{y:.4f},11.500,11.500\n")
    print(f"✓ Saved {filename} ({len(pts)} points, span: {max_x-min_x:.1f}m x {max_y-min_y:.1f}m)")

print("=== BUILDING AUTHENTIC REAL-WORLD OPEN ROADS FROM OPENSTREETMAP ===")

# 1. California State Route 1 (Pacific Coast Highway - Big Sur & Bixby Bridge)
print("\n[1/5] Fetching California State Route 1 (Pacific Coast Highway)...")
ca1_ways = fetch_osm_bbox("-121.915,36.355,-121.890,36.385", lambda t: "CA 1" in t.get("ref", "") or "Cabrillo" in t.get("name", "") or "Bixby" in t.get("name", ""))
ca1_coords = chain_ways(ca1_ways)
print(f"CA 1 chained coords: {len(ca1_coords)}")
lat0 = ca1_coords[0][0]
lon0 = ca1_coords[0][1]
ca1_pts = [latlon_to_xy(c[0], c[1], lat0, lon0) for c in ca1_coords]
ca1_loop = create_scenic_road_loop(ca1_pts, offset_dist=38.0, turnaround_radius=32.0)
ca1_smooth = resample_and_smooth(ca1_loop, target_spacing=8.0)
save_csv("PacificCoastHighway.csv", ca1_smooth, "California State Route 1 (Pacific Coast Highway - Big Sur)", "OpenStreetMap Relation/Ways CA 1, Cabrillo Hwy, Bixby Creek Bridge")

# 2. Passo dello Stelvio (Strada Statale 38 dello Stelvio - Italian Alps)
print("\n[2/5] Fetching Passo dello Stelvio (SS 38)...")
stelvio_ways = fetch_osm_bbox("10.440,46.520,10.470,46.540", lambda t: "SS38" in t.get("ref", "") or "SS38" in t.get("nat_ref", "") or "Stelvio" in t.get("name", ""))
stelvio_coords = chain_ways(stelvio_ways)
print(f"Stelvio chained coords: {len(stelvio_coords)}")
lat0 = stelvio_coords[0][0]
lon0 = stelvio_coords[0][1]
stelvio_pts = [latlon_to_xy(c[0], c[1], lat0, lon0) for c in stelvio_coords]
stelvio_loop = create_scenic_road_loop(stelvio_pts, offset_dist=34.0, turnaround_radius=28.0)
stelvio_smooth = resample_and_smooth(stelvio_loop, target_spacing=7.5)
save_csv("PassoDelloStelvio.csv", stelvio_smooth, "Passo dello Stelvio (Strada Statale 38 dello Stelvio)", "OpenStreetMap Ways SS38 Stilfser Joch, Italian Alps")

# 3. Tail of the Dragon (US Highway 129 Deals Gap - Great Smoky Mountains)
print("\n[3/5] Fetching Tail of the Dragon (US 129 Deals Gap)...")
us129_coords = fetch_osm_way(19413099)
print(f"US 129 surveyed coords: {len(us129_coords)}")
lat0 = us129_coords[0][0]
lon0 = us129_coords[0][1]
us129_pts = [latlon_to_xy(c[0], c[1], lat0, lon0) for c in us129_coords]
# Tail of the dragon is 14km long with 318 curves! Use the most scenic 4.5km mountain gap segment
segment_len = min(len(us129_pts), 550)
us129_pts_seg = us129_pts[:segment_len]
us129_loop = create_scenic_road_loop(us129_pts_seg, offset_dist=36.0, turnaround_radius=30.0)
us129_smooth = resample_and_smooth(us129_loop, target_spacing=8.0)
save_csv("TailOfTheDragon.csv", us129_smooth, "Tail of the Dragon (US Highway 129 Deals Gap)", "OpenStreetMap Way 19413099 Calderwood Highway, Great Smoky Mountains")

# 4. Transfăgărășan (Drumul Național 7C - Carpathian Mountains, Romania)
print("\n[4/5] Fetching Transfăgărășan (DN 7C)...")
dn7c_ways = fetch_osm_bbox("24.600,45.580,24.640,45.620", lambda t: "DN7C" in t.get("ref", "") or "Transfăgărășan" in t.get("name", ""))
dn7c_coords = chain_ways(dn7c_ways)
print(f"DN7C chained coords: {len(dn7c_coords)}")
lat0 = dn7c_coords[0][0]
lon0 = dn7c_coords[0][1]
dn7c_pts = [latlon_to_xy(c[0], c[1], lat0, lon0) for c in dn7c_coords]
dn7c_loop = create_scenic_road_loop(dn7c_pts, offset_dist=35.0, turnaround_radius=28.0)
dn7c_smooth = resample_and_smooth(dn7c_loop, target_spacing=8.0)
save_csv("Transfagarasan.csv", dn7c_smooth, "Transfăgărășan (Drumul Național 7C)", "OpenStreetMap Ways DN7C Bâlea Lac, Făgăraș Mountains")

# 5. German Autobahn A95 (Bavarian Alpine Expressway)
print("\n[5/5] Fetching Autobahn A95 (Bavarian Alpine Expressway)...")
a95_ways = fetch_osm_bbox("11.370,47.900,11.415,47.940", lambda t: "A 95" in t.get("ref", "") or "A95" in t.get("ref", ""))
a95_coords = chain_ways(a95_ways)
print(f"A95 chained coords: {len(a95_coords)}")
lat0 = a95_coords[0][0]
lon0 = a95_coords[0][1]
a95_pts = [latlon_to_xy(c[0], c[1], lat0, lon0) for c in a95_coords]
a95_loop = create_scenic_road_loop(a95_pts, offset_dist=45.0, turnaround_radius=38.0)
a95_smooth = resample_and_smooth(a95_loop, target_spacing=9.0)
save_csv("AutobahnA95.csv", a95_smooth, "Bundesautobahn A95 (Bavarian Alpine Expressway)", "OpenStreetMap Ways A 95 Starnberg / Loisachtal, Germany")

print("\n=== ALL REAL-WORLD OPEN ROAD CSVs SUCCESSFULLY BUILT AND SAVED! ===")
