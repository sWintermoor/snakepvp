cmake_minimum_required(VERSION 3.15)
project(snake_game)

# Set C++ Standard
set(CMAKE_CXX_STANDARD 17)

# Set CMake policies
cmake_policy(SET CMP0144 NEW) # For fine-grained interface and implementation visibility
cmake_policy(SET CMP0167 NEW) # Fix for FindBoost policy deprecation

# Define the vcpkg toolchain file
# Make sure the path to the vcpkg toolchain file is correctly set
set(CMAKE_TOOLCHAIN_FILE "C:/Users/Mark Oliver/Desktop/Projekt/SnakePvPProjekt/snakepvp/vcpkg/scripts/buildsystems/vcpkg.cmake" 
    CACHE STRING "Vcpkg toolchain file")

# Ensure compatibility for Windows
if(WIN32)
    add_definitions(-D_WIN32_WINNT=0x0601)
endif()

# Find required packages
find_package(Boost REQUIRED COMPONENTS beast system thread)
find_package(nlohmann_json REQUIRED)

# Define the executable
add_executable(universe
    src/main.cpp
    src/fruit.cpp
    src/snake.cpp
    src/universe.cpp
    src/session.cpp
    src/server.cpp
)

if(WIN32)
    target_compile_options(universe PRIVATE /bigobj)
endif()

# Add include directories
target_include_directories(universe PRIVATE
    ${Boost_INCLUDE_DIRS}
    include
)

# Link libraries
target_link_libraries(universe PRIVATE
    Boost::beast
    Boost::system
    Boost::thread
    nlohmann_json::nlohmann_json
)