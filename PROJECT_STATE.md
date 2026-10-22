# Spider Territory: project handoff

Updated: 2026-10-22. This file records the current source state for an agent continuing work in this repository. `README.md` contains older gameplay descriptions and should be checked against the code before use.

## Project and entry points

- Godot 4.7.2 project in this directory. Local engine: `C:\Users\Supreme Traders\Downloads\Godot_Engine\Godot_v4.7.2-stable_win64.exe`.
- Android export package name: `com.spidergame.rival` (`export_presets.cfg`).
- `project.godot` starts `scenes/splash.tscn`, then the main menu. Autoloads are `SignalHub`, `GameManager`, `AppSettings`, `AdsManager`, and `BillingManager`.
- Main gameplay scene: `scenes/first_hunt.tscn`; main gameplay logic: `scripts/web_trap.gd`. Menu, store, settings, and result UI live in `scripts/ui/`.
- The splash shows blue and red spiders and a gold bug. The main menu offers Bugs Mode, Rival Mode, Store, and Settings.

## Current gameplay

- Bugs Mode has **no rival** (`rival_count_for_level()` returns 0). The player catches flying bugs on a web. Movement through a bug should eat it without another tap; tapping the web creates web paths. Web cuts and repairs, bug escape, and powers are implemented in `scripts/web_trap.gd`.
- Bugs Mode and Rival Mode now use the same player spider speed at the same level: 175 on level 1, 185 on levels 2–5, and 225 thereafter, before the selected style modifier or a speed power. This replaces the former Bugs Mode base speed of 420. The speed power remains a 1.7× multiplier.
- Bugs Mode's starting countdown now decreases with level: `10 + 95 / (1 + 0.05 * (level - 1))` seconds, approaching but never dropping below 10 seconds (105 seconds at level 1). Catching a bug restores up to 6 seconds, allowing fast play to extend later rounds. The old timer increased with arena scale.
- Rival Mode has 1 rival on levels 1–2, 2 on 3–4, 3 on 5–6, and 4 from level 7 onward. The web and arena grow as levels progress. Bugs Mode starts at the same arena zoom as Rival Mode. Spider health bars are hidden; bug counts above spiders remain.
- Both modes advance one level after every win, including past level 1000. Their next unlocked levels are saved separately as `levels/bugs_next` and `levels/rival_next` in `user://spider_wars_progress.cfg`. Selecting a mode from the menu resumes its next unlocked level. Replay stays on the current level; a loss does not advance progress. Web size, bug count, and rival count still have gameplay caps even though the level number continues increasing.
- Bugs eaten increase the bug count, with no coin award. Eating a rival awards 1 coin. Winning a level awards 5 coins. A rewarded coin ad awards 5 coins.
- Each power starts with 2 charges. When depleted, a rewarded ad icon offers 2 more charges. Store power purchases cost 5 coins for 1 charge, saved as stock and applied at the next level start. Keys: `cut`, `weave`, `boost`, `stun`, `timer`, `cloak` (`scripts/game_manager.gd`).
- Result screens use `level_complete.mp3` and `level_fail.mp3`; coin and star animations use `coin_sound.wav` and `star_sound.mp3`. Sound respects `AppSettings.sfx_enabled`.
- The store (`scripts/ui/ShopScreen.gd`) displays powers, Watch Ad +5 coins, and a 100 coin Google Play purchase. Spider styles are no longer shown in the store. Settings contains Remove Ads.

## Ads and billing

- Godot managers: `scripts/ads_manager.gd` and `scripts/billing_manager.gd`. Android plugins: `android/build/src/main/java/com/godot/game/ads/SpiderAdsPlugin.java` and `android/build/src/main/java/com/godot/game/billing/SpiderBillingPlugin.java`.
- `config/admob_test.cfg` contains this app's AdMob app ID `ca-app-pub-1852108665659812~9400432505`, banner ID `ca-app-pub-1852108665659812/5261876941`, interstitial ID `ca-app-pub-1852108665659812/8087350834`, and rewarded ID `ca-app-pub-1852108665659812/6487987840`. The Android manifest uses the same app ID. Intended placement: banner on menus/results, interstitial after level win/fail, rewarded for coins or depleted powers. The Android ad plugin queues requests until `MobileAds.initialize` finishes. The result screen waits after its reveal, then polls briefly for a loaded interstitial. Configure the connected device as an AdMob test device while testing these real units.
- Google Play product IDs: `remove_ads` and `coins1`. The `coins1` one time purchase grants 100 coins; its $2 price must be configured in Play Console. The `remove_ads` fallback label is $4.99. Real product prices and purchase flow require Android/Play verification.
- **Open issue:** The user reports no ads on the connected device. Desktop ad previews and passing Godot tests do not establish that the Android plugin loads ads. The Android plugin has not been built and installed from the latest source in the recent session. An existing APK in the root may be old.

## Verification and environment blocker

- Run a headless test from the project root, for example:

  ```powershell
  & 'C:\Users\Supreme Traders\Downloads\Godot_Engine\Godot_v4.7.2-stable_win64.exe' --headless --path . --script res://tests/test_menu_flow.gd
  ```

- Recent passing tests include `test_menu_flow.gd`, `test_splash_screen.gd`, `test_first_hunt.gd`, `test_bugs_mode.gd`, `test_bugs_mode_levels.gd`, `test_rival_levels.gd`, `test_result_buttons.gd`, `test_ads_manager.gd`, and `test_ads_preview.gd`. Godot may emit sandbox related `user://logs`, certificate, or ObjectDB exit warnings despite a PASS marker.
- After the progression change, `test_bugs_mode_levels.gd`, `test_rival_levels.gd`, `test_menu_flow.gd`, and `test_result_buttons.gd` passed in headless Godot. The level tests now check advancement through level 1001 and resuming from the menu. The sandbox did not permit checking the on-disk `user://` save across game restarts.
- After the speed change, `test_bugs_mode.gd`, `test_bugs_mode_levels.gd`, and `test_rival_levels.gd` passed in headless Godot.
- After the timer change, `test_bugs_mode.gd` and `test_bugs_mode_levels.gd` passed in headless Godot. The latter checks decreasing starting time with a 10-second minimum; the former checks time restored by catches.
- The recent Android Gradle attempt from `android/build` using `.\gradlew.bat compileStandardDebugJavaWithJavac --offline` failed with **SDK location not found**. `C:\AndroidSdk` exists but the previous sandbox could not access its contents. `adb` was unavailable in PATH. No fresh APK was installed and no device logcat was captured. Check SDK and ADB access in the new environment, then compile/export/install and inspect AdMob load errors on device.
- Google Play billing and real ad delivery remain unverified on device. Do not report them as working solely from source inspection or desktop previews.

## Suggested next task

Resolve the Android SDK/ADB access problem, build the current project with its Android plugins, install that build on the connected device, and inspect logs while opening the menu, completing/failing a level, and requesting a rewarded ad. Use the logged ad error or missing plugin signal to fix the reported no ads issue. Verify `coins1` and `remove_ads` only with configured Play Console test products/accounts.
