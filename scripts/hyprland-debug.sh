#!/usr/bin/env bash
# Hyprland debugging script

set -euo pipefail

echo "=== Hyprland Debug Information ==="
echo

echo "--- System Information ---"
echo "Kernel: $(uname -r)"
echo "NixOS Version: $(nixos-version)"
echo

echo "--- GPU Information ---"
lspci | grep -E "VGA|3D|Display" || echo "No GPU detected via lspci"
echo

echo "--- DRM Devices ---"
ls -la /dev/dri/ || echo "No DRM devices found"
echo

echo "--- Wayland Environment ---"
env | grep -E "WAYLAND|XDG|QT_|GDK_|MOZ_|WLR_" | sort || echo "No Wayland variables set"
echo

echo "--- Session Information ---"
echo "Current session: ${XDG_SESSION_TYPE:-not set}"
echo "Current desktop: ${XDG_CURRENT_DESKTOP:-not set}"
echo "Display: ${WAYLAND_DISPLAY:-not set}"
loginctl show-session "$XDG_SESSION_ID" 2>/dev/null || echo "No session info available"
echo

echo "--- Seat Status ---"
if command -v seatd-launch >/dev/null 2>&1; then
    echo "seatd is installed"
else
    echo "WARNING: seatd not found"
fi
echo

echo "--- Portal Status ---"
systemctl --user status xdg-desktop-portal 2>/dev/null || echo "Portal service not running"
systemctl --user status xdg-desktop-portal-hyprland 2>/dev/null || echo "Hyprland portal not running"
echo

echo "--- D-Bus Status ---"
systemctl --user status dbus 2>/dev/null || echo "User D-Bus not running"
echo

echo "--- Hyprland Logs ---"
echo "Recent Hyprland logs (if any):"
journalctl --user -u hyprland -n 50 --no-pager 2>/dev/null || \
    journalctl --user -t hyprland -n 50 --no-pager 2>/dev/null || \
    echo "No Hyprland logs found in journal"
echo

echo "--- GPU Driver Logs ---"
echo "Recent GPU/DRM errors:"
journalctl -b -p err | grep -E "amdgpu|drm|gpu" | tail -20 || echo "No GPU errors found"
echo

echo "--- Checking Critical Files ---"
for file in /usr/share/wayland-sessions/hyprland.desktop \
           /run/opengl-driver/lib/dri/radeonsi_dri.so \
           /run/opengl-driver/share/vulkan/icd.d/radeon_icd.x86_64.json; do
    if [ -e "$file" ]; then
        echo "✓ $file exists"
    else
        echo "✗ $file missing"
    fi
done
echo

echo "--- Running Processes ---"
echo "Wayland compositors:"
pgrep -l "hyprland|sway|wayfire|niri" || echo "No Wayland compositor running"
echo
echo "Essential services:"
pgrep -l "pipewire|wireplumber|dbus|polkit" || echo "Some essential services not running"
echo

echo "--- Tips ---"
echo "1. Run 'hyprland -V' to check version"
echo "2. Run 'Hyprland' from TTY to see direct error output"
echo "3. Check ~/.config/hypr/hyprland.conf for syntax errors"
echo "4. Try 'WLR_NO_HARDWARE_CURSORS=1 Hyprland' if cursor issues"
echo "5. Use 'WAYLAND_DEBUG=1 Hyprland' for protocol debugging"