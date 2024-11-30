function main(){
    const canvas = document.getElementById("gameCanvas");
    const context = canvas.getContext("2d");
    const cellSize = 20;
    const gridSize = 20;
    const width = canvas.width = cellSize * gridSize;
    const height = canvas.height = cellSize * gridSize;

    // Initial world state
    const world = new World(0, [new Snake(1, [[5, 5]], "green", "alive", "up", 1, 0, 0)], [], "0:00", "playing");

    gameLoop(context, world, cellSize, width, height);
}
