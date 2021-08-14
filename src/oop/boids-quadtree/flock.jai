Flock :: struct {
    boids: *List(*Boid);
    boidsQuadTree: *QuadTree;
}

initFlock :: (numberOfBoids := NUMBER_OF_BOIDS) {
    ctx := context.gameContext;
    flock := ctx.flock;

    options: ListOptions(*Boid);
    options.capacity = numberOfBoids;
    options.freeItems = true;

    flock.boids = alloc(List(*Boid));
    init(flock.boids, options);

    for 0..numberOfBoids-1 {
        position := vec2(
            randomNext(0, ctx.windowSize.x),
            randomNext(0, ctx.windowSize.y)
        );
        velocity := vec2Random() * randomNext(5, 10);

        boid := alloc(Boid);
        initBoid(boid, position, velocity);
        add(flock.boids, boid);
    }

    initQuadTree();
}

initQuadTree :: () {
    ctx := context.gameContext;
    flock := ctx.flock;

    boundary := rect(
        VEC2_ZERO,
        vec2(ctx.windowSize)
    );

    flock.boidsQuadTree = alloc(QuadTree);
    init(flock.boidsQuadTree, boundary, 1);
    for boid : flock.boids {
        insert(flock.boidsQuadTree, boid.position, boid);
    }
}

updateFlock :: () {
    ctx := context.gameContext;
    flock := ctx.flock;

    otherBoidsTotal := 0;

    for boid : flock.boids {
        otherBoidsTotal += updateBoid(boid);
    }

    // print("Average other boids count: %\n", otherBoidsTotal / flock.boids.count);

    uninit(flock.boidsQuadTree, true);
    initQuadTree();
}

renderFlock :: () {
    ctx := context.gameContext;
    flock := ctx.flock;

    #if (RENDER_QUADTREE) {
        renderQuadTree(flock.boidsQuadTree);
    }

    for boid : flock.boids {
        renderBoid(boid);
    }

    #if (RENDER_PERCEPTION) {
        firstBoid := get(flock.boids, 0);
        renderBoidPerception(firstBoid);
    }
}

renderQuadTree :: (tree: *QuadTree) {
    ctx := context.gameContext;

    x := tree.boundary.x;
    y := tree.boundary.y;
    w := tree.boundary.w;
    h := tree.boundary.h;

    nvgSave(ctx.gfx);
    nvgBeginPath(ctx.gfx);
    nvgStrokeColor(ctx.gfx, nvgRGB(120, 120, 120));
    nvgRect(ctx.gfx, x, y, w, h);
    nvgStroke(ctx.gfx);
    nvgRestore(ctx.gfx);

    if (tree.children != null) {
        for i : 0..3 {
            renderQuadTree(*tree.children[i]);
        }
    }
}
