const GAMESIZE = 5;
const GRIDSIZE = GAMESIZE*5;
const CELLSIZE = GAMESIZE*6;
const WIDTH = GRIDSIZE*CELLSIZE;
const HEIGHT = GRIDSIZE*CELLSIZE;
const IMAGE = document.getElementById("gameImage");

var _SOCKET;

const PLAYBUTTON = document.getElementById("playButton");

var _BOARD;
var _CONTEXT;
//var _SNAKE1;
//var _SNAKE2;
var _WORLD;

var _STARTGAME;

PLAYBUTTON.addEventListener("click", testMain);

function testMain(){

    _SOCKET = new WebSocket('ws://192.168.2.117:5501');

    console.log("Entered main")

    _WORLD = new World(0, [], [], [], "0:00", "waiting");

    _STARTGAME = true;

    console.log("Starting receive mode")

    createBoard();

    initializeWaitingMode();

    _SOCKET.onopen = () => {
        console.log("Connected to WebSocket server");
    };
    
    _SOCKET.onmessage = (event) => {

        console.log("Received data", event.data);

        const data = JSON.parse(event.data);

        console.log("Parsed data", data);

        if(data.gameStatus == "waiting"){
            initializeWaitingMode();
        }
        else
        {
            if (data.gameStatus == "connected"){
                initializeGame();
                _STARTGAME = false;
                _SOCKET.send(JSON.stringify({key: "start"}));
            }
    
            else if(data.gameStatus == 'tie' || data.gameStatus == 'win' || data.gameStatus == 'loose'){
                drawResult();
                _SOCKET.onmessage = null;
            }
            else{
                console.log("Snake1", data.snake1Coordinates);
                _WORLD.setSnake1(data.snake1Coordinates);

                console.log("Snake2", data.snake2Coordinates);
                _WORLD.setSnake2(data.snake2Coordinates);

                console.log("fruitsTypes", data.fruitsTypes); 
                console.log("fruitsX", data.fruitsX);
                console.log("fruitsY", data.fruitsY);
                _WORLD.setFruits(data.fruitTypes, data.fruitsX, data.fruitsY);

                console.log("Timer", data.timer);
                _WORLD.setTimer(data.timer);

                console.log("Status", data.gameStatus);
                _WORLD.setStatus(data.gameStatus);
    
                drawPlayer();
                drawScore();
                drawTimer();
                drawSnakes();
                drawFoods();
                keyHandler();
            }
        }
    };

    _SOCKET.onerror = (error) => {
        console.log("Websocket error", error);
    };

    _SOCKET.onclose = (event) => {
        console.log("Websocket closed",{ 
            clean: event.wasClean,
            code: event.code, 
            reason: event.reason
        });
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
        _SOCKET.send(data);
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
    drawSnake(_WORLD.getSnake1());
    drawSnake(_WORLD.getSnake2());
}

function drawSnake(snakeInput){
    console.log("Drawing snake", snakeInput);
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
    constructor(id, snake1, snake2, fruits, timer, status){
        this.id = id;
        this.snake1 = snake1;
        this.snake2 = snake2;
        this.fruits = fruits;
        this.timer = timer;
        this.status = status;
    }

    getID(){
        return this.id;
    }

    getSnake1(){
        return this.snake1;
    }

    getSnake2(){
        return this.snake2;
    }

    getFruits(){
        return this.fruits;
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

    setSnake1(newSnake1){
        this.snake1 = newSnake1;
    }

    setSnake2(newSnake2){
        this.snake2 = newSnake2;
    }

    setFruits(newFruitsTypes, newFruitsX, newFruitsY){
        this.fruits = [];
        for (let i=0; i < newFruitsTypes.length; i++){
            this.fruits.push(new Item(newFruitsTypes[i], newFruitsX[i], newFruitsY[i]));
        }
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

