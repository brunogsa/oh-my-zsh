#!/bin/bash

function node-debug-reminder() {
  echo "Node Debugger Quick Steps"
  echo
  echo "1) Add 'debugger;' statements in your test file"
  echo "2) In one terminal, run:"
  echo "node --inspect-brk ./node_modules/.bin/jest [tests/myFeature.test.js]"
  echo
  echo "3) In another terminal, attach the debugger with:"
  echo "node inspect localhost:9229"
  echo
  echo "4) Builtin Debugger Commands:"
  echo "c                – continue"
  echo "n                – step over"
  echo "s                – step into"
  echo "o                – step out"
  echo "repl             – enter full REPL mode (like a mini Node console)"
  echo "restart          – restart the debug session"
  echo "watch('someVar') – watch a variable"
  echo
  echo "Enjoy your debugging session!"
}
