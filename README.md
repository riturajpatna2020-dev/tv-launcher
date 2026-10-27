# Aurora – a clean, dynamic Android TV launcher

An Apple TV–style home screen for Android TV / Google TV, built with Kotlin and Jetpack Compose for TV.

**What it does**

- Large hero area that follows focus: big artwork and app name for whatever tile is selected.
- Animated backdrop: the gradient changes with the time of day, and a soft glow in the focused app's colour drifts across the screen.
- Favourites row (with a built-in Settings tile) and an "All apps" row. No ads, no sponsored rows, no content feeds, just your apps.
- Hold **OK** on any app for options: add/remove favourites, hide, app info, uninstall. Hidden apps can be brought back from the "Show hidden apps" tile.
- Updates automatically when apps are installed or removed. Home and Back jump to the first tile.
- First run pins YouTube, Netflix, Prime Video, Hotstar and the Play Store if they are installed.

## Get the APK (no Android Studio needed)

1. Push this repo to GitHub (it already contains the workflow in `.github/workflows/build.yml`).
2. Open the repo's **Actions** tab, run **Build APK** (it also runs on every push to `main`).
3. When it finishes, download the **aurora-launcher-apk** artifact and unzip it to get `app-release.apk`.

To build locally instead: install JDK 17 and the Android SDK (platform 34), then run `gradle :app:assembleRelease` (Gradle 8.7), or open the folder in Android Studio.

The release APK is signed with the debug key so it installs directly. That is fine for a personal TV, not for the Play Store.

## Install on the TV over Wi-Fi

On the TV: **Settings → Device Preferences → About → tap "Build" 7 times** to enable Developer options, then turn on **USB debugging / Wireless debugging** (the name varies by version). TV and PC must be on the same Wi-Fi.

```bash
cd scripts
./tv.sh pair 192.168.1.50:37123 123456   # Android 11+ only: use the pairing IP:port and code shown on the TV
./tv.sh connect 192.168.1.50:5555        # use the IP:port shown on the TV's debugging screen
./tv.sh info                             # Android version, model, current Home app
./tv.sh install ../app-release.apk
```

On Windows use `tv.bat` with the same arguments. If `adb` is not installed, get Android platform-tools first.

## Making Aurora the Home app

Try these in order:

1. Press the Home button on the remote. If Android asks which launcher to use, choose **Aurora → Always**.
2. `./tv.sh set-home`
3. Last resort: disable the stock launcher with `./tv.sh disable <package>` (find its package name in the "Current Home app" line from `./tv.sh info`). Undo with `./tv.sh enable <package>`. Do this only after Aurora is installed and opens fine. Some vendor firmwares re-enable their launcher or restrict this.

If anything goes wrong you can always open Aurora from the TV's app list (it registers as a normal TV app too), and a factory reset restores the stock launcher.

## Removing bloatware

```bash
./tv.sh audit          # writes scripts/audit-system.txt and audit-user.txt
```

Review `audit-system.txt`, then uncomment the packages you want gone in `scripts/packages-to-remove.txt`.

```bash
DRY=1 ./tv.sh debloat  # preview
./tv.sh debloat        # remove for the current user (pm uninstall -k --user 0)
./tv.sh restore        # bring the listed packages back
```

This does not touch the system partition and is reversible. The list is empty by default because bloatware differs per TV model and firmware.

## Customising

- Tile size: `TileWidth` / `TileHeight` in `Tiles.kt`.
- Default favourites: `DEFAULT_PINS` in `LauncherScreen.kt`.
- Backdrop colours and motion: `Backdrop.kt` (remove the drift animation if the TV feels sluggish).
- App name and icon: `strings.xml` and `res/drawable/`.
