Boid :: struct {
    id: s32;
    position: Vec2;
    velocity: Vec2;
    color: Color;

    #if (RENDER_TRAILS) {
        trail: List(Vec2);
    }
}

staticId: s32 = 0;

initBoid :: (boid: *Boid, position: Vec2, velocity: Vec2 = VEC2_ZERO) {
    staticId += 1;

    boid.id = staticId;
    boid.position = position;
    boid.velocity = velocity;
    boid.color = getColorFromList(boid.id);
    #if (RENDER_TRAILS) {
        boid.trail = createList(Vec2, ListOptions(Vec2).{
            capacity = BOID_TRAIL_LENGTH
        });
    }
}

updateBoid :: (using boid: *Boid) -> s64 {
    ctx := context.gameContext;
    flock := ctx.flock;

    otherBoids := getOtherBoids(boid);
    defer uninit(*otherBoids);

    boid.velocity += getBoundsSteering(boid);
    boid.velocity += getFlockSteering(boid, otherBoids);
    boid.velocity = clampLength(boid.velocity, BOID_MAX_SPEED);
    boid.position += boid.velocity;
    boid.position = getBoundsCheck(boid);

    #if (RENDER_TRAILS) {
        if (boid.trail.count >= BOID_TRAIL_LENGTH) {
            removeAt(*boid.trail, 0);
        }
        add(*boid.trail, boid.position);
    }

    return otherBoids.count;
}

renderBoid :: (using boid: *Boid) {
    renderBoidBody(boid);

    #if (RENDER_TRAILS) {
        renderBoidTrail(boid);
    }
}

renderBoidBody :: (using boid: *Boid) {
    ctx := context.gameContext;

    nvgSave(ctx.gfx);
    nvgTranslate(ctx.gfx, position.x, position.y);

    nvgTranslate(ctx.gfx, 0, 2*BOID_HEIGHT/3);
    angle := angleClockwise(VEC2_UP, velocity);
    nvgRotate(ctx.gfx, angle);
    nvgTranslate(ctx.gfx, 0, -2*BOID_HEIGHT/3);

    nvgBeginPath(ctx.gfx);
    nvgMoveTo(ctx.gfx, 0, 0);
    nvgLineTo(ctx.gfx, -BOID_WIDTH/2, BOID_HEIGHT);
    nvgLineTo(ctx.gfx, 0, 2*BOID_HEIGHT/3);
    nvgLineTo(ctx.gfx, BOID_WIDTH/2, BOID_HEIGHT);
    nvgFillColor(ctx.gfx, nvgRGB(color.r, color.g, color.b));
    nvgFill(ctx.gfx);
    nvgRestore(ctx.gfx);
}

#if (RENDER_TRAILS) {
    renderBoidTrail :: (using boid: *Boid) {
        ctx := context.gameContext;

        if (trail.count < 2) {
            return;
        }

        nvgSave(ctx.gfx);
        nvgTranslate(ctx.gfx, 0, 2*BOID_HEIGHT/3);
        nvgBeginPath(ctx.gfx);
        nvgMoveTo(ctx.gfx, trail[trail.count-1].x, trail[trail.count-1].y);
        for < i : trail.count-2..0 {
            if (abs(trail[i].x - trail[i + 1].x) > 10 ||
                abs(trail[i].y - trail[i + 1].y) > 10)
            {
                nvgMoveTo(ctx.gfx, trail[i].x, trail[i].y);
            } else {
                nvgLineTo(ctx.gfx, trail[i].x, trail[i].y);
            }
        }
        nvgStrokeColor(ctx.gfx, nvgRGBA(color.r, color.g, color.b, color.a));
        nvgStrokeWidth(ctx.gfx, 1);
        nvgStroke(ctx.gfx);
        nvgRestore(ctx.gfx);
    }
}

#if (RENDER_PERCEPTION) {
    renderBoidPerception :: (using boid: *Boid) {
        ctx := context.gameContext;
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
}

#scope_file

getOtherBoids :: (using boid: *Boid) -> List(*Boid) {
    ctx := context.gameContext;
    flock := ctx.flock;

    otherBoids := createList(*Boid);

    range := rect(
        position.x - BOID_PERCEPTION * 0.5,
        position.y - BOID_PERCEPTION * 0.5,
        BOID_PERCEPTION,
        BOID_PERCEPTION
    );
    entries := createList(QuadTreeEntry);
    defer uninit(*entries);

    query(flock.boidsQuadTree, range, *entries);
    for entry : entries {
        other := cast(*Boid) entry.userData;
        if (other != boid) {
            add(*otherBoids, other);
        }
    }
    return otherBoids;
}

getBoundsSteering :: (using boid: *Boid) -> Vec2 {
    ctx := context.gameContext;
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

getBoundsCheck :: (boid: *Boid) -> Vec2 {
    ctx := context.gameContext;

    windowSize := vec2(ctx.windowSize);

    result := boid.position;

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

getFlockSteering :: (using boid: *Boid, otherBoids: List(*Boid)) -> Vec2 {
    ctx := context.gameContext;
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
        alignment -= velocity;
        alignment = clampLength(alignment, ALIGNMENT_FACTOR);

        separation /= total;
        separation = setLength(separation, BOID_MAX_SPEED);
        separation -= velocity;
        separation = clampLength(separation, SEPARATION_FACTOR);

        cohesion /= total;
        cohesion -= position;
        cohesion = setLength(cohesion, BOID_MAX_SPEED);
        cohesion -= velocity;
        cohesion = clampLength(cohesion, COHESION_FACTOR);
    }

    return alignment + separation + cohesion;
}
