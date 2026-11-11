# PHP perf measurements on Loongson 3B6000M (LoongArch64)

Hardware-counter measurements collected while investigating
[loongson-community/discussions#122](https://github.com/loongson-community/discussions/issues/122),
which asks why the Loongson 3B6000 lands below a Raspberry Pi 500+ in Phoronix's
PHPBench result (257,848 vs 420,699 — a 1.63x gap, not 500x; "500+" in the title is the
Pi 500+ model name).

The goal here is not to reproduce Phoronix's score (this is an 8-core 3B6000M, not the
12-core/24-thread 3B6000, and PHP versions differ). The goal is to characterise the
single-thread microarchitecture on the same LA664 core, so the claim "PHP is slow on
LoongArch" can be checked against hard numbers.

## Headline result

Single-threaded, PHP 8.5.12 CLI, 10.3 s run:

| Metric | Value |
|---|---|
| IPC (instructions / cycles) | **2.20** |
| Branch-misses | **0.135 %** |
| Effective clock | **2.38 GHz** |
| Instructions executed | 54.0 G |
| Cycles | 24.6 G |
| Zend JIT | **Not Available** on LoongArch |
| CPU frequency scaling | **no cpufreq driver** (fixed 2.4 GHz, no boost) |

## Interpretation

- **0.135 % branch misses** rules out branch prediction as the cause: this workload is
  highly predictable on LA664.
- **IPC 2.20** is the interesting number. For an ARM Cortex-A76 to score 1.63x higher at
  the same 2.4 GHz, it would need roughly IPC 3.5 on the same code. A76 typically lands
  in the 2.6–3.2 range on interpreter-style integer code, which is consistent with the
  observed gap without invoking any PHP-specific defect.
- **2.38 GHz measured, no cpufreq interface** means there is no boost headroom to recover
  the difference; the core runs at a fixed 2.4 GHz regardless of load.
- **JIT is unavailable** (`JIT => Not Available`) while `PCRE JIT Target` is LoongArch —
  so PHP core gets no JIT on this ISA. Note that PHPBench/CLI runs with
  `opcache.enable_cli=0` by default, so JIT is not active on either platform and does
  not explain this particular result; it does mean real web workloads will diverge further.
- Enabling `opcache.enable_cli=1` changes cycles by only ~2 % (24.16 G vs 24.56 G), as
  expected for a single-shot CLI process.

## Caveats

- This is a **3B6000M (8 cores)**; Phoronix tested a **3B6000 (12 cores / 24 threads)**.
  Same LA664 core, different SKU and possibly different frequency policy.
- The benchmark is a **custom interpreter-style microbenchmark**, not PTS `phpbench 0.8.1`.
  Compare IPC and branch behaviour, not scores.
- PHP 8.5.12 here vs PHP 8.4 on Debian 13.
- `cache-references` / `dTLB-*` counters on this PMU return implausible values
  (0.045 % miss on 6.4 G references) and are deliberately excluded.

## Reproduce

Requires `perf` and `/proc/sys/kernel/perf_event_paranoid <= 2` (user-space counting).

```bash
# default (matches PHPBench CLI conditions: opcache off)
N=100 PHP=/path/to/php ./scripts/run-perf.sh

# with opcache enabled in CLI
N=100 PHP=/path/to/php PHP_OPTS="-d opcache.enable_cli=1" ./scripts/run-perf.sh
```

On a Raspberry Pi 500+ (or any reference machine), run the same command. The script
prints cycles, instructions, IPC, effective clock, and branch-miss rate, so the two
machines can be compared directly.

## Files

```
bench/php_bench.php                  the workload (N=100 ≈ 10 s on 3B6000M)
scripts/run-perf.sh                  perf wrapper, prints IPC / clock / branch stats
results/raw/loongson-3b6000m-n100.txt          default run
results/raw/loongson-3b6000m-n100-opcache.txt  opcache.enable_cli=1
results/raw/system.txt                         CPU, kernel, PHP, cpupower, perf config
```
