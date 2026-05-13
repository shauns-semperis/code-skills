#!/bin/bash
# Wrapper that handles MSYS/Git Bash path conversion before calling docker.
# MINGW/MSYS rewrites Unix-style paths (e.g. /data/file.md) to Windows paths
# (C:/Program Files/Git/data/file.md), which breaks Docker container paths.

if [ -n "$MSYSTEM" ]; then
    export MSYS_NO_PATHCONV=1
fi

exec docker "$@"
