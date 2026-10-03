# Blender creature assets

## Files

- `source/pigoid.blend`, `source/sterq.blend`: editable Blender 4.5.3 sources, with packed UV textures, mesh parts, weighted armatures and animation actions. The source folder has `.gdignore` so Godot imports the GLB rather than invoking Blender on every project scan.
- `models/pigoid.glb`, `models/sterq.glb`: game-ready exported meshes, skins and animation clips.
- `textures/*_skin_albedo.png`: 1024px baked procedural skin-color maps, not manually painted textures.
- `concepts/`: approved art direction and generated turnaround references.

The bodies and limbs are lofted, voxel-fused, smoothed and reduced into continuous meshes inside Blender. Separate attached meshes provide split feet, feelers, proboscis folds, eyes, dorsal plates, membrane rays and skin creases. This is a first production pass made through Blender scripting, not a claim of hand sculpting or pixel-identical reproduction of the concept. Remaining differences include simplified facial anatomy, skin folds, membrane contours and the concept's hand-painted linework.

## Rigs and clips

Pigoid: six limbs, four central dorsal plates, 20 bones; `Idle`, `Walk`, `Feed`.
Sterq: four limbs, paired neck membranes, three tail bones, 19 bones; `Idle`, `Walk`, `Alert`.

Godot's `scripts/organism.gd` loads these models, applies `creature_ink.gdshader`, blends clips based on movement/behavior, and scales walk playback with movement speed. The old sphere/cylinder creature visuals have been replaced. Both creatures add runtime foot planting and analytic leg IK as described below.

## Rebuild and verify

From the project root:

```sh
/Applications/Blender.app/Contents/MacOS/Blender --background --factory-startup --python tools/blender/build_creatures.py
/path/to/godot --headless --editor --import --path .
/path/to/godot --headless --path . --script res://tests/creature_test.gd
/path/to/godot --headless --path . --script res://tests/smoke_test.gd
```

`tools/preview_creatures.gd` makes a neutral Godot asset preview. `tools/preview_creatures_in_world.gd` captures idle, walk and interaction poses using the real game materials and environment; it stages the creatures for review without changing the saved population or gameplay.

## Pigoid movement stability

Grazers now keep a food target until depleted, require 12 energy when choosing a replacement, and stop feeding at 1 energy. Fleeing enters at 12 m and exits at 16 m to prevent threshold oscillation. Acceleration is limited, 30 Hz simulation transforms are interpolated for rendering, turns use delta-based smoothing, and gait playback speed is eased. Walk/idle uses separate start/stop speed thresholds.

`tests/pigoid_motion_test.gd` simulates a deterministic minute and checks decision reversals, behavior transitions, render interpolation, and low-speed gait stability. `tools/preview_pigoid_motion.gd` follows a real simulated Pigoid for video review.

## Pigoid planted tripod gait

`scripts/pigoid_gait.gd` runs after manual AnimationPlayer evaluation, with configurable stride and limb count reused by Sterq. Front-left / middle-right / rear-left alternate with the opposite tripod. A distance-driven 0.66 m cycle uses 62% stance, a smooth 10.5 cm swing arc, raycast landing heights and fixed world-space ankle/orientation anchors during stance. Two-bone IK keeps the feet grounded while the body shifts subtly. Stopping finishes pending swings and leaves all six feet planted. Antenna tips get a small phase-delayed bend in the creature shader.

This refinement is applied by Godot at runtime; the Blender source retains the editable base clips. `tests/pigoid_gait_test.gd` measures actual skeletal ankle positions for straight movement, turning, speed changes and stopping. `tools/preview_pigoid_gait.gd` rehearses acceleration, side-on walking and a stop in the real environment.

## Sterq planted crawl and display

`scripts/sterq_gait.gd` reuses the planted-leg solver with four staggered footfalls, a 0.32 m distance-driven cycle, 81% stance and a 5.5 cm swing arc. At least three feet support the body during the crawl; all four settle on stopping. Three tail segments follow heading changes with progressively delayed response. Hunting or fleeing opens the paired neck membranes in about 0.72 seconds; relaxing folds them back over about 2.22 seconds.

These refinements run in Godot after the base clips; they are not baked into the Blender actions. `tests/sterq_gait_test.gd` checks planted ankle positions, turning, changing speeds, stopping, tail delay and settling, and membrane transitions. `tools/preview_sterq_gait.gd` stages walking, turning, alert and relaxation; the rendered review video is `models/sterq_gait.mp4`.

## Ground contact effects

Both runtime gait controllers emit one contact when a foot finishes its swing. `scripts/ground_contacts.gd` reuses a fixed pool of 96 overlays. `ground_contact.gdshader` shares `basin_field.gdshaderinc` with the terrain: shallow-water landings create small fading rings, while exposed ground receives a split-toe dark imprint that fades over seven seconds. Raised surfaces use the landing height to avoid water rings on the modeled banks. These are visual overlays, not fluid simulation or deformable mud. Overlays are excluded from the planar-reflection pass.

`tests/ground_contacts_test.gd` verifies both species emit landings, settled feet stop emitting, and effects expire without growing the pool. `tools/preview_ground_contacts.gd` stages both species for a real-time render review.

## Pigoid feeding readability

The original Feed clip moved the head by only about four degrees. The runtime gait now blends from a raised resting head into a larger, repeating feeding probe, then returns to rest on leaving FEEDING. All six feet remain planted. A feeding-pad reference point is clamped above raycast terrain to prevent the stronger nod from driving the mouth into the ground. This refinement is runtime-only, not baked into the exported GLB. `tests/pigoid_feeding_test.gd` checks visible repeated head movement, planted support and return to idle; `tools/preview_pigoid_feeding.gd` records the transition.

## Sterq feeding

Sterq now layers a visible feeding dip and recovery over its idle clip in Godot. A 1.6-second cycle leaves a pause after each dip, and the head turns up to 23 degrees toward its feeding target. Frills settle at partial opening while feeding. Four planted feet and the existing tail follow remain active. `tests/sterq_feeding_test.gd` checks head movement, support and recovery; `tools/preview_sterq_feeding.gd` stages the motion. No new GLB clip or Blender action is added.

## Live-world behavior audit

`tests/behavior_audit.gd` advances a deterministic minute in the actual basin after physics registration and measures displacement (not requested velocity). Spawn positions are settled outside obstacle and creature clearance volumes. Local avoidance can turn sideways or back when blocked, treats world edges as walls, and holds a detour for 0.85 seconds to avoid repeatedly turning back into the same obstacle. Collision sweeps and endpoint overlap checks remain active throughout. This is local avoidance, not global pathfinding; the audit guards against prolonged stalls in the default world, not every possible enclosure.
