#include <iostream>
#include <list>
#include <utility> // Für std::pair
using namespace std;

int main(){
    // Main function

    // Spielgeschwindigkeit
    int GAME_SPEED = 18; 

    // Spielfeldparameter
    int GAME_SIZE = 5; // Spielgröße
    int GRID_SIZE = 5 * GAME_SIZE; // Spielfeldgröße: hier 25x25 Zellen
    int CELL_SIZE = 6 * GAME_SIZE; // Jede Zelle ist hier 30x30 Pixel groß
    int WIDTH = GRID_SIZE * CELL_SIZE; // Gesambtbreite des Spielfelds in Pixeln
    int HEIGHT = GRID_SIZE * CELL_SIZE; // Gesamthöhe des Spielfelds in Pixeln

    // Werte für ID, Farbe, Geschwindigkeit, Geschwindigkeitsdauer, Score und Bananen der Schlangen
    int SNAKE_ID1 = 1;
    int SNAKE_ID2 = 2;
    list<pair<int, int>> SNAKE_COORDINATES1 =  {make_pair(1, 0), make_pair(0, 0)};
    list<pair<int, int>> SNAKE_COORDINATES2 =  {make_pair(GRID_SIZE - 2, GRID_SIZE - 1), make_pair(GRID_SIZE - 1, GRID_SIZE - 1)};
    int VELOCITY_NORMAL = 3;
    int BOOST = 1;
    int BOOST_DURATION_INITIAL = 0;
    int BOOST_DURATION = 15;
    int IMMUNITY_DURATION_INITIAL = 0;
    int IMMUNITY_DURATION = 15;
    int SCORE_INITIAL = 0;
    int BANANA_INITIAL = 0;
    int BLUEBERRY_INITIAL = 0;


    //Initale Schlangen und Früchte
    Snake _SNAKE(SNAKE_ID1, SNAKE_COORDINATES1, "red", BOOST_DURATION_INITIAL, IMMUNITY_DURATION_INITIAL, "right", VELOCITY_NORMAL, SCORE_INITIAL, BANANA_INITIAL, BLUEBERRY_INITIAL);
    Snake _SNAKE(SNAKE_ID2, SNAKE_COORDINATES2, "blue", BOOST_DURATION_INITIAL, IMMUNITY_DURATION_INITIAL, "left", VELOCITY_NORMAL, SCORE_INITIAL, BANANA_INITIAL, BLUEBERRY_INITIAL);
    return 0;
};

class Snake{
    private:
        int _id;
        list<pair<int, int>> _coordinates;
        std::string _color;
        int _boostDuration;
        int _immunityDuration;
        std::string _direction;
        int _velocity;
        int _score;
        int _banana;
        int _blueberry;

    public:
        Snake(int id, list<pair<int, int>> coordinates, std::string color, int boostDuration, int immunityDuration, std::string direction, int velocity, int score, int banana, int blueberry){
            // Constructor
            _id = id;
            _coordinates = coordinates;
            _color = color;
            _boostDuration = boostDuration;
            _immunityDuration = immunityDuration;
            _direction = direction;
            _velocity = velocity;
            _score = score;
            _banana = banana;
            _blueberry = blueberry;
        };
};

class Fruit{
    private:
        std::string _type;
        int _x;
        int _y;

    public:
        Fruit(std::string type, int x, int y){
            // Constructor
            _type = type;
            _x = x;
            _y = y;
        };
};

