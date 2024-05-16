#include <iostream>
#include <random>

int main() {
  std::random_device rd;
  std::mt19937 gen(rd());
  std::uniform_real_distribution<> dis(-1.0, 1.0);

  const size_t num_points = 10000000;
  size_t num_points_inside_circle = 0;

  for (size_t i = 0; i < num_points; ++i) {
    const double x = dis(gen);
    const double y = dis(gen);
    if (x * x + y * y <= 1.0) {
      ++num_points_inside_circle;
    }
  }

  const double pi = 4.0 * num_points_inside_circle / num_points;
  std::cout << "Pi: " << pi << '\n';

  return 0;
}
