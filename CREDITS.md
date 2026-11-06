# Credits

## Car model

"Car Concept" by Eric Chadwick, Darmstadt Graphics Group GmbH (2024), based on a public-domain model by Unity Fan. It comes from the [Khronos glTF Sample Assets](https://github.com/KhronosGroup/glTF-Sample-Assets/tree/main/Models/CarConcept).

Licensed under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/). See `models/car_concept_LICENSE.md`.

That license excludes the Khronos and 3D Commerce logos in the model. The game hides or removes them when it loads the car: the license plate, the steering-wheel emblem, the logos on the tire sidewalls, and the logo texture on small hardware parts.

Other changes made in `car.gd` at load time:
- Replaced the glass, because Godot does not support glTF transmission.
- Restored the paint's clearcoat and the tiling of the paint-flake detail map, which Godot's importer drops.
- Moved the ambient-shadow map onto the model's second UV set.

## Lamborghini Centenario (Player Car)

"Lamborghini Centenario LP-770 Interior SDC" by SDC PERFORMANCE™️ (https://sketchfab.com/3Duae), from [Sketchfab](https://sketchfab.com/3d-models/lamborghini-centenario-lp-770-interior-sdc-d679af35b5694301a185c7454a700c73).
Licensed under [CC BY 4.0](http://creativecommons.org/licenses/by/4.0/).

## Your car

The player's car body was generated from your own image (`supercar_burnout_twilight`, made in Antigravity) with [Hunyuan3D-2.1](https://huggingface.co/spaces/tencent/Hunyuan3D-2.1) by Tencent, then cleaned up in `models/your_car`: the ground and smoke under it were cut away, the fused-in wheels removed, and it was scaled to real size. It rides on the Car Concept's wheels. Paint, glass and lights are added by a shader in `car.gd`. Hunyuan3D outputs are covered by the Tencent Hunyuan 3D 2.1 Community License, which excludes use in the EU, UK and South Korea.

The image shows a Lamborghini-style car, so keep that in mind before sharing or selling the game publicly; the model carries no badges, but the design is recognisable.

## Sky

"Kloofendal 48d Partly Cloudy (Pure Sky)" HDRI by Greg Zaal, with sky edits by Jarod Guest. From [Poly Haven](https://polyhaven.com/a/kloofendal_48d_partly_cloudy_puresky), CC0 (public domain).

Sunset: "Belfast Sunset (Pure Sky)" HDRI from [Poly Haven](https://polyhaven.com/a/belfast_sunset_puresky), CC0 (public domain).

Night: "Qwantani Night (Pure Sky)" HDRI by Greg Zaal from [Poly Haven](https://polyhaven.com/a/qwantani_night_puresky), CC0 (public domain).

## Ground and road textures

All from [Poly Haven](https://polyhaven.com/textures), CC0 (public domain):
- "Aerial Grass Rock" by Rob Tuytel, tinted greener in the terrain shader
- "Rock Face 03" by Dario Barresi and Rico Cilliers
- "Snow 02" by Rob Tuytel
- "Asphalt Track" by Dimitrios Savva

## Trees

"Fir Tree 01" by Poly Haven ([source](https://polyhaven.com/a/fir_tree_01)), CC0 (public domain). The original is 7.8 million polygons, so the game uses it as an "impostor". It was pre-rendered from 8 angles into `textures/trees/`, and each tree in the game is a flat card that faces the camera and shows the matching view.

## Rocks

"Rock Moss Set 01" and "Boulder 01" from [Poly Haven](https://polyhaven.com/models), CC0 (public domain).

## Audio & Sound Effects

- **Engine Loops (Multi-RPM Crossfading):** "Racing car engine sound loops" by domasx2, from [OpenGameArt](https://opengameart.org/content/racing-car-engine-sound-loops), CC0 (public domain). Features 6 distinct loops (`engine_loop_0.wav` through `engine_loop_5.wav`) seamlessly crossfaded across 900 to 7,200+ RPM.
- **Tire Screech:** "Car tire squeal skid loop" by audible-edge and qubodup, from [OpenGameArt](https://opengameart.org/content/car-tire-squeal-skid-loop), licensed under [CC-BY 3.0](https://creativecommons.org/licenses/by/3.0/). Studio-recorded 96 kHz tire squeal on road asphalt.
- **Tire Scrub, Gear Whine, Overrun Decel, Limiter Cut, Shifts, BOV & Backfires:** Extracted from the open-source vehicle audio library [bungee-engine-audio](https://github.com/LeonManiora/bungee-engine-audio) by Leon Maniora, licensed under the [MIT License](https://github.com/LeonManiora/bungee-engine-audio/blob/main/addons/bungee/LICENSE.txt):
  - `tire_scrub.wav`: Asphalt grain friction scrub sound
  - `gear_whine.wav`: Straight-cut dog-gear transmission whine
  - `engine_decel.wav`: Off-throttle overrun engine braking rumble
  - `engine_limiter.wav`: Hard rev limiter bounce ignition cut
  - `gear_shift_up.wav` & `gear_shift_down.wav`: Sequential dog-box mechanical shifter clunk
  - `turbo_bov.wav` & `turbo_whistle.wav`: Blow-off valve compressor flutter and spool whistle
  - `backfire_1.wav` through `backfire_9.wav`: 9 distinct recorded exhaust backfires and pop variations
- **Metal Impact & Collision Sounds:** "Metal Impact Sounds" by Brian MacIntosh (BMacZero), from [OpenGameArt](https://opengameart.org/content/metal-impact-sounds), CC0 (public domain). Includes heavy chassis crashes (`impact_heavy.wav`), guardrail thuds (`impact_thud.wav`), and debris clinks (`impact_clink.wav`).

## Open-Source Real-World Public Roads & Highways

All primary road routes in Ridgeline Rally are surveyed authentic public roads and highways sourced directly from **[OpenStreetMap (OSM)](https://www.openstreetmap.org/)**:
- **Dataset License:** Open Data Commons Open Database License (ODbL 1.0) by © [OpenStreetMap contributors](https://www.openstreetmap.org/copyright).
- **Cartographic Data Processing:** Extracted via OpenStreetMap Overpass & REST API (`api.openstreetmap.org`) using `dev_tools/build_all_osm_tracks.py`.
- **Included Real-World Public Open Roads:**
  1. **California State Route 1 (Pacific Coast Highway - Big Sur) [OpenStreetMap]:**
     - Sourced from OSM Relations & Ways for `CA 1` / Cabrillo Highway across the world-famous concrete arch **Bixby Creek Bridge** (OSM Way 120270844) and **Rocky Creek Bridge** (OSM Way 120271130) along the Monterey ocean cliffs.
     - Features coastal clifftop sweeps, ocean views, double yellow centerlines, white shoulder fog lines, and scenic overlook turnouts.
  2. **Passo dello Stelvio (Strada Statale 38 dello Stelvio - Italian Alps) [OpenStreetMap]:**
     - Sourced from OSM Ways for `SS 38` / Strada Statale 38 dello Stelvio (Ways 73261783, 172951992, 184815465).
     - Captures the legendary 48 alpine switchbacks (tornanti) climbing to Italy's highest paved pass summit at 2,757 m (9,045 ft), equipped with stone parapets, curve warning chevrons, and summit signs.
  3. **Tail of the Dragon (US Highway 129 Deals Gap - Great Smoky Mountains) [OpenStreetMap]:**
     - Sourced from OSM Way 19413099 (1,351 surveyed nodes across 14.07 km of Calderwood Highway).
     - Captures the world's most famous winding mountain road with 318 continuous banked curves in 11 miles through the lush Appalachian mountain forest gorge along Cheoah River.
  4. **Transfăgărășan (Drumul Național 7C - Carpathian Mountains, Romania) [OpenStreetMap]:**
     - Sourced from OSM Ways for `DN 7C` (Ways 4833220, 284417548, 284417546, 37339527).
     - Serpentine high-altitude Carpathian highway ascending past the glacial valley bowl to Lake Bâlea and Bâlea Tunnel.
  5. **Bundesautobahn A95 (Bavarian Alpine Expressway) [OpenStreetMap]:**
     - Sourced from OSM Ways for German federal motorway `A 95` (Starnberg / Loisachtal).
     - 4-lane wide-radius expressway with unrestricted speed sweepers, overhead direction gantries, emergency breakdown shoulders, and the Bavarian Alps backdrop.

## Everything else

The terrain shape, track, grass, rear wing, carbon-fibre texture, exhaust flames, smoke, tire squeal, backfire crackle and wind noise are generated by the game's own code.

## Realistic city people

The crowd and sidewalk walkers are **Ready Player Me** avatars (claudia, eric, nathan and carla) from [Ready Player Me](https://readyplayer.me), using a walking animation retargeted across their shared 89-bone rig. Ready Player Me avatars and animations are provided under the [Ready Player Me avatar license](https://readyplayer.me/legal/terms).

- `models/city_hd/` holds the original avatars.
- `models/people_src/` holds decimated versions made with [glTF-Transform](https://gltf-transform.dev) (meshoptimizer simplification), used for crowd and walker performance.
- `models/people/` holds static walking-pose meshes baked from those avatars for the instanced ambient crowd (see `dev_tools/bake_people.gd`, which must run with a window so the renderer registers the skeletons).

All four people share the standard Ready Player Me skeleton, so one walk cycle drives every one of them.
