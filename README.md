# Ridgeline Rally

A driving game made in Godot 4 (tested on 4.7.2). Race three AI opponents over 3 laps of a mountain circuit in a rear-wheel-drive sports car, starting from the back of the grid, and chase your best lap time.

The car is a realistic 3D model, the CC BY 4.0 "Car Concept" from Khronos, and the player's body is generated from your own image; see [CREDITS.md](CREDITS.md). The landscape, track, grass, exhaust flames and other effects are built in code, and the textures, skies and sounds are CC0 assets, also credited there.

## Play

Open Godot, click **Import**, choose this folder's `project.godot`, then press **F5**.

| Action | Keyboard | Gamepad |
|---|---|---|
| Accelerate | W / Up | Right trigger |
| Brake / reverse | S / Down | Left trigger |
| Steer | A / D, Left / Right | Left stick |
| Handbrake (drift) | Space | A |
| Reset car to road | R | Y |
| Repair road (dispatch crew) | K | X |
| Next track (cycle circuits) | T | |
| Switch camera (chase / far chase / bumper / cockpit) | C | Back |
| Horn (pedestrians react, traffic honks back) | G | B |
| Look back | B (hold) | Left shoulder |
| Headlights | H | D-pad up |
| Show frame rate | F | |
| Photo mode (orbit with mouse drag or arrows, zoom with wheel or + -, Space saves to Pictures) | V | Right shoulder |
| Burnout | Hold Space and full throttle while stopped | |
| Pause menu (restart, AI difficulty, time of day, graphics quality, fullscreen, quit) | Esc or P | Start |

## Personalities

Every rival and every person on the street has their own character.

- **Rival drivers:** Blaze (aggressive — defends hard and fights back when overtaken), Pearl (technician — clean lines and gives you room), Red (wildcard — brakes late and taunts you).
- **Pedestrians:** timid (jumps clear early), curious (leans out to watch), oblivious (keeps walking), friendly (stops to wave you through).
- **Traffic:** polite (eases over to let you past), aggressive (speeds up and honks), tourist (slow drifters), courier (weaving scooters).
- **Animated characters:** 120 skeletal-animated walkers and service droids (CC0 robot, CC BY walker) stride the sidewalks, idle, and wave as you pass.
- **The crowd:** about 5,000 extra people fill the sidewalks and plazas, gathered in small groups — queues at bus stops, friends in plazas, onlookers at the kerb. Each group has a personality that decides where they stand and how they sway.
- Press **G** / gamepad **B** to sound the horn: nearby pedestrians react by personality and traffic honks back.

## Files

- `main.gd` builds the world: road mesh, multi-level elevated viaducts, alternate bypass routes, checkpoints, lighting, camera, HUD, and 5 selectable circuits in `TRACK_DATA`.
- `car.gd` handles car physics tuning, controls, and dynamic traction scaling via `road_traction_multiplier`.
- `road_repair_controller.gd` dynamic road repair system with `Area3D` triggers, non-blocking async coroutines, `VehicleWheel3D` traction modifiers, and particle effects.
- `city_builder.gd` constructs the multi-layer 3D metropolis, 3,800m `CityGroundMesh` with 2K PBR materials, street furniture, monorail, and skyline towers.
- `living_city_controller.gd` controls dynamic urban ambient lighting, neon signage pulses, and audio.
- `models/` holds the car model and its license.
- `ai_driver.gd` drives the opponents: follows the track, brakes for corners ahead, and overtakes.
- `tire_effects.gd` handles skid marks and tire smoke.
- `exhaust.gd` builds the exhaust tips and their backfire flames, and triggers the crackle.
- `pause_menu.gd` is the pause menu with track selector, AI difficulty, time of day and graphics settings.
- `minimap.gd` draws the color-coded multi-route minimap with overpass (cyan), bypass (amber), and tunnel (magenta) indicators.
- `city_visual_verification.md` detailed visual verification gallery with 10 rendered screenshot captures.
- `ROADMAP.md` lists the improvements made so far.
