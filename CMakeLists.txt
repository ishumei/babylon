cmake_minimum_required(VERSION 3.14)

project(babylon VERSION 1.2.3)

include(CTest)                      # for BUILD_TESTING option
include(CMakePackageConfigHelpers)  # for write_basic_package_version_file

option(BUILD_DEPS "Use FetchContent download and build dependencies" OFF)

if(BUILD_DEPS)
  include(FetchContent)
  FetchContent_Declare(
    googletest
    URL "https://github.com/google/googletest/archive/refs/tags/release-1.12.1.tar.gz"
    URL_HASH SHA256=81964fe578e9bd7c94dfdb09c8e4d6e6759e19967e397dbea48d1c10e45d0df2
  )
  if(BUILD_TESTING AND CMAKE_SOURCE_DIR STREQUAL CMAKE_CURRENT_SOURCE_DIR)
    FetchContent_MakeAvailable(googletest)
  endif()
endif()

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=gnu++1y")
add_subdirectory(third-party/abseil-cpp)

include(${CMAKE_CURRENT_SOURCE_DIR}/cmake/babylon-deps.cmake)

if(BUILD_TESTING AND CMAKE_SOURCE_DIR STREQUAL CMAKE_CURRENT_SOURCE_DIR)
  if(NOT TARGET GTest::gtest_main)
    find_package(GTest REQUIRED)
  endif()
endif()

file(GLOB_RECURSE BABYLON_SRCS "${CMAKE_CURRENT_SOURCE_DIR}/src/babylon/*.cpp")
add_library(babylon "${BABYLON_SRCS}")
add_library(babylon::babylon ALIAS babylon)
target_include_directories(babylon PUBLIC
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/src>
  $<INSTALL_INTERFACE:include>)
target_link_libraries(babylon absl::base absl::flat_hash_map absl::str_format)
set_source_files_properties(
  "${CMAKE_CURRENT_SOURCE_DIR}/src/babylon/reusable/message.trick.cpp"
  "${CMAKE_CURRENT_SOURCE_DIR}/src/babylon/reusable/patch/arena.cpp"
  PROPERTIES COMPILE_FLAGS "-fno-access-control")

if(NOT BUILD_DEPS AND CMAKE_SOURCE_DIR STREQUAL CMAKE_CURRENT_SOURCE_DIR)
  install(TARGETS babylon EXPORT babylon)
  install(DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/src/babylon"
    DESTINATION include
    FILES_MATCHING
      PATTERN "*.h"
      PATTERN "*.hpp")
  install(EXPORT babylon
    FILE babylon-targets.cmake
    NAMESPACE babylon::
    DESTINATION "lib/cmake/babylon")
  install(FILES "${CMAKE_CURRENT_SOURCE_DIR}/cmake/babylon-config.cmake"
    DESTINATION "lib/cmake/babylon")
  install(FILES "${CMAKE_CURRENT_SOURCE_DIR}/cmake/babylon-deps.cmake"
    DESTINATION "lib/cmake/babylon")
  write_basic_package_version_file(
    "babylon-config-version.cmake"
    COMPATIBILITY SameMinorVersion
  )
  install(FILES "${CMAKE_CURRENT_BINARY_DIR}/babylon-config-version.cmake"
    DESTINATION "lib/cmake/babylon")
endif()

if(BUILD_TESTING AND CMAKE_SOURCE_DIR STREQUAL CMAKE_CURRENT_SOURCE_DIR)
  include(GoogleTest)   # for gtest_discover_tests
  file(GLOB_RECURSE BABYLON_TEST_SRCS "${CMAKE_CURRENT_SOURCE_DIR}/test/test_*.cpp")
  list(FILTER BABYLON_TEST_SRCS EXCLUDE REGEX "test/test_string_view.cpp")
  foreach(SRC ${BABYLON_TEST_SRCS})
    string(REPLACE "${CMAKE_CURRENT_SOURCE_DIR}" "" TARGET_NAME ${SRC})
    string(REPLACE "/" "_" TARGET_NAME ${TARGET_NAME})
    string(REPLACE "." "_" TARGET_NAME ${TARGET_NAME})
    add_executable("${TARGET_NAME}" "${SRC}")
    target_include_directories("${TARGET_NAME}" PRIVATE "${CMAKE_CURRENT_BINARY_DIR}")
    target_include_directories("${TARGET_NAME}" PRIVATE "${CMAKE_CURRENT_BINARY_DIR}/proto")
    target_link_libraries("${TARGET_NAME}" babylon)
    target_link_libraries("${TARGET_NAME}" GTest::gtest_main)
    gtest_discover_tests("${TARGET_NAME}")
  endforeach()

  add_executable(test_string_view
    "${CMAKE_CURRENT_SOURCE_DIR}/test/test_string_view.cpp"
    "${CMAKE_CURRENT_SOURCE_DIR}/test/test_string_view_in_lib.cpp")
  target_link_libraries(test_string_view babylon)
  target_link_libraries(test_string_view GTest::gtest_main)
  gtest_discover_tests(test_string_view)
endif()
