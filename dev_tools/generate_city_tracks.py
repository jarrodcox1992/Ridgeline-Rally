#!/usr/bin/env python3
"""
Generates 5 brand new city street track layouts for Ridgeline Rally:
1. CityDowntownLoop.csv - Central Financial District & Skyscraper Canyons
2. CityNeonStrip.csv - Neon Entertainment Boulevard & High-Speed Strip
3. CityWaterfront.csv - Waterfront Bay Parkway & Marina Promenade
4. CityMidtownGrid.csv - Midtown Commercial Grid & Avenue Drift Circuit
5. CitySkylineExpressway.csv - Skyline Expressway & Elevated Downtown Ring
"""

import math
import os

TRACKS_DIR = "/Users/j/Documents/Ridgeline Rally/tracks"
os.makedirs(TRACKS_DIR, exist_ok=True)

def resample_and_smooth(pts, spacing=6.0, passes=3):
    """Resample polyline at equidistant intervals and apply Gaussian smoothing."""
    n = len(pts)
    # Resample
    resampled = [pts[0]]
    for i in range(1, n + 1):
        p0 = resampled[-1]
        p1 = pts[i % n]
        d = math.hypot(p1[0] - p0[0], p1[1] - p0[1])
        if d >= spacing:
            steps = max(1, int(d / spacing))
            for s in range(1, steps + 1):
                t = s / steps
                resampled.append((p0[0] + (p1[0] - p0[0]) * t, p0[1] + (p1[1] - p0[1]) * t))
    
    # Smooth
    curr = resampled
    for _ in range(passes):
        smoothed = []
        m = len(curr)
        for i in range(m):
            p_prev = curr[(i - 1 + m) % m]
            p_curr = curr[i]
            p_next = curr[(i + 1) % m]
            sx = 0.25 * p_prev[0] + 0.5 * p_curr[0] + 0.25 * p_next[0]
            sy = 0.25 * p_prev[1] + 0.5 * p_curr[1] + 0.25 * p_next[1]
            smoothed.append((sx, sy))
        curr = smoothed
    return curr

def save_city_csv(filename, pts, track_name, desc):
    min_x = min(p[0] for p in pts)
    max_x = max(p[0] for p in pts)
    min_y = min(p[1] for p in pts)
    max_y = max(p[1] for p in pts)
    cx = (min_x + max_x) * 0.5
    cy = (min_y + max_y) * 0.5
    
    path = os.path.join(TRACKS_DIR, filename)
    with open(path, "w") as f:
        f.write(f"# Ridgeline Rally - Brand New City Track\n")
        f.write(f"# Track: {track_name}\n")
        f.write(f"# Description: {desc}\n")
        f.write(f"# Total Waypoints: {len(pts)}\n")
        f.write(f"# x_m,y_m,w_tr_right_m,w_tr_left_m\n")
        for p in pts:
            x = p[0] - cx
            y = p[1] - cy
            # 11.5m half width = 23m 4-lane city boulevard
            f.write(f"{x:.4f},{y:.4f},11.500,11.500\n")
    print(f"✓ Saved {filename} ({len(pts)} points, span: {max_x-min_x:.1f}m x {max_y-min_y:.1f}m)")

print("=== GENERATING BRAND NEW CITY STREET TRACKS ===")

# 1. Metropolis Downtown Loop: Grand Financial Boulevard, Central Plaza, Skyscraper Canyons
control_downtown = [
    (0.0, -320.0), (140.0, -320.0), (280.0, -290.0), (360.0, -210.0),
    (380.0, -80.0), (340.0, 60.0), (390.0, 180.0), (340.0, 290.0),
    (200.0, 340.0), (50.0, 340.0), (-80.0, 280.0), (-160.0, 310.0),
    (-290.0, 270.0), (-360.0, 160.0), (-380.0, 20.0), (-320.0, -110.0),
    (-360.0, -220.0), (-260.0, -310.0), (-120.0, -320.0)
]
pts_downtown = resample_and_smooth(control_downtown, spacing=6.0)
save_city_csv("CityDowntownLoop.csv", pts_downtown, "Metropolis Downtown Loop (Financial District)", "Sweeping boulevard loop between 160m glass skyscrapers and Grand Financial Plaza")

# 2. Neon Strip & Entertainment Boulevard: High-speed straights, sweeping neon chicane
control_neon = [
    (-340.0, -260.0), (-100.0, -280.0), (150.0, -280.0), (330.0, -260.0),
    (390.0, -160.0), (360.0, -40.0), (260.0, 40.0), (340.0, 140.0),
    (360.0, 260.0), (180.0, 310.0), (-40.0, 310.0), (-220.0, 270.0),
    (-340.0, 180.0), (-310.0, 60.0), (-380.0, -40.0), (-390.0, -160.0)
]
pts_neon = resample_and_smooth(control_neon, spacing=6.0)
save_city_csv("CityNeonStrip.csv", pts_neon, "Neon City Strip (Entertainment District)", "Vibrant neon-drenched avenue with massive glowing digital billboards and high-speed drags")

# 3. Waterfront Bay Boulevard: Coastal metropolis avenue curving past marina and harbor
control_waterfront = [
    (-360.0, -280.0), (-120.0, -300.0), (120.0, -300.0), (310.0, -270.0),
    (390.0, -140.0), (410.0, 20.0), (360.0, 170.0), (240.0, 290.0),
    (90.0, 330.0), (-90.0, 330.0), (-250.0, 270.0), (-360.0, 150.0),
    (-410.0, 0.0), (-380.0, -150.0)
]
pts_waterfront = resample_and_smooth(control_waterfront, spacing=6.0)
save_city_csv("CityWaterfront.csv", pts_waterfront, "Waterfront Bay Promenade (Marina District)", "Scenic seaside avenue with palm-lined sidewalks, marina views, and modern bayfront towers")

# 4. Midtown Commercial Grid: 90-degree avenue drifts and urban square sweeps
control_midtown = [
    (-280.0, -280.0), (0.0, -280.0), (280.0, -280.0), (280.0, -90.0),
    (140.0, -90.0), (140.0, 70.0), (280.0, 70.0), (280.0, 280.0),
    (70.0, 280.0), (70.0, 150.0), (-110.0, 150.0), (-110.0, 280.0),
    (-280.0, 280.0), (-280.0, 90.0), (-160.0, 90.0), (-160.0, -90.0),
    (-280.0, -90.0)
]
pts_midtown = resample_and_smooth(control_midtown, spacing=6.0, passes=4)
save_city_csv("CityMidtownGrid.csv", pts_midtown, "Midtown Commercial Grid (Avenue Circuit)", "Technical urban street circuit with 90-degree intersection drifts and skyscraper canyons")

# 5. Skyline Ring Expressway: Fast elevated ring road surrounding downtown
control_expressway = [
    (0.0, -360.0), (200.0, -350.0), (350.0, -240.0), (410.0, -80.0),
    (380.0, 110.0), (290.0, 250.0), (120.0, 360.0), (-80.0, 370.0),
    (-260.0, 300.0), (-380.0, 160.0), (-420.0, -20.0), (-370.0, -200.0),
    (-220.0, -330.0)
]
pts_expressway = resample_and_smooth(control_expressway, spacing=6.0)
save_city_csv("CitySkylineExpressway.csv", pts_expressway, "Skyline Ring Expressway (Metropolis Ring)", "High-speed multi-lane urban ring highway with panoramic views of the entire glowing skyline")

print("=== ALL 5 CITY TRACKS GENERATED SUCCESSFULLY! ===")
