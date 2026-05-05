#include "session.h"
#include "config.h"
#include <nlohmann/json.hpp>
#include <iostream>
#include <thread>
#include <chrono>

using json = nlohmann::json;

Session::Session(tcp::socket socket1, tcp::socket socket2, int timerInput) :
    _ws1(std::move(socket1)),
    _ws2(std::move(socket2)),
    _timer(timerInput),
    _universe(nullptr) {}

void Session::do_write1() {
    bool should_write = false;
    {
        if (SHOW_COMMENTS) std::cout << "Universe: Locking writing for Client1" << std::endl;
        std::lock_guard<std::mutex> lock(_write_mutex1);
        if (SHOW_COMMENTS) std::cout << "Universe: do_write1: Queue size = " << _write_queue1.size() << ", writing = " << _writing1 << std::endl;
        if (!_write_queue1.empty() && !_writing1) {
            _writing1 = true;
            should_write = true;
        }
    }

    if (should_write) {
        if (SHOW_COMMENTS) std::cout << "Universe: do_write1: Starting async_write" << std::endl;
        auto self = shared_from_this();
        _ws1.async_write(
            net::buffer(_write_queue1.front()),
            [self](beast::error_code ec, std::size_t bytes) {
                if (SHOW_COMMENTS) std::cout << "Universe: do_write1: async_write completed, ec = " << ec.message() << std::endl;
                bool check_next = false;
                {
                    std::lock_guard<std::mutex> lock(self->_write_mutex1);
                    if (ec) {
                        std::cerr << "Universe: do_write1 error: "
                            << ec.message()
                            << " (code: " << ec.value() << ")"
                            << std::endl;
                    }
                    else {
                        if (SHOW_COMMENTS) std::cout << "Universe: async_write_1 success." << std::endl;
                        self->_write_queue1.pop();
                    }
                    self->_writing1 = false;
                    check_next = !self->_write_queue1.empty();
                }
                if (check_next) {
                    net::post(self->_ws1.get_executor(), [self]() {
                        self->do_write1();
                    });
                }
            }
        );
    }
}

void Session::do_write2() {
    bool should_write = false;
    {
        if (SHOW_COMMENTS) std::cout << "Universe: Locking writing for Client2" << std::endl;
        std::lock_guard<std::mutex> lock(_write_mutex2);
        if (SHOW_COMMENTS) std::cout << "Universe: do_write2: Queue size = " << _write_queue2.size() << ", writing = " << _writing2 << std::endl;
        if (!_write_queue2.empty() && !_writing2) {
            _writing2 = true;
            should_write = true;
        }
    }

    if (should_write) {
        if (SHOW_COMMENTS) std::cout << "Universe: do_write2: Starting async_write" << std::endl;
        auto self = shared_from_this();
        _ws2.async_write(
            net::buffer(_write_queue2.front()),
            [self](beast::error_code ec, std::size_t bytes) {
                if (SHOW_COMMENTS) std::cout << "Universe: do_write2: async_write completed, ec = " << ec.message() << std::endl;
                bool check_next = false;
                {
                    std::lock_guard<std::mutex> lock(self->_write_mutex2);
                    if (ec) {
                        std::cerr << "Universe: do_write2 error: "
                             << ec.message()
                             << " (code: " << ec.value() << ")"
                             << std::endl;
                    }
                    else {
                        if (SHOW_COMMENTS) std::cout << "Universe: async_write_2 success." << std::endl;
                        self->_write_queue2.pop();
                    }
                    self->_writing2 = false;
                    check_next = !self->_write_queue2.empty();
                }
                if (check_next) {
                    net::post(self->_ws2.get_executor(), [self]() {
                        self->do_write2();
                    });
                }
            }
        );
    }
}

void Session::checkQueueAndScheduleNextTick() {
    bool schedule = false;
    {
        if (SHOW_COMMENTS) std::cout << "Universe: Locking for next tick" << std::endl;
        std::lock_guard<std::mutex> lock1(_write_mutex1);
        std::lock_guard<std::mutex> lock2(_write_mutex2);
        if (!_writing1 && !_writing2 &&
            _write_queue1.empty() && _write_queue2.empty() &&
            !_tickScheduled) {
            _tickScheduled = true;
            schedule = true;
        }
    }

    if (SHOW_COMMENTS) std::cout << "Universe: Unlocking for next tick" << std::endl;

    if (schedule) {
        net::post(_ws1.get_executor(), [self = shared_from_this()]() {
            self->_tickScheduled = false;
            self->sessionTick();
        });
    }
    else {
        if (SHOW_COMMENTS) std::cout << "Universe: Not scheduling next tick, already scheduled or writing in progress." << std::endl;
        net::post(_ws1.get_executor(), [self = shared_from_this()]() {
            self->checkQueueAndScheduleNextTick();
        });
    }
}

void Session::start() {
    auto self = shared_from_this();
    _ws1.async_accept(
        [self](beast::error_code ec) {
            if (!ec) {
                self->_ws2.async_accept(
                    [self](beast::error_code ec) {
                        if (!ec) {
                            if (SHOW_COMMENTS) std::cout << "Universe: Creating Universe Object" << std::endl;
                            self->_universe = Universe::createDefault();
                            self->read_client1();
                            self->read_client2();
                        }
                    }
                );
            }
        });
}

void Session::sessionTick() {
    if (_processingTick.exchange(true)) {
        if (SHOW_COMMENTS) std::cout << "Universe: Already processing tick, skipping this one." << std::endl;
        return;
    }

    try {
        std::this_thread::sleep_for(std::chrono::milliseconds(TICK_PAUSE));

        _timer -= 1;
        if (SHOW_COMMENTS) std::cout << "Universe: Beginn tick" << std::endl;

        if (_timer == 0) {
            _timer = TIMER_INITIAL;
        }

        if (_timer == 0) {
        }
        else {
            if (SHOW_COMMENTS) std::cout << "Universe: Timer: " << _timer << std::endl;
            bool timerPermission = (_timer % GAME_SPEED == 0);
            if (SHOW_COMMENTS) std::cout << "Universe: Timer permission: " << timerPermission << std::endl;
            bool endOfGame = _universe->universeTick(timerPermission);
            if (endOfGame) {
                if (SHOW_COMMENTS) std::cout << "Universe: Setting final score" << std::endl;
                setFinalScore();
            }
            else {
                std::cout << "Universe: Start to update clients" << std::endl;
                updateClients();
                auto self = shared_from_this();
                net::post(_ws1.get_executor(), [self]() {
                    if (SHOW_COMMENTS) std::cout << "Universe: Trying to start next tick" << std::endl;
                    self->checkQueueAndScheduleNextTick();
                });
            }
        }
    }
    catch (const std::exception& e) {
        std::cerr << "Universe: Error in sessionTick: " << e.what() << std::endl;
        _processingTick.store(false);
    }
    _processingTick.store(false);
}

void Session::setFinalScore() {
    std::list<std::pair<int, int>> snake1Coordinates;
    std::list<std::pair<int, int>> snake2Coordinates;
    std::list<std::string> fruitsTypes;
    std::list<int> fruitsX;
    std::list<int> fruitsY;
    std::string gameStatus1;
    std::string gameStatus2;

    std::tie(snake1Coordinates, snake2Coordinates, fruitsTypes, fruitsX, fruitsY, gameStatus1, gameStatus2) = _universe->finalMessageToSend();
    sendMessageClient(snake1Coordinates, snake2Coordinates, fruitsTypes, fruitsX, fruitsY, _timer, gameStatus1, gameStatus2);
}

void Session::updateClients() {
    std::list<std::pair<int, int>> snake1Coordinates;
    std::list<std::pair<int, int>> snake2Coordinates;
    std::list<std::string> fruitsTypes;
    std::list<int> fruitsX;
    std::list<int> fruitsY;
    std::string gameStatus1;
    std::string gameStatus2;
    int snake1Score, snake1Banana, snake1Blueberry, snake2Score, snake2Banana, snake2Blueberry;
    std::string snake1Direction;
    std::string snake2Direction;

    std::tie(snake1Coordinates, snake2Coordinates, fruitsTypes, fruitsX, fruitsY, gameStatus1, gameStatus2, snake1Score, snake1Banana, snake1Blueberry, snake1Direction, snake2Score, snake2Banana, snake2Blueberry, snake2Direction) = _universe->getStatusWhileRunning();
    sendMessageClient(snake1Coordinates, snake2Coordinates, fruitsTypes, fruitsX, fruitsY, _timer, gameStatus1, gameStatus2, snake1Score, snake1Banana, snake1Blueberry, snake1Direction, snake2Score, snake2Banana, snake2Blueberry, snake2Direction);
}

void Session::read_client1() {
    _ws1.async_read(
        _buffer1,
        [self = shared_from_this()](beast::error_code ec, std::size_t bytes) {
            if (!ec) {
                std::cout << "Universe: Reading messages from client 1" << std::endl;
                self->handleMessage(1, beast::buffers_to_string(self->_buffer1.data()));
                self->_buffer1.consume(self->_buffer1.size());
                std::cout << "Universe: Finished reading messages from client 1" << std::endl;
                self->read_client1();
            }
        });
}

void Session::read_client2() {
    _ws2.async_read(
        _buffer2,
        [self = shared_from_this()](beast::error_code ec, std::size_t bytes) {
            if (!ec) {
                std::cout << "Universe: Reading messages from client 2" << std::endl;
                self->handleMessage(2, beast::buffers_to_string(self->_buffer2.data()));
                self->_buffer2.consume(self->_buffer2.size());
                std::cout << "Universe: Finished reading messages from client 2" << std::endl;
                self->read_client2();
            }
        });
}

void Session::handleMessage(int id, const std::string& message) {
    std::cout << "Universe: handleMessage received: '" << message << "' from client '" << id << "'" << std::endl;
    try {
        json Data = json::parse(message);
        if (Data.contains("key") && Data["key"] == "start" && _gameStarted.exchange(true)) {
            if (SHOW_COMMENTS) std::cout << "Universe: Starting session for clients" << std::endl;
            checkQueueAndScheduleNextTick();
        }
        else {
            if (Data.contains("movement") && Data["movement"].is_string()) {
                std::cout << "Universe: Updating snake direction for client " << id << std::endl;
                _universe->updateSnakeDirection(id, Data["movement"]);
            }
        }
    }
    catch (const json::exception& e) {
        std::cerr << "Universe: JSON parsing error: " << e.what() << std::endl;
    }
}

void Session::sendMessageClient(std::list<std::pair<int,int>> snake1Coordinates, std::list<std::pair<int,int>> snake2Coordinates, std::list<std::string> fruitsTypes, std::list<int> fruitsX, std::list<int> fruitsY, int timer, std::string gameStatus1, std::string gameStatus2,
    int snake1Score, int snake1Banana, int snake1Blueberry, std::string snake1Direction, int snake2Score, int snake2Banana, int snake2Blueberry, std::string snake2Direction) {
    json message1 = {
        {"snake1Coordinates", snake1Coordinates},
        {"snake2Coordinates", snake2Coordinates},
        {"fruitsTypes", fruitsTypes},
        {"fruitsX", fruitsX},
        {"fruitsY", fruitsY},
        {"timer", timer},
        {"gameStatus", gameStatus1},
        {"apple1Score", snake1Score},
        {"banana1Score", snake1Banana},
        {"blueberry1Score", snake1Blueberry},
        {"direction1", snake1Direction},
        {"apple2Score", snake2Score},
        {"banana2Score", snake2Banana},
        {"blueberry2Score", snake2Blueberry},
        {"direction2", snake2Direction}
    };

    json message2 = {
        {"snake1Coordinates", snake1Coordinates},
        {"snake2Coordinates", snake2Coordinates},
        {"fruitsTypes", fruitsTypes},
        {"fruitsX", fruitsX},
        {"fruitsY", fruitsY},
        {"timer", timer},
        {"gameStatus", gameStatus2},
        {"apple1Score", snake1Score},
        {"banana1Score", snake1Banana},
        {"blueberry1Score", snake1Blueberry},
        {"direction1", snake1Direction},
        {"apple2Score", snake2Score},
        {"banana2Score", snake2Banana},
        {"blueberry2Score", snake2Blueberry},
        {"direction2", snake2Direction}
    };

    if (SHOW_COMMENTS) std::cout << "Universe: Pushing message for client 1 to _write_queue1" << std::endl;
    {
        std::lock_guard<std::mutex> lock(_write_mutex1);
        _write_queue1.push(message1.dump());
    }
    if (SHOW_COMMENTS) std::cout << "Universe: Pushing message for client 2 to _write_queue2" << std::endl;
    {
        std::lock_guard<std::mutex> lock(_write_mutex2);
        _write_queue2.push(message2.dump());
    }

    if (SHOW_COMMENTS) std::cout << "Universe: Starting writing operation for client 1" << std::endl;
    net::post(_ws1.get_executor(), [self = shared_from_this()]() {
        self->do_write1();
    });

    if (SHOW_COMMENTS) std::cout << "Universe: Starting writing operation for client 2" << std::endl;
    net::post(_ws2.get_executor(), [self = shared_from_this()]() {
        self->do_write2();
    });
}
