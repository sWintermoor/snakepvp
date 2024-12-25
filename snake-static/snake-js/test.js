const GAMESIZE = 5;
const GRIDSIZE = GAMESIZE*5;
const CELLSIZE = GAMESIZE*6;
const WIDTH = GRIDSIZE*CELLSIZE;
const HEIGHT = GRIDSIZE*CELLSIZE;
const IMAGE = document.getElementById("gameImage");

var SOCKET;

const PLAYBUTTON = document.getElementById("playButton");

var _BOARD;
var _CONTEXT;
var _SNAKE1;
var _SNAKE2;
var _WORLD;

var _STARTGAME;

PLAYBUTTON.addEventListener("click", testMain);

function testMain(){

    SOCKET = new WebSocket('ws://192.168.2.117:5501');

    console.log("Entered main")

    _WORLD = new World(0, [], [], "0:00", "waiting");
    _STARTGAME = true;

    console.log("Starting receive mode")

    createBoard();

    initializeWaitingMode();

    SOCKET.onopen = () => {
        console.log("Connected to WebSocket server");
    };
    
    SOCKET.onmessage = (event) => {

        const data = JSON.parse(event.data);

        console.log("game Loop");

        if (_STARTGAME == true){
            initializeGame();
            _STARTGAME = false;
        }

        if(_WORLD.getStatus() == 'tie' || _WORLD.getStatus() == 'win' || _WORLD.getStatus == 'loose'){
            drawResult();
            SOCKET.onmessage = null;
        }
        else{
            _WORLD.setID(data[0]);
            _WORLD.setSnakes(data[1]);
            _WORLD.setItems(data[2]);
            _WORLD.setTimer(data[3]);
            _WORLD.setStatus(data[4]);

            drawPlayer();
            drawScore();
            drawTimer();
            drawSnakes();
            drawFoods();
            keyHandler();
        }
    };

    SOCKET.onclose = () => {
        console.log("Disconnected from WebSocket server");
    };
}

function createBoard(){
    _BOARD=document.getElementById("gameCanvas");
    _BOARD.width=WIDTH;
    _BOARD.height=HEIGHT;
    _CONTEXT=_BOARD.getContext("2d");

    IMAGE.style.display = "none";
    _BOARD.style.display = "block";
}

function initializeWaitingMode(){
    _CONTEXT.fillStyle = "orange";
    _CONTEXT.font = "30px Arial";
    _CONTEXT.textAlign = "center";
    _CONTEXT.fillText("Waiting...", _BOARD.width / 2, _BOARD.height / 2);
}

function initializeGame(){
    cleanBoard();
    drawGrid();
    createKeyHandler();
}

function cleanBoard(){
    _CONTEXT.fillStyle="white";
    _CONTEXT.fillRect(0, 0, _BOARD.width, _BOARD.height);
    _BOARD.style.border = "2px solid black";   
}

function drawGrid(){
    for (let i=0; i <= GRIDSIZE; i++){
        _CONTEXT.beginPath();
        _CONTEXT.moveTo(i*CELLSIZE, 0);
        _CONTEXT.lineTo(i*CELLSIZE, HEIGHT);
        _CONTEXT.moveTo(0, i*CELLSIZE);
        _CONTEXT.lineTo(HEIGHT, i*CELLSIZE);
        _CONTEXT.strokeStyle="black";
        _CONTEXT.lineWidth=2;
        _CONTEXT.stroke();
    }
}

function createKeyHandler(){
    document.addEventListener("keydown", (event) => {
        const data = JSON.stringify({key: event.key});
        SOCKET.send(data);
});
}

function drawPlayer(){
    // Missing
}

function drawScore(){
    // Missing
}

function drawTimer(){
    // Missing
}

function drawSnakes(){
    drawSnake(_SNAKE1);
    drawSnake(_SNAKe2);
}

function drawSnake(snakeInput){
    for (const coordinate in snakeInput[1]){
        drawCoordinate(coordinate);
    }
}

function drawCoordinate([x, y]){
    _CONTEXT.fillRect(x, y, (x+CELLSIZE), (y+CELLSIZE));
}

function drawFoods(){
    for (const food in _ITEMS){
        drawSpecificFood(food);
    }
}

function drawSpecificFood(food){
    x = food[0];
    y = food[1];
    type = food[2];

    if (type == "apple"){
        drawApple(x, y);
    }
    else if (type == "banana"){
        drawBanana(x, y);
    }
    else{
        drawBlueberry(x, y);
    }
}

function drawApple(x, y){
    _CONTEXT.beginPath();
    _CONTEXT.arc(x, y, (CELLSIZE/2), 0, 2*Math.PI);
    _CONTEXT.fillStyle = 'red';
    _CONTEXT.fill();
}

function drawBanana(x, y){
    _CONTEXT.beginPath();
    _CONTEXT.arc(x, y, (CELLSIZE/2), 0, 2*Math.PI);
    _CONTEXT.fillStyle = 'yellow';
    _CONTEXT.fill();
}

function drawBlueberry(x, y){
    _CONTEXT.beginPath();
    _CONTEXT.arc(x, y, (CELLSIZE/2), 0, 2*Math.PI);
    _CONTEXT.fillStyle = 'blue';
    _CONTEXT.fill();
}

function drawResult(){
    // Missing
}


class World{
    constructor(id, snakes, items, timer, status){
        this.id = id;
        this.snakes = snakes;
        this.items = items;
        this.timer = timer;
        this.status = status;
    }

    getID(){
        return this.id;
    }

    getSnakes(){
        return this.snakes;
    }

    getItems(){
        return this.items;
    }

    getTimer(){
        return this.timer;
    }

    getStatus(){
        return this.status;
    }

    setID(newID){
        this.id = newID;
    }

    setSnakes(newSnakes){
        this.snakes = newSnakes;
    }

    setItems(newItems){
        this.items = newItems;
    }

    setTimer(newTimer){
        this.timer = newTimer;
    }

    setStatus(newStatus){
        this.status = newStatus;
    }
}

class Snake{
    constructor(id, coordinates, color, boostDuration, immunityDuration, direction, velocity, score, banana, blueberry){
        this.id = id;
        this.coordinates = coordinates;
        this.color = color;
        this.boostDuration = boostDuration;
        this.immunityDuration = immunityDuration;
        this.direction = direction;
        this.velocity = velocity;
        this.score = score;
        this.banana = banana;
        this.blueberry = blueberry
    }
}

class Item{
    constructor(type, xCoordinate, yCoordinate){
        this.type = type;
        this.xCoordinate = xCoordinate;
        this.yCoordinate = yCoordinate;
    }
}

