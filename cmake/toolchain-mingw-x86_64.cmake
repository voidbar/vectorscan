# MinGW-w64 toolchain file for cross-compiling to Windows x86_64
set(CMAKE_SYSTEM_NAME Windows)
set(CMAKE_SYSTEM_PROCESSOR x86_64)

# specify the cross compiler
set(CMAKE_C_COMPILER x86_64-w64-mingw32-gcc-posix)
set(CMAKE_CXX_COMPILER x86_64-w64-mingw32-g++-posix)
set(CMAKE_AR x86_64-w64-mingw32-gcc-ar-posix CACHE FILEPATH "ar")
set(CMAKE_RANLIB x86_64-w64-mingw32-gcc-ranlib-posix CACHE FILEPATH "ranlib")

# where is the target environment
set(CMAKE_FIND_ROOT_PATH /usr/x86_64-w64-mingw32)

# search for programs in the build host directories
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
# for libraries and headers in the target directories
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

# Boost headers location (extracted to project root)
set(Boost_INCLUDE_DIR ${PROJECT_SOURCE_DIR}/boost)

# Architecture settings for x86_64
set(GNUCC_ARCH "x86-64")
set(TUNE_FLAG "generic")
