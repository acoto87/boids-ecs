
#import "flecs-jai";

PositionComponent :: struct {
    position: Vec2;
}

VelocityComponent :: struct {
    velocity: Vec2;
}

ColorComponent :: struct {
    color: Color;
}

TrailComponent :: struct {
    positions: List(Vec2);
}

Flock :: struct {
    world: *ecs_world_t;
    positionId: ecs_entity_t;
    velocityId: ecs_entity_t;
    colorId: ecs_entity_t;
    trailId: ecs_entity_t;
    updateQuadTreeSystemId: ecs_entity_t;
    updateBoidsSystemId: ecs_entity_t;
    renderBoidsSystemId: ecs_entity_t;
    #if (RENDER_TRAILS) {
        renderTrailsSystemId: ecs_entity_t;
    }
    boidsQuadTree: *QuadTree;
}

initFlock :: (numberOfBoids := NUMBER_OF_BOIDS) {
    ctx := context.gameContext;
    flock := ctx.flock;

    world := ecs_init();

    positionId := ecs_component(world, PositionComponent);
    velocityId := ecs_component(world, VelocityComponent);
    colorId := ecs_component(world, ColorComponent);

    #if (RENDER_TRAILS) {
        trailId := ecs_component(world, TrailComponent);
    }

    for i : 0..numberOfBoids-1 {
        entity := ecs_entity(world, null, "PositionComponent, VelocityComponent, ColorComponent");

        position := vec2(
            randomNext(0, ctx.windowSize.x),
            randomNext(0, ctx.windowSize.y)
        );
        positionComponent: PositionComponent;
        positionComponent.position = position;
        ecs_set(world, entity, positionId, *positionComponent);

        velocity := vec2Random() * randomNext(BOID_MAX_SPEED/2, BOID_MAX_SPEED);
        velocityComponent: VelocityComponent;
        velocityComponent.velocity = velocity;
        ecs_set(world, entity, velocityId, *velocityComponent);

        color := getColorFromList(cast(s64) entity);
        colorComponent: ColorComponent;
        colorComponent.color = color;
        ecs_set(world, entity, colorId, *colorComponent);

        #if (RENDER_TRAILS) {
            trailComponent: TrailComponent;
            trailComponent.positions = createList(Vec2, ListOptions(Vec2).{
                capacity = BOID_TRAIL_LENGTH
            });
            ecs_set(world, entity, trailId, *trailComponent);
        }
    }

    updateQuadTreeSystemId := ecs_system(world, "UpdateQuadTree", updateQuadTree, 0, "PositionComponent, VelocityComponent");
    #if (RENDER_TRAILS) {
        updateBoidsSystemId := ecs_system(world, "UpdateBoids", updateBoids, 0, "PositionComponent, VelocityComponent, TrailComponent");
    } else {
        updateBoidsSystemId := ecs_system(world, "UpdateBoids", updateBoids, 0, "PositionComponent, VelocityComponent");
    }
    renderBoidsSystemId := ecs_system(world, "RenderBoids", renderBoids, 0, "PositionComponent, VelocityComponent, ColorComponent");

    #if (RENDER_TRAILS) {
        renderTrailsSystemId := ecs_system(world, "RenderTrails", renderTrails, 0, "TrailComponent, ColorComponent");
    }

    flock.world = world;
    flock.positionId = positionId;
    flock.velocityId = velocityId;
    flock.colorId = colorId;
    flock.updateQuadTreeSystemId = updateQuadTreeSystemId;
    flock.updateBoidsSystemId = updateBoidsSystemId;
    flock.renderBoidsSystemId = renderBoidsSystemId;

    #if (RENDER_TRAILS) {
        flock.trailId = trailId;
        flock.renderTrailsSystemId = renderTrailsSystemId;
    }
}

updateQuadTree :: (it: *ecs_iter_t) #c_call {
    newContext: Context;
    push_context newContext {
        ctx := cast(*GameContext) it.param;
        flock := ctx.flock;

        boundary := rect(
            VEC2_ZERO,
            vec2(ctx.windowSize)
        );

        if (flock.boidsQuadTree != null) {
            uninit(flock.boidsQuadTree, true, true);
        }
        flock.boidsQuadTree = alloc(QuadTree);
        init(flock.boidsQuadTree, boundary, 1);

        positionComponents := ecs_term(it, PositionComponent, 1);
        velocityComponents := ecs_term(it, VelocityComponent, 2);

        for i : 0..it.count-1 {
            boid := alloc(Boid);
            boid.id = it.entities[i];
            boid.position = positionComponents[i].position;
            boid.velocity = velocityComponents[i].velocity;

            insert(flock.boidsQuadTree, boid.position, boid);
        }
    }
}

updateBoids :: (it: *ecs_iter_t) #c_call {
    newContext: Context;
    push_context newContext {
        ctx := cast(*GameContext) it.param;
        flock := ctx.flock;

        positionComponents := ecs_term(it, PositionComponent, 1);
        velocityComponents := ecs_term(it, VelocityComponent, 2);

        #if (RENDER_TRAILS) {
            trailComponents := ecs_term(it, TrailComponent, 3);
        }

        for i : 0..it.count-1 {
            boid: Boid;
            boid.id = it.entities[i];
            boid.position = positionComponents[i].position;
            boid.velocity = velocityComponents[i].velocity;

            boid = updateBoid(ctx, boid);

            positionComponents[i].position = boid.position;
            velocityComponents[i].velocity = boid.velocity;

            #if (RENDER_TRAILS) {
                if (trailComponents[i].positions.count >= BOID_TRAIL_LENGTH) {
                    removeAt(*trailComponents[i].positions, 0);
                }
                add(*trailComponents[i].positions, boid.position);
            }
        }
    }
}

updateFlock :: () {
    ctx := context.gameContext;
    flock := ctx.flock;

    ecs_run(flock.world, flock.updateQuadTreeSystemId, 0, ctx);
    ecs_run(flock.world, flock.updateBoidsSystemId, 0, ctx);
}

renderBoids :: (it: *ecs_iter_t) #c_call {
    newContext: Context;
    push_context newContext {
        ctx := cast(*GameContext) it.param;
        flock := ctx.flock;

        #if (RENDER_QUADTREE) {
            renderQuadTree(ctx, flock.boidsQuadTree);
        }

        positionComponents := ecs_term(it, PositionComponent, 1);
        velocityComponents := ecs_term(it, VelocityComponent, 2);
        colorComponents := ecs_term(it, ColorComponent, 3);

        for i : 0..it.count-1 {
            renderBoid(ctx.gfx, positionComponents[i].position, velocityComponents[i].velocity, colorComponents[i].color);
        }

        #if (RENDER_PERCEPTION) {
            renderBoidPerception(ctx, positionComponents[0].position);
        }
    }
}

renderTrails :: (it: *ecs_iter_t) #c_call {
    newContext: Context;
    push_context newContext {
        ctx := cast(*GameContext) it.param;
        flock := ctx.flock;

        trailComponents := ecs_term(it, TrailComponent, 1);
        colorComponents := ecs_term(it, ColorComponent, 2);

        for i : 0..it.count-1 {
            renderBoidTrail(ctx.gfx, trailComponents[i].positions, colorComponents[i].color);
        }
    }
}

renderFlock :: () {
    ctx := context.gameContext;
    flock := ctx.flock;

    ecs_run(flock.world, flock.renderBoidsSystemId, 0, ctx);

    #if (RENDER_TRAILS) {
        ecs_run(flock.world, flock.renderTrailsSystemId, 0, ctx);
    }
}

renderQuadTree :: (ctx: *GameContext, tree: *QuadTree) {
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
            renderQuadTree(ctx, *tree.children[i]);
        }
    }
}
