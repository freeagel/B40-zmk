#!/usr/bin/env bash
set -euo pipefail
sudo apt-get update
sudo apt-get install -y git cmake ninja-build gperf ccache dfu-util device-tree-compiler wget curl xz-utils file make gcc g++ python3-dev python3-venv python3-pip libsdl2-dev libmagic1
task_root="$HOME/b40-local"
mkdir -p "$task_root"
python3 -m venv "$task_root/venv"
source "$task_root/venv/bin/activate"
pip install 'west==1.5.0' 'setuptools<81'
if [ ! -d "$task_root/workspace/.west" ]; then
    west init -m https://github.com/zmkfirmware/zmk --mr v0.3 --mf app/west.yml "$task_root/workspace"
fi
cd "$task_root/workspace"
west update
west zephyr-export
pip install -r zephyr/scripts/requirements.txt
sdk="$task_root/zephyr-sdk-0.16.9"
if [ ! -d "$sdk" ]; then
    curl -fL --retry 3 -o "$task_root/sdk.tar.xz" https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v0.16.9/zephyr-sdk-0.16.9_linux-x86_64_minimal.tar.xz
    tar -xf "$task_root/sdk.tar.xz" -C "$task_root"
fi
cd "$sdk"
./setup.sh -t arm-zephyr-eabi -h -c
printf 'ZMK local tools installed in %s\n' "$task_root"
