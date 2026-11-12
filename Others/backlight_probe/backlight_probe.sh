#! /usr/bin/env bash
# backlight_probe.sh - Measure how the amdgpu kernel driver maps the requested
# backlight value to the real one, find "flat zones" (several requested values
# giving the same real brightness), and tell you what to do next.
#
# Background: since Linux 6.15, amdgpu can remap the backlight through a
# "custom brightness curve" read from the laptop firmware. On this laptop that
# curve creates flat zones (e.g. 2%, 3% and 4% look identical). The kernel
# option amdgpu.dcdebugmask=0x40000 disables that curve.
#
# The screen flickers for about 5 seconds during the measurement. The original
# brightness is restored at the end, even if you press Ctrl+C.
#
# Usage:
#   ~/.config/awesome/Others/backlight_probe/backlight_probe.sh
#   (run it once before the fix, and once again after the reboot)
#
# Output: a table, a verdict with the next step, and a copy of everything in
#   ~/.config/awesome/Others/backlight_probe/results_<YYYY-MM-DD_HH-MM-SS>.txt

set -u

BACKLIGHT_DIR="/sys/class/backlight/amdgpu_bl1"
DCDEBUGMASK_FILE="/sys/module/amdgpu/parameters/dcdebugmask"
DISABLE_CURVE_BIT=$((0x40000))
BOOT_ENTRY="/boot/loader/entries/2024-09-02_08-11-10_linux.conf"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESULT_FILE="$SCRIPT_DIR/results_$(date +%Y-%m-%d_%H-%M-%S).txt"
SETTLE_DELAY=0.1

ORIGINAL_BRIGHTNESS=""

# Print a message on screen and append it to the result file.
# Args:    $@ - text to print (joined with spaces)
# Returns: 0
# Example: log "Max brightness: 65535"
log() {
    printf '%s\n' "$*" | tee -a "$RESULT_FILE"
}

# Write a raw value to the backlight and wait for the hardware to settle.
# Args:    $1 - raw brightness value (0..max_brightness)
# Returns: 0 on success, non-zero if the write failed
# Example: set_raw_brightness 6553
set_raw_brightness() {
    echo "$1" > "$BACKLIGHT_DIR/brightness" && sleep "$SETTLE_DELAY"
}

# Restore the brightness saved at start-up. Called automatically on exit.
# Args:    none
# Returns: 0
# Example: trap restore_brightness EXIT
restore_brightness() {
    if [[ -n "$ORIGINAL_BRIGHTNESS" ]]; then
        echo "$ORIGINAL_BRIGHTNESS" > "$BACKLIGHT_DIR/brightness" 2>/dev/null
        ORIGINAL_BRIGHTNESS=""
    fi
}

# Tell whether the kernel uses the firmware brightness curve on this boot.
# Args:    none
# Returns: 0 if "Using custom brightness curve" is in the kernel log, 1 otherwise
# Example: if curve_is_active; then echo "curve on"; fi
curve_is_active() {
    journalctl -k -b 2>/dev/null | grep -qi "Using custom brightness curve"
}

# Tell whether the amdgpu.dcdebugmask option that disables the curve is set.
# Args:    none
# Returns: 0 if bit 0x40000 is set in the current dcdebugmask, 1 otherwise
# Example: if disable_flag_is_set; then echo "flag set"; fi
disable_flag_is_set() {
    local mask
    mask="$(cat "$DCDEBUGMASK_FILE" 2>/dev/null || echo 0)"
    (( (mask & DISABLE_CURVE_BIT) != 0 ))
}

# Sweep the backlight and print requested -> real values, counting flat zones.
# A flat zone is a requested step whose real value is the same as the
# previous step's real value.
# Args:    $1 - max_brightness of the panel
# Returns: prints the number of flat steps on the last line of stdout
# Example: flat=$(sweep 65535 | tail -n 1)
sweep() {
    local max="$1" pct raw actual previous_actual="" flat=0 mark
    local percents=( $(seq 0 1 20) $(seq 25 5 100) )
    printf '%8s %10s %10s  %s\n' "percent" "requested" "real" "" | tee -a "$RESULT_FILE" >&2
    for pct in "${percents[@]}"; do
        raw=$(( pct * max / 100 ))
        if ! set_raw_brightness "$raw"; then
            echo "ERROR: cannot write $BACKLIGHT_DIR/brightness (are you in the 'video' group?)" >&2
            exit 1
        fi
        actual="$(cat "$BACKLIGHT_DIR/actual_brightness")"
        mark=""
        if [[ -n "$previous_actual" && "$actual" == "$previous_actual" ]]; then
            mark="<- same as previous step (flat zone)"
            flat=$(( flat + 1 ))
        fi
        printf '%7s%% %10s %10s  %s\n' "$pct" "$raw" "$actual" "$mark" | tee -a "$RESULT_FILE" >&2
        previous_actual="$actual"
    done
    echo "$flat"
}

# Print the verdict and the next step, based on the kernel state and the sweep.
# Args:    $1 - number of flat steps found by sweep
# Returns: 0
# Example: print_verdict 3
print_verdict() {
    local flat="$1" curve="no" flag="no"
    curve_is_active && curve="yes"
    disable_flag_is_set && flag="yes"

    log ""
    log "Kernel brightness curve active : $curve"
    log "Disable flag (0x40000) set     : $flag"
    log "Flat steps found               : $flat"
    log ""
    if [[ "$flag" == "no" && "$curve" == "yes" ]]; then
        if (( flat > 0 )); then
            log "RESULT: $flat flat step(s) found. The kernel brightness curve is active"
            log "        and causes them."
        else
            log "RESULT: no flat step visible in actual_brightness, but the kernel"
            log "        brightness curve is active (it may hide them from this file)."
        fi
        log "NEXT:   1. Add amdgpu.dcdebugmask=0x40000 at the end of the 'options' line of:"
        log "              sudoedit $BOOT_ENTRY"
        log "           (and the same in the '-fallback' .conf next to it)"
        log "        2. Reboot."
        log "        3. Run this script again."
    elif [[ "$flag" == "yes" && "$curve" == "no" && "$flat" -eq 0 ]]; then
        log "RESULT: no flat step. The brightness follows the requested value."
        log "NEXT:   The fix works. Nothing more to do."
        log "        (If the low steps feel too dim or too bright, tune the steps in"
        log "        f_redshift_brightness in ~/.config/awesome/rc_laptop.lua.)"
    elif [[ "$flag" == "yes" && "$curve" == "yes" ]]; then
        log "RESULT: the flag is set but the kernel still uses the curve."
        log "NEXT:   The flag has no effect on this kernel. Go back to Claude"
        log "        (with this result file) for the lookup-table fix."
    else
        log "RESULT: unexpected state (curve: $curve, flag: $flag, flat steps: $flat)."
        log "NEXT:   Go back to Claude with this result file."
    fi
    log ""
    log "Saved to: $RESULT_FILE"
}

# Run the whole probe: checks, warning, sweep, restore, verdict.
# Args:    none
# Returns: 0 on success, 1 if the backlight is missing
# Example: main
main() {
    if [[ ! -w "$BACKLIGHT_DIR/brightness" ]]; then
        echo "ERROR: $BACKLIGHT_DIR/brightness missing or not writable." >&2
        return 1
    fi
    local max flat
    max="$(cat "$BACKLIGHT_DIR/max_brightness")"
    ORIGINAL_BRIGHTNESS="$(cat "$BACKLIGHT_DIR/brightness")"
    trap restore_brightness EXIT
    trap 'exit 130' INT TERM

    log "Backlight probe - $(date '+%Y-%m-%d %H:%M:%S') - kernel $(uname -r)"
    log "Max brightness: $max   Original brightness: $ORIGINAL_BRIGHTNESS"
    log ""
    echo "The screen will flicker for about 5 seconds. Starting in 3 s (Ctrl+C to cancel)..."
    sleep 3

    flat="$(sweep "$max" | tail -n 1)"
    restore_brightness
    if [[ ! "$flat" =~ ^[0-9]+$ ]]; then
        log "ERROR: the measurement did not complete (see the message above)."
        return 1
    fi
    print_verdict "$flat"
}

main "$@"
