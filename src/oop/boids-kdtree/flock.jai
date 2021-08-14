Flock :: struct {
    maxSpeed := MAX_SPEED;
    perception := PERCEPTION;
    alignmentFactor := ALIGNMENT_FACTOR;
    separationFactor := SEPARATION_FACTOR;
    cohesionFactor := COHESION_FACTOR;
    boundsMargin := BOUNDS_MARGIN;
    boundsSteeringFactor := BOUNDS_FACTOR;
    boids: *List(*Boid);
    boidsKdTree: *KdTree;
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

    initKdTree();
}

initKdTree :: () {
    ctx := context.gameContext;
    assert(ctx != null);

    flock := ctx.flock;
    assert(flock != null);

    boundary := rect(VEC2_ZERO, vec2(ctx.windowSize));

    entries := allocArray(KdTreeEntry, flock.boids.count);
    for boid, i : flock.boids {
        entries[i].point = boid.position;
        entries[i].userData = boid;
    }
    defer free(entries);

    flock.boidsKdTree = alloc(KdTree);
    init(flock.boidsKdTree, boundary, entries);
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

    uninit(flock.boidsKdTree, true);
    initKdTree();
}

renderFlock :: () {
    ctx := context.gameContext;
    assert(ctx != null);

    flock := ctx.flock;
    assert(flock != null);

    // renderKdTree(flock.boidsKdTree);

    for boid : flock.boids {
        renderBoid(boid);
    }

    firstBoid := get(flock.boids, 0);
    renderBoidPerception(firstBoid);
}

renderKdTree :: (tree: *KdTree) {
    ctx := context.gameContext;
    assert(ctx != null);

    renderKdTree(tree, 0);
}

renderKdTree :: (tree: *KdTree, depth: s64) {
    ctx := context.gameContext;
    assert(ctx != null);

    nvgSave(ctx.gfx);
    nvgBeginPath(ctx.gfx);
    nvgStrokeColor(ctx.gfx, nvgRGB(120, 120, 120));

    if ((depth & 1) == 0) {
        nvgMoveTo(ctx.gfx, tree.point.x, tree.boundary.y);
        nvgLineTo(ctx.gfx, tree.point.x, tree.boundary.y + tree.boundary.h);
        nvgStroke(ctx.gfx);
        nvgRestore(ctx.gfx);
    } else {
        nvgMoveTo(ctx.gfx, tree.boundary.x, tree.point.y);
        nvgLineTo(ctx.gfx, tree.boundary.x + tree.boundary.w, tree.point.y);
        nvgStroke(ctx.gfx);
        nvgRestore(ctx.gfx);
    }

    if (tree.left != null) {
        renderKdTree(tree.left, depth + 1);
    }

    if (tree.right != null) {
        renderKdTree(tree.right, depth + 1);
    }
}
