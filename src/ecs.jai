#import "glfw";
#import "GL";
#import "stb_image";
#import "stb_image_write";
#import "nanovg";
#import "collections";
#import "utils";
#import "strings";

// OOP
// #load "oop/boids-quadtree/boids.jai";
// #load "oop/boids-quadtree/flock.jai";

// ECS
#load "ecs/boids-quadtree/boids.jai";
#load "ecs/boids-quadtree/flock.jai";

#load "game.jai";

NUMBER_OF_BOIDS :: 1000;
BOID_WIDTH :: 4;
BOID_HEIGHT :: 6;
BOID_MAX_SPEED :: 6.0;
BOID_PERCEPTION :: 50.0;
BOID_TRAIL_LENGTH :: 10;
ALIGNMENT_FACTOR :: 0.1;
SEPARATION_FACTOR :: 0.1;
SEPARATION_DISTANCE :: 1.5 * #run sqrtf(BOID_WIDTH * BOID_WIDTH + BOID_HEIGHT * BOID_HEIGHT);
COHESION_FACTOR :: 0.01;
BOUNDS_MARGIN :: 50;
BOUNDS_STEERING_FACTOR :: 0.7;
RENDER_QUADTREE :: false;
RENDER_PERCEPTION :: false;
RENDER_TRAILS :: false;

EXIT_SUCCESS :: 0;
EXIT_FAILURE :: -1;

SECONDS_PER_FRAME :: (1.0/60.0);

main :: () {
    loggerData := LoggerData.{
        severity = LogSeverity.Debug
    };
    initLogger(*loggerData);

    ctx: GameContext;
    context.gameContext = *ctx;

    if (!initGame("ECS Demo", vec2i(1366, 768), 1, 1)) {
        logError("Can't initialize the game!\n");
        exit(EXIT_FAILURE);
    }

    updateTitleTime := 1.0;

    while (!glfwWindowShouldClose(ctx.window)) {
        updateTitleTime -= ctx.deltaTime;
        if (updateTitleTime <= 0) {
            setWindowTitle(
                sprint(
                    "ECS Demo 1: % at % fps (%)",
                    formatFloat(ctx.time, trailing_width=2, zero_removal=FormatFloat.Zero_Removal.NO),
                    ctx.fps,
                    formatFloat(ctx.deltaTime, trailing_width=4, zero_removal=FormatFloat.Zero_Removal.NO)
                )
            );

            updateTitleTime = 1.0;
        }

        updateGame();
        renderGame();
        presentGame();

        resetTemporaryStorage();
    }

    uninitGame();

    exit(EXIT_SUCCESS);
}

#scope_file

Compiler :: #import "Compiler";
setTypeInfoFlags :: Compiler.compiler_set_type_info_flags;

#run setTypeInfoFlags(GL_Procedures, .PROCEDURES_ARE_VOID_POINTERS);
#run setTypeInfoFlags(GL_Procedures, .NO_SIZE_COMPLAINT);

// #import "flecs-jai";

// #run build(lib = false);
