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
| 7 | Animated steering wheel and working headlight beams | Makes the cockpit view feel alive | Done (headlights matter most at night; a night mode would be a good follow-up) |
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
