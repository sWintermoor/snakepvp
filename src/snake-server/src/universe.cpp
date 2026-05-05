#include "universe.h"
#include "config.h"
#include <iostream>
#include <cmath>
#include <algorithm>
#include <cstdlib>

Universe::Universe(Snake snake1, Snake snake2, Fruits fruits) :
    _snake1(snake1), _snake2(snake2), _fruits(fruits) {
    _gameState = "running";
}

std::unique_ptr<Universe> Universe::createDefault() {
    std::list<std::pair<int, int>> coords1 = {
        std::make_pair(CELL_SIZE * 1, CELL_SIZE * 0),
        std::make_pair(CELL_SIZE * 0, CELL_SIZE * 0)
    };
    std::list<std::pair<int, int>> coords2 = {
        std::make_pair(CELL_SIZE * GRID_SIZE - CELL_SIZE * 2, CELL_SIZE * GRID_SIZE - CELL_SIZE * 1),
        std::make_pair(CELL_SIZE * GRID_SIZE - CELL_SIZE * 1, CELL_SIZE * GRID_SIZE - CELL_SIZE * 1)
    };

    Snake snake1(1, coords1, "red", BOOST_DURATION_INITIAL, IMMUNITY_DURATION_INITIAL, "ArrowRight", VELOCITY_NORMAL, SCORE_INITIAL, BANANA_INITIAL, BLUEBERRY_INITIAL);
    Snake snake2(2, coords2, "blue", BOOST_DURATION_INITIAL, IMMUNITY_DURATION_INITIAL, "ArrowLeft", VELOCITY_NORMAL, SCORE_INITIAL, BANANA_INITIAL, BLUEBERRY_INITIAL);
    Fruit initialFruit("apple", (int)std::floor(CELL_SIZE * GRID_SIZE / 2.0), (int)std::floor(CELL_SIZE * GRID_SIZE / 2.0));

    return std::make_unique<Universe>(snake1, snake2, Fruits(initialFruit));
}

bool Universe::universeTick(bool timerPermission) {
    if (SHOW_COMMENTS) std::cout << "Universe: universeTick" << std::endl;
    if (checkCollisions() == -1) {
        if (SHOW_COMMENTS) std::cout << "Universe: No collision detected" << std::endl;

        if (timerPermission || checkBooster(&_snake1)) {
            if (SHOW_COMMENTS) std::cout << "Universe: Update Snake1 and Fruits" << std::endl;
            int updateConsumption = checkFruit(&_snake1);
            _snake1.update(timerPermission, updateConsumption);
            if (updateConsumption > -1) {
                if (SHOW_COMMENTS) std::cout << "Universe: Spawning fruits (snake1)" << std::endl;
                spawnFruits();
            }
        }
        if (timerPermission || checkBooster(&_snake2)) {
            if (SHOW_COMMENTS) std::cout << "Universe: Update Snake2 and Fruits" << std::endl;
            int updateConsumption = checkFruit(&_snake2);
            _snake2.update(timerPermission, updateConsumption);
            if (updateConsumption > -1) {
                if (SHOW_COMMENTS) std::cout << "Universe: Spawning fruits (snake2)" << std::endl;
                spawnFruits();
            }
        }
        return false;
    }
    else {
        if (SHOW_COMMENTS) std::cout << "Universe: Collision detected" << std::endl;
        return true;
    }
}

bool Universe::checkBooster(Snake* snake) {
    if (snake->getBoostDuration() > 0) {
        return true;
    }
    else {
        return false;
    }
}

int Universe::checkCollisions() {
    std::pair<int, int> head1 = _snake1.getHead();
    std::pair<int, int> head2 = _snake2.getHead();
    int collision = -1;

    if (head1.first == head2.first && head1.second == head2.second) {
        collision = 0;
    }
    else {
        std::list<std::pair<int, int>> body1 = _snake1.getCoordinates();
        std::list<std::pair<int, int>> body2 = _snake2.getCoordinates();
        body1.pop_front();
        body2.pop_front();

        if (!_snake1.checkImmunity() && (std::find(body1.begin(), body1.end(), head1) != body1.end())) {
            collision = 1;
        }
        if (!_snake2.checkImmunity() && (std::find(body2.begin(), body2.end(), head2) != body2.end())) {
            if (collision == 1) {
                collision = 0;
            }
            else {
                collision = 2;
            }
        }
        if (!_snake1.checkImmunity() && !_snake2.checkImmunity()) {
            if (std::find(body1.begin(), body1.end(), head2) != body1.end()) {
                if (collision == 1) {
                    collision = 0;
                }
                else {
                    collision = 2;
                }
            }
            if (std::find(body2.begin(), body2.end(), head1) != body2.end()) {
                if (collision == 2) {
                    collision = 0;
                }
                else {
                    collision = 1;
                }
            }
        }
    }
    return collision;
}

int Universe::checkFruit(Snake* snake) {
    std::pair<int, int> head = snake->getHead();
    int consumedFruit = -1;

    for (Fruit fruit : _fruits.getFruits()) {
        std::cout << "snakehead and fruit position: snakehead: " << head.first << ", " << head.second << "; fruit: " << (fruit.getX() - FRUIT_SHIFT) << ", " << (fruit.getY() - FRUIT_SHIFT) << std::endl;

        if (head.first == (fruit.getX() - FRUIT_SHIFT) && head.second == (fruit.getY() - FRUIT_SHIFT)) {
            if (fruit.getType() == "apple") {
                snake->setScore(snake->getScore() + 1);
                consumedFruit = 0;
            }
            else if (fruit.getType() == "banana") {
                snake->setBanana(snake->getBanana() + 1);
                consumedFruit = 1;
            }
            else if (fruit.getType() == "blueberry") {
                snake->setBlueberry(snake->getBlueberry() + 1);
                consumedFruit = 2;
            }
            _fruits.tryRemoveFruit(fruit);
        }
    }
    return consumedFruit;
}

void Universe::spawnFruits() {
    std::cout << "Spawnging new fruit(s)" << std::endl;

    int random_numberX = rand();
    int random_numberY = rand();

    if (random_numberX < 0) {
        random_numberX = -1 * random_numberX;
    }
    if (random_numberY < 0) {
        random_numberY = -1 * random_numberY;
    }

    int randomX = (random_numberX % (GRID_SIZE)) * CELL_SIZE + (CELL_SIZE/2);
    int randomY = (random_numberY % (GRID_SIZE)) * CELL_SIZE + (CELL_SIZE/2);
    std::list<std::pair<int, int>> snake1Coordinates = _snake1.getCoordinates();
    std::list<std::pair<int, int>> snake2Coordinates = _snake2.getCoordinates();
    std::list<std::pair<int, int>> _fruitCoordinates = _fruits.getFruitsCoordinates();

    while (std::find(snake1Coordinates.begin(), snake1Coordinates.end(), std::make_pair(randomX - FRUIT_SHIFT, randomY - FRUIT_SHIFT)) != snake1Coordinates.end() || std::find(snake2Coordinates.begin(), snake2Coordinates.end(), std::make_pair(randomX - FRUIT_SHIFT, randomY - FRUIT_SHIFT)) != snake2Coordinates.end() || std::find(_fruitCoordinates.begin(), _fruitCoordinates.end(), std::make_pair(randomX - FRUIT_SHIFT, randomY - FRUIT_SHIFT)) != _fruitCoordinates.end()) {
        int random_numberX = rand();
        int random_numberY = rand();

        if (random_numberX < 0) {
            random_numberX = -1 * random_numberX;
        }
        if (random_numberY < 0) {
            random_numberY = -1 * random_numberY;
        }

        int randomX = (random_numberX % (GRID_SIZE)) * CELL_SIZE + (CELL_SIZE/2);
        int randomY = (random_numberY % (GRID_SIZE)) * CELL_SIZE + (CELL_SIZE/2);
    }

    int randomFruit = rand() % 6;
    std::string fruitType1;
    std::string fruitType2;

    if (randomFruit == 0) {
        fruitType1 = "apple";
    }
    else if (randomFruit == 1) {
        fruitType1 = "banana";
    }
    else if (randomFruit == 2) {
        fruitType1 = "blueberry";
    }
    else if (randomFruit == 3) {
        fruitType1 = "apple";
        fruitType2 = "apple";
    }
    else if (randomFruit == 4) {
        fruitType1 = "apple";
        fruitType2 = "banana";
    }
    else if (randomFruit == 5) {
        fruitType1 = "apple";
        fruitType2 = "blueberry";
    }

    Fruit newFruit(fruitType1, randomX, randomY);
    _fruits.addFruit(newFruit);

    if (randomFruit > 2) {
        Fruit newFruit2(fruitType2, randomX, randomY);
        _fruits.addFruit(newFruit2);
    }
}

std::tuple<std::list<std::pair<int,int>>, std::list<std::pair<int,int>>, std::list<std::string>, std::list<int>, std::list<int>, std::string, std::string> Universe::finalMessageToSend() {
    int collisionStatus = checkCollisions();
    if (collisionStatus == -1 || collisionStatus == 0) {
        return {_snake1.getCoordinates(), _snake2.getCoordinates(), _fruits.getFruitsTypes(), _fruits.getFruitsX(), _fruits.getFruitsY(), "draw", "draw"};
    }
    else if (collisionStatus == 1) {
        return {_snake1.getCoordinates(), _snake2.getCoordinates(), _fruits.getFruitsTypes(), _fruits.getFruitsX(), _fruits.getFruitsY(), "lose", "win"};
    }
    else {
        return {_snake1.getCoordinates(), _snake2.getCoordinates(), _fruits.getFruitsTypes(), _fruits.getFruitsX(), _fruits.getFruitsY(), "win", "lose"};
    }
}

std::tuple<std::list<std::pair<int,int>>, std::list<std::pair<int,int>>, std::list<std::string>, std::list<int>, std::list<int>, std::string, std::string, int, int, int, std::string, int, int, int, std::string> Universe::getStatusWhileRunning() {
    std::list<std::pair<int, int>> snake1Coordinates = _snake1.getCoordinates();
    std::list<std::pair<int, int>> snake2Coordinates = _snake2.getCoordinates();
    int snake1Score = _snake1.getScore();
    int snake1Banana = _snake1.getBanana();
    int snake1Blueberry = _snake1.getBlueberry();
    int snake2Score = _snake2.getScore();
    int snake2Banana = _snake2.getBanana();
    int snake2Blueberry = _snake2.getBlueberry();
    std::string snake1Direction = _snake1.getDirection();
    std::string snake2Direction = _snake2.getDirection();
    return {snake1Coordinates, snake2Coordinates, _fruits.getFruitsTypes(), _fruits.getFruitsX(), _fruits.getFruitsY(), "running", "running", snake1Score, snake1Banana, snake1Blueberry, snake1Direction, snake2Score, snake2Banana, snake2Blueberry, snake2Direction};
}

void Universe::updateSnakeDirection(int id, std::string key) {
    std::cout << "Universe: Setting new movement:" << key << std::endl;
    if (id == 1) {
        if (key == "ArrowUp" || key == "ArrowDown" || key == "ArrowLeft" || key == "ArrowRight") {
            std::cout << "Universe: New Snake " << id << " direction: " << key << std::endl;
            _snake1.setDirection(key);
        }
        else if (key == "w") {
            _snake1.changeBoost(BOOST_DURATION);
        }
    }
    else if (id == 2) {
        if (key == "ArrowUp" || key == "ArrowDown" || key == "ArrowLeft" || key == "ArrowRight") {
            _snake2.setDirection(key);
        }
        else if (key == "w") {
            _snake2.changeBoost(BOOST_DURATION);
        }
    }
}
