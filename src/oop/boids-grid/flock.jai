Flock :: struct {
    maxSpeed := MAX_SPEED;
    perception := PERCEPTION;
    alignmentFactor := ALIGNMENT_FACTOR;
    separationFactor := SEPARATION_FACTOR;
    cohesionFactor := COHESION_FACTOR;
    boundsMargin := BOUNDS_MARGIN;
    boundsSteeringFactor := BOUNDS_FACTOR;
    boids: *List(*Boid);
    boidsGrid: [] List(*Boid);
}

initFlock :: (numberOfBoids := NUMBER_OF_BOIDS) {
    ctx := context.gameContext;
    assert(ctx != null);

    flock := ctx.flock;
    assert(flock != null);

    options: ListOptions(*Boid);
    options.capacity = numberOfBoids;
    options.freeItems = true;

    flock.boids = alloc(List(*Boid));
    init(flock.boids, options);

    for 0..numberOfBoids-1 {
        position := vec2(
            randomNext(flock.boundsMargin, ctx.windowSize.x - flock.boundsMargin),
            randomNext(flock.boundsMargin, ctx.windowSize.y - flock.boundsMargin)
        );
        velocity := vec2Random() * randomNext(5, 10);

        boid := alloc(Boid);
        initBoid(boid, position, velocity);
        add(flock.boids, boid);
    }

    initBoidsGrid();
}

initBoidsGrid :: () {
    ctx := context.gameContext;
    assert(ctx != null);

    flock := ctx.flock;
    assert(flock != null);

    rows, cols := getGridSize();
    flock.boidsGrid = allocArray(List(*Boid), rows * cols);
    for * list : flock.boidsGrid {
        <<list = createList(*Boid);
    }
    updateBoidsGrid();
}

uninitBoidsGrid :: () {
    ctx := context.gameContext;
    assert(ctx != null);

    flock := ctx.flock;
    assert(flock != null);

    for * list : flock.boidsGrid {
        uninit(list);
    }
    free(flock.boidsGrid);
}

updateBoidsGrid :: () {
    ctx := context.gameContext;
    assert(ctx != null);

    flock := ctx.flock;
    assert(flock != null);

    rows, cols := getGridSize();
    cellSize := getGridCellSize(rows - 2, cols - 2);

    for * list : flock.boidsGrid {
        clear(list);
    }

    for boid : flock.boids {
        row := cast(s64) (boid.position.y / cellSize.y) + 1;
        col := cast(s64) (boid.position.x / cellSize.x) + 1;
        if (row >= 0 && row < rows && col >= 0 && col < cols) {
            list := *flock.boidsGrid[row * cols + col];
            add(list, boid);
        }
    }
}

updateFlock :: () {
    ctx := context.gameContext;
    assert(ctx != null);

    flock := ctx.flock;
    assert(flock != null);

    otherBoidsTotal := 0;

    for boid : flock.boids {
        otherBoidsTotal += updateBoid(boid);
    }

    // print("Average other boids count: %\n", otherBoidsTotal / flock.boids.count);

    uninitBoidsGrid();
    initBoidsGrid();
}

renderFlock :: () {
    ctx := context.gameContext;
    assert(ctx != null);

    flock := ctx.flock;
    assert(flock != null);

    // renderBoidsGrid();

    for boid : flock.boids {
        renderBoid(boid);
    }

    firstBoid := get(flock.boids, 0);
    renderBoidPerception(firstBoid);
}

renderBoidsGrid :: () {
    ctx := context.gameContext;
    assert(ctx != null);

    flock := ctx.flock;
    assert(flock != null);

    windowSize := vec2(ctx.windowSize);

    rows, cols := getGridSize();
    cellSize := getGridCellSize(rows - 2, cols - 2);

    nvgSave(ctx.gfx);
    nvgBeginPath(ctx.gfx);
    nvgStrokeColor(ctx.gfx, nvgRGB(120, 120, 120));

    for row : 2..rows-2 {
        nvgMoveTo(ctx.gfx, 0, (row - 1) * cellSize.y);
        nvgLineTo(ctx.gfx, windowSize.x, (row - 1) * cellSize.y);
    }

    for col : 2..cols-2 {
        nvgMoveTo(ctx.gfx, (col - 1) * cellSize.x, 0);
        nvgLineTo(ctx.gfx, (col - 1) * cellSize.x, windowSize.y);
    }

    nvgStroke(ctx.gfx);
    nvgRestore(ctx.gfx);
}

getGridSize :: () -> (rows: s64, cols: s64) {
    ctx := context.gameContext;
    assert(ctx != null);

    flock := ctx.flock;
    assert(flock != null);

    value := cast(s64) ceilf(sqrtf(cast(f32) flock.boids.count));
    return (value + 2, value + 2);
}

getGridCellSize :: (rows: s64, cols: s64) -> Vec2 {
    ctx := context.gameContext;
    assert(ctx != null);

    return vec2(
        cast(f32) ctx.windowSize.x / cols,
        cast(f32) ctx.windowSize.y / rows
    );
}