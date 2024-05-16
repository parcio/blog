#include <benchmark/benchmark.h>
#include "sum.hpp"

static void BM_Sum(benchmark::State& state) {
  for (auto _ : state) {
    benchmark::DoNotOptimize(sum(state.range(0), state.range(1)));
  }
  state.SetComplexityN(state.range(0) + state.range(1));
}

BENCHMARK(BM_Sum)->Args({1, 2})->Args({10, 20})->Complexity();

BENCHMARK_MAIN();
