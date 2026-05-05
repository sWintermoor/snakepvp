#pragma once
#include <list>
#include <string>
#include <utility>

class Fruit {
private:
    std::string _type;
    int _x;
    int _y;

public:
    Fruit(std::string type, int x, int y);

    std::string getType();
    int getX();
    int getY();

    bool operator==(const Fruit& other) const;
    bool operator!=(const Fruit& other) const;
};

class Fruits {
private:
    std::list<Fruit> _fruits;
    std::list<std::string> _fruitsTypes;
    std::list<int> _fruitsX;
    std::list<int> _fruitsY;
    std::list<std::pair<int, int>> _fruitCoordinates;

public:
    Fruits(Fruit fruit);

    void addFruit(Fruit fruit);
    bool tryRemoveFruit(Fruit fruit);

    std::list<Fruit> getFruits();
    std::list<std::string> getFruitsTypes();
    std::list<int> getFruitsX();
    std::list<int> getFruitsY();
    std::list<std::pair<int, int>> getFruitsCoordinates();
};
