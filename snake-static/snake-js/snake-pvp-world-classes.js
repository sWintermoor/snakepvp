class World{
    constructor(id, snakes, items, timer, status){
        this.id = id;
        this.snakes = snakes;
        this.items = items;
        this.timer = timer;
        this.status = status;
    }
}

class snake{
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

class item{
    constructor(type, xCoordinate, yCoordinate){
        this.type = type;
        this.xCoordinate = xCoordinate;
        this.yCoordinate = yCoordinate;
    }
}