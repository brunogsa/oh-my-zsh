#!/usr/bin/env node

// Reads a JSONL file of API Gateway log entries (one JSON per line)
// and outputs a distribution table grouped by method, path, status, and API key.
//
// Usage: node apigw-distribution-table.js <jsonl-file>

const fs = require("fs");

const inputFile = process.argv[2];
if (!inputFile) {
  console.error("Usage: node apigw-distribution-table.js <jsonl-file>");
  process.exit(1);
}

const lines = fs.readFileSync(inputFile, "utf8").trim().split("\n");
const counts = {};

for (const line of lines) {
  try {
    const entry = JSON.parse(line);
    const method = entry.httpMethod || "UNKNOWN";
    const path = entry.resourcePath || entry.path || "UNKNOWN";
    const status = String(entry.status || "UNKNOWN");
    const rawKey = entry.apiKey || "";
    const apiKey = rawKey && rawKey !== "-"
      ? "..." + rawKey.slice(-6)
      : "(no key)";

    const key = [method, path, status, apiKey].join("\t");
    counts[key] = (counts[key] || 0) + 1;
  } catch (_) {
    // skip malformed lines
  }
}

// Sort by count descending
const sorted = Object.entries(counts).sort((a, b) => b[1] - a[1]);

// Calculate column widths
const headers = ["METHOD", "PATH", "STATUS", "API_KEY", "COUNT"];
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
