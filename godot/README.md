# ELYRA AI — Godot 4 Android migration

This is an **early native 3D Godot prototype**, not a finished realistic companion.

## Open locally
1. Install Godot 4.3 or newer.
2. Import the `godot/project.godot` project.
3. Run `scenes/main.tscn`.
4. For Android export, install Android SDK, JDK 17 and Godot Android export templates. Configure an Android export preset.

## Present
- Native 3D scene and basic room (floor/wall)
- Placeholder mannequin, basic animation states and outfit color
- Czech chat with canned replies, local history and romance age-confirmation UI

## Not yet implemented
- Licensed realistic rigged 3D character and authored animation clips
- Czech speech synthesis and speech recognition in Godot (Android bridge needed)
- Real hybrid AI backend, safe server-side API keys and offline model runtime
- Reliable adult age verification
- Production security, privacy, moderation, and end-to-end Android QA

The earlier Android WebView prototype remains in `app/`; the Godot project is a **parallel migration**.
