#!/usr/bin/env bash
# ops-detect-cli.sh — Detect which CLI is running (Claude Code or OpenCode).
# Called by ops-init to dispatch to the correct sub-skill.
#
# Usage: ops-detect-cli.sh
#   No arguments. Reads environment variables and the process tree.
#
# Output: single line
#   cli=<claude-code|opencode|unknown>
#
# Detection cascade:
#   1. Environment variables: CLAUDECODE=1 or OPENCODE=1
#   2. Process tree: walk ancestors via /proc/<pid>/cmdline or ps
#   3. Fallback: unknown
#
# Exit codes:
#   0 = always (informational output only)

set -euo pipefail
[[ "${DEBUG:-}" == "1" ]] && set -x

# --- 1. Environment variable detection ---
if [[ "${CLAUDECODE:-}" == "1" ]]; then
    echo "cli=claude-code"
    exit 0
fi

if [[ "${OPENCODE:-}" == "1" ]]; then
    echo "cli=opencode"
    exit 0
fi

# --- 2. Process tree detection ---
# Wrapped in a function to catch any failures safely.
detect_via_process_tree() {
    local pid=$$
    local cmdline

    while true; do
        # Get parent PID — try /proc first (Linux), fall back to ps (portable)
        local ppid=""
        if [[ -r "/proc/${pid}/status" ]]; then
            ppid=$(grep -m1 '^PPid:' "/proc/${pid}/status" 2>/dev/null | awk '{print $2}') || true
        fi
        if [[ -z "$ppid" ]]; then
            ppid=$(ps -o ppid= -p "$pid" 2>/dev/null | tr -d ' ') || true
        fi

        # Stop if we can't get a parent or we've reached init (pid 1 or 0)
        [[ -z "$ppid" || "$ppid" -le 1 ]] && break

        # Read the command line of the parent process
        cmdline=""
        if [[ -r "/proc/${ppid}/cmdline" ]]; then
            cmdline=$(tr '\0' ' ' < "/proc/${ppid}/cmdline" 2>/dev/null) || true
        fi
        if [[ -z "$cmdline" ]]; then
            cmdline=$(ps -o args= -p "$ppid" 2>/dev/null) || true
        fi

        if [[ -n "$cmdline" ]]; then
            if [[ "$cmdline" == *"claude"* ]]; then
                echo "cli=claude-code"
                return 0
            fi
            if [[ "$cmdline" == *"opencode"* ]]; then
                echo "cli=opencode"
                return 0
            fi
        fi

        pid="$ppid"
    done

    return 1
}

if detect_via_process_tree 2>/dev/null; then
    exit 0
fi

# --- 3. Fallback ---
echo "cli=unknown"
exit 0
