# Browser build

The Web export preset uses the Compatibility renderer and single-threaded Godot 4.7.2 templates. Build output: `exports/web/index.html`. Uploadable archive: `exports/vesta-web.zip` (index.html is at the ZIP root). Only exported files should be uploaded, not Blender sources or the project Git directory.

Desktop controls: click the game to capture the mouse, WASD to move, Shift for slow walk, Esc to release the mouse. Mobile touch controls are not implemented. Browser audio begins after user interaction.

Serve the complete exports/web directory over HTTP for local testing or HTTPS for online hosting. Do not open index.html with file://. Keep the generated file names unchanged. The host must serve .wasm as application/wasm. Single-threaded export does not require cross-origin isolation headers. Enable gzip/Brotli on the host to reduce download size.

Export with Godot 4.7.2: `godot --headless --path . --export-release Web exports/web/index.html`. Install matching official templates first. The template archive is saved in the Mac Downloads directory.

This is a single-player browser build, not multiplayer. Saves, cloud persistence and touch input require separate implementation. The itch.io project page is https://syl-ying.itch.io/vesta-quiet-walk (project ID 5042568). The prepared ZIP is uploaded and marked playable in the browser. Restricted access is saved (unlisted; owner and authorized testers only), with payments disabled. Embed size: 960 × 540, fullscreen button enabled. Invite testers using itch.io download keys; the page URL alone does not grant access.

Verification: native scene smoke test and Web export completed. Local HTTP serving returned 200. On 2026-09-22, the prepared build loaded past its title screen into the 3D scene in the Codex embedded Chromium browser. W movement visibly changed the view, Tab opened and closed the observation journal, and Q/E input did not stop rendering. Mouse capture attempts produced Chromium `UnknownError` messages; mouse-look and audible sound remain unverified. This is a limited browser smoke check, not a complete gameplay verification. After email verification, upload succeeded and the playable browser setting was saved. The hosted itch.io build reached the title screen and 3D scene; movement changed the view and Tab displayed the observation panel. No warnings or errors were captured in the hosted check. Audio and mouse-look have not been fully verified. The narrow Codex browser panel clips the fixed-size embed; use a desktop browser window for playtesting.
