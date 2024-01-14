project(
  'benchmarks',
  'cpp',
  default_options : [
    'b_lto=true',
    'buildtype=release',
    'warning_level=3',
    'cpp_std=c++17',
  ],
)
executable('simple_micro', 'simple_micro.cpp')
executable('monte_carlo', 'monte_carlo.cpp')
benchmark = dependency('benchmark', version : '>=1.3.0', required : false)
if benchmark.found()
  executable('google_micro', 'google_micro.cpp', dependencies : benchmark)
endif
