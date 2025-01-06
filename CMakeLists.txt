cmake_minimum_required(VERSION 3.15)
project(snake_game)

add_definitions(-D_WIN32_WINNT=0x0601)

set(CMAKE_CXX_STANDARD 17)

# Add vcpkg toolchain file
set(CMAKE_TOOLCHAIN_FILE "C:/Users/Mark Oliver/Desktop/Projekt/SnakePvPProjekt/snakepvp/vcpkg/scripts/buildsystems/vcpkg.cmake")

# Find Boost and nlohmann_json
find_package(Boost REQUIRED)
find_package(nlohmann_json CONFIG REQUIRED)

add_executable(universe 
    snake-server/universe.cpp
)

target_link_libraries(universe PRIVATE
    Boost::beast
    nlohmann_json::nlohmann_json
)