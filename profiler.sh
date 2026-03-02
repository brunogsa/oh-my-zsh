#!/usr/bin/env bash
# profiler - Profile zsh login shell startup time per source file
#
# Uses xtrace timestamps to measure wall time spent in each file during a full
# login shell startup (the same kind tmux spawns for new panes).
#
# Usage:
#   ./profiler.sh                  # default: aggregate by file, top 25
#   ./profiler.sh --top 10         # show top 10 files
#   ./profiler.sh --iterations 30  # variance analysis: stats + fast vs slow comparison
#   ./profiler.sh --raw            # dump raw xtrace log path for manual analysis
#
# Examples:
#   ./profiler.sh                  # quick overview of startup bottlenecks
#   ./profiler.sh --top 5          # just the 5 slowest files
#   ./profiler.sh --iterations 30  # find what causes slow outliers
#   ./profiler.sh --raw            # get log path, then grep it yourself
#
# With --iterations, a detailed report is written to /tmp/zsh-profiler-report.txt
# containing stats, per-file tables, delta, and line-level gap analysis of the
# slowest run. Summary is printed to stdout.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# --- args -----------------------------------------------------------

export TOP_N=25
RAW_MODE=false
ITERATIONS=1

while [[ $# -gt 0 ]]; do
  case "$1" in
    --top)          TOP_N="$2"; shift 2 ;;
    --iterations)   ITERATIONS="$2"; shift 2 ;;
    --raw)          RAW_MODE=true; shift ;;
    -h|--help)
      awk 'NR>1 && /^[^#]/{exit} NR>1{sub(/^# ?/,""); print}' "$0"
      exit 0
      ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

# --- detect zsh binary -----------------------------------------------

source "$SCRIPT_DIR/lib/detect-os.sh"
OS_TYPE=$(detect_os)

if [[ "$OS_TYPE" == "macos" ]]; then
  ZSH_BIN="/opt/homebrew/bin/zsh"
else
  ZSH_BIN="/usr/bin/zsh"
fi

if [[ ! -x "$ZSH_BIN" ]]; then
  echo "Error: zsh not found at $ZSH_BIN" >&2
  exit 1
fi

# --- warm the completion dump ----------------------------------------
# First run rebuilds the dump if stale; we want to measure steady-state.

"$ZSH_BIN" -l -i -c 'exit' 2>/dev/null || true

# --- helpers ----------------------------------------------------------

run_single_xtrace() {
  local trace_log="$1"
  PS4='+[%D{%s.%6.}]%N:%i> ' "$ZSH_BIN" -x -l -i -c 'exit' 2>"$trace_log" || true
}

extract_total_ms() {
  perl -ne '
    if (/^\+\[(\d+\.\d+)\]/) { $first //= $1; $last = $1 }
    END { printf "%.1f\n", ($last - $first) * 1000 }
  ' "$1"
}

# Aggregate xtrace log by source file, output TSV: ms\tfile
aggregate_by_file() {
  perl -ne '
    if (/^\+\[(\d+\.\d+)\](\S+?):/) {
      $curr = $1; $file = $2;
      if (defined $prev) { $totals{$prev_file} += ($curr - $prev) * 1000 }
      $prev = $curr; $prev_file = $file;
    }
    END {
      my $home = $ENV{HOME} // "";
      for (sort { $totals{$b} <=> $totals{$a} } keys %totals) {
        my $d = $_; $d =~ s/^\Q$home\E/~/;
        printf "%.1f\t%s\n", $totals{$_}, $d;
      }
    }
  ' "$1"
}

# Print per-file table from an xtrace log
print_file_table() {
  local trace_log="$1"

  _TOP_N="${TOP_N}" perl -ne '
    if (/^\+\[(\d+\.\d+)\](\S+?):/) {
      $curr = $1; $file = $2;
      if (defined $prev) {
        $totals{$prev_file} += ($curr - $prev) * 1000;
        $counts{$prev_file}++;
      }
      $prev = $curr; $prev_file = $file;
      $first //= $curr; $last = $curr;
    }
    END {
      my $total = ($last - $first) * 1000;
      my $top_n = $ENV{_TOP_N} || 25;
      my $home = $ENV{HOME} // "";

      printf "%-62s %8s %6s\n", "FILE", "ms", "CALLS";
      printf "%s\n", "-" x 80;

      my $rank = 0;
      for (sort { $totals{$b} <=> $totals{$a} } keys %totals) {
        last if ++$rank > $top_n;
        my $d = $_; $d =~ s/^\Q$home\E/~/;
        printf "%-62s %8.1f %6d\n", $d, $totals{$_}, $counts{$_};
      }

      printf "%s\n", "-" x 80;
      printf "TOTAL: %.0fms\n", $total;
    }
  ' "$trace_log"
}

# Print time gaps > threshold from an xtrace log
print_gaps() {
  local trace_log="$1"
  local threshold_ms="${2:-10}"

  _THRESHOLD="$threshold_ms" perl -ne '
    if (/^\+\[(\d+\.\d+)\](.+)/) {
      $curr = $1; $line = $2;
      if (defined $prev) {
        my $delta = ($curr - $prev) * 1000;
        if ($delta > $ENV{_THRESHOLD}) {
          my $home = $ENV{HOME} // "";
          my $pl = $prev_line; $pl =~ s/\Q$home\E/~/g;
          my $cl = $line;      $cl =~ s/\Q$home\E/~/g;
          printf "%6.0fms gap  %s\n", $delta, substr($pl, 0, 120);
          printf "       then  %s\n\n", substr($cl, 0, 120);
        }
      }
      $prev = $curr; $prev_line = $line;
    }
  ' "$trace_log"
}

# --- multi-iteration mode ---------------------------------------------

if [[ "$ITERATIONS" -gt 1 ]]; then
  TRACE_DIR=$(mktemp -d /tmp/zsh-profiler-batch.XXXXXX)
  REPORT="/tmp/zsh-profiler-report.txt"
  TOTALS=()
  TRACE_FILES=()

  for i in $(seq 1 "$ITERATIONS"); do
    trace_log="$TRACE_DIR/run-$i.log"
    run_single_xtrace "$trace_log"
    ms=$(extract_total_ms "$trace_log")
    TOTALS+=("$ms")
    TRACE_FILES+=("$trace_log")
    printf "\r[%d/%d] %sms" "$i" "$ITERATIONS" "$ms" >&2
  done
  printf "\r%*s\r" 40 "" >&2

  # Find fastest and slowest run indices
  FAST_IDX=0
  SLOW_IDX=0
  for i in "${!TOTALS[@]}"; do
    if (( $(echo "${TOTALS[$i]} < ${TOTALS[$FAST_IDX]}" | bc -l) )); then FAST_IDX=$i; fi
    if (( $(echo "${TOTALS[$i]} > ${TOTALS[$SLOW_IDX]}" | bc -l) )); then SLOW_IDX=$i; fi
  done

  FAST_FILE="${TRACE_FILES[$FAST_IDX]}"
  SLOW_FILE="${TRACE_FILES[$SLOW_IDX]}"

  # --- write full report to file ---
  {
    # stats
    printf '%s\n' "${TOTALS[@]}" | perl -e '
      my @vals = sort { $a <=> $b } map { chomp; $_ + 0 } <STDIN>;
      my $n = scalar @vals;
      my $sum = 0; $sum += $_ for @vals;
      my $mean = $sum / $n;
      my $variance = 0; $variance += ($_ - $mean)**2 for @vals; $variance /= $n;
      my $stddev = sqrt($variance);
      my $median = $n % 2 ? $vals[int($n/2)] : ($vals[$n/2 - 1] + $vals[$n/2]) / 2;
      my $p95 = $vals[int($n * 0.95)];

      printf "=== STATS (%d iterations) ===\n", $n;
      printf "  min:    %6.0fms\n", $vals[0];
      printf "  median: %6.0fms\n", $median;
      printf "  mean:   %6.0fms\n", $mean;
      printf "  p95:    %6.0fms\n", $p95;
      printf "  max:    %6.0fms\n", $vals[-1];
      printf "  stddev: %6.0fms\n", $stddev;
      printf "\nAll runs (ms): %s\n", join(", ", map { sprintf("%.0f", $_) } @vals);
    '

    echo ""
    echo "=== FASTEST RUN (${TOTALS[$FAST_IDX]}ms) ==="
    print_file_table "$FAST_FILE"

    echo ""
    echo "=== SLOWEST RUN (${TOTALS[$SLOW_IDX]}ms) ==="
    print_file_table "$SLOW_FILE"

    # delta
    echo ""
    echo "=== DELTA (slow - fast, files that grew >5ms) ==="
    printf "%-62s %8s %8s %8s\n" "FILE" "FAST" "SLOW" "DELTA"
    printf '%s\n' "$(printf '%0.s-' {1..92})"

    paste <(aggregate_by_file "$FAST_FILE") <(aggregate_by_file "$SLOW_FILE") \
      | perl -e '
        my (%fast, %slow);
        while (<STDIN>) {
          chomp;
          my @cols = split /\t/;
          if (defined $cols[0] && defined $cols[1]) { $fast{$cols[1]} = $cols[0] + 0 }
          if (defined $cols[2] && defined $cols[3]) { $slow{$cols[3]} = $cols[2] + 0 }
        }
        my %all_files = map { $_ => 1 } (keys %fast, keys %slow);
        my @results;
        for my $f (keys %all_files) {
          my $fv = $fast{$f} // 0;
          my $sv = $slow{$f} // 0;
          my $delta = $sv - $fv;
          push @results, [$f, $fv, $sv, $delta] if $delta > 5;
        }
        for (sort { $b->[3] <=> $a->[3] } @results) {
          printf "%-62s %7.1fms %7.1fms %+7.1fms\n", @$_;
        }
      '

    # line-level gaps in slowest run
    echo ""
    echo "=== SLOWEST RUN: LINE-LEVEL GAPS (>10ms) ==="
    echo "Shows the exact xtrace lines where the shell stalled."
    echo ""
    print_gaps "$SLOW_FILE" 10

  } > "$REPORT"

  # --- print summary to stdout ---
  head -12 "$REPORT"
  echo ""
  echo "=== DELTA (slow - fast, files that grew >5ms) ==="
  # Extract delta section from report
  sed -n '/^=== DELTA/,/^=== SLOWEST RUN: LINE/{ /^=== SLOWEST/d; p; }' "$REPORT" | tail -n +2

  echo ""
  echo "Full report: $REPORT"

  rm -rf "$TRACE_DIR"
  exit 0
fi

# --- single run mode ---------------------------------------------------

TRACE_LOG=$(mktemp /tmp/zsh-profiler.XXXXXX)

run_single_xtrace "$TRACE_LOG"

if "$RAW_MODE"; then
  echo "$TRACE_LOG"
  exit 0
fi

echo ""
print_file_table "$TRACE_LOG"
echo ""

rm -f "$TRACE_LOG"
