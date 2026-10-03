# Crashed orbital capsule

- `concepts/crashed_capsule_blueprint.png`: generated concept turnaround with front, left, rear, top and crash-pose views. Created with the built-in image_gen tool; full prompt is in `concepts/generation_prompt.txt`.
- `source/crashed_capsule.blend`: editable Blender scene with named parts, packed hull texture, crashed-pose parent, lights and render cameras. Open directly in Blender. The source directory has `.gdignore`.
- `models/crashed_capsule.glb`: portable Godot asset with embedded materials, the tilted capsule, silt base and loose debris. Studio floor, cameras and lights are excluded. Drag this file from Godot's FileSystem into a scene.
- `models/crashed_capsule_render.png`, `models/crashed_capsule_rear.png`: actual Blender model renders, not generated concept images.
- `textures/capsule_hull_albedo.png`: baked procedural color, bands, scratches and lower-hull scorching.

The hull is approximately 5.05 m long; including the rear engine it spans 5.59 m before crash-pose rotation. Main body width is 3.2 m; fins extend beyond it. Structural features include three inset windows, circular front hatch, open left maintenance bay, internal ribs and hanging cables, bent hatch and stabilizers, broken struts, six hollow auxiliary nozzles and one central nozzle. Render-only staging is separate from the exported asset.

This is a script-built 3D interpretation of the drawing. The drawing is a concept sheet, not certified engineering dimensions. Fine hand-drawn linework, individual dents, and weathering are simplified. The raw GLB has no interior walkable cabin, collision or LODs. The separate crash_site.tscn now provides gameplay placement and exterior collision.

Rebuild with `/Applications/Blender.app/Contents/MacOS/Blender --background --factory-startup --python tools/blender/build_crashed_capsule.py`. `tests/capsule_asset_test.gd` validates the GLB directly through Godot's GLTFDocument loader.

## Wetland placement

`assets/spacecraft/crash_site.tscn` is spawned by the main scene at (-10, 0, 16), to the left and behind the initial player view. It adds a conservative capsule hull collider, fin colliders, a shallow raised-edge drag scar and twelve trail fragments. The existing ground remains intact beneath the scar. The open maintenance bay is visual detail, not a playable entrance. Random food plants avoid the crash footprint. `tests/crash_site_test.gd` checks player-layer blocking and creature movement sweeps; `tools/preview_crash_site.gd` captures the in-game view.

## Habitable version

The live crash site now loads `models/habitat_capsule.glb`; the first smaller asset is preserved. The new editable source is `source/habitat_capsule.blend`, rebuilt by `tools/blender/build_habitat_capsule.py`.

Design dimensions (fictional game asset, not flight-qualified engineering): length including engine about 7.0 m; main hull width 4.0 m; level deck 4.5 × 2.5 m (11.25 m² before future fittings). The deck is 0.72 m above the surrounding ground, reached by a 2.8 m sloped ramp. The opening and curved cabin are tested with the game's 1.8 m tall, 0.76 m wide player capsule. The crashed exterior has 6° roll and 2° nose-down pitch; the habitable floor is level independently of the shell.

Concave shell/floor/ramp collision preserves the entrance and cabin. A separate layer-4 exterior barrier keeps creatures outside without blocking the player. HomeSocket_Bed, HomeSocket_Workbench and HomeSocket_Storage are empty attachment markers only: furniture, storage interaction, doors, repairs, saving and home-building gameplay are not implemented yet. A warm service light makes the empty cabin readable.

`tests/habitat_entry_test.gd` walks a player-sized CharacterBody3D into the cabin, across the floor, and out again. Exterior and interior screenshots are captured by `tools/preview_habitat.gd` and `tools/preview_habitat_interior.gd`.
