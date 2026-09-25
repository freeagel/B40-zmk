#!/usr/bin/env bash
set -euo pipefail
repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
task_root="$HOME/b40-local"
source "$task_root/venv/bin/activate"
export ZEPHYR_TOOLCHAIN_VARIANT=zephyr
export ZEPHYR_SDK_INSTALL_DIR="$task_root/zephyr-sdk-0.16.9"
cd "$task_root/workspace"
variant="${1:-debug}"
case "$variant" in
    debug) extra=(-S studio-rpc-usb-uart -S zmk-usb-logging); settings=(-DCONFIG_ZMK_LOG_LEVEL_DBG=y) ;;
    normal) extra=(-S studio-rpc-usb-uart); settings=() ;;
    *) printf 'Usage: bash build-local-zmk.sh [debug|normal]\n' >&2; exit 2 ;;
esac
west build -p always -s zmk/app -d "build/b40-$variant" -b b40 "${extra[@]}" -- "-DZMK_CONFIG=$repo_root/zmk-config/config" "-DZMK_EXTRA_MODULES=$repo_root/zmk-config" "${settings[@]}"
mkdir -p "$repo_root/local-firmware"
cp "build/b40-$variant/zephyr/zmk.uf2" "$repo_root/local-firmware/b40-$variant.uf2"
printf 'Firmware: %s/local-firmware/b40-%s.uf2\n' "$repo_root" "$variant"
