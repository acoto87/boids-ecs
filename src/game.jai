GameContext :: struct {
    time: f32;
    deltaTime: f32;
    fps: u32;

    paused: bool;

    globalScale: f32;
    globalSpeed: f32;
    musicEnabled: bool;
    soundEnabled: bool;
    musicVolume: f32;
    soundVolume: f32;

    originalWindowSize: Vec2i;
    windowSize: Vec2i;
    framebufferSize: Vec2i;
    devicePixelRatio: f32;
    windowTitle: string;
    window: *GLFWwindow;

    gfx: *NVGcontext;

    flock: *Flock;
}

#add_context gameContext: *GameContext;

setWindowTitle :: (title: string) {
    ctx := context.gameContext;
    assert(ctx != null);

    if (!isEmpty(ctx.windowTitle)) {
        free(ctx.windowTitle);
    }

    ctx.windowTitle = allocString(title);
    glfwSetWindowTitle(ctx.window, toCString(ctx.windowTitle, tempAllocator));
}

setWindowSize :: (size: Vec2i) {
    ctx := context.gameContext;
    assert(ctx != null);

    ctx.windowSize = size;
    glfwSetWindowSize(ctx.window, ctx.windowSize.x, ctx.windowSize.y);
    glfwGetFramebufferSize(ctx.window, *ctx.framebufferSize.x, *ctx.framebufferSize.y);
    ctx.devicePixelRatio = cast(f32) ctx.framebufferSize.x / cast(f32) ctx.windowSize.x;
}

setGlobalScale :: (scale: f32) {
    ctx := context.gameContext;
    assert(ctx != null);

    ctx.globalScale = max(scale, 1.0);
    logDebug("set global scale to: %\n", ctx.globalScale);

    newSize := ctx.originalWindowSize * ctx.globalScale;
    setWindowSize(newSize);
}

changeGlobalScale :: (deltaScale: f32) {
    ctx := context.gameContext;
    assert(ctx != null);

    setGlobalScale(ctx.globalScale + deltaScale);
}

setGlobalSpeed :: (speed: f32) {
    ctx := context.gameContext;
    assert(ctx != null);

    ctx.globalSpeed = max(speed, 1.0);
    logDebug("set global speed to: %\n", ctx.globalSpeed);
}

changeGlobalSpeed :: (deltaSpeed: f32) {
    ctx := context.gameContext;
    assert(ctx != null);

    setGlobalSpeed(ctx.globalSpeed + deltaSpeed);
}

getScaledSpeed :: (t: f32) -> f32 {
    ctx := context.gameContext;
    assert(ctx != null);

    t *= ctx.globalSpeed;
    return t;
}

getScaledTime :: inline (t: f32) -> f32 {
    ctx := context.gameContext;
    assert(ctx != null);

    t /= ctx.globalSpeed;
    return t;
}

initGame :: (windowTitle: string, originalWindowSize: Vec2i, globalScale: f32, globalSpeed: f32) -> bool {
    ctx := context.gameContext;
    assert(ctx != null);

    assert(!isEmpty(windowTitle));
    assert(originalWindowSize.x > 0 && originalWindowSize.y > 0);

    if (globalScale <= 0) {
        globalScale = 1;
    }

    if (globalSpeed <= 0) {
        globalSpeed = 1;
    }

    glfwSetErrorCallback(glfwErrorCallback);

    if (!glfwInit()) {
        logError("Error initializing GLFW!\n");
        return false;
    }

    glfwWindowHint(GLFW_RESIZABLE, 0);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 2);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 0);
    // glfwWindowHint(GLFW_CLIENT_API, GLFW_OPENGL_ES_API);

    ctx.globalScale = globalScale;
    ctx.globalSpeed = globalSpeed;
    ctx.musicEnabled = true;
    ctx.soundEnabled = true;
    ctx.musicVolume = 1;
    ctx.soundVolume = 1;
    ctx.originalWindowSize = originalWindowSize;
    ctx.windowSize = ctx.originalWindowSize * ctx.globalScale;
    ctx.windowTitle = allocString(windowTitle);
    ctx.window = glfwCreateWindow(ctx.windowSize.x, ctx.windowSize.y, toCString(ctx.windowTitle, tempAllocator), null, null);

    if (!ctx.window) {
        logError("GLFW window could not be created!\n");
        glfwTerminate();
        return false;
    }

    glfwSetWindowUserPointer(ctx.window, ctx);
    glfwSetCharCallback(ctx.window, inputCharCallback);

    glfwGetWindowSize(ctx.window, *ctx.windowSize.x, *ctx.windowSize.y);
    glfwGetFramebufferSize(ctx.window, *ctx.framebufferSize.x, *ctx.framebufferSize.y);
    ctx.devicePixelRatio = cast(f32) ctx.framebufferSize.x / cast(f32) ctx.windowSize.x;

    glfwMakeContextCurrent(ctx.window);

    glfwSetInputMode(ctx.window, GLFW_CURSOR, GLFW_CURSOR_HIDDEN);

    glLoad(glfwGetProcAddress);

    glCheckOpenGLVersion();

    // init graphics
    ctx.gfx = nvgCreateGL2(NVGcreateFlags.NVG_ANTIALIAS | .NVG_DEBUG);
    if (ctx.gfx == null) {
        logError("Could not init nanovg.\n");
        glfwDestroyWindow(ctx.window);
        glfwTerminate();
        return false;
    }

    ctx.flock = alloc(Flock);
    initFlock();

    glViewport(0, 0, cast(u32) ctx.framebufferSize.x, cast(u32) ctx.framebufferSize.y);
    glClearColor(0, 0, 0, 1.0);

    ctx.time = cast(f32) glfwGetTime();
    return true;
}

uninitGame :: () {
    ctx := context.gameContext;
    assert(ctx != null);

    nvgDeleteGL2(ctx.gfx);
    glfwDestroyWindow(ctx.window);
    glfwTerminate();
}

updateGame :: () {
    ctx := context.gameContext;
    assert(ctx != null);

    if (glfwIsKeyPressed(GLFW_KEY_ESCAPE)) {
        glfwSetWindowShouldClose(ctx.window, GLFW_TRUE);
    }

    if (glfwIsKeyPressed(GLFW_KEY_P)) {
        ctx.paused = !ctx.paused;
    }

    if (ctx.paused) {
        return;
    }

    // updateFlock();
}

renderGame :: () {
    ctx := context.gameContext;
    assert(ctx != null);

    glViewport(0, 0, cast(u32) ctx.framebufferSize.x, cast(u32) ctx.framebufferSize.y);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT | GL_STENCIL_BUFFER_BIT);

    nvgBeginFrame(ctx.gfx, cast(f32) ctx.windowSize.x, cast(f32) ctx.windowSize.y, ctx.devicePixelRatio);
    // renderFlock();

    nvgSave(ctx.gfx);
    // nvgBeginPathBatch(ctx.gfx);
    nvgBeginPath(ctx.gfx);

    nvgSave(ctx.gfx);
    nvgTranslate(ctx.gfx, 100.0, 100.0);
    nvgScale(ctx.gfx, 3, 3);
    nvgMoveTo(ctx.gfx, 50,  5);
    nvgLineTo(ctx.gfx, 80, 30);
    nvgLineTo(ctx.gfx, 65, 60);
    nvgLineTo(ctx.gfx, 35, 60);
    nvgLineTo(ctx.gfx, 20, 30);
    nvgClosePath(ctx.gfx);
    nvgRestore(ctx.gfx);

    // for i : 0..10 {
    //     for j : 0..10 {
    //         nvgSave(ctx.gfx);
    //         nvgTranslate(ctx.gfx, j * 100.0, i * 100.0);
    //         nvgMoveTo(ctx.gfx, 50,  5);
    //         nvgLineTo(ctx.gfx, 80, 30);
    //         nvgLineTo(ctx.gfx, 65, 60);
    //         nvgLineTo(ctx.gfx, 35, 60);
    //         nvgLineTo(ctx.gfx, 20, 30);
    //         nvgClosePath(ctx.gfx);
    //         nvgRestore(ctx.gfx);
    //     }
    // }

    nvgFillColor(ctx.gfx, nvgRGB(255, 0, 0));
    // nvgFillBatch(ctx.gfx);
    nvgFill(ctx.gfx);

    nvgRestore(ctx.gfx);

    // nvgSave(ctx.gfx);
    // // nvgAddPath(ctx.gfx);

    // nvgBeginPathBatch(ctx.gfx);

    // // nvgBeginPath(ctx.gfx);
    // nvgMoveTo(ctx.gfx, 100, 100);
    // nvgLineTo(ctx.gfx, 200, 100);
    // nvgLineTo(ctx.gfx, 200, 200);
    // nvgLineTo(ctx.gfx, 100, 200);
    // nvgClosePath(ctx.gfx);
    // // nvgFillColor(ctx.gfx, nvgRGB(255, 0, 0));
    // // nvgFill(ctx.gfx);

    // // nvgBeginPath(ctx.gfx);
    // nvgMoveTo(ctx.gfx, 300, 100);
    // nvgLineTo(ctx.gfx, 400, 100);
    // nvgLineTo(ctx.gfx, 400, 200);
    // nvgLineTo(ctx.gfx, 300, 200);
    // nvgClosePath(ctx.gfx);
    // // nvgFillColor(ctx.gfx, nvgRGB(255, 0, 0));
    // // nvgFill(ctx.gfx);

    // nvgFillColor(ctx.gfx, nvgRGB(255, 0, 0));
    // nvgFill(ctx.gfx);

    // nvgRestore(ctx.gfx);

    nvgEndFrame(ctx.gfx);
}

presentGame :: () {
    ctx := context.gameContext;
    assert(ctx != null);

    glfwSwapBuffers(ctx.window);
    glfwPollEvents();

    currentTime := cast(f32) glfwGetTime();
    ctx.deltaTime = (currentTime - ctx.time);

    while (ctx.deltaTime <= SECONDS_PER_FRAME) {
        currentTime = cast(f32) glfwGetTime();
        ctx.deltaTime = (currentTime - ctx.time);
    }

    ctx.time = currentTime;
    ctx.fps = cast(u32) (1.0 / ctx.deltaTime);
}

#scope_file

glfwErrorCallback :: (error: s32, description: *u8) #c_call {
    newContext: Context;
    push_context newContext {
        loggerData := LoggerData.{};
        initLogger(*loggerData);

        logError("Error: %\n", toString(description));
    }
}

inputCharCallback :: (window: *GLFWwindow, codepoint: u32) #c_call {
    ctx := cast(*GameContext) glfwGetWindowUserPointer(window);

    newContext: Context;
    newContext.gameContext = ctx;
    push_context newContext {
        // call here some method to process keys
    }
}

glfwIsKeyPressed :: inline (key: s32) -> bool {
    ctx := context.gameContext;
    assert(ctx != null);

    return glfwGetKey(ctx.window, key) == GLFW_PRESS;
}
