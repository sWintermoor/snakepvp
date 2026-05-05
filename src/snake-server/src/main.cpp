#include "server.h"
#include "config.h"
#include <iostream>
#include <cstdlib>

int main() {
    try {
        if (SHOW_COMMENTS) std::cout << "Universe: Starting WebSocket server..." << std::endl;
        WebSocketServer server;
        if (SHOW_COMMENTS) std::cout << "Universe: WebSocket server running on port 9092" << std::endl;
        server.run();
    }
    catch (std::exception const& e) {
        std::cerr << "Universe: Error: " << e.what() << std::endl;
        return EXIT_FAILURE;
    }
    return EXIT_SUCCESS;
}
