#include <chrono>
#include <iostream>
#include "sum.hpp"

using namespace std::chrono;

const int iterations = 100000000;

int main() {
  // Benchmark sum(1, 2)
  auto start = steady_clock::now();
  for (int i = 0; i < iterations; i++) {
    sum(1, 2);
  }
  auto end = steady_clock::now();
  auto duration = duration_cast<microseconds>(end - start).count();
  std::cout << "sum(1, 2) took " << duration << " microseconds" << std::endl;

  // Benchmark sum(10, 20)
  start = steady_clock::now();
  for (int i = 0; i < iterations; i++) {
    sum(10, 20);
  }
  end = steady_clock::now();
  duration = duration_cast<microseconds>(end - start).count();
  std::cout << "sum(10, 20) took " << duration << " microseconds" << std::endl;

  return 0;
}
