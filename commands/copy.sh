#!/usr/bin/env bash
# Cross-platform clipboard copy utility using copyq
# Works on both Linux and macOS
# Usage: echo "text" | copy
#        cat file.txt | copy

if [[ "$OSTYPE" == "darwin"* ]] && ! command -v copyq &>/dev/null; then
    export PATH="/Applications/CopyQ.app/Contents/MacOS:$PATH"
fi

copy() {
    copyq add - && copyq select 0
}
