#include <iostream>
#include <list>
#include <cmath>
#include <utility> // Für std::pair
#include <boost/beast/core.hpp>
#include <boost/beast/websocket.hpp>
#include <boost/asio/ip/tcp.hpp>
#include <thread>

namespace beast = boost::beast;
namespace websocket = beast::websocket;
namespace net = boost::asio;
using tcp = boost::asio::ip::tcp;
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
    Snake _SNAKE1(SNAKE_ID1, SNAKE_COORDINATES1, "red", BOOST_DURATION_INITIAL, IMMUNITY_DURATION_INITIAL, "right", VELOCITY_NORMAL, SCORE_INITIAL, BANANA_INITIAL, BLUEBERRY_INITIAL);
    Snake _SNAKE2(SNAKE_ID2, SNAKE_COORDINATES2, "blue", BOOST_DURATION_INITIAL, IMMUNITY_DURATION_INITIAL, "left", VELOCITY_NORMAL, SCORE_INITIAL, BANANA_INITIAL, BLUEBERRY_INITIAL);
    Fruit FRUIT("apple", std::floor(GRID_SIZE / 2), std::floor(GRID_SIZE / 2));

    // Initiale Listen und Werte für Welten, Schlangen, Früchte und Timer



    WebSocketServer server;
    server.run();

    return 0;
};

class WebSocketServer {
private:
    net::io_context ioc;
    tcp::acceptor acceptor;
    
public:
    WebSocketServer() : 
        acceptor(ioc, tcp::endpoint(tcp::v4(), 9092)) {
        accept();
    }

    void accept() {
        acceptor.async_accept(
            [this](beast::error_code ec, tcp::socket socket) {
                if (!ec) {
                    std::make_shared<Session>(std::move(socket))->start();
                }
                accept();
            });
    }

    void run() {
        ioc.run();
    }
};

class Session : public std::enable_shared_from_this<Session> {
private:
    websocket::stream<tcp::socket> ws;
    beast::flat_buffer buffer;

public:
    explicit Session(tcp::socket socket) : ws(std::move(socket)) {}

    void start() {
        ws.async_accept(
            [self = shared_from_this()](beast::error_code ec) {
                if (!ec) {
                    self->read();
                }
            });
    }

    void read() {
        ws.async_read(
            buffer,
            [self = shared_from_this()](beast::error_code ec, std::size_t bytes) {
                if (!ec) {
                    // Handle received message
                    self->handleMessage(beast::buffers_to_string(self->buffer.data()));
                    self->buffer.consume(self->buffer.size());
                    self->read();
                }
            });
    }

    void handleMessage(const std::string& message) {
        // Handle game logic here
        ws.async_write(
            net::buffer(message),
            [self = shared_from_this()](beast::error_code ec, std::size_t bytes) {
                if (!ec) {
                    // Message sent successfully
                }
            });
    }
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
};

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
};

