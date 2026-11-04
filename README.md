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
| Next track (cycle circuits) | T | |
| Switch camera (chase / far chase / bumper / cockpit) | C | Back |
| Look back | B (hold) | Left shoulder |
| Headlights | H | D-pad up |
| Show frame rate | F | |
| Photo mode (orbit with mouse drag or arrows, zoom with wheel or + -, Space saves to Pictures) | V | Right shoulder |
| Burnout | Hold Space and full throttle while stopped | |
| Pause menu (restart, AI difficulty, time of day, graphics quality, fullscreen, quit) | Esc or P | Start |

## Files

- `main.gd` builds the world: terrain, road, trees, lighting, checkpoints, lap timing, camera and HUD. Multi-track layouts (Alpine Pass, Mount Akina Touge, Coastal Super-Speedway, Forest Grand Prix) with real 3D elevation and verticality are configured in `TRACK_DATA`.
- `car.gd` handles car physics tuning and controls. It also loads the 3D model, attaches its wheels to the physics wheels, fixes materials, pitches the engine loop, and synthesizes the tire, wind and backfire sounds.
- `models/` holds the car model and its license.
- `ai_driver.gd` drives the opponents: follows the track, brakes for corners ahead, and overtakes.
- `tire_effects.gd` handles skid marks and tire smoke.
- `exhaust.gd` builds the exhaust tips and their backfire flames, and triggers the crackle.
- `pause_menu.gd` is the pause menu with AI difficulty, time of day and graphics settings, saved to `user://settings.cfg`.
- `minimap.gd` draws the top-down track map with every car on it.
- `ROADMAP.md` lists the improvements made so far.
