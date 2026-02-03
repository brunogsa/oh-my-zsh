#!/usr/bin/env node

// Reads JSONL and outputs a distribution table grouped by the specified fields.
//
// Usage: node jsonl-distribution-table.js --fields field1,field2,... [file]
//
// Reads from file if provided, otherwise from stdin (/dev/stdin).
// Appends a COUNT column. Sorted by count descending.
// Missing field values default to "UNKNOWN".

const fs = require("fs");

function showHelp() {
  console.error("Usage: node jsonl-distribution-table.js --fields field1,field2,... [file]");
  console.error("");
  console.error("Options:");
  console.error("  --fields <f1,f2,...>  Comma-separated JSON field names to group by (required)");
  console.error("  [file]               JSONL file path (defaults to /dev/stdin)");
  console.error("");
  console.error("Examples:");
  console.error("  cat logs.jsonl | node jsonl-distribution-table.js --fields httpMethod,resourcePath,status");
  console.error("  node jsonl-distribution-table.js --fields level,flow /tmp/logs.jsonl");
  process.exit(1);
}

const args = process.argv.slice(2);
if (args.includes("-h") || args.includes("--help") || args.length === 0) {
  showHelp();
}

const fieldsIdx = args.indexOf("--fields");
if (fieldsIdx === -1 || !args[fieldsIdx + 1]) {
  console.error("Error: --fields is required");
  showHelp();
}

const fields = args[fieldsIdx + 1].split(",");
const remaining = args.filter((_, i) => i !== fieldsIdx && i !== fieldsIdx + 1);
const inputFile = remaining[0] || "/dev/stdin";

const content = fs.readFileSync(inputFile, "utf8").trim();
if (!content) {
  process.exit(0);
}

const counts = {};

for (const line of content.split("\n")) {
  try {
    const entry = JSON.parse(line.trim());
    const key = fields.map((f) => String(entry[f] ?? "UNKNOWN")).join("\t");
    counts[key] = (counts[key] || 0) + 1;
  } catch (_) {
    // skip malformed lines
  }
}

const sorted = Object.entries(counts).sort((a, b) => b[1] - a[1]);

const headers = [...fields.map((f) => f.toUpperCase()), "COUNT"];
const widths = headers.map((h) => h.length);

const rows = sorted.map(([key, count]) => {
  const parts = key.split("\t");
  parts.push(String(count));
  parts.forEach((val, i) => {
    widths[i] = Math.max(widths[i], val.length);
  });
  return parts;
});

const formatRow = (cols) =>
  cols.map((col, i) => col.padEnd(widths[i])).join("  ");

console.log(formatRow(headers));
for (const row of rows) {
  console.log(formatRow(row));
}
