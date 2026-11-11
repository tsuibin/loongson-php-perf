# Raw results — Loongson 3B6000M

Collected 2026-11-11 on AOSC OS 14.0.1, kernel 7.1.13-aosc-main-16k, PHP 8.5.12 (NTS).

## Default (opcache.enable_cli=0)

```
cycles        24,561,084,659
instructions  54,023,984,354
IPC           2.20
clock         2.38 GHz
branches      9,306,610,350
branch-misses 12,593,758 (0.135%)
```

## opcache.enable_cli=1

```
cycles        24,159,985,082
instructions  53,279,262,746
IPC           2.21
clock         2.38 GHz
branches      9,197,061,224
branch-misses 10,024,848 (0.109%)
```

## Notes

- `task-clock` ≈ wall time, `user` ≈ wall time: the benchmark is single-threaded, so the
  8 available cores play no role.
- Effective clock never moves (2.38 GHz measured against a 2,400 MHz nominal) because the
  platform exposes no cpufreq driver.
- A shorter N=10 run gives IPC 2.08 and 0.63 % branch-misses: at that size the fixed
  `fib(30)` recursion dominates, which is more branch-heavy than the loop sections.
  N=100 is the reported configuration.
