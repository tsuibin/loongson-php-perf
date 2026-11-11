<?php
// Single-threaded interpreter-heavy microbenchmark, in the spirit of PHPBench 0.8.1.
// Mixes: array/hash updates, string append + compare, recursion, method dispatch, float math.
// Usage: php php_bench.php [N]   (N=100 ≈ 10 s on a Loongson 3B6000M @ 2.4 GHz)
$N = (int)($argv[1] ?? 1);
$t0 = microtime(true);

$data = [];
for ($i = 0; $i < 200000 * $N; $i++) {
    $k = 'k' . ($i % 997);
    $data[$k] = ($data[$k] ?? 0) + $i;
}

$s = '';
for ($i = 0; $i < 50000 * $N; $i++) $s .= chr(65 + ($i % 26));
$cmp = 0;
for ($i = 0; $i < 50000 * $N; $i++) if (strcmp($s, 'ABC') > 0) $cmp++;

function fib(int $n): int { return $n < 2 ? $n : fib($n - 1) + fib($n - 2); }
$f = fib(30);

class Counter { public int $x = 0; public function add(int $v): int { return $this->x += $v; } }
$c = new Counter();
for ($i = 0; $i < 200000 * $N; $i++) $c->add($i);

$acc = 0.0;
for ($i = 0; $i < 300000 * $N; $i++) $acc += sqrt($i + 1);

$t1 = microtime(true);
printf("N=%d time=%.3fs\n", $N, $t1 - $t0);
