#!/usr/bin/env bash
# Swap sapphire-blue layout.kdl between dark/light variants.
# No-op for any other niri preset (default / material-you / user).
set -uo pipefail

NIRI_DIR="${HOME}/.config/niri"
PRESET_FILE="${HOME}/.config/NyxNiri/presets/niri.active"
DARK_KDL="${NIRI_DIR}/layout-dark.kdl"
LIGHT_KDL="${NIRI_DIR}/layout-light.kdl"
DEST_KDL="${NIRI_DIR}/layout.kdl"

preset="default"
if [ -f "$PRESET_FILE" ]; then
    preset=$(tr -d '[:space:]' < "$PRESET_FILE" 2>/dev/null || echo "default")
fi
if [ "$preset" != "sapphire-blue" ]; then
    exit 0
fi
if [ ! -f "$DARK_KDL" ] || [ ! -f "$LIGHT_KDL" ]; then
    exit 0
fi

MODE="${1:-}"
if [ "$MODE" != "dark" ] && [ "$MODE" != "light" ]; then
    MODE=""
    if command -v noctalia >/dev/null 2>&1 && noctalia msg status >/dev/null 2>&1; then
        MODE=$(noctalia msg theme-mode-get 2>/dev/null || echo "")
    fi
    if [ -z "$MODE" ] || [ "$MODE" = "auto" ] || [ "$MODE" = "unknown" ]; then
        if command -v gsettings >/dev/null 2>&1; then
            scheme=$(gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null | tr -d "'" || echo "")
            if [ "$scheme" = "prefer-light" ] || [ "$scheme" = "default" ]; then
                MODE="light"
            else
                MODE="dark"
            fi
        else
            MODE="dark"
        fi
    fi
fi

SRC="$DARK_KDL"
if [ "$MODE" = "light" ]; then
    SRC="$LIGHT_KDL"
fi

if [ -f "$DEST_KDL" ] && cmp -s "$SRC" "$DEST_KDL"; then
    exit 0
fi

tmp=$(mktemp "${DEST_KDL}.XXXXXX") || exit 1
cp "$SRC" "$tmp"
chmod --reference="$SRC" "$tmp" 2>/dev/null || chmod 644 "$tmp"
mv -f "$tmp" "$DEST_KDL"

if command -v niri >/dev/null 2>&1; then
    niri msg action load-config-file >/dev/null 2>&1 || true
fi
