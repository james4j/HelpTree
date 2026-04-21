cmake_minimum_required(VERSION 3.16)
project(HelpTree CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(CLI11 REQUIRED)

# Header-only library
add_library(help_tree INTERFACE)
target_include_directories(help_tree INTERFACE
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/src>
)

# Examples
add_executable(basic examples/basic.cpp)
target_link_libraries(basic PRIVATE help_tree CLI11::CLI11)

add_executable(deep examples/deep.cpp)
target_link_libraries(deep PRIVATE help_tree CLI11::CLI11)

add_executable(hidden examples/hidden.cpp)
target_link_libraries(hidden PRIVATE help_tree CLI11::CLI11)

set_target_properties(basic deep hidden PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/examples
)
