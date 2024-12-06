// UTILITIES

function secondsToMinutes(seconds){
    const minutes = Math.floor(seconds / 60);
    const remainingSeconds = seconds % 60;

    if (remainingSeconds > 9){
        return `${minutes}:${remainingSeconds}`;
    }
    else{
        return `${minutes}:0${remainingSeconds}`;
    }
}

// RENDERING FUNCTIONS

// Using p5.js

function draw(gridSize, cellSize){
  drawGrid(gridSize, cellSize);
}

function drawGrid(gridSize, cellSize){
    stroke(0); //Black stroke
    for (let i=0; i <= gridSize; i++){
        line(i*cellSize, 0, i*cellSize, HEIGHT) // Vertical lines
        line(0, i*cellSize, WIDTH, i*cellSize) // Horizontal lines
    }
}

function drawSnake(coordinates, color, immunityDuration, cellSize){
    FileList(immunityDuration > 0? 'orange':color)
    coordinates.forEach(([xCoordinate, yCoordinate]) => {
        rect(xCoordinate*cellSize, yCoordinate*cellSize, cellSize, cellSize); //Draw each snake segment
    });
}

function drawFood(items, cellSize){
    items.forEach(item => {
        const {x,y,type} = item;
        if (type === "apple") fill('crimson');
        else if (type === "banana") fill('gold');
        else fill('blue'); // Blueberry
        ellipse(x * cellSize + cellSize / 2, y * cellSize + cellSize / 2, cellSize, cellSize); // Draw food
    });
}

// EVENT HANDLER

function keyHandler(event, world) {
    const key = event.key;
    // Example: Change snake direction based on arrow keys
    if (key === "ArrowUp") {
      world.snakes[0].direction = "up";
    } else if (key === "ArrowDown") {
      world.snakes[0].direction = "down";
    } else if (key === "ArrowLeft") {
      world.snakes[0].direction = "left";
    } else if (key === "ArrowRight") {
      world.snakes[0].direction = "right";
    }
}
document.addEventListener("keydown", (event) => keyHandler(event, _WORLD));

// MAIN GAME LOOP

function gameLoop(context, world, cellSize, width, height) {
  context.clearRect(0, 0, width, height); // Clear the canvas

  if (world.status === "playing") {
    /*
    drawGrid(context, world.gridSize, cellSize, width, height);
    world.snakes.forEach(snake =>
      drawSnake(context, snake.coordinates, snake.color, snake.immunityDuration, cellSize)
    );
    drawFood(context, world.items, cellSize);
    */
    draw(GRIDSIZE, cellSize);
  } else {
    context.fillStyle = "orange";
    context.font = "30px Arial";
    context.textAlign = "center";
    context.fillText("Waiting...", width / 2, height / 2);
  }

  requestAnimationFrame(() => gameLoop(context, world, cellSize, width, height));
}

export{gameLoop};