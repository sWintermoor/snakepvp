const GAMESIZE = 5;
const GRIDSIZE = GAMESIZE*5;
const CELLSIZE = GAMESIZE*6;
const WIDTH = GRIDSIZE*CELLSIZE;
const HEIGHT = GRIDSIZE*CELLSIZE;
const IMAGE = document.getElementById("gameImage");
// Hex-Codes für Neon-Look
const SNAKE1COLOR = "#00FF00"; // Neon Grün
const SNAKE2COLOR = "#00FFFF"; // Neon Cyan

var _SOCKET;
const PLAYBUTTON = document.getElementById("playButton");

var _BOARD;
var _CONTEXT;
var _WORLD;
var _SNAKE1;
var _SNAKE2;
var _STARTGAME;

PLAYBUTTON.addEventListener("click", testMain);

// ... (testMain Funktion bleibt gleich, Socket Logic ist ok) ...
// Hier nur der relevante Teil für testMain, kopiere deinen existierenden Code
// ABER: Entferne in testMain() das "initializeGame()" wenn "connected", 
// da dies oft das Board zu früh löscht. Die Logik unten regelt das Zeichnen.
// Ansonsten lass testMain wie es ist.

function testMain(){
    // ... dein bestehender Code ...
    // Achte darauf, dass initializeGame() unten aktualisiert wird
    _SOCKET = new WebSocket('ws://127.0.0.1:5501');
    
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

    // Beim socket.onmessage Teil:
    _SOCKET.onmessage = (event) => {
        console.log("test");

        console.log("Received data", event.data);

        const data = JSON.parse(event.data);

        console.log("Parsed data", data);

        console.log("Type of gameStatus:", typeof data.gameStatus);

        if(data.gameStatus == "waiting"){
            initializeWaitingMode();
        }
        else {
            if (data.gameStatus == "connected"){
                initializeGame();
                _STARTGAME = false;
                const startMessage = (JSON.stringify({key: "start"}));
                console.log("Attempting to send start message:", startMessage);
                try {
                    _SOCKET.send(startMessage);
                } catch (error) { console.error(error); }
            }
            else if(data.gameStatus == 'tie' || data.gameStatus == 'win' || data.gameStatus == 'loose'){
                // STATUS AUCH SETZEN DAMIT DRAWRESULT ZUGRIFF HAT
                 _WORLD.setStatus(data.gameStatus);
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
                    //_WORLD.setScore(data.apple1Score, data.banana1Score, data.blueberry1Score, data.apple2Score, data.banana2Score, data.blueberry2Score);

                    console.log("Timer", data.timer);
                    _WORLD.setTimer(data.timer);

                    console.log("Status", data.gameStatus);
                    _WORLD.setStatus(data.gameStatus);
        
                    // UPDATE LOOP
                    cleanBoard();
                    drawGrid(); // Kann man weglassen für cleaneren Look, ich habe es dezenter gemacht
                    drawSnakes();
                    drawFoods();
                    // UI am Ende zeichnen, damit sie über allem liegt
                    drawUI(data.apple1Score, data.banana1Score, data.blueberry1Score, data.apple2Score, data.banana2Score, data.blueberry2Score); 
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
    _BOARD = document.getElementById("gameCanvas");
    _BOARD.setAttribute("tabindex", "0");
    _BOARD.width = WIDTH;
    _BOARD.height = HEIGHT;
    _CONTEXT = _BOARD.getContext("2d");

    IMAGE.style.display = "none";
    _BOARD.style.display = "block";
    PLAYBUTTON.style.display = "none"; // Button ausblenden während Spiel

    window.addEventListener('load', () => _BOARD.focus());
    _BOARD.addEventListener('click', () => _BOARD.focus());
}

function initializeWaitingMode(){
    cleanBoard();
    _CONTEXT.fillStyle = "#00ffcc";
    _CONTEXT.font = "bold 30px 'Roboto Mono'";
    _CONTEXT.textAlign = "center";
    _CONTEXT.shadowBlur = 10;
    _CONTEXT.shadowColor = "#00ffcc";
    _CONTEXT.fillText("WAITING FOR OPPONENT...", _BOARD.width / 2, _BOARD.height / 2);
    _CONTEXT.shadowBlur = 0; // Reset
}

function initializeGame(){
    //cleanBoard();
    //drawGrid();
    createKeyHandler();
}

function cleanBoard(){
    // Dunkler Hintergrund statt weiß
    _CONTEXT.fillStyle = "#111"; 
    _CONTEXT.fillRect(0, 0, _BOARD.width, _BOARD.height);
    _BOARD.style.border = "2px solid #333";   
}

function drawGrid(){
    _CONTEXT.beginPath();
    // Sehr subtiles Grid
    _CONTEXT.strokeStyle = "rgba(255, 255, 255, 0.05)"; 
    _CONTEXT.lineWidth = 1;

    for (let i=0; i <= GRIDSIZE; i++){
        _CONTEXT.moveTo(i*CELLSIZE, 0);
        _CONTEXT.lineTo(i*CELLSIZE, HEIGHT);
        _CONTEXT.moveTo(0, i*CELLSIZE);
        _CONTEXT.lineTo(HEIGHT, i*CELLSIZE);
    }
    _CONTEXT.stroke();
}

function createKeyHandler(){
    // Um Mehrfach-Events zu vermeiden, besser prüfen ob Listener schon existiert
    // Oder einfach document.onkeydown nutzen (quick fix)
    document.onkeydown = (event) => {
        const data = JSON.stringify({movement: event.key});
        if(_SOCKET && _SOCKET.readyState === WebSocket.OPEN) {
            _SOCKET.send(data);
        }
    };
}

// Zusammengefasste UI Funktion (Score + Timer)
function drawUI(apple1Score, banana1Score, blueberry1Score, apple2Score, banana2Score, blueberry2Score){
    // Top Bar Background
    _CONTEXT.fillStyle = "rgba(0, 0, 0, 0.6)";
    _CONTEXT.fillRect(0, 0, WIDTH, 40);

    _CONTEXT.font = "bold 20px 'Roboto Mono'";
    _CONTEXT.textBaseline = "middle";
    
    // Timer (Mitte)
    _CONTEXT.fillStyle = "white";
    _CONTEXT.textAlign = "center";
    let timerText = _WORLD.getTimer() || "0:00";
    _CONTEXT.fillText(timerText, WIDTH/2, 20);

    // Player 1 (Links)
    _CONTEXT.fillStyle = SNAKE1COLOR;
    _CONTEXT.textAlign = "left";
    // Score Logik fehlt im World Objekt, daher zeigen wir hier nur "P1" an oder Länge
    let s1Length = _WORLD.getSnake1Coordinates() ? _WORLD.getSnake1Coordinates().length : 0;
    //console.log("Snake1 Fruits for UI:", _WORLD.getFruits());
    //let s1Bananas = 
    //let s1Blueberries = _WORLD.getFruits().filter(f => f.getType() === "blueberry").length;
    _CONTEXT.fillText("P1: P: " + s1Length + " Ba: " + banana1Score + " Bl: " + blueberry1Score, 10, 20);

    // Player 2 (Rechts)
    _CONTEXT.fillStyle = SNAKE2COLOR;
    _CONTEXT.textAlign = "right";
    let s2Length = _WORLD.getSnake2Coordinates() ? _WORLD.getSnake2Coordinates().length : 0;
    //let s2Bananas = _WORLD.getFruits().filter(f => f.getType() === "banana").length;
    //let s2Blueberries = _WORLD.getFruits().filter(f => f.getType() === "blueberry").length;
    _CONTEXT.fillText("P2: P: " + s2Length + " Ba: " + banana2Score + " Bl: " + blueberry2Score, WIDTH - 10, 20);
}

// Deine alten drawPlayer/drawScore/drawTimer brauchst du nicht mehr einzeln, 
// da drawUI das übernimmt. Ich lasse sie leer stehen falls du sie referenzierst.
function drawPlayer(){}
function drawScore(){}
function drawTimer(){}

function drawSnakes(){
    // Snake 1
    if(_WORLD.getSnake1()) drawSnake(_WORLD.getSnake1(), SNAKE1COLOR);
    // Snake 2
    if(_WORLD.getSnake2()) drawSnake(_WORLD.getSnake2(), SNAKE2COLOR);
}

function drawSnake(snakeInput, colorOverride){
    const coords = snakeInput.getCoordinates();
    if(!coords) return;

    _CONTEXT.fillStyle = colorOverride || snakeInput.getColor();
    
    // Glow Effekt
    _CONTEXT.shadowBlur = 10;
    _CONTEXT.shadowColor = colorOverride || snakeInput.getColor();

    coords.forEach(coordinate => {
        // Etwas kleiner als die Zelle für einen Segment-Look
        _CONTEXT.fillRect(coordinate[0] + 1, coordinate[1] + 1, CELLSIZE - 2, CELLSIZE - 2);
    });

    _CONTEXT.shadowBlur = 0; // Reset Glow für Performance und andere Objekte
}


function drawCoordinate([x, y]){
    // Wird von drawSnake ersetzt
    _CONTEXT.fillRect(x, y, CELLSIZE, CELLSIZE);
}

function drawFoods(){
    _WORLD.getFruits().forEach(food => {
        drawSpecificFood(food);
    });
}

function drawSpecificFood(food){
    let x = food.getXCoordinate();
    let y = food.getYCoordinate();
    let type = food.getType();
    
    let radius = CELLSIZE/2.5;

    _CONTEXT.save(); 

    if (type == "apple"){
        _CONTEXT.shadowColor = "red";
        _CONTEXT.shadowBlur = 15;
        _CONTEXT.fillStyle = '#ff3333';
        _CONTEXT.beginPath();
        _CONTEXT.arc(x, y, radius, 0, 2*Math.PI);
        _CONTEXT.fill();
    }
    else if (type == "banana"){
        _CONTEXT.shadowColor = "yellow";
        _CONTEXT.shadowBlur = 10;
        _CONTEXT.fillStyle = '#ffff33';
        _CONTEXT.beginPath();
        _CONTEXT.arc(x, y, radius, 0, 2*Math.PI);
        _CONTEXT.fill();
    }
    else{ // Blueberry
        _CONTEXT.shadowColor = "blue";
        _CONTEXT.shadowBlur = 15;
        _CONTEXT.fillStyle = '#3333ff';
        _CONTEXT.beginPath();
        _CONTEXT.arc(x, y, radius, 0, 2*Math.PI);
        _CONTEXT.fill();
    }
    
    _CONTEXT.restore(); // Schatteneinstellungen zurücksetzen
}

function drawResult(){
    // Overlay zeichnen
    _CONTEXT.fillStyle = "rgba(0,0,0,0.7)";
    _CONTEXT.fillRect(0,0,WIDTH,HEIGHT);

    let status = _WORLD.getStatus();
    let message = "";
    let color = "white";

    if(status == "win") { message = "YOU WON!"; color = "#00ffcc"; }
    else if(status == "loose") { message = "GAME OVER"; color = "#ff3333"; }
    else if(status == "tie") { message = "DRAW!"; color = "orange"; }

    _CONTEXT.font = "bold 50px 'Roboto Mono'";
    _CONTEXT.textAlign = "center";
    _CONTEXT.fillStyle = color;
    _CONTEXT.shadowBlur = 20;
    _CONTEXT.shadowColor = color;
    
    _CONTEXT.fillText(message, WIDTH/2, HEIGHT/2);
    
    _CONTEXT.font = "20px 'Roboto Mono'";
    _CONTEXT.fillStyle = "white";
    _CONTEXT.shadowBlur = 0;
    _CONTEXT.fillText("Refresh to play again", WIDTH/2, HEIGHT/2 + 50);

    PLAYBUTTON.style.display = "inline-block"; 
    PLAYBUTTON.textContent = "Restart";
    PLAYBUTTON.onclick = () => location.reload();
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

    setScore(apple1Score, banana1Score, blueberry1Score, apple2Score, banana2Score, blueberry2Score){
        this.snake1.score = apple1Score;
        this.snake1.banana = banana1Score;
        this.snake1.blueberry = blueberry1Score;
        this.snake2.score = apple2Score;
        this.snake2.banana = banana2Score;
        this.snake2.blueberry = blueberry2Score;
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

