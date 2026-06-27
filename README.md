# Godot Unity Ads (Android)

Unity Ads in a Godot 4 game, without the boilerplate. You get interstitial, rewarded
and banner ads from plain GDScript, and every ID lives in Project Settings instead of
being buried in code. There's a small demo project so you can poke at it before dropping
it into your own game.

Android only for now — no iOS bridge yet.

## What's in the repo

```
plugin/      The Android side, in Kotlin. Build it into an .aar.
demo/        A Godot 4 project that uses the plugin.
  addons/unityads/
    unity_ads.gd       The autoload you call: UnityAds.show_rewarded(), etc.
    export_plugin.gd   Pulls in the .aar + Unity SDK when you export
    GodotUnityAds.release.aar
  main.gd              The demo screen
```

## Before you start

- Godot 4.2+ with the Android build template installed.
- A Unity Ads **Game ID** (see below). Without one, ads won't fill.
- JDK 17 + Android SDK (platform-34) — only if you want to rebuild the `.aar` yourself.

## Quick tutorial

**1. Build the Android library** *(skip this — a prebuilt `.aar` already ships in the repo.
Only needed if you edit the Kotlin.)*

```sh
cd plugin
./gradlew :GodotUnityAds:assembleRelease
cp GodotUnityAds/build/outputs/aar/GodotUnityAds-release.aar \
   ../demo/addons/unityads/GodotUnityAds.release.aar
```
If you're not on Godot 4.3, change the `org.godotengine:godot:<version>` line in
`plugin/GodotUnityAds/build.gradle.kts` to match your editor.

**2. Enable the plugin.** Project → Project Settings → Plugins → turn on **Godot Unity Ads**.
This adds a new **Unity Ads** group under Project Settings → General. (If you don't see it,
reopen the project once.)

**3. Fill in your settings** under Project Settings → General → Unity Ads:

| Setting | What to put |
| --- | --- |
| Android / Game Id | your Android Game ID from the dashboard |
| Test Mode | on, while you're developing |
| Auto Initialize | on — starts the SDK on launch |
| Placements | your dashboard's ad unit names |

A fresh Unity project hands you `Interstitial_Android`, `Rewarded_Android` and
`Banner_Android` out of the box, which is exactly what the placement fields default to —
so most of the time you don't touch them.

**4. Export to Android.** Project → Install Android Build Template (once), tick
**Use Gradle Build** in the Android export preset, then export to your device.

**5. Call it from your game.** Everything goes through the `UnityAds` autoload:

```gdscript
# Rewarded — grant the reward when the "rewarded" signal fires
UnityAds.rewarded.connect(func(_placement): give_coins(50))
UnityAds.load_rewarded()
UnityAds.show_rewarded()

# Interstitial
UnityAds.load_interstitial()
UnityAds.show_interstitial()

# Banner — position is "<top|center|bottom>_<left|center|right>"
UnityAds.load_banner("bottom_center")
UnityAds.show_banner()
```

In the editor or on desktop there's no Unity SDK, so these calls quietly do nothing.
That means you can leave them in your game code without wrapping every one in a platform
check.

## Getting a Game ID

Ads only fill with a real Game ID, and getting one is free — this is *not* the same as
publishing an app to a store.

1. Open the Unity dashboard, create a project, and enable Ads / monetization on it.
2. Copy the **Android Game ID** (a short number) and switch on test mode.
3. Drop that number into **Android / Game Id**, and make sure the three placement fields
   match your dashboard's ad unit names.

New projects already include `Interstitial_Android`, `Rewarded_Android` and
`Banner_Android`, so usually there's nothing to change there.

### A note on the bundled test ID

The demo ships with Unity's old public sample Game ID (`14851`) so you can see *something*
without an account. Fair warning: it's a shared, unofficial ID, and in practice only the
**rewarded** ad reliably fills on it. Interstitial and banner usually come back with
"Placement not found" or no fill — that's the test ID being flaky, not the plugin. Plug in
your own Game ID for anything real.

## API reference

| Call | Does |
| --- | --- |
| `initialize()` | start the SDK (automatic on launch unless you turn Auto Initialize off) |
| `load_interstitial()` / `show_interstitial()` | interstitial |
| `load_rewarded()` / `show_rewarded()` | rewarded |
| `load_banner(pos)` / `show_banner()` / `hide_banner()` / `destroy_banner()` | banner |
| `load_ad(id)` / `show_ad(id)` | low-level — pass a placement ID directly |
| `is_available()` / `game_id()` | quick checks |

Signals: `initialized`, `init_failed`, `ad_loaded`, `ad_load_failed`, `ad_completed`,
`ad_show_failed`, `banner_loaded`, `banner_load_failed`, and `rewarded` — which fires the
moment a rewarded ad finishes, so that's where you hand out the reward.

## Still on the list

iOS support and mediation (LevelPlay) aren't here yet — they'll land when I need them.

## Support

If this saved you some time, you can [buy me a coffee](https://buymeacoffee.com/carbon06). ☕
