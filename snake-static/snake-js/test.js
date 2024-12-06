const GAMESIZE = 5;
const GRIDSIZE = GAMESIZE*5;
const CELLSIZE = GAMESIZE*6;
const WIDTH = GRIDSIZE*CELLSIZE;
const HEIGHT = GRIDSIZE*CELLSIZE;
const IMAGE = document.getElementById("gameImage");

const SOCKET = new WebSocket('ws://localhost:9092');
const PLAYBUTTON = document.getElementById("playButton");

var _BOARD;
var _CONTEXT;
var _SNAKE1;
var _SNAKE2;
var _WORLD;

var _ID;
var _SNAKES;
var _ITEMS;
var _TIMER;
var _WORLDSTATUS;

function testMain(){
    _WORLD = new World(0, [], [], "0:00", "waiting");

    if (_WORLD[5] == "waiting"){
        initializeWaitingMode();
    }
    else{
        initializeGame();
    }

    SOCKET.onmessage({data}) => {
        _ID = data[0];
        _SNAKES = data[1];
        _ITEMS = data[2];
        _TIMER = data[3];
        _WORLDSTATUS = data[4];
    };
}

function initializeWaitingMode(){
    _CONTEXT.fillStyle = "orange";
    _CONTEXT.font = "30px Arial";
    _CONTEXT.textAlign = "center";
    _CONTEXT.fillText("Waiting...", canvas.width / 2, canvas.height / 2);
}

function initializeGame(){

    createBoard();
    drawGrid();
    createSnakes();
}

function createBoard(){
    _BOARD=document.getElementById("gameCanvas");
    _BOARD.width=WIDTH;
    _BOARD.height=HEIGHT;
    _CONTEXT=_BOARD.getContext("2d");

    IMAGE.style.display = "none";
    _BOARD.style.display = "block";

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

function createSnakes(){
    _SNAKE1 = new Snake()
}

function printHello(){
    IMAGE.style.display = "none";
    alert("Hi");
}


class World{
    constructor(id, snakes, items, timer, status){
        this.id = id;
        this.snakes = snakes;
        this.items = items;
        this.timer = timer;
        this.status = status;
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

PLAYBUTTON.addEventListener("click", testMain);