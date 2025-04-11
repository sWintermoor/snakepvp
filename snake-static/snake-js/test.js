const GAMESIZE = 5;
const GRIDSIZE = GAMESIZE*5;
const CELLSIZE = GAMESIZE*6;
const WIDTH = GRIDSIZE*CELLSIZE;
const HEIGHT = GRIDSIZE*CELLSIZE;
const IMAGE = document.getElementById("gameImage");
const SNAKE1COLOR = "green";
const SNAKE2COLOR = "blue";

var _SOCKET;

const PLAYBUTTON = document.getElementById("playButton");

var _BOARD;
var _CONTEXT;
//var _SNAKE1;
//var _SNAKE2;
var _WORLD;
var _SNAKE1;
var _SNAKE2;

var _STARTGAME;

PLAYBUTTON.addEventListener("click", testMain);

function testMain(){

    _SOCKET = new WebSocket('ws://192.168.2.117:5501');

    console.log("Entered main")

    _SNAKE1 = new Snake([], SNAKE1COLOR);
    _SNAKE2 = new Snake([], SNAKE2COLOR);

    _WORLD = new World(0, _SNAKE1, _SNAKE2, [], "0:00", "waiting");

    _STARTGAME = true;

    console.log("Starting receive mode")

    createBoard();

    initializeWaitingMode();

    _SOCKET.onopen = () => {
        console.log("Connected to WebSocket server");
    };
    
    _SOCKET.onmessage = (event) => {

        console.log("test");

        console.log("Received data", event.data);

        const data = JSON.parse(event.data);

        console.log("Parsed data", data);

        console.log("Type of gameStatus:", typeof data.gameStatus);

        if(data.gameStatus == "waiting"){
            initializeWaitingMode();
        }
        else
        {
            if (data.gameStatus == "connected"){
                initializeGame();
                _STARTGAME = false;
                const startMessage = (JSON.stringify({key: "start"}));
                console.log("Attempting to send start message:", startMessage);
    
                try {
                    _SOCKET.send(startMessage);
                    console.log("Start message sent successfully");
                } catch (error) {
                    console.error("Error sending start message:", error);
                }
            }
    
            else if(data.gameStatus == 'tie' || data.gameStatus == 'win' || data.gameStatus == 'loose'){
                drawResult();
                _SOCKET.onmessage = null;
            }
            else{
                console.log("Check for update")
                if (data.gameStatus !== "no_update"){
                    console.log("Doing update")
                    console.log("Snake1 Coordinates", data.snake1Coordinates);
                    _WORLD.setSnake1Coordinates(data.snake1Coordinates);

                    console.log("Snake2 Coordinates", data.snake2Coordinates);
                    _WORLD.setSnake2Coordinates(data.snake2Coordinates);

                    console.log("fruitsTypes", data.fruitsTypes); 
                    console.log("fruitsX", data.fruitsX);
                    console.log("fruitsY", data.fruitsY);
                    _WORLD.setFruits(data.fruitsTypes, data.fruitsX, data.fruitsY);

                    console.log("Timer", data.timer);
                    _WORLD.setTimer(data.timer);

                    console.log("Status", data.gameStatus);
                    _WORLD.setStatus(data.gameStatus);
        
                    drawPlayer();
                    drawScore();
                    drawTimer();
                    drawSnakes();
                    drawFoods();
                }
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
    snakeInput.getCoordinates().forEach(coordinate => {
        _CONTEXT.fillStyle = snakeInput.getColor(); // oder verschiedene Farben für verschiedene Schlangen
        drawCoordinate(coordinate);
    });
}

function drawCoordinate([x, y]){
    _CONTEXT.fillRect(x, y, CELLSIZE, CELLSIZE);
}

function drawFoods(){
    console.log("Drawing foods", _WORLD.getFruits());
    _WORLD.getFruits().forEach(food => {
        console.log("Drawing food", food);
        drawSpecificFood(food);
    });
}

function drawSpecificFood(food){
    let x = food.getXCoordinate();
    let y = food.getYCoordinate();
    let type = food.getType();

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

    getSnake1Coordinates(){
        return this.snake1.getCoordinates();
    }

    getSnake2Coordinates(){
        return this.snake2.getCoordinates();
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

    setSnake1Coordinates(newSnake1Coordinates){
        this.snake1.setCoordinates(newSnake1Coordinates);
    }

    setSnake2Coordinates(newSnake2Coordinates){
        this.snake2.setCoordinates(newSnake2Coordinates);
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
    constructor(coordinates, color){
        this.coordinates = coordinates;
        this.color = color;
    }

    setCoordinates(newCoordinates){
        this.coordinates = newCoordinates;
    }

    setColor(newColor){
        this.color = newColor;
    }

    getCoordinates(){
        return this.coordinates;
    }

    getColor(){
        return this.color;
    }
}

class Item{
    constructor(type, xCoordinate, yCoordinate){
        this.type = type;
        this.xCoordinate = xCoordinate;
        this.yCoordinate = yCoordinate;
    }

    getType(){
        return this.type;
    }
    
    getXCoordinate(){
        return this.xCoordinate;
    }

    getYCoordinate(){
        return this.yCoordinate;
    }
}

