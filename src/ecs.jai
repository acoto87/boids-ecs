#import "glfw";
#import "GL";
#import "stb_image";
#import "stb_image_write";
#import "nanovg";
#import "collections";
#import "utils";
#import "strings";

#load "boids.jai";
#load "flock.jai";
#load "game.jai";

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

    if (!initGame("ECS Demo", vec2i(320, 200), 3, 1)) {
        logError("Can't initialize the game!\n");
        exit(EXIT_FAILURE);
    }

    while (!glfwWindowShouldClose(ctx.window)) {
        setWindowTitle(
            sprint(
                "ECS Demo 1: % at % fps (%)",
                formatFloat(ctx.time, trailing_width=2, zero_removal=FormatFloat.Zero_Removal.NO),
                ctx.fps,
                formatFloat(ctx.deltaTime, trailing_width=4, zero_removal=FormatFloat.Zero_Removal.NO)
            )
        );

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
