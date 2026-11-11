#!/usr/bin/env bash
# Run the benchmark under perf and print IPC / branch-miss rate / effective clock.
# Usage:
#   N=100 PHP=/path/to/php ./scripts/run-perf.sh
#   N=100 PHP=/path/to/php PHP_OPTS="-d opcache.enable_cli=1" ./scripts/run-perf.sh
set -euo pipefail
PHP="${PHP:-php}"
PHP_OPTS="${PHP_OPTS:-}"
N="${N:-100}"
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="$(mktemp)"

read -ra OPTS <<< "$PHP_OPTS"
perf stat -x, -e task-clock,cycles,instructions,branches,branch-misses \
  "$PHP" "${OPTS[@]}" "$DIR/bench/php_bench.php" "$N" > /dev/null 2> "$OUT" || true

python3 - "$OUT" <<'EOF'
import sys

vals = {}
for line in open(sys.argv[1]):
    parts = line.strip().split(",")
    if len(parts) >= 3 and parts[0]:
        try:
            vals[parts[2]] = float(parts[0])
        except ValueError:
            pass

def get(name):
    return vals.get(name + ":u") or vals.get(name)

cyc, ins = get("cycles"), get("instructions")
br, bm = get("branches"), get("branch-misses")
tc = get("task-clock")  # milliseconds

if not cyc or not ins:
    print("perf produced no counter data - check /proc/sys/kernel/perf_event_paranoid (<=2 allows user-space counting)")
    sys.exit(1)

print(f"cycles        {cyc:,.0f}")
print(f"instructions  {ins:,.0f}")
print(f"IPC           {ins / cyc:.2f}")
if tc:
    print(f"clock         {cyc / (tc / 1000) / 1e9:.2f} GHz")
if br and bm:
    print(f"branches      {br:,.0f}")
    print(f"branch-misses {bm:,.0f} ({bm / br * 100:.3f}%)")
EOF
rm -f "$OUT"
