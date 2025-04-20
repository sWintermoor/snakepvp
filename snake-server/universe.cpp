#include <iostream>
#include <list>
#include <cmath>
#include <utility> // Für std::pair
#include <tuple>
#include <boost/beast/core.hpp>
#include <boost/beast/websocket.hpp>
#include <boost/asio/ip/tcp.hpp> 
#include <thread>
#include <queue>
#include <nlohmann/json.hpp>
#include <chrono>

namespace beast = boost::beast;
namespace websocket = beast::websocket;
namespace net = boost::asio;
using tcp = boost::asio::ip::tcp;
using json = nlohmann::json;
using namespace std;

// Spielgeschwindigkeit
int GAME_SPEED = 3; 

// Spielfeldparameter
int GAME_SIZE = 5; // Spielgröße
int GRID_SIZE = 5 * GAME_SIZE; // Spielfeldgröße: hier 25x25 Zellen#
int CELL_SIZE = 6 * GAME_SIZE; // Jede Zelle ist hier 30x30 Pixel groß
int WIDTH = GRID_SIZE * CELL_SIZE; // Gesambtbreite des Spielfelds in Pixeln
int HEIGHT = GRID_SIZE * CELL_SIZE; // Gesamthöhe des Spielfelds in Pixeln

// Werte für ID, Farbe, Geschwindigkeit, Geschwindigkeitsdauer, Score und Bananen der Schlangen
int SNAKE_ID1 = 1;
int SNAKE_ID2 = 2;
list<pair<int, int>> SNAKE_COORDINATES1 =  {make_pair(CELL_SIZE * 1, CELL_SIZE * 0), make_pair(CELL_SIZE * 0, CELL_SIZE * 0)};
list<pair<int, int>> SNAKE_COORDINATES2 =  {make_pair(CELL_SIZE * GRID_SIZE - CELL_SIZE * 2, CELL_SIZE * GRID_SIZE - CELL_SIZE * 1), make_pair(CELL_SIZE * GRID_SIZE - CELL_SIZE * 1, CELL_SIZE * GRID_SIZE - CELL_SIZE * 1)};
int VELOCITY_NORMAL = 3;
int BOOST = 1;
int BOOST_DURATION_INITIAL = 0;
int BOOST_DURATION = 15;
int IMMUNITY_DURATION_INITIAL = 0;
int IMMUNITY_DURATION = 15;
int SCORE_INITIAL = 0;
int BANANA_INITIAL = 0;
int BLUEBERRY_INITIAL = 0;

// Initiale Listen und Werte für Früchte und Timer
int TIMER_INITIAL = 180*GAME_SPEED; // Timer in Sekunden
int TICK_VALUE = 1 / GAME_SPEED; // Zeitwert für Ticks

class Fruit{
    private:
        std::string _type;
        int _x;
        int _y;

    public:
        Fruit(std::string type, int x, int y):
            // Constructor
            _type(type),
            _x(x),
            _y(y)
        {};

        std::string getType(){
            return _type;
        };

        int getX(){
            return _x;
        };

        int getY(){
            return _y;
        };

        // Definieren, wie der Gleich-Operator für Früchte funktioniert
        bool operator==(const Fruit& other) const {
            return _type == other._type && 
                   _x == other._x && 
                   _y == other._y;
        }

        bool operator!=(const Fruit& other) const {
            return !(*this == other);
        }
};

class Fruits{
    private:
        list<Fruit> _fruits;
        list<std::string> _fruitsTypes;
        list<int> _fruitsX;
        list<int> _fruitsY;
        list<pair<int, int>> _fruitCoordinates;

    public:
        Fruits(Fruit fruit){
            _fruits.push_back(fruit);
            _fruitsTypes.push_back(fruit.getType());
            _fruitsX.push_back(fruit.getX());
            _fruitsY.push_back(fruit.getY());
            _fruitCoordinates.push_back(make_pair(fruit.getX(), fruit.getY()));
        };

        void addFruit(Fruit fruit){
            _fruits.push_back(fruit);
            _fruitsTypes.push_back(fruit.getType());
            _fruitsX.push_back(fruit.getX());
            _fruitsY.push_back(fruit.getY());
            _fruitCoordinates.push_back(make_pair(fruit.getX(), fruit.getY()));
        };

        bool tryRemoveFruit(Fruit fruit){
            list<Fruit>::iterator it = find(_fruits.begin(), _fruits.end(), fruit);
            if (it != _fruits.end()){
                int index = distance(_fruits.begin(), it);
                _fruits.erase(it);
                _fruitsTypes.erase(next(_fruitsTypes.begin(), index));
                _fruitsX.erase(next(_fruitsX.begin(), index));
                _fruitsY.erase(next(_fruitsY.begin(), index));
                _fruitCoordinates.erase(next(_fruitCoordinates.begin(), index));
                return true;
            }
            else{
                return false;
            }
        };

        list<Fruit> getFruits(){
            return _fruits;
        };

        list<std::string> getFruitsTypes(){
            return _fruitsTypes;
        };

        list<int> getFruitsX(){
            return _fruitsX;
        };

        list<int> getFruitsY(){
            return _fruitsY;
        };

        list<pair<int, int>> getFruitsCoordinates(){
            return _fruitCoordinates;
        };
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
        Snake(int id, list<pair<int, int>> coordinates, std::string color, int boostDuration, int immunityDuration, std::string direction, int velocity, int score, int banana, int blueberry):
            // Constructor
            _id(id), 
            _coordinates(coordinates), 
            _color(color), 
            _boostDuration(boostDuration), 
            _immunityDuration(immunityDuration), 
            _direction(direction), 
            _velocity(velocity), 
            _score(score), 
            _banana(banana), 
            _blueberry(blueberry)
        {};

        void update(bool changeImmunityBooster, int fruitConsumption){
            // Update function
            bool appleConsumption = (fruitConsumption == 0);

            modifyBooster(changeImmunityBooster);
            modifyImmunity(changeImmunityBooster);
            move(appleConsumption);
        };

        void modifyBooster(bool changeImmunityBooster){
            // Check booster function
            if (_boostDuration > 0 && changeImmunityBooster){
                _boostDuration -= 1;
            }
        };

         void changeBoost(int additionalBoostDuration){
            // Change boost function
            _boostDuration += additionalBoostDuration;
        };

        bool checkImmunity(){
            if (getImmunityDuration() > 0){
                return true;
            }
            else{
                return false;
            }
        };

        void modifyImmunity(bool changeImmunityBooster){
            // Check immunity function
            if (_immunityDuration > 0 && changeImmunityBooster){
                _immunityDuration -= 1;
            }
        };

        void move(bool appleConsumption){
            // Move function
            pair<int, int> head = getHead();
            pair<int, int> newHead;
            if (_direction == "up"){
                newHead = make_pair(head.first, (head.second - 1*CELL_SIZE) % (GRID_SIZE*CELL_SIZE));
            }
            else if (_direction == "down"){
                newHead = make_pair(head.first, (head.second + 1*CELL_SIZE) % (GRID_SIZE*CELL_SIZE));
            }
            else if (_direction == "left"){
                newHead = make_pair((head.first - 1*CELL_SIZE) % (GRID_SIZE*CELL_SIZE), head.second);
            }
            else if (_direction == "right"){
                newHead = make_pair((head.first + 1*CELL_SIZE) % (GRID_SIZE*CELL_SIZE), head.second);
            }
            _coordinates.push_front(newHead);

            if (!appleConsumption){
                _coordinates.pop_back();
            }
        };

        void setDirection(std::string newDirection){
            // Set direction function
            _direction = newDirection;
        };

        void setScore(int newScore){
            // Set score function
            _score = newScore;
        };

        void setBanana(int newBanana){
            // Set banana function
            _banana = newBanana;
        };

        void setBlueberry(int newBlueberry){
            // Set blueberry function
            _blueberry = newBlueberry;
        };

        pair<int, int> getHead(){
            return _coordinates.front();
        };

        list<pair<int, int>> getCoordinates(){
            return _coordinates;
        };

        int getBoostDuration(){
            return _boostDuration;
        };

        int getImmunityDuration(){
            return _immunityDuration;
        };

        int getScore(){
            return _score;
        };

        int getBanana(){
            return _banana;
        };

        int getBlueberry(){
            return _blueberry;
        };
};

// Code ist unschön positioniert

//Initale Schlangen und Früchte
Snake _SNAKE1(SNAKE_ID1, SNAKE_COORDINATES1, "red", BOOST_DURATION_INITIAL, IMMUNITY_DURATION_INITIAL, "right", VELOCITY_NORMAL, SCORE_INITIAL, BANANA_INITIAL, BLUEBERRY_INITIAL);
Snake _SNAKE2(SNAKE_ID2, SNAKE_COORDINATES2, "blue", BOOST_DURATION_INITIAL, IMMUNITY_DURATION_INITIAL, "left", VELOCITY_NORMAL, SCORE_INITIAL, BANANA_INITIAL, BLUEBERRY_INITIAL);
Fruit FRUIT_INITIAL("apple", std::floor(CELL_SIZE * GRID_SIZE / 2), std::floor(CELL_SIZE * GRID_SIZE / 2));

class Universe{
    private:
        Snake _snake1;
        Snake _snake2;
        Fruits _fruits;
        std::string _gameState;

    public:
        Universe(Snake snake1, Snake snake2, Fruits fruit):
            // Constructor
            _snake1(snake1),
            _snake2(snake2),
            _fruits(fruit)
        {
            _gameState = "running";
        };

        bool universeTick(bool timerPermission){
            // Tick function
            std::cout << "Universe: universeTick" << std::endl;
            if (checkCollisions() == -1){
                std::cout << "Universe: No collision detected" << std::endl;

                if (timerPermission || checkBooster(_snake1)){
                    std::cout << "Universe: Update Snake1 and Fruits" << std::endl;
                    int updateConsumption = checkFruit(_snake1);
                    _snake1.update(timerPermission, updateConsumption);
                    if (updateConsumption > -1){
                        std::cout << "Universe: Spawning fruits (snake1)" << std::endl;
                        spawnFruits();
                    }
                }
                if (timerPermission || checkBooster(_snake2)){
                    std::cout << "Universe: Update Snake2 and Fruits" << std::endl;
                    int updateConsumption = checkFruit(_snake2);
                    _snake2.update(timerPermission, updateConsumption);
                    if (updateConsumption > -1){
                        std::cout << "Universe: Spawning fruits (snake2)" << std::endl;
                        spawnFruits();
                    }
                }
                return false;                    
            }
            else{
                std::cout << "Universe: Collision detected" << std::endl;
                return true;
            }
        };

        bool checkBooster(Snake snake){
            if (snake.getBoostDuration() > 0){
                return true;
            }
            else{
                return false;
            }
        };

        int checkCollisions(){
            pair<int, int> head1 = _snake1.getHead();
            pair<int, int> head2 = _snake2.getHead();
            int collision = -1;

            if (head1.first == head2.first && head1.second == head2.second){
                collision = 0;
            }
            else{
                list<pair<int, int>> body1 = _snake1.getCoordinates();
                list<pair<int, int>> body2 = _snake2.getCoordinates();
                body1.pop_front();
                body2.pop_front();

                if (!_snake1.checkImmunity() && (find(body1.begin(), body1.end(), head1) != body1.end())){
                    collision = 1;
                }
                if (!_snake2.checkImmunity() && (find(body2.begin(), body2.end(), head2) != body2.end())){
                    if (collision == 1){
                        collision = 0;
                    }
                    else{
                        collision = 2;
                    }
                }
                if (!_snake1.checkImmunity() && !_snake2.checkImmunity()){
                    if (find(body1.begin(), body1.end(), head2) != body1.end()){
                        if (collision == 1){
                            collision = 0;
                        }
                        else{
                            collision = 2;
                        }
                    }
                    if (find(body2.begin(), body2.end(), head1) != body2.end()){
                        if (collision == 2){
                            collision = 0;
                        }
                        else{
                            collision = 1;
                        }
                    }   
                }
            }
            return collision;
        }

        int checkFruit(Snake snake){
            pair<int, int> head = snake.getHead();
            int consumedFruit = -1;

            for (Fruit fruit : _fruits.getFruits()){
                if (head.first == fruit.getX() && head.second == fruit.getY()){
                    if (fruit.getType() == "apple"){
                        snake.setScore(snake.getScore() + 1);
                        consumedFruit = 0;
                    }
                    else if (fruit.getType() == "banana"){
                        snake.setBanana(snake.getBanana() + 1);
                        consumedFruit = 1;
                    }
                    else if (fruit.getType() == "blueberry"){
                        snake.setBlueberry(snake.getBlueberry() + 1);
                        consumedFruit = 2;
                    }
                    _fruits.tryRemoveFruit(fruit);
                }
            }
            return consumedFruit;
        };

        std::tuple<list<pair<int, int>>, list<pair<int, int>>, list<std::string>, list<int>, list<int>, std::string, std::string> finalMessageToSend(){
            int collisionStatus = checkCollisions();
            if (collisionStatus == -1 || collisionStatus == 0){
                return {_snake1.getCoordinates(), _snake2.getCoordinates(), _fruits.getFruitsTypes(), _fruits.getFruitsX(), _fruits.getFruitsY(), "draw", "draw"};
            }
            else if (collisionStatus == 1){
                return {_snake1.getCoordinates(), _snake2.getCoordinates(), _fruits.getFruitsTypes(), _fruits.getFruitsX(), _fruits.getFruitsY(), "lose", "win"};
            }
            else{
                return {_snake1.getCoordinates(), _snake2.getCoordinates(), _fruits.getFruitsTypes(), _fruits.getFruitsX(), _fruits.getFruitsY(), "win", "lose"};
            }
        }

        void spawnFruits(){
            int randomX = (rand()*CELL_SIZE) % (GRID_SIZE*CELL_SIZE) + (CELL_SIZE/2);
            int randomY = (rand()*CELL_SIZE) % (GRID_SIZE*CELL_SIZE) + (CELL_SIZE/2);
            list<pair<int, int>> snake1Coordinates = _snake1.getCoordinates();
            list<pair<int, int>> snake2Coordinates = _snake2.getCoordinates();
            list<pair<int, int>> _fruitCoordinates = _fruits.getFruitsCoordinates(); 

            while (find(snake1Coordinates.begin(), snake1Coordinates.end(), make_pair(randomX, randomY)) != snake1Coordinates.end() || find(snake2Coordinates.begin(), snake2Coordinates.end(), make_pair(randomX, randomY)) != snake2Coordinates.end() || find(_fruitCoordinates.begin(), _fruitCoordinates.end(), make_pair(randomX, randomY)) != _fruitCoordinates.end()){
                randomX = (rand()*CELL_SIZE) % (GRID_SIZE*CELL_SIZE) + (CELL_SIZE/2);
                randomY = (rand()*CELL_SIZE) % (GRID_SIZE*CELL_SIZE) + (CELL_SIZE/2);
            }

            int randomFruit = rand() % 6;
            std::string fruitType1;
            std::string fruitType2;

            if (randomFruit == 0){
                fruitType1 = "apple";
            }
            else if (randomFruit == 1){
                fruitType1 = "banana";
            }
            else if (randomFruit == 2){
                fruitType1 = "blueberry";
            }
            else if (randomFruit == 3){
                fruitType1 = "apple";
                fruitType2 = "apple";
            }
            else if (randomFruit == 4){
                fruitType1 = "apple";
                fruitType2 = "banana";
            }
            else if (randomFruit == 5){
                fruitType1 = "apple";
                fruitType2 = "blueberry";
            }

            Fruit newFruit(fruitType1, randomX, randomY);
            _fruits.addFruit(newFruit);

            if (randomFruit > 2){
                Fruit newFruit2(fruitType2, randomX, randomY);
                _fruits.addFruit(newFruit2);
            }
        }

        std::tuple<list<pair<int, int>>, list<pair<int, int>>, list<std::string>, list<int>, list<int>, std::string, std::string> getStatusWhileRunning(){
            list<pair<int, int>> snake1Coordinates = _snake1.getCoordinates();
            list<pair<int, int>> snake2Coordinates = _snake2.getCoordinates();
            return {snake1Coordinates, snake2Coordinates, _fruits.getFruitsTypes(), _fruits.getFruitsX(), _fruits.getFruitsY(), "running", "running"};
        }

        void updateSnakeDirection(int id, std::string key){
            if (id == 1){
                if (key == "up" || key == "down" || key == "left" || key == "right"){
                    _snake1.setDirection(key);
                }
                else if (key == "space"){
                    _snake1.changeBoost(BOOST_DURATION);
                }
            }
            else if (id == 2){
                if (key == "up" || key == "down" || key == "left" || key == "right"){
                    _snake2.setDirection(key);
                }
                else if (key == "space"){
                    _snake2.changeBoost(BOOST_DURATION);
                }
            }
        };
};

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

    void do_write1() {
        bool should_write = false;
        {
            std::cout << "Universe: Locking writing for Client1" << std::endl;
            std::lock_guard<std::mutex> lock(_write_mutex1);
            std::cout << "Universe: do_write1: Queue size = " << _write_queue1.size() << ", writing = " << _writing1 << std::endl;
            if (!_write_queue1.empty() && !_writing1){
                _writing1 = true;
                should_write = true;
            }
        }
        
        if (should_write){
            std::cout << "Universe: do_write1: Starting async_write" << std::endl;
            auto self = shared_from_this();
            _ws1.async_write(
                net::buffer(_write_queue1.front()),
                [self](beast::error_code ec, std::size_t bytes) {
                    std::cout << "Universe: do_write1: async_write completed, ec = " << ec.message() << std::endl;
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
                            std::cout << "Universe: async_write_1 success." << std::endl;
                            self->_write_queue1.pop();
                        }
                        self->_writing1 = false;
                        check_next = !self->_write_queue1.empty();
                    }
                    if (check_next) {
                        net::post(self-> _ws1.get_executor(), [self]() {
                            self->do_write1(); // Check if more messages to send
                        });
                    }
                }
            );
        }
    }

    void do_write2() {
        bool should_write = false;
        {
            std::cout << "Universe: Locking writing for Client2" << std::endl;
            std::lock_guard<std::mutex> lock(_write_mutex2);
            std::cout << "Universe: do_write2: Queue size = " << _write_queue2.size() << ", writing = " << _writing2 << std::endl;
            if (!_write_queue2.empty() && !_writing2){
                _writing2 = true;
                should_write = true;
            }
        }

        if (should_write){
            std::cout << "Universe: do_write2: Starting async_write" << std::endl;
            auto self = shared_from_this();
            _ws2.async_write(
                net::buffer(_write_queue2.front()),
                [self](beast::error_code ec, std::size_t bytes) {
                    std::cout << "Universe: do_write2: async_write completed, ec = " << ec.message() << std::endl;
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
                            std::cout << "Universe: async_write_2 success." << std::endl;
                            self->_write_queue2.pop();
                        }
                        self->_writing2 = false;
                        check_next = !self->_write_queue2.empty();
                    }
                    if (check_next) {
                        net::post(self-> _ws2.get_executor(), [self]() {
                            self->do_write2(); // Check if more messages to send
                        });
                    }
                }
            );
        }
    }

    void checkQueueAndScheduleNextTick() {
        bool schedule = false;
        {
            std::cout << "Universe: Locking for next tick" << std::endl;
            std::lock_guard<std::mutex> lock1(_write_mutex1);
            std::lock_guard<std::mutex> lock2(_write_mutex2);
            if (!_writing1 && !_writing2 &&
                _write_queue1.empty() && _write_queue2.empty() &&
                !_tickScheduled) {
                _tickScheduled = true;
                schedule = true;
            }
        } 

        std::cout << "Universe: Unlocking for next tick" << std::endl;

        if (schedule) {
            net::post(_ws1.get_executor(), [self = shared_from_this()]() {
                self->_tickScheduled = false;
                self->sessionTick();
            });
        }
        else {
            std::cout << "Universe: Not scheduling next tick, already scheduled or writing in progress." << std::endl;
            net::post(_ws1.get_executor(), [self = shared_from_this()]() {
                self->checkQueueAndScheduleNextTick();
            });
        }
    }

public:
    explicit Session(tcp::socket socket1, tcp::socket socket2, int timerInput) : 
    _ws1(std::move(socket1)),
    _ws2(std::move(socket2)),
    _timer(timerInput),
    _universe(nullptr) {}

    void start() {
        auto self = shared_from_this();
        _ws1.async_accept(
            [self](beast::error_code ec) {
                if (!ec) {
                    self->_ws2.async_accept(
                        [self](beast::error_code ec) {
                            if (!ec) {
                                std::cout << "Universe: Creating Universe Object" << std::endl;
                                self -> _universe = std::make_unique<Universe>(
                                _SNAKE1, 
                                _SNAKE2, 
                                FRUIT_INITIAL);
                                self->read_client1();
                                self->read_client2();
                            }
                        }
                    );
                }
            });
    }

    void sessionTick(){
        if (_processingTick.exchange(true)){
            std::cout << "Universe: Already processing tick, skipping this one." << std::endl;
            return;
        }

        try {
            
            std::this_thread::sleep_for(std::chrono::seconds(1));

            _timer -= 1;
            std::cout << "Universe: Beginn tick" << std::endl;

            if(_timer == 0){
                //End of game
            }
            else{
                std::cout << "Universe: Timer: " << _timer << std::endl;
                bool timerPermission = (_timer % GAME_SPEED == 0);
                std::cout << "Universe: Timer permission: " << timerPermission << std::endl;
                bool endOfGame = _universe->universeTick(timerPermission);
                if (endOfGame){
                    std::cout << "Universe: Setting final score" << std::endl;
                    setFinalScore();
                }
                else{
                    std::cout << "Universe: Start to update clients" << std::endl;
                    updateClients();
                    // Plane den nächsten Tick
                    auto self = shared_from_this();
                    net::post(_ws1.get_executor(), [self]() {
                        std::cout << "Universe: Trying to start next tick" << std::endl;
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

    void setFinalScore(){
        list<pair<int, int>> snake1Coordinates; 
        list<pair<int, int>> snake2Coordinates; 
        list<std::string> fruitsTypes; 
        list<int> fruitsX; 
        list<int> fruitsY; 
        std::string gameStatus1; 
        std::string gameStatus2;

        tie(snake1Coordinates, snake2Coordinates, fruitsTypes, fruitsX, fruitsY, gameStatus1, gameStatus2) = _universe->finalMessageToSend();
        sendMessageClient(snake1Coordinates, snake2Coordinates, fruitsTypes, fruitsX, fruitsY, _timer, gameStatus1, gameStatus2);
    }

    void updateClients(){
        list<pair<int, int>> snake1Coordinates; 
        list<pair<int, int>> snake2Coordinates; 
        list<std::string> fruitsTypes; 
        list<int> fruitsX; 
        list<int> fruitsY; 
        std::string gameStatus1; 
        std::string gameStatus2;

        tie(snake1Coordinates, snake2Coordinates, fruitsTypes, fruitsX, fruitsY, gameStatus1, gameStatus2 ) = _universe->getStatusWhileRunning();
        sendMessageClient(snake1Coordinates, snake2Coordinates, fruitsTypes, fruitsX, fruitsY, _timer, gameStatus1, gameStatus2);
    }

    void read_client1() {
        _ws1.async_read(
            _buffer1,
            [self = shared_from_this()](beast::error_code ec, std::size_t bytes) {
                if (!ec) {
                    // Handle received message
                    std::cout << "Universe: Reading messages from client 1" << std::endl;
                    self->handleMessage(1, beast::buffers_to_string(self->_buffer1.data()));
                    self->_buffer1.consume(self->_buffer1.size()); // Clear buffer
                    std::cout << "Universe: Finished reading messages from client 1" << std::endl;
                    self->read_client1();
                }
            });
    }

    void read_client2() {
        _ws2.async_read(
            _buffer2,
            [self = shared_from_this()](beast::error_code ec, std::size_t bytes) {
                if (!ec) {
                    // Handle received message
                    std::cout << "Universe: Reading messages from client 2" << std::endl;
                    self->handleMessage(2, beast::buffers_to_string(self->_buffer2.data()));
                    self->_buffer2.consume(self->_buffer2.size());
                    std::cout << "Universe: Finished reading messages from client 2" << std::endl;
                    self->read_client2();
                }
            });
    }

    void handleMessage(int id, const std::string& message) {
        std::cout << "Universe: handleMessage received: '" << message << "' from client '" << id << "'" << std::endl;
        try{
            json Data = json::parse(message);
            if (Data.contains("key") && Data["key"] == "start" && _gameStarted.exchange(true)){
                std::cout << "Universe: Starting session for clients" << std::endl;
                checkQueueAndScheduleNextTick();
            }
            else{
                if(Data.contains("direction") && Data["direction"].is_string()){
                    _universe->updateSnakeDirection(id, Data["direction"]);
                }
            }
        }
        catch (const json::exception& e) {
        // Handle JSON parsing errors
        std::cerr << "Universe: JSON parsing error: " << e.what() << std::endl;
        }
    }

    void sendMessageClient(list<pair<int,int>> snake1Coordinates, list<pair<int,int>> snake2Coordinates, list<std::string> fruitsTypes, list<int> fruitsX, list<int> fruitsY, int timer, std::string gameStatus1, std::string gameStatus2) {
        // Send game state to clients
        // Format: {"snake1": [[x1, y1], [x2, y2], ...], "snake2": [[x1, y1], [x2, y2], ...], "fruit": [[x, y]], "timer": timer}
        json message1 = {
            {"snake1Coordinates", snake1Coordinates},
            {"snake2Coordinates", snake2Coordinates},
            {"fruitsTypes", fruitsTypes},
            {"fruitsX", fruitsX},
            {"fruitsY", fruitsY},
            {"timer", timer},
            {"gameStatus", gameStatus1}
        };

        json message2 = {
            {"snake1Coordinates", snake1Coordinates},
            {"snake2Coordinates", snake2Coordinates},
            {"fruitsTypes", fruitsTypes},
            {"fruitsX", fruitsX},
            {"fruitsY", fruitsY},
            {"timer", timer},
            {"gameStatus", gameStatus2}
        };

        std::cout << "Universe: Pushing message for client 1 to _write_queue1" << std::endl;
        {
            std::lock_guard<std::mutex> lock(_write_mutex1);
            _write_queue1.push(message1.dump());
        }
        std::cout << "Universe: Pushing message for client 2 to _write_queue2" << std::endl;
        { 
            std::lock_guard<std::mutex> lock(_write_mutex2);
            _write_queue2.push(message2.dump());
        }

        std::cout << "Universe: Starting writing operation for client 1" << std::endl;
        net::post(_ws1.get_executor(), [self = shared_from_this()]() {
            self->do_write1();
        });

        std::cout << "Universe: Starting writing operation for client 2" << std::endl;
        net::post(_ws2.get_executor(), [self = shared_from_this()]() {
            self->do_write2();
        });
    }
};

class WebSocketServer {
private:
    net::io_context _ioc;
    tcp::acceptor _acceptor;
    std::optional<tcp::socket> first_socket;
    std::mutex _mutex;
    
public:
    WebSocketServer() : 
        _acceptor(_ioc, tcp::endpoint(tcp::v4(), 9092)) {
        accept();
    }

    void accept() {
        _acceptor.async_accept(
            [this](beast::error_code ec, tcp::socket socket) {
                try {
                    auto remote = socket.remote_endpoint();
                    std::cout << "Universe: Connection from " << remote.address().to_string() 
                              << ":" << remote.port() << std::endl;
                } catch (std::exception &e) {
                    std::cerr << "Universe: Failed to get remote endpoint: " << e.what() << std::endl;
                }
                if (!ec) {
                    std::lock_guard<std::mutex> lock(_mutex);
                    if (!first_socket){
                        // Erster Client
                        first_socket.emplace(std::move(socket));
                        std::cout << "Universe: First player connected" << std::endl;
                    }
                    else{
                        // Zweiter Client und Start der Session
                        std::cout << "Universe: Second player connected" << std::endl;
                        auto session = std::make_shared<Session>(
                            std::move(*first_socket),
                            std::move(socket),
                            TIMER_INITIAL
                        );
                        session->start();
                        first_socket.reset();
                    }
                }
                accept();
            });
    }

    void run() {
        _ioc.run();
    }
};

// Funktionen für die Spiellogik

int main(){
    // Main function
    try {
        std::cout << "Universe: Starting WebSocket server..." << std::endl;
        WebSocketServer server;
        std::cout << "Universe: WebSocket server running on port 9092" << std::endl;
        server.run();
    }
    catch (std::exception const& e) {
        std::cerr << "Universe: Error: " << e.what() << std::endl;
        return EXIT_FAILURE;
    }
    return EXIT_SUCCESS;
};