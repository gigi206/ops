#!/usr/bin/env bash
# ops-capture-task-state.sh — Capture cumulative working-tree state for per-task code review.
# Called by /ops-implement Step 2d to give the per-task code-reviewer
# the full state of changes since the start of /ops-implement.
#
# Usage: ops-capture-task-state.sh
#   No arguments. Must be run from inside a git repository (anywhere — the
#   script cd's to the repo toplevel internally so output is consistent
#   regardless of the caller's working directory).
#
# Output: text blob containing
#   1. `git diff HEAD` output (modifications to files that already existed
#      at the start of /ops-implement — i.e. tracked files). Skipped if the
#      repository has no HEAD yet (fresh `git init`, no commits).
#   2. For each untracked new file: a `=== NEW FILE: <path> ===` marker
#      followed by the file content. Five marker variants exist for
#      non-text content:
#        - `[binary file — content omitted]`     for files containing NUL bytes
#        - `[empty file]`                         for zero-byte files
#        - `[symbolic link → <target>]`           for symlinks
#        - `[not a regular file — skipped]`       for FIFOs, sockets, devices
#        - `[unreadable file — content omitted]`  for files that fail -r check
#                                                 or whose cat fails at read time
#
# Why: `git diff HEAD` alone does NOT show untracked files. Tasks that
# create new files (the most common shape for "create X" tasks) would be
# invisible to the per-task reviewer if only `git diff HEAD` were used.
# This script concatenates both sources (tracked diff + untracked content)
# into a single text blob that the orchestrator passes inline to the
# code-reviewer dispatch prompt.
#
# Side effects: NONE. Read-only on the working tree and the git index.
#   - cd's to the repo toplevel (process-local, doesn't affect parent shell)
#   - `git diff HEAD` reads HEAD and the working tree
#   - `git ls-files --others --exclude-standard` reads the working tree
#   - `cat`, `readlink`, `grep -I` read files
# No `git add`, no `git stash`, no temporary index, no `git reset`.
#
# Portability: written for POSIX-ish bash 4+ on Linux and macOS. Avoids
# GNU-only flags (no `grep -P`, no `grep $'\x00'`). The binary detection
# uses `grep -I` which is in both GNU and BSD grep.
#
# Exit codes:
#   0 = success (output is the captured state; may be empty if the working
#       tree is clean and there are no untracked files)
#   1 = not in a git repository
#   2 = git error during diff (other than "no HEAD", which is handled)

set -euo pipefail
[[ "${DEBUG:-}" == "1" ]] && set -x

# --- 1. Verify we're in a git repository AND cd to its toplevel ---
# `git ls-files` is scoped to cwd by default, so running this script from
# a subdirectory of the repo would silently miss untracked files outside
# that subdirectory. cd'ing to the toplevel guarantees consistent output
# regardless of where the orchestrator invokes the script.
toplevel=$(git rev-parse --show-toplevel 2>/dev/null) || {
    echo "ERROR: ops-capture-task-state.sh must be run from inside a git repository" >&2
    exit 1
}
cd "$toplevel"

# --- 2. Tracked file modifications via `git diff HEAD` ---
# Captures: modifications to existing files, deletions, mode changes, renames.
# Does NOT capture: untracked files (handled in step 3 below).
#
# Special case: a freshly `git init`'d repo has no HEAD until the first
# commit. `git diff HEAD` would fail with "fatal: bad revision 'HEAD'".
# In that case, every file is "new" and is captured by the untracked-files
# branch below — there is nothing to diff, so we skip the diff step.
if git rev-parse --verify HEAD >/dev/null 2>&1; then
    if ! git diff HEAD; then
        echo "ERROR: git diff HEAD failed" >&2
        exit 2
    fi
fi

# --- 3. Untracked new files ---
# `git ls-files --others --exclude-standard` lists files that are:
#   - present in the working tree
#   - not tracked by git
#   - not ignored by .gitignore
# This is exactly the set of files created since the last commit (or all
# files in the working tree if there is no HEAD yet).
#
# For each such file, output a marker line and the file content (text only).
# Binary files, empty files, symlinks, special files, and unreadable files
# are reported with explicit placeholders so the reviewer never sees a
# silent omission.
#
# `git ls-files -z` outputs NUL-delimited filenames (no quoting, no escaping),
# which correctly handles filenames with embedded newlines, spaces, or other
# special characters. The matching `read -r -d ''` reads NUL-delimited records.
while IFS= read -r -d '' f; do
    [[ -z "$f" ]] && continue

    # Symlinks: report the link target, not the dereferenced content.
    # `-L` MUST be checked before `-f` because `-f` follows symlinks.
    # Use `./$f` rather than `-- $f` because BSD readlink (older macOS) does
    # not reliably support `--` as end-of-options. The `./` prefix protects
    # against filenames starting with `-` and works on all readlink variants.
    if [[ -L "$f" ]]; then
        printf '\n=== NEW FILE: %s ===\n[symbolic link → %s]\n' "$f" "$(readlink "./$f")"
        continue
    fi

    # Non-regular files (FIFOs, sockets, devices, broken non-symlink targets):
    # note presence. In practice `git ls-files` doesn't list these, so this
    # branch is defensive — but if it ever fires, we want a placeholder, not
    # a `cat` failure.
    if [[ ! -f "$f" ]]; then
        printf '\n=== NEW FILE: %s ===\n[not a regular file — skipped]\n' "$f"
        continue
    fi

    # Unreadable file (e.g. chmod 000): note presence. Without this branch,
    # `cat` would fail and `set -e` would terminate the loop, silently
    # dropping every untracked file alphabetically after this one.
    if [[ ! -r "$f" ]]; then
        printf '\n=== NEW FILE: %s ===\n[unreadable file — content omitted]\n' "$f"
        continue
    fi

    # Empty file: explicit placeholder. An empty file is meaningful (forgotten
    # __init__.py, accidentally-cleared module, intentional placeholder) and
    # the reviewer should see it as empty, not as binary.
    if [[ ! -s "$f" ]]; then
        printf '\n=== NEW FILE: %s ===\n[empty file]\n' "$f"
        continue
    fi

    # Binary detection via `grep -I`. The `-I` flag tells grep to skip binary
    # files (returns no match). Combined with the empty pattern `''` (which
    # matches every line of a text file), we get:
    #   - text file: empty pattern matches → grep returns 0 → text branch
    #   - binary file: -I skips it → grep returns 1 → binary branch
    # This is portable across GNU grep (Linux) and BSD grep (macOS), unlike
    # `grep -P '\x00'` which is GNU-only and silently breaks on macOS.
    # Empty files are not reached here (handled above), so the "no lines
    # to match" edge case doesn't apply.
    if LC_ALL=C grep -Iq '' -- "$f" 2>/dev/null; then
        printf '\n=== NEW FILE: %s ===\n' "$f"
        # Guard cat against transient read errors (race conditions, e.g. file
        # removed or chmod'd between -r check and cat). Continue the loop on
        # failure, reusing the same unified unreadable placeholder. No leading
        # \n here because line 142's printf already ended the marker with \n —
        # adding another would produce a blank line inconsistent with the
        # early -r branch above.
        if ! cat -- "$f" 2>/dev/null; then
            printf '[unreadable file — content omitted]\n'
        fi
    else
        printf '\n=== NEW FILE: %s ===\n[binary file — content omitted]\n' "$f"
    fi
done < <(git ls-files -z --others --exclude-standard)
