#!/usr/bin/env bash
# Cross-platform clipboard copy utility using copyq
# Works on both Linux and macOS
# Usage: echo "text" | copy
#        cat file.txt | copy

copy() {
    copyq add - && copyq select 0
}
