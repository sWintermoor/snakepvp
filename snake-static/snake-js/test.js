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

    _WORLD = new World(0, [], [], "0:00", "waiting");

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

        if(data.status == "waiting"){
            initializeWaitingMode();
        }
        else
        {
            if (data.status == "connected"){
                initializeGame();
                _STARTGAME = false;
            }
    
            else if(_WORLD.getStatus() == 'tie' || _WORLD.getStatus() == 'win' || _WORLD.getStatus == 'loose'){
                drawResult();
                _SOCKET.onmessage = null;
            }
            else{
                console.log("ID", data.status[0]);
                _WORLD.setID(data.status[0]);

                console.log("Snakes", data.status[1]);
                _WORLD.setSnakes(data.status[1]);

                console.log("Items", data);
                _WORLD.setItems(data[2]);

                console.log("Timer", data);
                _WORLD.setTimer(data[3]);

                console.log("Status", data);
                _WORLD.setStatus(data[4]);
    
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
    constructor(id, snakes, items, timer, status){
        this.id = id;
        this.snakes = snakes;
        this.snake1 = snakes[0];
        this.snake2 = snakes[1];
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

    getSnake1(){
        return this.snake1;
    }

    getSnake2(){
        return this.snake2;
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
        this.snake1 = newSnakes[0];
        this.snake2 = newSnakes[1];
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

