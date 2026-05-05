#include "server.h"
#include "config.h"
#include <iostream>

WebSocketServer::WebSocketServer() :
    _acceptor(_ioc, tcp::endpoint(tcp::v4(), 9092)) {
    accept();
}

void WebSocketServer::accept() {
    _acceptor.async_accept(
        [this](beast::error_code ec, tcp::socket socket) {
            try {
                auto remote = socket.remote_endpoint();
                if (SHOW_COMMENTS) std::cout << "Universe: Connection from " << remote.address().to_string()
                          << ":" << remote.port() << std::endl;
            } catch (std::exception& e) {
                std::cerr << "Universe: Failed to get remote endpoint: " << e.what() << std::endl;
            }
            if (!ec) {
                std::lock_guard<std::mutex> lock(_mutex);
                if (!first_socket) {
                    first_socket.emplace(std::move(socket));
                    if (SHOW_COMMENTS) std::cout << "Universe: First player connected" << std::endl;
                }
                else {
                    if (SHOW_COMMENTS) std::cout << "Universe: Second player connected" << std::endl;
                    auto session = std::make_shared<Session>(
                        std::move(*first_socket),
                        std::move(socket),
                        TIMER_INITIAL
                    );
                    session->start();
                    first_socket.reset();
                }
            }
            accept();
        });
}

void WebSocketServer::run() {
    _ioc.run();
}
