# Godot Unity Ads Plugin (Android)

A Unity Ads bridge + demo for Godot 4.2+. Loads and shows interstitial and
rewarded ads from GDScript. All IDs live in Project Settings — nothing is
hardcoded.

```
plugin/                       Android library module (Kotlin) → produces the AAR
  GodotUnityAds/src/main/java/com/godot/unityads/GodotUnityAds.kt
demo/                         Godot 4.x demo project
  addons/unityads/
    plugin.cfg                editor plugin
    export_plugin.gd          adds the AAR + Unity Ads Maven dependency to the export
    unity_ads.gd              autoload bridge (signals)
    GodotUnityAds.release.aar (copied here after building)
  main.gd / main.tscn         demo UI
```

## Requirements
- JDK 17, Android SDK (platform-34), Godot 4.2+ (Android export + build template installed).

## Quick test (no dashboard project)
The demo ships pre-filled with Unity's sample test Game ID (`14851`) and the
default placements (`video` / `rewardedVideo`) — just build the AAR (step 1),
export to Android, then **Initialize → Load → Show**.

> Heads-up: on the public test Game ID only the **rewarded** placement
> (`rewardedVideo`) reliably fills. The interstitial placement (`video`) often
> returns "Placement not found" — that's a limit of the shared test ID, not the
> plugin. Both work once you plug in your own Game ID below.

## Real project (required before publishing)
> This is *not* "publishing an app" — it's creating a **free project** on the
> Unity dashboard (~2 min, no store listing). You need your own Game ID to ship
> and earn revenue.

Create a project on the dashboard → get your **Android Game ID** and **turn on
test mode**. Then under `Project Settings → Unity Ads` replace `android/game_id`
with your own ID, and set the placements to the names from your dashboard
(usually `Interstitial_Android`, `Rewarded_Android`).

## 1) Build the AAR
```sh
cd plugin
./gradlew :GodotUnityAds:assembleRelease
cp GodotUnityAds/build/outputs/aar/GodotUnityAds-release.aar \
   ../demo/addons/unityads/GodotUnityAds.release.aar
```
> Match the Godot version to your editor in the `org.godotengine:godot:<version>`
> line of `plugin/GodotUnityAds/build.gradle.kts`.

## 2) Godot side
1. **Project → Project Settings → Plugins** → enable **Godot Unity Ads**.
   (Settings are added automatically; if they don't show, reopen the project once.)
2. Fill in under **Project Settings → General → Unity Ads**:
   - `Android/Game Id` → your Android Game ID from the dashboard
   - `Test Mode` → on (while developing)
   - `Auto Initialize` → on (init automatically on launch)
   - `Placements/Interstitial` and `Placements/Rewarded` → the dashboard names
3. **Project → Install Android Build Template** (if not installed).
4. Enable **Use Gradle Build** in the Android export preset.

> No ID is written in code; everything comes from Project Settings. Whoever uses
> the plugin just fills in these fields.

## 3) Run
Export / install to a device. In order: **Initialize → Load → Show**. For
rewarded, when the ad completes you'll see `🎁 REWARD GRANTED` in the status box.

## API (autoload `UnityAds`)
| Method | |
|---|---|
| `initialize()` | start with the Game ID + test_mode from Project Settings |
| `load_interstitial()` / `show_interstitial()` | configured interstitial placement |
| `load_rewarded()` / `show_rewarded()` | configured rewarded placement |
| `load_banner(position := "bottom_center")` | load the banner; position is `<top\|center\|bottom>_<left\|center\|right>` |
| `show_banner()` / `hide_banner()` / `destroy_banner()` | toggle / remove the banner |
| `load_ad(id)` / `show_ad(id)` | low-level: explicit placement ID |
| `game_id()` / `is_available()` | helper queries |

Signals: `initialized`, `init_failed(e,m)`, `ad_loaded(p)`,
`ad_load_failed(p,e,m)`, `ad_completed(p,state)`, `ad_show_failed(p,e,m)`,
`banner_loaded(p)`, `banner_load_failed(p,e,m)`,
**`rewarded(p)`** (emitted when a rewarded placement reaches `COMPLETED` — hook
your reward here).

Simplest usage: `UnityAds.show_interstitial()` and
`UnityAds.rewarded.connect(...)`.

## Ad types
Interstitial, rewarded, and banner — the full Unity Ads SDK surface. (Unity Ads
has no rewarded-interstitial or consent/UMP form; those are AdMob concepts.)

## Not yet (added when needed)
iOS bridge, LevelPlay/mediation.
