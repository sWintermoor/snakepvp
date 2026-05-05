#include "snake.h"
#include "config.h"
#include <iostream>
#include <algorithm>

Snake::Snake(int id, std::list<std::pair<int, int>> coordinates, std::string color,
             int boostDuration, int immunityDuration, std::string direction,
             int velocity, int score, int banana, int blueberry) :
    _id(id), _coordinates(coordinates), _color(color),
    _boostDuration(boostDuration), _immunityDuration(immunityDuration),
    _direction(direction), _velocity(velocity), _score(score),
    _banana(banana), _blueberry(blueberry) {}

void Snake::update(bool changeImmunityBooster, int fruitConsumption) {
    bool appleConsumption = (fruitConsumption == 0);
    modifyBooster(changeImmunityBooster);
    modifyImmunity(changeImmunityBooster);
    move(appleConsumption);
}

void Snake::modifyBooster(bool changeImmunityBooster) {
    if (_boostDuration > 0 && changeImmunityBooster) {
        _boostDuration -= 1;
    }
}

void Snake::changeBoost(int additionalBoostDuration) {
    if (_banana > 0) {
        _boostDuration += additionalBoostDuration;
        _banana -= 1;
    }
}

bool Snake::checkImmunity() {
    return getImmunityDuration() > 0;
}

void Snake::modifyImmunity(bool changeImmunityBooster) {
    if (_immunityDuration > 0 && changeImmunityBooster) {
        _immunityDuration -= 1;
    }
}

void Snake::move(bool appleConsumption) {
    std::pair<int, int> head = getHead();
    std::pair<int, int> newHead;

    if (_direction == "ArrowUp") {
        newHead = std::make_pair(head.first, ((head.second - 1*CELL_SIZE) + (GRID_SIZE * CELL_SIZE)) % (GRID_SIZE*CELL_SIZE));
    }
    else if (_direction == "ArrowDown") {
        newHead = std::make_pair(head.first, (head.second + 1*CELL_SIZE) % (GRID_SIZE*CELL_SIZE));
    }
    else if (_direction == "ArrowLeft") {
        int new_head_first = (head.first - 1*CELL_SIZE) % (GRID_SIZE*CELL_SIZE);
        if (new_head_first < 0) {
            new_head_first = GRID_SIZE*CELL_SIZE - CELL_SIZE;
        }
        newHead = std::make_pair(new_head_first, head.second);
    }
    else if (_direction == "ArrowRight") {
        newHead = std::make_pair((head.first + 1*CELL_SIZE) % (GRID_SIZE*CELL_SIZE), head.second);
    }

    _coordinates.push_front(newHead);
    std::cout << "Universe: Snake " << _id << " current direction: " << _direction << std::endl;

    if (!appleConsumption) {
        if (SHOW_COMMENTS) std::cout << "Universe: Remove last coordinates of snake" << std::endl;
        _coordinates.pop_back();
    }
}

void Snake::setDirection(std::string newDirection) { _direction = newDirection; }
void Snake::setScore(int newScore) { _score = newScore; }
void Snake::setBanana(int newBanana) { _banana = newBanana; }
void Snake::setBlueberry(int newBlueberry) { _blueberry = newBlueberry; }

std::pair<int, int> Snake::getHead() { return _coordinates.front(); }
std::list<std::pair<int, int>> Snake::getCoordinates() { return _coordinates; }
int Snake::getBoostDuration() { return _boostDuration; }
int Snake::getImmunityDuration() { return _immunityDuration; }
int Snake::getScore() { return _score; }
int Snake::getBanana() { return _banana; }
int Snake::getBlueberry() { return _blueberry; }
std::string Snake::getDirection() { return _direction; }
