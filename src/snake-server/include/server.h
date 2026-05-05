#pragma once
#include "session.h"
#include <optional>
#include <mutex>

class WebSocketServer {
private:
    net::io_context _ioc;
    tcp::acceptor _acceptor;
    std::optional<tcp::socket> first_socket;
    std::mutex _mutex;

public:
    WebSocketServer();
    void accept();
    void run();
};
