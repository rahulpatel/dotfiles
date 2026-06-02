#!/usr/bin/env bash
# modules/xcode.sh - verify Xcode Command Line Tools are installed. The boot
# script handles installation on fresh machines; this is a safety net for
# direct ./install runs.

prepare() {
    if ! xcode-select -p >/dev/null 2>&1; then
        die "Xcode Command Line Tools not found. Run: xcode-select --install"
    fi
}
