WORKSPACE_NAME :: "ecs";
EXECUTABLE_NAME :: "ecs.exe";

#if OS == .WINDOWS {
    OUTPUT_FOLDER_PATH :: "build/win64/";
} else if OS == .LINUX {
    OUTPUT_FOLDER_PATH :: "build/linux64/";
}

MODULES_PATH :: "jai-modules";
BUILD_FILE_PATH :: "src/ecs.jai";

#if OS == .WINDOWS {
    LIBS_FOLDER_PATH :: "libs/win64/";
} else if OS == .LINUX {
    LIBS_FOLDER_PATH :: "libs/linux64/";
}

ASSETS_FOLDER_PATH :: "assets/";

build :: () {
    setWorkingDirectory(#filepath);

    // Don't produce output for this default workspace
    opts := getBuildOptions();
    opts.output_type = .NO_OUTPUT;
    setBuildOptions(opts);

    opts.output_type = .EXECUTABLE;
    opts.output_executable_name = EXECUTABLE_NAME;
    opts.output_path = OUTPUT_FOLDER_PATH;
    opts.shorten_filenames_in_error_messages = false;
    opts.backend = .LLVM;
    opts.optimization_level = .DEBUG;

    importPath: [..] string;
    arrayAdd(*importPath, ..opts.import_path);
    arrayAdd(*importPath, MODULES_PATH);
    opts.import_path = importPath;

    makeDirectoryIfNotExist(opts.output_path);

    // Start a new workspace for the actual program
    workspace := createWorkspace(WORKSPACE_NAME);
    setBuildOptions(opts, workspace);

    beginIntercept(workspace);

    addBuildFile(BUILD_FILE_PATH, workspace);

    messageLoop(workspace);

    endIntercept(workspace);

    copyFiles(LIBS_FOLDER_PATH, opts.output_path);
    copyFiles(ASSETS_FOLDER_PATH, opts.output_path);
}

messageLoop :: (workspace: Workspace) {
    while (true) {
        message := waitForMessage();
        if (!message) break;

        if (message.kind == .COMPLETE) {
            break;
        }

        partialEnums(workspace, message);
        runAtPhase(workspace, message);
    }
}

#run build();

#scope_file

Basic :: #import "Basic";
arrayAdd :: Basic.array_add;

#import "utils";
#import "strings";
#import "meta";
