cmake_minimum_required(VERSION 3.16)

project(
    fcitx5-status
    VERSION 1.0.0
    LANGUAGES CXX
)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

find_package(
    Fcitx5Core REQUIRED
)

add_library(
    fcitx5-status
    SHARED
    status.cpp
)

target_link_libraries(
    fcitx5-status
    PRIVATE
    Fcitx5::Core
)

set_target_properties(
    fcitx5-status
    PROPERTIES
    PREFIX ""
)

configure_file(
    fcitx5-status.conf.in
    fcitx5-status.conf
    @ONLY
)

install(
    TARGETS fcitx5-status
    LIBRARY DESTINATION lib/fcitx5
)

install(
    FILES
        ${CMAKE_CURRENT_BINARY_DIR}/fcitx5-status.conf
    DESTINATION
        share/fcitx5/addon
)
