#pragma once
#include "universe.h"
#include "net_aliases.h"
#include <memory>
#include <queue>
#include <mutex>
#include <atomic>
#include <string>
#include <list>
#include <utility>

class Session : public std::enable_shared_from_this<Session> {
private:
    websocket::stream<tcp::socket> _ws1;
    websocket::stream<tcp::socket> _ws2;
    beast::flat_buffer _buffer1;
    beast::flat_buffer _buffer2;
    std::unique_ptr<Universe> _universe;
    int _timer;
    std::queue<std::string> _write_queue1;
    std::queue<std::string> _write_queue2;
    bool _writing1 = false;
    bool _writing2 = false;
    std::mutex _write_mutex1;
    std::mutex _write_mutex2;
    std::atomic<bool> _tickScheduled{false};
    std::atomic<bool> _processingTick{false};
    std::atomic<bool> _gameStarted{false};

    void do_write1();
    void do_write2();
    void checkQueueAndScheduleNextTick();

public:
    explicit Session(tcp::socket socket1, tcp::socket socket2, int timerInput);

    void start();
    void sessionTick();
    void setFinalScore();
    void updateClients();
    void read_client1();
    void read_client2();
    void handleMessage(int id, const std::string& message);
    void sendMessageClient(
        std::list<std::pair<int,int>> snake1Coordinates,
        std::list<std::pair<int,int>> snake2Coordinates,
        std::list<std::string> fruitsTypes,
        std::list<int> fruitsX,
        std::list<int> fruitsY,
        int timer,
        std::string gameStatus1,
        std::string gameStatus2,
        int snake1Score = 2,
        int snake1Banana = 0,
        int snake1Blueberry = 0,
        std::string snake1Direction = "ArrowRight",
        int snake2Score = 2,
        int snake2Banana = 0,
        int snake2Blueberry = 0,
        std::string snake2Direction = "ArrowLeft"
    );
};
