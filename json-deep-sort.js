#!/usr/bin/env node

const fs = require("fs");

// Recursively sort arrays by fieldNames and objects by key
function sortArrayByFields(arr, fieldNames) {
  if (!Array.isArray(arr)) return arr;

  let sortedArr = arr.slice(); // stable sort copy

  fieldNames.forEach(field => {
    sortedArr.sort((a, b) => {
      const aVal = a[field] !== undefined ? a[field] : "";
      const bVal = b[field] !== undefined ? b[field] : "";

      if (aVal < bVal) return -1;
      if (aVal > bVal) return 1;
      return 0; // stable
    });
  });

  return sortedArr.map(item => deepSortArrays(item, fieldNames));
}

function deepSortArrays(obj, fieldNames) {
  if (Array.isArray(obj)) {
    return sortArrayByFields(obj, fieldNames);
  } else if (obj && typeof obj === "object" && obj !== null) {
    const sorted = {};
    Object.keys(obj).sort().forEach(key => {
      sorted[key] = deepSortArrays(obj[key], fieldNames);
    });
    return sorted;
  }
  return obj;
}

function main() {
  const [file, fields] = process.argv.slice(2);
  if (!file) {
    console.error("Usage: json-deep-sort.js <json_file> [field1,field2,...]");
    process.exit(1);
  }

  const json = JSON.parse(fs.readFileSync(file, "utf-8"));
  const fieldNames = fields ? fields.split(",") : [];

  const sorted = deepSortArrays(json, fieldNames);

  console.log(JSON.stringify(sorted, null, 2));
}

main();
