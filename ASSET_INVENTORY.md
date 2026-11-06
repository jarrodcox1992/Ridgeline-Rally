# Neo-Veridia — World & Asset Inventory

Everything currently in the game, grouped by category. Counts marked "exact" come from the build log; others are from the spawn loops.

## Player & rivals

| What | Model | Count |
|---|---|---|
| Player car | Khronos Car Concept (CC BY 4.0); optional Centenario body; custom body baked from your photo | 1 |
| Rival cars | Car Concept bodies, paint + persona | 3 (Blaze, Pearl, Red) |

## Vehicles

### Ring-road traffic (exact: 46 moving)

| Vehicle | Model | Count |
|---|---|---|
| City buses | HD Isuzu Erga Mio | 6 |
| Taxis | HD 2001 Toyota Crown Comfort | 8 of 24 ring sedans |
| Sleek sedans | procedural, 6 paint colours | 16 of 24 ring sedans |
| White box trucks | HD Suzuki kei truck + cargo box/reefer | 10 |
| Courier scooters | HD old scooter | 4 |
| Police cruisers (patrol) | HD cop cruiser | 2 |
| Police cruiser (staged) | HD cop cruiser | 1 |
| Fire truck | HD fire truck | 1 |
| Ambulance | HD ambulance | 1 |

### City-grid traffic (exact: 36)

| Vehicle | Model | Count |
|---|---|---|
| Taxis | HD Toyota Crown Comfort | 18 |
| Kei trucks | HD Suzuki kei truck | 18 |

### Rail, air & harbor

| Vehicle | What | Count |
|---|---|---|
| Bullet monorail | 5-car articulated mag-lev train on the elevated guideway | 4 trains / 20 cars |
| Security drones | Hovering quad-rotor patrol drones with scanner beams | 14 |
| Cargo freighters | Moored container ships in the harbor | 5 |
| Port cranes | Yellow articulated quayside cranes over each ship | 5 |

### Parked / street vehicles

- HD bicycle (parked, every third bench bay on one side)
- HD scooter (parked at alternating bays)
- Delivery truck prop (`models/props/delivery_truck.glb`)
- Shopping cart, pallets, crates (alley/prop set dressing)

## People

| Group | Model / look | Count |
|---|---|---|
| Animated walkers | Ready Player Me: Claudia, Eric, Nathan, Carla (low-poly) | 160 (exact) |
| Ambient crowd | 4 baked realistic poses (Claudia, Eric, Nathan, Carla) | 1,200 (exact, 4 × 300) |
| Player | body generated from your image | 1 |
| Rival drivers | Car Concept cockpit occupants | 3 |
| Commuters | RPM people walking the promenades | ~155 |
| Vendors | Nathan behind vending/kiosk stalls | ~19 |
| Drifters / bus-stop waiters | Claudia waiting at shelters | ~19 |
| Skybridge commuters | RPM people crossing the 8 overpasses | 24 |
| Park socializers | Nathan + Carla pairs on pocket-park lawns | 16 |
| Terrace / balcony commuters | RPM people on second-story decks | per building |

### Pedestrian personalities (9)
Timid, curious, oblivious, friendly, hurried, tourist, shopper, performer, phone-talker — each with its own walk speed, pauses, idle routine, emote and car reaction.

## Street furniture & items

### Lighting, signs & screens
- Cast-iron street lamps (every 24 m, both sides)
- Modern promenade lamps
- Neon billboards: horizontal jumbotrons, vertical screens, corner screens, rooftop LED boards
- 20 street-photo billboards (CC0 Tokyo/New York photos)
- Traffic lights (high-detail HD + signal network at ~every 120 m)
- Bollards, stop signs, no-parking signs, route portal gantries
- Holographic arches/holograms, security lights, security cameras
- Wet neon-reflection pools, oil puddles

### Seating, shelter & greenery
- Modular street seating and park benches (every 36 m)
- Bus-stop shelters (~every 72 m, alternating sides)
- Cafe parasols, awnings, balconies, fire escapes, roller shutters
- Large leafy trees (every 24 m), planter boxes, shrubs
- Bioluminescent pocket-park lawns, blossoms, under-glow lights

### Waste, utility & construction
- Trash cans, trash bags, metal trash cans, dumpsters (closed/open)
- Utility boxes (2 types), exterior AC units, water tanks, antenna dishes
- Fire hydrants, postboxes, manhole covers, steam vents
- Jersey barriers, construction barriers, traffic cones
- Pallets, wooden crates, plastic crates, cardboard boxes, old tyres

### Street commerce & props
- Red Japanese vending machines, vending kiosks
- Parked bicycles and scooters, shopping carts
- Delivery trucks, propane tanks, pipes
- Shopfront interiors, ramen-counter texture panels

### Road markings & surfaces
- Yellow centre lines, white lane lines, tactile paving
- Zebra crosswalks (two parallel sets per intersection)
- Yellow box-junction crisscross grids
- Sidewalk pavers, granite curbs, plaza aprons, 3,800 m ground plane

### Race infrastructure
- Start/finish gantry with "START / FINISH" sign
- 10 checkpoints
- 3 route portal gantries (SKY-EXPRESSWAY OVERPASS, HYPER-STRAIGHT BYPASS, NEON TUNNEL SPLIT-ROUTE)
- Guardrails/barriers, pit/repair-road infrastructure

## Buildings & structures

### Boulevard frontage (exact: 205)
| Archetype | Height | Notes |
|---|---|---|
| Corporate highrise | 105–175 m (Sector 1), 78–135 m elsewhere | glass facades, podium, beacons, rooftop antenna dishes |
| Residential megablock | 38–68 m | lit balconies, second-story decks |
| Historic brick | 26–48 m | brick warehouse shader, fire escapes |
| Industrial logistics | 16–24 m | corrugated metal, loading bays |
| Landmark exoskeleton spires | 210 m | 2 of them (o = 133 m and 1,145 m) |
| Quayside commercial pavilion | 7.4 m | waterfront, rooftop garden, cyan LED billboard |

### Background city (exact: 853)
- Glass towers with exoskeleton corner columns, 40–185 m by distance from centre
- Rooftop details (water tanks, antennae, AC units)
- High-altitude megatower skybridges where two towers ≥ 68 m face each other

### Civil engineering
- 14-street city grid (±900 m, 14 m wide, yellow centre lines)
- 8 low pedestrian skybridges at 6.2 m with glass stair towers and neon ticker banners
- Elevated monorail guideway (24+ bents) with 4 stations and platform commuters
- Main circuit viaducts, overpass, bypass and tunnel split-route
- Waterfront: 5 quays, 5 cargo ships, 5 port cranes, 5 smokestack clusters (10 stacks), reactor domes, hyperbolic cooling towers
- 8 pocket-park lawns (4 offsets × 2 sides)
- 3,800 m city ground slab, sidewalks, plaza aprons, curbs

## Environment, effects & audio

- **Weather:** clear golden haze, neon mist, acid rain (with faster, shelter-seeking commuters)
- **Time of day:** multiple settings via the pause menu, with headlights and neon states
- **Effects:** rain particles, steam plumes, exhaust flames/backfire, debris, fire, smoke, splatter, skid marks, tire smoke, neon flicker, hologram pulse, drone scanners, emergency strobes, wet reflections
- **Audio:** multi-RPM engine loops, limiter, gear shifts/whine, turbo whistle/BOV, backfire (9 variants), tire screech/scrub, impacts (heavy/thud/clink), distant siren, urban canyon ambience, subway vent hum, mag-lev train pass, drone rotors, dual-tone horns, neon buzz
- **Textures:** 2K PBR city surfaces (paving, brick, concrete, iron, gravel, asphalt), 6 CC0 street photos, billboard art, storefront interiors, tree impostors
