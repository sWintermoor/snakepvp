#pragma once
#include <list>
#include <string>
#include <utility>

class Snake {
private:
    int _id;
    std::list<std::pair<int, int>> _coordinates;
    std::string _color;
    int _boostDuration;
    int _immunityDuration;
    std::string _direction;
    int _velocity;
    int _score;
    int _banana;
    int _blueberry;

public:
    Snake(int id, std::list<std::pair<int, int>> coordinates, std::string color,
          int boostDuration, int immunityDuration, std::string direction,
          int velocity, int score, int banana, int blueberry);

    void update(bool changeImmunityBooster, int fruitConsumption);
    void modifyBooster(bool changeImmunityBooster);
    void changeBoost(int additionalBoostDuration);
    bool checkImmunity();
    void modifyImmunity(bool changeImmunityBooster);
    void move(bool appleConsumption);

    void setDirection(std::string newDirection);
    void setScore(int newScore);
    void setBanana(int newBanana);
    void setBlueberry(int newBlueberry);

    std::pair<int, int> getHead();
    std::list<std::pair<int, int>> getCoordinates();
    int getBoostDuration();
    int getImmunityDuration();
    int getScore();
    int getBanana();
    int getBlueberry();
    std::string getDirection();
};
