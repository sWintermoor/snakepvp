import * as snakeClass from 'snake-pvp-world-classes.js';
import * as snakeFunction from 'snake-pvp-world-functions.js';

export function main(){
    const canvas = document.getElementById("gameCanvas");
    const image = document.getElementById("gameImage");
    const context = canvas.getContext("2d");
    const cellSize = 20;
    const gridSize = 20;
    const width = canvas.width = cellSize * gridSize;
    const height = canvas.height = cellSize * gridSize;

    image.style.display = "none";
    canvas.style.display = "block";

    // Initial world state
    const world = new snakeClass.World(0, [new snakeClass.Snake(1, [[5, 5]], "green", "alive", "up", 1, 0, 0)], [], "0:00", "waiting");

    snakeFunction.gameLoop(context, world, cellSize, width, height);
}
