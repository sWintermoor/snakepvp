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