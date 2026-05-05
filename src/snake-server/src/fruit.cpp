#include "fruit.h"
#include <algorithm>

Fruit::Fruit(std::string type, int x, int y) :
    _type(type), _x(x), _y(y) {}

std::string Fruit::getType() { return _type; }
int Fruit::getX() { return _x; }
int Fruit::getY() { return _y; }

bool Fruit::operator==(const Fruit& other) const {
    return _type == other._type && _x == other._x && _y == other._y;
}

bool Fruit::operator!=(const Fruit& other) const {
    return !(*this == other);
}

Fruits::Fruits(Fruit fruit) {
    _fruits.push_back(fruit);
    _fruitsTypes.push_back(fruit.getType());
    _fruitsX.push_back(fruit.getX());
    _fruitsY.push_back(fruit.getY());
    _fruitCoordinates.push_back(std::make_pair(fruit.getX(), fruit.getY()));
}

void Fruits::addFruit(Fruit fruit) {
    _fruits.push_back(fruit);
    _fruitsTypes.push_back(fruit.getType());
    _fruitsX.push_back(fruit.getX());
    _fruitsY.push_back(fruit.getY());
    _fruitCoordinates.push_back(std::make_pair(fruit.getX(), fruit.getY()));
}

bool Fruits::tryRemoveFruit(Fruit fruit) {
    std::list<Fruit>::iterator it = std::find(_fruits.begin(), _fruits.end(), fruit);
    if (it != _fruits.end()) {
        int index = std::distance(_fruits.begin(), it);
        _fruits.erase(it);
        _fruitsTypes.erase(std::next(_fruitsTypes.begin(), index));
        _fruitsX.erase(std::next(_fruitsX.begin(), index));
        _fruitsY.erase(std::next(_fruitsY.begin(), index));
        _fruitCoordinates.erase(std::next(_fruitCoordinates.begin(), index));
        return true;
    }
    return false;
}

std::list<Fruit> Fruits::getFruits() { return _fruits; }
std::list<std::string> Fruits::getFruitsTypes() { return _fruitsTypes; }
std::list<int> Fruits::getFruitsX() { return _fruitsX; }
std::list<int> Fruits::getFruitsY() { return _fruitsY; }
std::list<std::pair<int, int>> Fruits::getFruitsCoordinates() { return _fruitCoordinates; }
