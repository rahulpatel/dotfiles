#!/usr/bin/env bash
# preflight/xcode.sh - verify Xcode Command Line Tools are installed.
# The boot script handles installation on fresh machines; this is a safety net
# for direct ./install runs.

if ! xcode-select -p >/dev/null 2>&1; then
    die "Xcode Command Line Tools not found. Run: xcode-select --install"
fi
