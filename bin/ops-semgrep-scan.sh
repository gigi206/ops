#!/usr/bin/env bash
# ops-semgrep-scan.sh — Run semgrep with automatic config and baseline detection.
# Called by ops-security-gate Step 1b to encapsulate branching logic.
#
# Usage: ops-semgrep-scan.sh [--config <path|auto>] [file1 file2 ...]
#   --config: semgrep config to use. Auto-detects if omitted.
#   If no files given, scans git-changed files.
#
# Output: structured key=value pairs followed by raw semgrep JSON (if any).
#   Metadata lines (always present):
#     status=<findings|findings_unknown|no_findings|error|not_installed|no_files>
#     config=<config used>
#     baseline=<commit or none>
#     exit_code=<semgrep exit code or n/a>
#   If status=findings or status=no_findings, the raw semgrep JSON follows after a
#   blank line separator. The caller (LLM) parses the findings from the raw JSON.
#   If status=error, an error= line is included instead.
#   Findings are detected by parsing the JSON results array (no --error flag dependency).
#
# Exit codes:
#   0 = success (findings detected from JSON, not exit code)
#   1 = semgrep not installed
#   2 = semgrep execution failed

set -euo pipefail
[[ "${DEBUG:-}" == "1" ]] && set -x

PROJECT_ROOT="${PROJECT_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"

# --- Check semgrep availability ---
if ! command -v semgrep &>/dev/null; then
    echo "status=not_installed"
    echo "config=none"
    echo "baseline=none"
    echo "exit_code=n/a"
    echo "error=semgrep not found in PATH"
    exit 1
fi

# --- Determine config ---
config_arg=""
config_used=""

# Accept --config from caller to avoid re-detection
if [[ "${1:-}" == "--config" && -n "${2:-}" ]]; then
    config_used="$2"
    config_arg="$2"
    shift 2
fi

# Auto-detect if not provided
if [[ -z "$config_arg" ]]; then
    if [[ -d "$PROJECT_ROOT/.semgrep" ]]; then
        rule_count=$(find "$PROJECT_ROOT/.semgrep" -name '*.yml' -o -name '*.yaml' 2>/dev/null | head -20 | wc -l)
        if [[ "$rule_count" -gt 0 ]]; then
            config_arg="$PROJECT_ROOT/.semgrep"
            config_used="$PROJECT_ROOT/.semgrep"
        fi
    elif [[ -f "$PROJECT_ROOT/.semgrep.yml" ]]; then
        if ! grep -qE '^\s*rules:\s*\[\s*\]' "$PROJECT_ROOT/.semgrep.yml" 2>/dev/null; then
            config_arg="$PROJECT_ROOT/.semgrep.yml"
            config_used="$PROJECT_ROOT/.semgrep.yml"
        fi
    fi
    # Fallback to auto
    if [[ -z "$config_arg" ]]; then
        config_arg="auto"
        config_used="auto"
    fi
fi

# --- Determine baseline commit ---
baseline_flag=""
baseline_used="none"

# Try feature branch: merge-base with main or master
main_branch=""
if git rev-parse --verify main &>/dev/null; then
    main_branch="main"
elif git rev-parse --verify master &>/dev/null; then
    main_branch="master"
fi

current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")

if [[ -n "$main_branch" && -n "$current_branch" && "$current_branch" != "$main_branch" && "$current_branch" != "HEAD" ]]; then
    # Feature branch: use merge-base
    merge_base=$(git merge-base HEAD "$main_branch" 2>/dev/null || echo "")
    if [[ -n "$merge_base" ]]; then
        baseline_flag="--baseline-commit=$merge_base"
        baseline_used="$merge_base"
    fi
elif [[ -n "$main_branch" && -n "$current_branch" && "$current_branch" == "$main_branch" ]]; then
    # On main branch: use HEAD~1 if available
    parent=$(git rev-parse HEAD~1 2>/dev/null || echo "")
    if [[ -n "$parent" ]]; then
        baseline_flag="--baseline-commit=$parent"
        baseline_used="$parent"
    fi
elif [[ "$current_branch" == "HEAD" ]]; then
    # Detached HEAD: use HEAD~1 if available
    parent=$(git rev-parse HEAD~1 2>/dev/null || echo "")
    if [[ -n "$parent" ]]; then
        baseline_flag="--baseline-commit=$parent"
        baseline_used="$parent"
    fi
fi

# --- Determine file list ---
files=("$@")
if [[ ${#files[@]} -eq 0 ]]; then
    # No files provided: use git-changed files (tracked + untracked, deduplicated)
    mapfile -t files < <({
        git diff --name-only HEAD 2>/dev/null
        git diff --name-only --cached 2>/dev/null
        git ls-files --others --exclude-standard 2>/dev/null
    } | sort -u)
fi

# Filter to files semgrep can actually scan (source code, config, etc.)
# Exclude purely document-like extensions that cause "Invalid scanning root" errors.
scannable_files=()
for f in "${files[@]}"; do
    case "$f" in
        *.md|*.txt|*.rst|*.adoc|*.pdf|*.png|*.jpg|*.jpeg|*.gif|*.svg|*.ico|*.woff|*.woff2|*.ttf|*.eot|*.mp3|*.mp4|*.webm|*.zip|*.tar|*.gz) continue ;;
        *) scannable_files+=("$f") ;;
    esac
done

if [[ ${#scannable_files[@]} -eq 0 ]]; then
    echo "status=no_files"
    echo "config=$config_used"
    echo "baseline=$baseline_used"
    echo "exit_code=n/a"
    exit 0
fi

# --- Run semgrep ---
# Build command — each argument as a separate array element to handle paths with spaces
cmd=(semgrep scan --config "$config_arg" --json)
if [[ -n "$baseline_flag" ]]; then
    cmd+=("$baseline_flag")
fi
cmd+=("${scannable_files[@]}")

# Execute and capture output. Stderr goes to a temp file for diagnostics.
stderr_file=$(mktemp)
trap 'rm -f "$stderr_file"' EXIT
output=""
exit_code=0
output=$("${cmd[@]}" 2>"$stderr_file") || exit_code=$?

# Without --error, semgrep exits 0 on success (with or without findings),
# non-zero on execution failure. Parse findings from JSON instead of exit code.
if [[ $exit_code -ne 0 ]]; then
    error_msg=$(head -5 "$stderr_file" | tr '\n' ' ')
    [[ -z "$error_msg" ]] && error_msg=$(echo "$output" | head -5 | tr '\n' ' ')
    [[ -z "$error_msg" ]] && error_msg="semgrep failed with exit code $exit_code"
    echo "status=error"
    echo "config=$config_used"
    echo "baseline=$baseline_used"
    echo "exit_code=$exit_code"
    echo "error=$error_msg"
    exit 2
fi

# --- Detect findings from JSON ---
# Cascade: jq (precise) → python3 (universal) → unknown.
count_json_results() {
    local json="$1"
    if command -v jq &>/dev/null; then
        echo "$json" | jq '.results | length' 2>/dev/null && return 0
    fi
    if command -v python3 &>/dev/null; then
        echo "$json" | python3 -c "import json,sys; print(len(json.load(sys.stdin).get('results',[])))" 2>/dev/null && return 0
    fi
    # No JSON parser available — cannot reliably count results
    echo "unknown"
}

finding_count=$(count_json_results "$output")

if [[ "$finding_count" == "unknown" ]]; then
    status="findings_unknown"
elif [[ "$finding_count" -gt 0 ]]; then
    status="findings"
else
    status="no_findings"
fi

# --- Output metadata + raw JSON ---
echo "status=$status"
echo "config=$config_used"
echo "baseline=$baseline_used"
echo "exit_code=$exit_code"
echo ""
echo "$output"
