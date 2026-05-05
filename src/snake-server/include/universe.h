#pragma once
#include "snake.h"
#include "fruit.h"
#include <list>
#include <string>
#include <tuple>
#include <memory>

class Universe {
private:
    Snake _snake1;
    Snake _snake2;
    Fruits _fruits;
    std::string _gameState;

public:
    Universe(Snake snake1, Snake snake2, Fruits fruits);

    static std::unique_ptr<Universe> createDefault();

    bool universeTick(bool timerPermission);
    bool checkBooster(Snake* snake);
    int checkCollisions();
    int checkFruit(Snake* snake);
    void spawnFruits();
    void updateSnakeDirection(int id, std::string key);

    std::tuple<
        std::list<std::pair<int,int>>,
        std::list<std::pair<int,int>>,
        std::list<std::string>,
        std::list<int>,
        std::list<int>,
        std::string,
        std::string
    > finalMessageToSend();

    std::tuple<
        std::list<std::pair<int,int>>,
        std::list<std::pair<int,int>>,
        std::list<std::string>,
        std::list<int>,
        std::list<int>,
        std::string,
        std::string,
        int, int, int,
        std::string,
        int, int, int,
        std::string
    > getStatusWhileRunning();
};
