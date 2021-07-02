Boid :: struct {
    position: Vec2;
    velocity: Vec2;
    acceleration: Vec2;
}

createBoid :: (position: Vec2, velocity: Vec2 = VEC2_ZERO, acceleration: Vec2 = VEC2_ZERO) -> *Boid {
    boid := alloc(Boid);
    boid.position = position;
    boid.velocity = velocity;
    boid.acceleration = acceleration;
    return boid;
}

align :: (using boid: *Boid) -> Vec2 {
    ctx := context.gameContext;
    assert(ctx != null);

    perception := 100.0;
    total: s32 = 0;

    steering := vec2(0, 0);
    for other : ctx.flock {
        if (boid != other && distance(position, other.position) < perception) {
            steering += other.velocity;
            total += 1;
        }
    }
    if (total > 0) {
        steering /= total;
        steering -= velocity;
    }
    return steering;
}

updateBoid :: (using boid: *Boid) {
    ctx := context.gameContext;
    assert(ctx != null);

    steering := align(boid);
    boid.acceleration = steering;

    boid.position += boid.velocity;
    boid.velocity += boid.acceleration;
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