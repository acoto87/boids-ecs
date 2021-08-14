Flock :: struct {
    maxSpeed := MAX_SPEED;
    perception := PERCEPTION;
    alignmentFactor := ALIGNMENT_FACTOR;
    separationFactor := SEPARATION_FACTOR;
    cohesionFactor := COHESION_FACTOR;
    boundsMargin := BOUNDS_MARGIN;
    boundsSteeringFactor := BOUNDS_FACTOR;
    boids: *List(*Boid);
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
}

renderFlock :: () {
    ctx := context.gameContext;
    assert(ctx != null);

    flock := ctx.flock;
    assert(flock != null);

    for boid : flock.boids {
        renderBoid(boid);
    }

    firstBoid := get(flock.boids, 0);
    renderBoidPerception(firstBoid);
}
