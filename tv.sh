#!/usr/bin/env bash
# Helper for setting up Aurora on an Android TV over ADB (Wi-Fi). Run from your PC/laptop.
#
#   ./tv.sh pair <tv-ip:pairing-port> <pairing-code>   (Android 11+ wireless debugging)
#   ./tv.sh connect <tv-ip:port>
#   ./tv.sh info                  Android version, model, current Home app
#   ./tv.sh audit                 write audit-system.txt / audit-user.txt (installed packages)
#   ./tv.sh debloat               remove packages listed in packages-to-remove.txt (DRY=1 to preview)
#   ./tv.sh restore               bring the listed packages back
#   ./tv.sh install <apk>         install/update the launcher APK
#   ./tv.sh set-home              ask Android to use Aurora as the Home app
#   ./tv.sh disable <package>     advanced: disable a stock launcher so Home opens Aurora
#   ./tv.sh enable <package>      undo `disable`

set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
LIST="$HERE/packages-to-remove.txt"
ACT="com.riturajpatna.tvlauncher/.MainActivity"

command -v adb >/dev/null 2>&1 || {
  echo "adb not found. Install Android platform-tools and make sure 'adb' is on your PATH."
  exit 1
}

# Print the package names from the list file (comments and blank lines stripped).
listed_packages() {
  while IFS= read -r line || [ -n "$line" ]; do
    p="${line%%#*}"
    p="$(printf '%s' "$p" | tr -d '[:space:]')"
    [ -n "$p" ] && printf '%s\n' "$p"
  done < "$LIST"
}

case "${1:-help}" in
  pair)
    adb pair "${2:?usage: tv.sh pair <ip:pairing-port> <code>}" "${3:?usage: tv.sh pair <ip:pairing-port> <code>}"
    ;;

  connect)
    adb connect "${2:?usage: tv.sh connect <ip:port>}"
    adb devices
    ;;

  info)
    echo "Brand/model : $(adb shell getprop ro.product.brand | tr -d '\r') $(adb shell getprop ro.product.model | tr -d '\r')"
    echo "Android     : $(adb shell getprop ro.build.version.release | tr -d '\r') (SDK $(adb shell getprop ro.build.version.sdk | tr -d '\r'))"
    echo "Current Home app:"
    adb shell cmd package resolve-activity --brief -a android.intent.action.MAIN -c android.intent.category.HOME | tr -d '\r'
    echo "All Home candidates:"
    adb shell cmd package query-activities --brief -a android.intent.action.MAIN -c android.intent.category.HOME 2>/dev/null | tr -d '\r'
    ;;

  audit)
    adb shell pm list packages -s | tr -d '\r' | sed 's/^package://' | sort > "$HERE/audit-system.txt"
    adb shell pm list packages -3 | tr -d '\r' | sed 's/^package://' | sort > "$HERE/audit-user.txt"
    echo "Wrote $HERE/audit-system.txt ($(wc -l < "$HERE/audit-system.txt") packages)"
    echo "Wrote $HERE/audit-user.txt ($(wc -l < "$HERE/audit-user.txt") packages)"
    ;;

  debloat)
    INSTALLED="$(adb shell pm list packages --user 0 | tr -d '\r')"
    count=0
    for p in $(listed_packages); do
      if grep -qx "package:$p" <<<"$INSTALLED"; then
        if [ "${DRY:-0}" = "1" ]; then
          echo "[dry-run] would remove $p"
        else
          echo "Removing $p"
          adb shell pm uninstall -k --user 0 "$p"
        fi
        count=$((count + 1))
      else
        echo "Skipping $p (not installed)"
      fi
    done
    echo "Done. $count package(s) matched."
    ;;

  restore)
    for p in $(listed_packages); do
      echo "Restoring $p"
      adb shell pm install-existing --user 0 "$p"
    done
    ;;

  install)
    adb install -r "${2:?usage: tv.sh install <path-to.apk>}"
    ;;

  set-home)
    adb shell cmd package set-home-activity --user 0 "$ACT"
    echo "If Home still opens the old launcher, see README -> 'Making Aurora the Home app'."
    ;;

  disable)
    adb shell pm disable-user --user 0 "${2:?usage: tv.sh disable <package>}"
    ;;

  enable)
    adb shell pm enable "${2:?usage: tv.sh enable <package>}"
    ;;

  *)
    sed -n '2,15p' "$0"
    ;;
esac
