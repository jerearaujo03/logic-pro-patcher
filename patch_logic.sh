#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# Logic Pro ARM64 BNNS Compatibility Patcher for macOS 27+
# Root Cause: Missing _BNNSGraphContextGetContextSize and _BNNSGraphContextInitialize
# ==============================================================================

SRC_APP="${1:-/Applications/Logic Pro X.app}"
DST_APP="${2:-/Applications/Logic Pro X Patched.app}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SHIM_SRC="$SCRIPT_DIR/bnns_shim.c"
SHIM_DYLIB="$SCRIPT_DIR/libBNNSFix.dylib"

echo "=== Logic Pro macOS 27 BNNS Patcher ==="
echo "Source App:      $SRC_APP"
echo "Destination App: $DST_APP"

if [ ! -d "$SRC_APP" ]; then
    echo "[-] Error: Source application not found at '$SRC_APP'" >&2
    exit 1
fi

# 1. Compile Shim Library (Universal arm64 + x86_64)
echo "[+] Compiling Universal BNNS shim library..."
clang -dynamiclib -arch arm64 -arch x86_64 \
    -install_name "@loader_path/libBNNSFix.dylib" \
    -reexport_framework Accelerate \
    -O3 \
    -o "$SHIM_DYLIB" "$SHIM_SRC"

# 2. Clone application bundle (instantaneous via APFS copy-on-write)
if [ -d "$DST_APP" ]; then
    echo "[!] Target '$DST_APP' already exists. Recreating copy..."
    rm -rf "$DST_APP"
fi

echo "[+] Creating APFS clone of '$SRC_APP' to '$DST_APP'..."
cp -cR "$SRC_APP" "$DST_APP"

# 3. Inject shim dylib into MAMachineLearning.framework
FRAMEWORK_DIR="$DST_APP/Contents/Frameworks/MAMachineLearning.framework/Versions/A"
TARGET_BIN="$FRAMEWORK_DIR/MAMachineLearning"

if [ ! -f "$TARGET_BIN" ]; then
    echo "[-] Error: MAMachineLearning binary not found in target bundle!" >&2
    exit 1
fi

echo "[+] Installing libBNNSFix.dylib into MAMachineLearning.framework..."
cp "$SHIM_DYLIB" "$FRAMEWORK_DIR/libBNNSFix.dylib"

# 4. Retarget Accelerate link dependency in MAMachineLearning
echo "[+] Modifying LC_LOAD_DYLIB in MAMachineLearning..."
install_name_tool -change \
    "/System/Library/Frameworks/Accelerate.framework/Versions/A/Accelerate" \
    "@loader_path/libBNNSFix.dylib" \
    "$TARGET_BIN"

# 5. Remove quarantine flags & ad-hoc code sign inside-out
echo "[+] Clearing extended quarantine attributes..."
xattr -cr "$DST_APP"

echo "[+] Signing libBNNSFix.dylib..."
codesign --force --sign - "$FRAMEWORK_DIR/libBNNSFix.dylib"

echo "[+] Signing frameworks inside-out..."
find "$DST_APP/Contents/Frameworks" -depth -name "*.framework" -exec codesign --force --sign - {} + 2>/dev/null || true

if [ -d "$DST_APP/Contents/XPCServices" ]; then
    echo "[+] Signing XPCServices..."
    find "$DST_APP/Contents/XPCServices" -depth -name "*.xpc" -exec codesign --force --sign - {} + 2>/dev/null || true
fi

if [ -d "$DST_APP/Contents/PlugIns" ]; then
    echo "[+] Signing PlugIns..."
    find "$DST_APP/Contents/PlugIns" -depth -name "*.bundle" -exec codesign --force --sign - {} + 2>/dev/null || true
fi

echo "[+] Signing main executable..."
codesign --force --sign - "$DST_APP/Contents/MacOS/Logic Pro X"

echo "[+] Signing app bundle..."
codesign --force --sign - "$DST_APP"

echo ""
echo "=== PATCH COMPLETED SUCCESSFULLY! ==="
echo "The patched application is ready at:"
echo "  $DST_APP"
echo ""
echo "To test run via terminal:"
echo "  \"$DST_APP/Contents/MacOS/Logic Pro X\""
echo "Or launch directly from Finder / Applications."
