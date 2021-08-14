Boid :: struct {
    id: ecs_entity_t;
    position: Vec2;
    velocity: Vec2;
}

updateBoid :: (ctx: *GameContext, boid: Boid) -> Boid {
    flock := ctx.flock;

    boidCopy := boid;

    otherBoids := getOtherBoids(ctx, boidCopy);
    defer uninit(*otherBoids);

    boidCopy.velocity += getBoundsSteering(ctx, boidCopy);
    boidCopy.velocity += getFlockSteering(ctx, boidCopy, otherBoids);
    boidCopy.velocity = clampLength(boidCopy.velocity, BOID_MAX_SPEED);
    boidCopy.position += boidCopy.velocity;
    boidCopy.position = getBoundsCheck(ctx, boidCopy.position);
    return boidCopy;
}

renderBoid :: (gfx: *NVGcontext, position: Vec2, velocity: Vec2, color: Color) {
    nvgSave(gfx);
    nvgTranslate(gfx, position.x, position.y);

    nvgTranslate(gfx, 0, 2*BOID_HEIGHT/3);
    angle := angleClockwise(VEC2_UP, velocity);
    nvgRotate(gfx, angle);
    nvgTranslate(gfx, 0, -2*BOID_HEIGHT/3);

    nvgBeginPath(gfx);
    nvgMoveTo(gfx, 0, 0);
    nvgLineTo(gfx, -BOID_WIDTH/2, BOID_HEIGHT);
    nvgLineTo(gfx, 0, 2*BOID_HEIGHT/3);
    nvgLineTo(gfx, BOID_WIDTH/2, BOID_HEIGHT);
    nvgFillColor(gfx, nvgRGB(color.r, color.g, color.b));
    nvgFill(gfx);
    nvgRestore(gfx);
}

renderBoidTrail :: (gfx: *NVGcontext, trail: List(Vec2), color: Color) {
    if (trail.count < 2) {
        return;
    }

    nvgSave(gfx);
    nvgTranslate(gfx, 0, 2*BOID_HEIGHT/3);
    nvgBeginPath(gfx);
    nvgMoveTo(gfx, trail[trail.count-1].x, trail[trail.count-1].y);
    for < i : trail.count-2..0 {
        if (abs(trail[i].x - trail[i + 1].x) > 10 ||
            abs(trail[i].y - trail[i + 1].y) > 10)
        {
            nvgMoveTo(gfx, trail[i].x, trail[i].y);
        } else {
            nvgLineTo(gfx, trail[i].x, trail[i].y);
        }
    }
    nvgStrokeColor(gfx, nvgRGBA(color.r, color.g, color.b, color.a));
    nvgStrokeWidth(gfx, 1);
    nvgStroke(gfx);
    nvgRestore(gfx);
}

renderBoidPerception :: (ctx: *GameContext, position: Vec2) {
    flock := ctx.flock;

    nvgSave(ctx.gfx);
    nvgTranslate(ctx.gfx, position.x, position.y + 8);
    nvgBeginPath(ctx.gfx);
    nvgCircle(ctx.gfx, 0, 0, BOID_PERCEPTION);
    nvgFillColor(ctx.gfx, nvgRGBA(100, 100, 100, 100));
    nvgFill(ctx.gfx);
    nvgCircle(ctx.gfx, 0, 0, BOID_PERCEPTION);
    nvgStrokeColor(ctx.gfx, nvgRGBA(255, 255, 255, 255));
    nvgStrokeWidth(ctx.gfx, 2.0);
    nvgStroke(ctx.gfx);
    nvgRestore(ctx.gfx);
}

#scope_file

getOtherBoids :: (ctx: *GameContext, boid: Boid) -> List(Boid) {
    flock := ctx.flock;

    otherBoids := createList(Boid);

    entries := createList(QuadTreeEntry);
    defer uninit(*entries);

    range := rect(
        boid.position.x - BOID_PERCEPTION * 0.5,
        boid.position.y - BOID_PERCEPTION * 0.5,
        BOID_PERCEPTION,
        BOID_PERCEPTION
    );
    query(flock.boidsQuadTree, range, *entries);
    for entry : entries {
        other := cast(*Boid) entry.userData;
        if (other.id != boid.id) {
            add(*otherBoids, <<other);
        }
    }
    return otherBoids;
}

getBoundsSteering :: (ctx: *GameContext, boid: Boid) -> Vec2 {
    flock := ctx.flock;

    windowSize := vec2(ctx.windowSize);

    steering := vec2(0, 0);

    if (boid.position.x < BOUNDS_MARGIN) {
        steering.x = BOUNDS_STEERING_FACTOR;
    } else if (boid.position.x > windowSize.x - BOUNDS_MARGIN) {
        steering.x = -BOUNDS_STEERING_FACTOR;
    }

    if (boid.position.y < BOUNDS_MARGIN) {
        steering.y = BOUNDS_STEERING_FACTOR;
    } else if (boid.position.y > windowSize.y - BOUNDS_MARGIN) {
        steering.y = -BOUNDS_STEERING_FACTOR;
    }

    return steering;
}

getBoundsCheck :: (ctx: *GameContext, position: Vec2) -> Vec2 {
    result := position;

    windowSize := vec2(ctx.windowSize);

    if (result.x < 0) {
        result.x = windowSize.x;
    } else if (result.x >= windowSize.x) {
        result.x = 0;
    }

    if (result.y < 0) {
        result.y = windowSize.y;
    } else if (result.y >= windowSize.y) {
        result.y = 0;
    }

    return result;
}

getFlockSteering :: (ctx: *GameContext, boid: Boid, otherBoids: List(Boid)) -> Vec2 {
    flock := ctx.flock;

    alignment := vec2(0, 0);
    separation := vec2(0, 0);
    cohesion := vec2(0, 0);

    total: s32 = 0;

    for other : otherBoids {
        alignment += other.velocity;

        diff := boid.position - other.position;
        dist := length(diff);
        if (dist <= SEPARATION_DISTANCE) {
            separation += (diff / dist);
        }

        cohesion += other.position;

        total += 1;
    }

    if (total > 0) {
        alignment /= total;
        alignment = setLength(alignment, BOID_MAX_SPEED);
        alignment -= boid.velocity;
        alignment = clampLength(alignment, ALIGNMENT_FACTOR);

        separation /= total;
        separation = setLength(separation, BOID_MAX_SPEED);
        separation -= boid.velocity;
        separation = clampLength(separation, SEPARATION_FACTOR);

        cohesion /= total;
        cohesion -= boid.position;
        cohesion = setLength(cohesion, BOID_MAX_SPEED);
        cohesion -= boid.velocity;
        cohesion = clampLength(cohesion, COHESION_FACTOR);
    }

    return alignment + separation + cohesion;
}
