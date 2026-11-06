# Ridgeline Rally — improvement list

Ordered by how much each one adds to realism or fun, given what a 2019 MacBook Pro can run.

| # | Improvement | Why | Status |
|---|---|---|---|
| 1 | Realistic sky and lighting from an HDRI photo | Lighting and reflections on the car paint matter more for realism than anything else | Done |
| 2 | Photo-scanned ground and road textures (grass, rock, snow, asphalt) | Replaces the flat colors, which read as "game-like" | Done |
| 3 | Realistic trees | The cone trees no longer match the car | Done |
| 4 | Grass clumps and rocks along the roadside | Close-up detail sells speed and realism | Done |
| 5 | Road details: dashed center line, red-and-white curbs, guardrails | Makes it read as a real road and race circuit | Done |
| 6 | Skid marks and tire smoke | Feedback when braking hard and drifting | Done |
| 7 | Animated steering wheel, working headlight beams, and Night Mode | Makes driving at night and the cockpit view feel alive | Done (Night mode with starry sky, shadow-casting headlights, and illuminated track) |
| 8 | Better engine sound | The synthesized buzz is the weakest part of the game | Done |
| 9 | Pause menu with graphics quality settings | Lets the game run well on slower and faster machines | Done (Medium is the default: 60 fps on this Mac; High is about 43) |
| 10 | AI opponent cars | Something to race against | Done: 3 opponents, 3-lap race with countdown, positions and results |

Free assets come from CC0 (public domain) sources such as Poly Haven unless noted, and get credited in CREDITS.md.

## Tuning pass

Measured on a flat test surface before and after:

| | Before | After |
|---|---|---|
| 0–100 km/h | 19.4 s | 6.1 s |
| Top speed | 107 km/h | 252 km/h |
| 100–0 km/h braking | 102 m | 37 m |
| Cornering grip | 1.54 g | 1.33 g |
| Handbrake turn at 80 km/h | full spin, down to 15 km/h | 47° drift, keeps 32 km/h |
| Lane change at 140 km/h | spin | 3° slip, stable |

Also added: speed-sensitive steering, AI difficulty (Easy / Normal / Hard) with physics-based AI cornering, four camera views plus look-back with camera collision, shader warm-up for the tire effects, and an FPS counter (F).

## Sunset look

Inspired by a photo of a black supercar doing a burnout at sunset (no real car's design or badges are copied):
- Sunset sky (Poly Haven "Belfast Sunset") with a time-of-day option, plus per-time fog, exposure and colour grading.
- Player car in gloss black with black rims, a carbon-fibre rear wing, brighter taillights and a red glow behind.
- Exhaust tips with backfire flames and crackle when lifting off at high revs or upshifting.
- Thicker, wispier tire smoke and burnouts (hold handbrake and full throttle while stopped).
- Photo mode (V) with an orbit camera, depth of field and screenshots saved to Pictures, plus a subtle vignette.

## Car realism pass

- Soft contact shadow under every car (a decal on the ground only), so cars sit on the road.
- Fresnel glass: see-through face on, mirror-like at shallow angles; opponents have tinted glass.
- Matte dark-grey rubber tires.
- Wheel blur: a faint ring overlay fades in from 35 km/h, like spinning rims on camera.
- Opponents' cockpits are drawn within 25 m, so you don't see an empty car alongside.
- Screen-space reflections (paint reflects road, cars and trees) on High quality only; on this Mac they cost about 20 fps.
- No other realistic car models are freely licensed, so all cars share the Car Concept model in different colours.

## Polish pass

Found by driving the race through scripted runs, then fixed:

- Cutting across the infield, or a reset, no longer earns distance: a car is only credited with progress it could have driven since the last frame.
- Finishing needs three laps confirmed by the checkpoints, not distance alone, so a cut course can't end the race. Missing a checkpoint now says so on the HUD.
- The lap timer stops when you finish and the HUD switches to your race time, instead of counting up behind "Finished P3".
- Photo mode silences the engine like the pause menu does, resets its hint after a save, and reports a failed screenshot.

## Immersion & Polish Pass

- **Collision Sparks & Metal Scrape**: Real-time particle sparks and dynamic metal grind audio when scraping guardrails or colliding with opponents.
- **Curb Rumble & Camera Shaking**: High-frequency physical thumping sound and camera vibration when clipping red-and-white corner rumble strips at speed.
- **Turbo Spool & Blow-Off Valve (BOV)**: Procedural high-pitch turbo compressor whistle spooling under heavy throttle above 2600 rpm, paired with signature compressor flutter ("stututu") upon sudden throttle lift-off.
- **Dynamic Speed FOV**: Camera dynamically widens field of view as speed increases to sell the sensation of speed.
- **F1-Style Shift Light Bar**: 9-LED cluster positioned directly above the digital speedometer (3 green, 3 amber, 2 red, 1 blue) that fills sequentially as RPM builds and flashes the full bar at 6850+ RPM redline.
- **Night Mode with Starry Sky & Dynamic Headlights**: CC0 Qwantani night sky with moon illumination, deep blue fog, and real shadow-casting dual headlights on the player car with automatic night activation for AI opponents.
- **Refined Custom Car Mesh**: Elliptical wheel cutout pass restoring 840+ triangles along the front fender arch for smooth, seamless bodywork.

## City & Environment Upgrades & Dynamic Road Mechanics

- **CityGroundMesh (3,800m with 2K PBR Materials)**: Expanded 3.8 km x 3.8 km foundational city plaza with 2K photo-scanned tarred gravel diffuse, normal, and roughness textures.
- **5 Selectable Tracks**:
  - `Neo-Veridia // Sector-9`: Flagship cyberpunk corporate core and alternate network
  - `Veridia Sky-Expressway`: Multi-level viaducts and highway ramps
  - `Cyber-Harbor`: Quayside terminal straightaways and port flyovers
  - `Synapse Midtown`: High-density urban grid with 90° chicanes
  - `Sector-9 Autobahn A-95`: 1.76 km span high-velocity perimeter circuit
- **3 Drivable Overpass & Alternate Routing Branches**:
  - **▲ Sky-Expressway Overpass**: Elevated double-decker highway viaduct rising to $y = 16.2\text{m}$ across the urban canyon with concrete Jersey crash barriers, dual glowing cyan LED strips, and viaduct piers.
  - **► Hyper-Straight Bypass**: Chord-straightened outer velocity straightaway with amber neon portal gantries.
  - **◄ Neon Tunnel Split-Route**: Covered brutalist tunnel gallery with magenta neon light ribs spaced every $8.5\text{m}$.
- **Color-Coded Multi-Route Minimap & Lap Checkpoints**:
  - Custom HUD minimap rendering cyan (overpass), amber (bypass), and magenta (tunnel) alternate routes with legend badges.
  - Expanded lap checkpoint bounding boxes ($163\text{m} \times 52\text{m}$) for seamless lap counting on ground avenues, elevated overpasses, and outer bypasses.
- **Dynamic Road Mechanics (RoadRepairController)**:
  - Ported from Unity C# to Godot 4.7 GDScript (`road_repair_controller.gd`).
  - `Area3D` triggers with non-blocking async coroutines (`await get_tree().create_timer()`) and `GPUParticles3D` repair steam/sparks.
  - Modifies `VehicleWheel3D` traction ($0.60\times$ damaged to $1.00\times$ fixed) and dynamically syncs with `car.road_traction_multiplier`.
  - In-game dispatch via `K` key / gamepad `X`.



## One unified map with a city street grid

- There is now a single map (`Neo-Veridia`). The T-key track cycling and the pause-menu Track selector are gone.
- A 14-street grid of flat asphalt roads with collision is laid across the map, buildings on those roads are cleared, and the ring circuit remains the race course. Cars can cross the kerb to roam the grid.
- Crash destruction: hitting traffic shreds the car into physics debris with fire, smoke and a flash; hitting people bursts them into red particles, chunks and a ground splat.
- 36 HD taxis and kei trucks cruise the grid lines (two-way lanes, wrapping at the map edge), facing their direction of travel.

## Track 4 redesign

- Track 4 now uses a smooth, flat, procedural loop (no alternate routes or guardrails) instead of the surveyed Alpine autobahn data. It completes a lap in the automated drive test at ~150 km/h and is playable.

## Known issues

- Track 0 can occasionally leave the car wedged against a sidewalk prop. The game now shows a "Stuck? Press R to reset" hint after 3 seconds stopped off the road; the drive test resets the car automatically and continues.

## Interactive personalities

- **Rival drivers have personalities:** Blaze (aggressive, defends the line, boosts to retake a place), Pearl (technical, clean and gives room), Red (wildcard, late braking and wobble). Each taunts the player when overtaken.
- **Pedestrians react by personality:** timid jump clear early, curious lean out to watch, oblivious barely notice, friendly stop and wave. All react to the player's horn.
- **Traffic has attitudes:** polite drivers ease aside, aggressive ones speed up and honk, tourists drift slowly, couriers weave. Traffic honks back at the player's horn.
- **Player horn** on G / gamepad B.

## Thriving city crowd

- The crowd is now built from four realistic Ready Player Me people baked into walking-pose meshes (1,700 verts each after decimation) and instanced with `MultiMeshInstance3D`, placed in personality-based clusters along the sidewalks and plazas: timid back from the road, curious at the kerb, oblivious on the pavement, friendly in the plazas.
- `CROWD_SCALE` env var scales the population for profiling.

## Life-like animated characters

- Added 160 skeletal-animated Ready Player Me men and women (downloaded and decimated with glTF-Transform; credited in CREDITS.md). One walk cycle from nathan is retargeted across all four avatars by bone index, so they stride the sidewalks facing their direction of travel. Their animations are started/kept running from the update loop so they never freeze after world build.

