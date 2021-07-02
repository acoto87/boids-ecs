initFlock :: () {
    ctx := context.gameContext;
    assert(ctx != null);

    ctx.flock = alloc(List(*Boid));
    init(ctx.flock, ListOptions(*Boid).{
        freeItems = true
    });

    // https://www.youtube.com/watch?v=mhjuuHl6qHM

    for 0..100 {
        position := vec2(randomNext(0, ctx.windowSize.x), randomNext(0, ctx.windowSize.y));
        velocity := vec2Random() * randomNext(5, 10);
        boid := createBoid(position, velocity);
        add(ctx.flock, boid);
    }
}

updateFlock :: () {
    ctx := context.gameContext;
    assert(ctx != null);

    for boid : ctx.flock {
        updateBoid(boid);
    }
}

renderFlock :: () {
    ctx := context.gameContext;
    assert(ctx != null);

    for boid : ctx.flock {
        renderBoid(boid);
    }
}