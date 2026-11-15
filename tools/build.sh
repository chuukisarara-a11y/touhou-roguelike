#!/bin/bash
# 打包脚本。用法: tools/build.sh [Android|Windows|macOS]
# Android 签名通过环境变量传入，钥匙文件不进仓库：
#   KEYSTORE=/path/release.keystore KEY_USER=xxx KEY_PASS=xxx tools/build.sh Android
set -e
cd "$(dirname "$0")/.."
GODOT=${GODOT:-/home/claude/tools/godot}
TARGET=${1:-Android}
mkdir -p build
export GODOT_ANDROID_KEYSTORE_RELEASE_PATH=${KEYSTORE:-/home/claude/tools/release.keystore}
export GODOT_ANDROID_KEYSTORE_RELEASE_USER=${KEY_USER:-touhourogue}
export GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD=${KEY_PASS:-touhou2026}
"$GODOT" --headless --path . --import >/dev/null 2>&1 || true
"$GODOT" --headless --path . --export-release "$TARGET" 2>&1 | grep -E "ERROR|WARNING|export: end|Signed" || true
ls -la build/
