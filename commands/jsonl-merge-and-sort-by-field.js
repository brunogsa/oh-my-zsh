#!/usr/bin/env node

// Merges multiple JSONL files and sorts entries by a specified field.
//
// Usage: node jsonl-merge-and-sort-by-field.js --sort-field <field> [--desc] <file1> [file2] ...
//
// Entries without the sort field, or with unparseable values, are placed at the end.
// Output: sorted JSONL to stdout.

const fs = require("fs");

function showHelp() {
  console.error("Usage: node jsonl-merge-and-sort-by-field.js --sort-field <field> [--desc] <file1> [file2] ...");
  console.error("");
  console.error("Options:");
  console.error("  --sort-field <field>  JSON field name to sort by (required)");
  console.error("  --desc                Sort descending (default: ascending)");
  console.error("  <files...>            One or more JSONL file paths");
  console.error("");
  console.error("Examples:");
  console.error("  node jsonl-merge-and-sort-by-field.js --sort-field timestamp f1.jsonl f2.jsonl");
  console.error("  node jsonl-merge-and-sort-by-field.js --sort-field requestTime --desc f1.jsonl");
  process.exit(1);
}

const args = process.argv.slice(2);
if (args.includes("-h") || args.includes("--help") || args.length === 0) {
  showHelp();
}

const sortFieldIdx = args.indexOf("--sort-field");
if (sortFieldIdx === -1 || !args[sortFieldIdx + 1]) {
  console.error("Error: --sort-field is required");
  showHelp();
}

const sortField = args[sortFieldIdx + 1];
const descending = args.includes("--desc");
const files = args.filter((_, i) => {
  if (i === sortFieldIdx || i === sortFieldIdx + 1) return false;
  if (args[i] === "--desc") return false;
  return true;
});

if (files.length === 0) {
  console.error("Error: at least one file is required");
  showHelp();
}

const FALLBACK_TS = descending ? -Infinity : Infinity;

function toSortableValue(raw) {
  if (raw == null) return FALLBACK_TS;

  if (typeof raw === "number") return raw;

  const str = String(raw);
  const asNum = Number(str);
  if (!isNaN(asNum)) return asNum;

  const asDate = new Date(str).getTime();
  if (!isNaN(asDate)) return asDate;

  return FALLBACK_TS;
}

const entries = [];

for (const filePath of files) {
  let content;
  try {
    content = fs.readFileSync(filePath, "utf8").trim();
  } catch (_) {
    console.error(`Warning: could not read ${filePath}, skipping`);
    continue;
  }

  if (!content) continue;

  for (const line of content.split("\n")) {
    const trimmed = line.trim();
    if (!trimmed) continue;

    try {
      const obj = JSON.parse(trimmed);
      const sortValue = toSortableValue(obj[sortField]);
      entries.push({ sortValue, obj });
    } catch (_) {
      // skip malformed lines
    }
  }
}

if (descending) {
  entries.sort((a, b) => b.sortValue - a.sortValue);
} else {
  entries.sort((a, b) => a.sortValue - b.sortValue);
}

for (const { obj } of entries) {
  console.log(JSON.stringify(obj));
}
