#!/bin/bash

function gen-schema-from-json () {
  if [[ -z $1 ]]; then
    echo "Usage: gen-schema-from-json <input_json_file>"
    return 1
  fi

  local inputJson=$1
  local fileName=${inputJson%.json}

  # 1. JSON  ➜  JSON-Schema
  npx quicktype \
    --src "$inputJson" \
    --src-lang json \
    --lang schema \
    --out "${fileName}.schema.json"
}
