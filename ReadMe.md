# libsg_cmake

A collection of CMake modules. Provides opinionated defaults (warnings,
RPATH, sanitizers, IPO, SSE/AVX detection, coverage, Doxygen) and a
`setup_target()` helper that wraps the usual
`add_library`/`add_executable` boilerplate.

## Usage

Add as a submodule (for example under e.g. `cmake/`) and prepend it to
`CMAKE_MODULE_PATH`. Then include the `DefaultPreamble` and
`DefaultPostamble` at the start and end of your CMake script.

```cmake
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}/cmake")

include(DefaultPreamble)
# ... project targets ...
include(DefaultPostamble)
```

`DefaultPreamble` recurses into `external/sanitizers-cmake` and expects it to
be checked out, so clone with `--recurse-submodules`.

### Defining targets

Use `setup_library`, `setup_executable`, or `setup_interface` (all thin
wrappers around `setup_target`):

As an example

```cmake
setup_library(
  TARGET    common
  NAMESPACE testnamespace
  DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}

  SOURCES_PRIVATE      src/foo.cpp ...
  INCLUDE_PUBLIC       ...
  LINK_PUBLIC          fmt::fmt Boost::boost
  LINK_PRIVATE         Threads::Threads
  COMPILE_FEATURES_PUBLIC cxx_std_20
  COMPILE_DEFINITIONS_PUBLIC ...

  GENERATE_EXPORT_HEADER  # writes <ns>/export/<target>.h
)
```

The helper creates an `testnamespace::common` alias, sets
`VERSION`/`SOVERSION` from `PROJECT_VERSION`, wires sanitizers, optional
`clang-tidy`, coverage, and per-target Doxygen, and installs
headers/binaries when the relevant `INSTALL_*` flag is on. Pass
`STATIC`/`SHARED` to force a library kind, `RECURSE_SRC_DIR` to glob
`<dir>/src/*.{c,cc,cpp}`, or `INTERFACE` for header-only libraries.

## Project-wide options

Set in `DefaultPreamble`; flip from the cache or parent project.

| Option                                    | Default              | Effect                                          |
|-------------------------------------------|----------------------|-------------------------------------------------|
| `BUILD_SHARED_LIBS`                       | `ON`                 | Shared vs static libraries                      |
| `USE_STATIC_LIBS`                         | `!BUILD_SHARED_LIBS` | Prefer `.a`/`.lib` when searching               |
| `USE_STATIC_RUNTIME` (MSVC)               | `USE_STATIC_LIBS`    | `/MT[d]` MSVC runtime                           |
| `IPO`                                     | `OFF`                | Link-time / interprocedural optimisation        |
| `ARCH_NATIVE`                             | `OFF`                | `-march=native` (or full SSE set on MSVC)       |
| `USE_SSE`                                 | `ARCH_NATIVE`        | Require SSE4.2, AVX2, CLMUL / ARM_CRC, ARM_SHA3 |
| `USE_LIBC++`                              | `OFF`                | Force libc++ (Clang only)                       |
| `SANITIZE`                                | `OFF`                | Enables address + UB sanitizers                 |
| `USE_LINTING`                             | `OFF`                | Run `clang-tidy` per target                     |
| `COVERAGE`                                | `OFF`                | Clang source-based coverage                     |
| `BUILD_DOCS`                              | `OFF`                | Build Doxygen target with the awesome-css theme |
| `INSTALL_<project>_HEADERS` / `_BINARIES` | top-level            | Per-project install gates                       |

`DefaultPreamble` also exports `compile_commands.json`, sets sensible
`INSTALL_RPATH` (`$ORIGIN`, `@loader_path`), detects the CPU arch, picks
the standard-library name (`libstdc++`/`libc++`), pulls in CPM,
configures `CMP0069`/`CMP0091`/`CMP0135`, and generates
`<binary>/include/<ns>/export/<project>_version.h` from `version.h.in`.

**Find modules**
- `FindLabVIEW.cmake`, `FindVISA.cmake` — National Instruments toolkits.
- `Findlibpqxx.cmake` — falls back to `pkg-config` when no `libpqxx-config`.
- `Findlibuv.cmake` — full-featured find module with `libuv::libuv` target.
