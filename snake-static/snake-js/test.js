const cellSize = 20;
const gridSize = 20;

const image = document.getElementById("gameImage");

var playButton = document.getElementById("playButton");
playButton.addEventListener("click", printHello);

function testMain(){
    const canvas = document.getElementById("gameCanvas");
    const image = document.getElementById("gameImage");
    const context = canvas.getContext("2d");

    image.style.display = "none";
    canvas.style.display = "block";

    // Set the canvas size
    canvas.width = 500;
    canvas.height = 500;

    // Draw a red rectangle
    // context.fillStyle = "red";
    // context.fillRect(50, 50, 100, 100);

    context.fillStyle = "orange";
    context.font = "30px Arial";
    context.textAlign = "center";
    context.fillText("Waiting...", canvas.width / 2, canvas.height / 2);
}

function printHello(){
    image.style.display = "none";
    alert("Hi");
}

function draw(gridSize, cellSize){
    drawGrid(gridSize, cellSize);
}
  
function drawGrid(gridSize, cellSize){
    stroke(0); //Black stroke
    for (let i=0; i <= gridSize; i++){
        line(i*cellSize, 0, i*cellSize, height) // Vertical lines
        line(0, i*cellSize, width, i*cellSize) // Horizontal lines
    }
}