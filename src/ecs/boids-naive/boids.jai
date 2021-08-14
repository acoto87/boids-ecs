Boid :: struct {
    id: s32;
    position: Vec2;
    velocity: Vec2;
}

staticId: s32 = 0;

initBoid :: (boid: *Boid, position: Vec2, velocity: Vec2 = VEC2_ZERO) {
    staticId += 1;

    boid.id = staticId;
    boid.position = position;
    boid.velocity = velocity;
}

updateBoid :: (using boid: *Boid) -> s64 {
    ctx := context.gameContext;
    assert(ctx != null);

    flock := ctx.flock;
    assert(flock != null);

    otherBoids := getOtherBoids(boid);
    defer uninit(*otherBoids);

    boid.velocity += getBoundsSteering(boid);
    boid.velocity += getFlockSteering(boid, otherBoids);
    boid.velocity = clampLength(boid.velocity, flock.maxSpeed);

    boid.position += boid.velocity;

    return otherBoids.count;
}

renderBoid :: (using boid: *Boid) {
    ctx := context.gameContext;
    assert(ctx != null);

    nvgSave(ctx.gfx);
    nvgTranslate(ctx.gfx, position.x, position.y);

    nvgTranslate(ctx.gfx, 0, 8);
    angle := angleClockwise(VEC2_UP, boid.velocity);
    nvgRotate(ctx.gfx, angle);
    nvgTranslate(ctx.gfx, 0, -8);

    nvgBeginPath(ctx.gfx);
    nvgMoveTo(ctx.gfx, 0, 0);
    nvgLineTo(ctx.gfx, -5, 12);
    nvgLineTo(ctx.gfx, 0, 8);
    nvgLineTo(ctx.gfx, 5, 12);
    nvgFillColor(ctx.gfx, nvgRGB(255, 0, 0));
    nvgFill(ctx.gfx);
    nvgRestore(ctx.gfx);
}

renderBoidPerception :: (using boid: *Boid) {
    ctx := context.gameContext;
    assert(ctx != null);

    flock := ctx.flock;
    assert(flock != null);

    nvgSave(ctx.gfx);
    nvgTranslate(ctx.gfx, position.x, position.y + 8);
    nvgBeginPath(ctx.gfx);
    nvgCircle(ctx.gfx, 0, 0, flock.perception);
    nvgFillColor(ctx.gfx, nvgRGBA(100, 100, 100, 100));
    nvgFill(ctx.gfx);
    nvgCircle(ctx.gfx, 0, 0, flock.perception);
    nvgStrokeColor(ctx.gfx, nvgRGBA(255, 255, 255, 255));
    nvgStrokeWidth(ctx.gfx, 2.0);
    nvgStroke(ctx.gfx);
    nvgRestore(ctx.gfx);
}

#scope_file

getOtherBoids :: (using boid: *Boid) -> List(Boid) {
    ctx := context.gameContext;
    assert(ctx != null);

    flock := ctx.flock;
    assert(flock != null);

    otherBoids := createList(Boid);
    for other : flock.boids {
        if (other.id != boid.id && distanceSqr(position, other.position) <= flock.perception * flock.perception) {
            add(*otherBoids, other);
        }
    }
    return otherBoids;
}

getBoundsSteering :: (using boid: *Boid) -> Vec2 {
    ctx := context.gameContext;
    assert(ctx != null);

    flock := ctx.flock;
    assert(flock != null);

    windowSize := vec2(ctx.windowSize);

    steering := vec2(0, 0);

    if (position.x < flock.boundsMargin) {
        steering.x = flock.boundsSteeringFactor;
    } else if (position.x > windowSize.x - flock.boundsMargin) {
        steering.x = -flock.boundsSteeringFactor;
    }

    if (position.y < flock.boundsMargin) {
        steering.y = flock.boundsSteeringFactor;
    } else if (position.y > windowSize.y - flock.boundsMargin) {
        steering.y = -flock.boundsSteeringFactor;
    }

    return steering;
}

getFlockSteering :: (using boid: *Boid, otherBoids: List(Boid)) -> Vec2 {
    ctx := context.gameContext;
    assert(ctx != null);

    flock := ctx.flock;
    assert(flock != null);

    alignment := vec2(0, 0);
    separation := vec2(0, 0);
    cohesion := vec2(0, 0);

    total: s32 = 0;

    for other : otherBoids {
        dist := distance(position, other.position);

        alignment += other.velocity;
        separation += (position - other.position) / dist;
        cohesion += other.position;

        total += 1;
    }

    if (total > 0) {
        alignment /= total;
        alignment = setLength(alignment, flock.maxSpeed);
        alignment -= velocity;
        alignment = clampLength(alignment, flock.alignmentFactor);

        separation /= total;
        separation = setLength(separation, flock.maxSpeed);
        separation -= velocity;
        separation = clampLength(separation, flock.separationFactor);

        cohesion /= total;
        cohesion -= position;
        cohesion = setLength(cohesion, flock.maxSpeed);
        cohesion -= velocity;
        cohesion = clampLength(cohesion, flock.cohesionFactor);
    }

    return alignment + separation + cohesion;
}
