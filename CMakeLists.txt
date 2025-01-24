cmake_minimum_required(VERSION 3.15)
project(snake_game)

# Set CMake policies
cmake_policy(SET CMP0144 NEW)
cmake_policy(SET CMP0167 NEW)

set(CMAKE_CXX_STANDARD 17)
add_definitions(-D_WIN32_WINNT=0x0601)

# Set vcpkg toolchain before any find_package calls
set(CMAKE_TOOLCHAIN_FILE "" 
    CACHE STRING "Vcpkg toolchain file")

find_package(Boost REQUIRED COMPONENTS system thread beast)

add_executable(universe 
    snake-server/universe.cpp
)

target_include_directories(universe PRIVATEs
    ${Boost_INCLUDE_DIRS}
)

target_link_libraries(universe PRIVATE
    Boost::beast
    Boost::system
    nlohmann_json::nlohmann_json
)