const std = @import("std");

pub const SdlOptions = struct {
    ///The enabled video implementations
    video_implementations: EnabledSdlVideoImplementations = .{},
    ///The enabled video sub-implementations
    video_sub_implementations: EnabledSdlVideoSubImplementations = .{},
    ///The enabled render implementations
    render_implementations: EnabledSdlRenderImplementations = .{},
    ///The enabled audio implementations
    audio_implementations: EnabledSdlAudioImplementations = .{},
    ///The enabled joystick implementations
    joystick_implementations: EnabledSdlJoystickImplementations = .{},
    ///The thread implementation to use
    thread_implementation: SdlThreadImplementation = .generic,
    ///The power implementation to use
    power_implementation: ?SdlPowerImplementation = null,
    ///The thread implementation to use
    timer_implementation: SdlTimerImplementation = .dummy,
    ///The locale implementation to use
    locale_implementation: SdlLocaleImplementation = .dummy,
    ///The haptic implementation to use
    haptic_implementation: SdlHapticImplementation = .dummy,
    ///The loadso implementation to use
    loadso_implementation: SdlLoadSoImplementation = .dummy,
    ///Whether or not to build SDL as a shared library
    shared: bool = false,

    ///Path to a MacOS SDK
    osx_sdk_path: ?[]const u8 = null,
    ///Path to a Linux SDK
    linux_sdk_path: ?[]const u8 = null,
};

///Gets the default recommended options for a particular Target
pub fn getDefaultOptionsForTarget(target: std.Target) SdlOptions {
    var options = SdlOptions{};

    if (target.abi == .android) {
        options.video_implementations.android = true;
        options.haptic_implementation = SdlHapticImplementation.android;
        options.joystick_implementations.android = true;
        options.joystick_implementations.hidapi = true;
        options.joystick_implementations.virtual = true;
        options.joystick_implementations.dummy = true;
        options.locale_implementation = SdlLocaleImplementation.android;

        options.power_implementation = SdlPowerImplementation.android;
        options.thread_implementation = SdlThreadImplementation.pthread;
        options.timer_implementation = SdlTimerImplementation.unix;
        options.audio_implementations.android = true;
        options.audio_implementations.openslES = true;
        options.audio_implementations.aaudio = true;
        options.audio_implementations.dummy = true;
        options.loadso_implementation = .dlopen;

        //TODO: re-enable once the weird linker errors are fixed >:(
        //      eg: error: use of undeclared identifier 'glBlendEquationOES'
        // options.video_sub_implementations.opengl_es = true;
        // options.render_implementations.opengles = true;

        options.video_sub_implementations.opengl_es2 = true;
        options.video_sub_implementations.opengl_egl = true;
        options.render_implementations.opengles2 = true;

        options.shared = true;

        //Return out early to prevent later checks from returning true
        return options;
    }

    if (target.os.tag == .linux or target.os.tag == .freebsd or target.os.tag == .openbsd or target.os.tag == .netbsd or target.os.tag == .dragonfly) {
        //Linux, UNIX and BSD-likes all will have X11 and pthreads
        options.video_implementations.x11 = true;
        options.thread_implementation = .pthread;
        options.timer_implementation = .unix;
        options.locale_implementation = .unix;
        options.loadso_implementation = .dlopen;

        options.render_implementations.opengl = true;
    }

    if (target.os.tag == .linux) {
        options.joystick_implementations.linux = true;
        options.joystick_implementations.steam = true;
        options.haptic_implementation = .linux;

        options.power_implementation = .linux;

        options.audio_implementations.alsa = true;
        options.audio_implementations.jack = true;
        options.audio_implementations.pipewire = true;
        options.audio_implementations.pulseaudio = true;

        // Wayland is by-default on some modern distros, so lets compile it in by default too
        // temporarily commented out until linker errors are fixed
        // options.video_implementations.wayland = true;
    }

    if (target.os.tag == .freebsd or target.os.tag == .openbsd or target.os.tag == .netbsd or target.os.tag == .dragonfly) {
        options.joystick_implementations.bsd = true;
    }

    if (target.os.tag == .windows) {
        options.video_implementations.windows = true;

        //enable all 3 types of windows joystick input
        options.joystick_implementations.dinput = true;
        options.joystick_implementations.xinput = true;
        options.joystick_implementations.rawinput = true;

        options.audio_implementations.directsound = true;
        options.audio_implementations.winmm = true;
        options.audio_implementations.disk = true;

        options.thread_implementation = .windows;
        options.power_implementation = .windows;
        options.timer_implementation = .windows;
        options.locale_implementation = .windows;

        options.haptic_implementation = .windows;

        options.loadso_implementation = .windows;

        options.video_sub_implementations.opengl = true;
        options.video_sub_implementations.opengl_wgl = true;
        options.video_sub_implementations.opengl_es2 = true;
        options.video_sub_implementations.opengl_egl = true;

        options.render_implementations.direct3d = true;
        options.render_implementations.direct3d11 = true;
        options.render_implementations.direct3d12 = true;
        options.render_implementations.opengl = true;
    }

    if (target.isDarwin()) {
        options.thread_implementation = .pthread;
        options.power_implementation = .macosx;
        options.timer_implementation = .unix;
        options.locale_implementation = .macosx;

        options.haptic_implementation = .darwin;
        options.joystick_implementations.darwin = true;

        options.audio_implementations.coreaudio = true;
        options.audio_implementations.disk = true;

        options.video_implementations.cocoa = true;

        options.loadso_implementation = .dlopen;

        options.video_sub_implementations.opengl = true;
        options.video_sub_implementations.opengl_es2 = true;
        options.video_sub_implementations.opengl_egl = true;
        options.video_sub_implementations.opengl_cgl = true;
        options.video_sub_implementations.opengl_glx = true;

        options.video_sub_implementations.metal = true;

        options.render_implementations.metal = true;

        // #if SDL_PLATFORM_SUPPORTS_METAL
        // options.video_sub_implementations.vulkan = true;
    }

    //Lets enable the dummy implementations by default on all platforms
    options.joystick_implementations.dummy = true;
    options.audio_implementations.dummy = true;

    return options;
}

//NOTE: these enum names must match the folder names!
const SdlThreadImplementation = enum {
    generic,
    n3ds,
    ngage,
    os2,
    ps2,
    psp,
    pthread,
    stdcpp,
    vita,
    windows,
};

//NOTE: these enum names must match the folder names!
const SdlPowerImplementation = enum {
    android,
    emscripten,
    haiku,
    linux,
    macosx,
    n3ds,
    psp,
    uikit,
    vita,
    windows,
    winrt,
};

//NOTE: these names must match the folder names!
const SdlHidApiImplementation = enum {
    android,
    ios,
    libusb,
    linux,
    mac,
    windows,
};

//NOTE: these names must match the folder names!
const SdlHapticImplementation = enum {
    android,
    darwin,
    dummy,
    linux,
    windows,
};

//NOTE: these names must match the folder names!
const SdlLoadSoImplementation = enum {
    dlopen,
    dummy,
    os2,
    windows,
};

//NOTE: these names must match the folder names!
const SdlTimerImplementation = enum {
    dummy,
    haiku,
    n3ds,
    ngage,
    os2,
    ps2,
    psp,
    unix,
    vita,
    windows,
};

//NOTE: these names must match the folder names!
const SdlLocaleImplementation = enum {
    android,
    dummy,
    emscripten,
    haiku,
    macosx,
    n3ds,
    unix,
    vita,
    windows,
    winrt,
};

const EnabledSdlJoystickImplementations = struct {
    android: bool = false,
    apple: bool = false,
    bsd: bool = false,
    darwin: bool = false,
    dummy: bool = false,
    emscripten: bool = false,
    haiku: bool = false,
    hidapi: bool = false,
    iphoneos: bool = false,
    linux: bool = false,
    n3ds: bool = false,
    os2: bool = false,
    ps2: bool = false,
    psp: bool = false,
    steam: bool = false,
    virtual: bool = false,
    vita: bool = false,
    rawinput: bool = false,
    dinput: bool = false,
    xinput: bool = false,
    wgi: bool = false,
};

//NOTE: these names need to stay the same as the folders in src/video/
const EnabledSdlVideoImplementations = struct {
    android: bool = false,
    arm: bool = false,
    cocoa: bool = false,
    directfb: bool = false,
    dummy: bool = false,
    emscripten: bool = false,
    haiku: bool = false,
    khronos: bool = false,
    kmsdrm: bool = false,
    n3ds: bool = false,
    nacl: bool = false,
    ngage: bool = false,
    offscreen: bool = false,
    os2: bool = false,
    pandora: bool = false,
    ps2: bool = false,
    psp: bool = false,
    qnx: bool = false,
    raspberry: bool = false,
    riscos: bool = false,
    uikit: bool = false,
    vita: bool = false,
    vivante: bool = false,
    wayland: bool = false,
    windows: bool = false,
    winrt: bool = false,
    x11: bool = false,
};

const EnabledSdlVideoSubImplementations = struct {
    opengl: bool = false, //SDL_VIDEO_OPENGL
    opengl_es: bool = false, //SDL_VIDEO_OPENGL_ES
    opengl_es2: bool = false, //SDL_VIDEO_OPENGL_ES2
    opengl_egl: bool = false, //SDL_VIDEO_OPENGL_EGL
    opengl_cgl: bool = false, //SDL_VIDEO_OPENGL_CGL
    opengl_glx: bool = false, //SDL_VIDEO_OPENGL_GLX
    opengl_wgl: bool = false, //SDL_VIDEO_OPENGL_WGL
    metal: bool = false, //SDL_VIDEO_METAL
    vulkan: bool = false, //SDL_VIDEO_VULKAN
};

//NOTE: these names need to stay the same as the folders in src/audio/
const EnabledSdlAudioImplementations = struct {
    aaudio: bool = false,
    alsa: bool = false,
    android: bool = false,
    arts: bool = false,
    coreaudio: bool = false,
    directsound: bool = false,
    disk: bool = false,
    dsp: bool = false,
    dummy: bool = false,
    emscripten: bool = false,
    esd: bool = false,
    fusionsound: bool = false,
    haiku: bool = false,
    jack: bool = false,
    n3ds: bool = false,
    nacl: bool = false,
    nas: bool = false,
    netbsd: bool = false,
    openslES: bool = false,
    os2: bool = false,
    paudio: bool = false,
    pipewire: bool = false,
    ps2: bool = false,
    psp: bool = false,
    pulseaudio: bool = false,
    qsa: bool = false,
    sndio: bool = false,
    sun: bool = false,
    vita: bool = false,
    wasapi: bool = false,
    winmm: bool = false,
};

const EnabledSdlRenderImplementations = struct {
    direct3d: bool = false,
    direct3d11: bool = false,
    direct3d12: bool = false,
    metal: bool = false,
    opengl: bool = false,
    opengles: bool = false,
    opengles2: bool = false,
    ps2: bool = false,
    psp: bool = false,
    software: bool = true,
    vitagxm: bool = false,
};

//lazy toUpper implementation, only supports ASCII strings
pub fn lazyToUpper(allocator: std.mem.Allocator, str: []const u8) ![]const u8 {
    var upper = try allocator.alloc(u8, str.len);

    for (str, 0..str.len) |char, i| {
        if (str[i] > 0x7A or str[i] < 0x61) {
            upper[i] = char;
            continue;
        }

        upper[i] = char - 0x20;
    }

    return upper;
}

pub fn createSDL(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode, _sdl_options: SdlOptions) !*std.Build.Step.Compile {
    var sdl_options = _sdl_options;
    const options = .{
        .name = "SDL2",
        .target = target,
        .optimize = optimize,
    };

    const lib: *std.Build.Step.Compile = if (sdl_options.shared) b.addSharedLibrary(options) else b.addStaticLibrary(options);

    var c_flags = std.ArrayList([]const u8).init(b.allocator);

    // try c_flags.append("-std=c99");

    //workaround some parsing issues in the macos system-sdk in use
    lib.defineCMacro("__kernel_ptr_semantics", "");

    switch (target.result.os.tag) {
        .linux => {
            try c_flags.appendSlice(&.{
                "-DSDL_INPUT_LINUXEV",
                "-DHAVE_LINUX_INPUT_H", //TODO: properly check for this like the CMake script does
            });
        },
        else => {},
    }

    switch (target.result.abi) {
        .android => {
            //Define android
            lib.defineCMacro("__ANDROID__", "1");

            //Needed in general by SDL
            lib.linkSystemLibrary("android");
            lib.linkSystemLibrary("log");
            lib.linkSystemLibrary("dl");
        },
        else => {},
    }

    { //SDL_VIDEO_X
        if (sdl_options.video_sub_implementations.opengl) {
            lib.defineCMacro("SDL_VIDEO_OPENGL", "1");
        }

        if (sdl_options.video_sub_implementations.opengl_es) {
            lib.defineCMacro("SDL_VIDEO_OPENGL_ES", "1");
            if (target.result.abi == .android) {
                lib.linkSystemLibrary("GLESv1_CM");
            }
        }

        if (sdl_options.video_sub_implementations.opengl_es2) {
            lib.defineCMacro("SDL_VIDEO_OPENGL_ES2", "1");
            if (target.result.abi == .android) {
                lib.linkSystemLibrary("GLESv2");
            }
        }

        if (sdl_options.video_sub_implementations.opengl_egl) {
            lib.defineCMacro("SDL_VIDEO_OPENGL_EGL", "1");
        }

        if (sdl_options.video_sub_implementations.opengl_cgl) {
            lib.defineCMacro("SDL_VIDEO_OPENGL_CGL", "1");
        }

        if (sdl_options.video_sub_implementations.opengl_glx) {
            lib.defineCMacro("SDL_VIDEO_OPENGL_GLX", "1");
        }

        if (sdl_options.video_sub_implementations.opengl_wgl) {
            lib.defineCMacro("SDL_VIDEO_OPENGL_WGL", "1");
        }

        if (sdl_options.video_sub_implementations.metal) {
            lib.defineCMacro("SDL_VIDEO_METAL", "1");
        }

        if (sdl_options.video_sub_implementations.vulkan) {
            lib.defineCMacro("SDL_VIDEO_VULKAN", "1");
        }
    } //SDL_VIDEO_X

    lib.addIncludePath(b.path("include"));
    lib.addCSourceFiles(.{ .files = &generic_src_files, .flags = c_flags.items });
    lib.defineCMacro("SDL_USE_BUILTIN_OPENGL_DEFINITIONS", "1");

    lib.linkLibC();
    //TODO: we need to link LibCpp in some cases, like the libcpp thread implementation
    //    lib.linkLibCpp();

    //assume libcpp on android for now
    if (target.result.abi == .android) {
        lib.linkLibCpp();
    }

    //Define the C macro enabling the correct timer implementation
    lib.defineCMacro(try std.mem.concat(b.allocator, u8, &.{ "SDL_TIMER_", try lazyToUpper(b.allocator, @tagName(sdl_options.timer_implementation)) }), "1");

    //Define the C macro enabling the correct thread implementation
    lib.defineCMacro(try std.mem.concat(b.allocator, u8, &.{ "SDL_THREAD_", try lazyToUpper(b.allocator, @tagName(sdl_options.thread_implementation)) }), "1");

    //Darwin is *special* and the define name doesnt match.
    if (sdl_options.haptic_implementation == .darwin) {
        lib.defineCMacro("SDL_HAPTIC_IOKIT", "1");
    } else if (sdl_options.haptic_implementation == .windows) {
        lib.defineCMacro("SDL_HAPTIC_DINPUT", "1");
        lib.defineCMacro("SDL_HAPTIC_XINPUT", "1");
    } else {
        //Define the C macro enabling the correct thread implementation
        lib.defineCMacro(try std.mem.concat(b.allocator, u8, &.{ "SDL_HAPTIC_", try lazyToUpper(b.allocator, @tagName(sdl_options.haptic_implementation)) }), "1");
    }

    var any_video_enabled = false;
    const viStructInfo: std.builtin.Type.Struct = @typeInfo(EnabledSdlVideoImplementations).Struct;
    //Iterate over all fields on the video implementations struct
    inline for (viStructInfo.fields) |field| {
        const enabled: bool = @field(sdl_options.video_implementations, field.name);
        //If its enabled in the options
        if (enabled) {
            //they arent consistent with their naming always :/
            if (std.mem.eql(u8, field.name, "raspberry")) {
                lib.defineCMacro("SDL_VIDEO_DRIVER_RPI", "1");
            } else {
                //Make the macro name
                const name = try std.mem.concat(b.allocator, u8, &.{
                    "SDL_VIDEO_DRIVER_",
                    try lazyToUpper(b.allocator, field.name),
                });
                //Set the macro to 1
                lib.defineCMacro(name, "1");
                // std.debug.print("enabling video driver {s} from {s} upper {s}\n", .{ name, field.name, try lazyToUpper(b.allocator, field.name) });
            }
            any_video_enabled = true;
        }
    }
    if (!any_video_enabled) {
        lib.defineCMacro("SDL_VIDEO_DISABLED", "1");
    } else {}
    lib.addCSourceFiles(.{ .files = &video_src_files, .flags = c_flags.items });

    var any_joystick_enabled = false;
    const jiStructInfo: std.builtin.Type.Struct = @typeInfo(EnabledSdlJoystickImplementations).Struct;
    //Iterate over all fields on the video implementations struct
    inline for (jiStructInfo.fields) |field| {
        const enabled: bool = @field(sdl_options.joystick_implementations, field.name);
        //If its enabled in the options
        if (enabled) {
            //they arent consistent with their naming always :/
            if (std.mem.eql(u8, field.name, "darwin")) {
                lib.defineCMacro("SDL_JOYSTICK_IOKIT", "1");
            } else if (std.mem.eql(u8, field.name, "bsd")) {
                lib.defineCMacro("SDL_JOYSTICK_USBHID", "1");
            } else {
                //Make the macro name
                const name = try std.mem.concat(b.allocator, u8, &.{
                    "SDL_JOYSTICK_",
                    try lazyToUpper(b.allocator, field.name),
                });
                //Set the macro to 1
                lib.defineCMacro(name, "1");
                // std.debug.print("enabling joystick driver {s} from {s} upper {s}\n", .{ name, field.name, try lazyToUpper(b.allocator, field.name) });
            }
            any_joystick_enabled = true;
        }
    }
    if (!any_joystick_enabled) {
        lib.defineCMacro("SDL_JOYSTICK_DISABLED", "1");
        sdl_options.joystick_implementations.dummy = true;
    }

    var any_audio_enabled = false;
    const aiStructInfo: std.builtin.Type.Struct = @typeInfo(EnabledSdlAudioImplementations).Struct;
    //Iterate over all fields on the audio implementations struct
    inline for (aiStructInfo.fields) |field| {
        const enabled: bool = @field(sdl_options.audio_implementations, field.name);
        //If its enabled in the options
        if (enabled) {
            //they arent consistent with their naming always :/
            if (std.mem.eql(u8, field.name, "directsound")) { //ok
                lib.defineCMacro("SDL_AUDIO_DRIVER_DSOUND", "1");
            } else if (std.mem.eql(u8, field.name, "sun")) { //bruh
                lib.defineCMacro("SDL_AUDIO_DRIVER_SUNAUDIO", "1");
            } else if (std.mem.eql(u8, field.name, "dsp")) { //?????
                lib.defineCMacro("SDL_AUDIO_DRIVER_OSS", "1");
            } else {
                //Make the macro name
                const name = try std.mem.concat(b.allocator, u8, &.{
                    "SDL_AUDIO_DRIVER_",
                    try lazyToUpper(b.allocator, field.name),
                });
                //Set the macro to 1
                lib.defineCMacro(name, "1");
                // std.debug.print("enabling joystick driver {s} from {s} upper {s}\n", .{ name, field.name, try lazyToUpper(b.allocator, field.name) });
            }
            any_audio_enabled = true;
        }
    }
    lib.addCSourceFiles(.{ .files = &audio_src_files, .flags = c_flags.items });
    if (any_audio_enabled) {} else {
        lib.defineCMacro("SDL_AUDIO_DISABLED", "1");
    }

    var any_render_enabled = false;
    const riStructInfo: std.builtin.Type.Struct = @typeInfo(EnabledSdlRenderImplementations).Struct;
    //Iterate over all fields on the video implementations struct
    inline for (riStructInfo.fields) |field| {
        const enabled: bool = @field(sdl_options.render_implementations, field.name);
        //If its enabled in the options
        if (enabled) {
            any_render_enabled = true;
            //they arent consistent with their naming always :/
            if (std.mem.eql(u8, field.name, "software")) { //ok
                lib.defineCMacro("SDL_VIDEO_RENDER_SW", "1");
            } else if (std.mem.eql(u8, field.name, "opengl")) { //ok
                lib.defineCMacro("SDL_VIDEO_RENDER_OGL", "1");
            } else if (std.mem.eql(u8, field.name, "opengles")) { //ok
                lib.defineCMacro("SDL_VIDEO_RENDER_OGL_ES", "1");
            } else if (std.mem.eql(u8, field.name, "opengles2")) { //ok
                lib.defineCMacro("SDL_VIDEO_RENDER_OGL_ES2", "1");
            } else if (std.mem.eql(u8, field.name, "direct3d")) { //ok
                lib.defineCMacro("SDL_VIDEO_RENDER_OGL_D3D", "1");
            } else if (std.mem.eql(u8, field.name, "direct3d11")) { //ok
                lib.defineCMacro("SDL_VIDEO_RENDER_OGL_D3D11", "1");
            } else if (std.mem.eql(u8, field.name, "direct3d12")) { //ok
                lib.defineCMacro("SDL_VIDEO_RENDER_OGL_D3D12", "1");
            } else if (std.mem.eql(u8, field.name, "vitagxm")) { //ok
                lib.defineCMacro("SDL_VIDEO_RENDER_VITA_GXM", "1");
            } else {
                //Make the macro name
                const name = try std.mem.concat(b.allocator, u8, &.{
                    "SDL_VIDEO_RENDER_",
                    try lazyToUpper(b.allocator, field.name),
                });
                //Set the macro to 1
                lib.defineCMacro(name, "1");
                // std.debug.print("enabling joystick driver {s} from {s} upper {s}\n", .{ name, field.name, try lazyToUpper(b.allocator, field.name) });
            }
        }
    }
    lib.addCSourceFiles(.{ .files = &render_src_files, .flags = c_flags.items });
    if (any_render_enabled) {} else {
        lib.defineCMacro("SDL_RENDER_DISABLED", "1");
    }

    switch (target.result.os.tag) {
        //TODO: figure out why when linking against our built SDL it causes a linker failure `__stack_chk_fail was replaced` on windows
        .windows => {
            lib.addCSourceFiles(.{ .files = &windows_src_files, .flags = c_flags.items });

            lib.linkSystemLibrary("setupapi");
            lib.linkSystemLibrary("winmm");
            lib.linkSystemLibrary("gdi32");
            lib.linkSystemLibrary("imm32");
            lib.linkSystemLibrary("version");
            lib.linkSystemLibrary("oleaut32");
            lib.linkSystemLibrary("ole32");
        },
        .macos => {
            lib.addCSourceFiles(.{ .files = &darwin_src_files, .flags = c_flags.items });

            const obj_flags = try std.mem.concat(b.allocator, []const u8, &.{ &.{"-fobjc-arc"}, c_flags.items });
            lib.addCSourceFiles(.{ .files = &objective_c_src_files, .flags = obj_flags });
        },
        .linux => {
            if (target.result.abi == .android) {
                lib.addCSourceFiles(.{ .files = &android_src_files, .flags = c_flags.items });
            } else {
                lib.addCSourceFiles(.{ .files = &linux_src_files, .flags = c_flags.items });
            }
        },
        else => {
            @panic("Unsupported OS! Please open a PR!");
            // const config_header = b.addConfigHeader(.{
            //     .style = .{ .cmake = .{ .path = root_path ++ "include/SDL_config.h.cmake" } },
            //     .include_path = root_path ++ "SDL2/SDL_config.h",
            // }, .{});

            // lib.addConfigHeader(config_header);
            // lib.installConfigHeader(config_header, .{});
        },
    }

    try applyLinkerArgs(b, target, lib, sdl_options);

    switch (sdl_options.thread_implementation) {
        //stdcpp and ngage have cpp code, so lets add exceptions for those, since find_c_cpp_sources separates the found c/cpp files
        .stdcpp => lib.addCSourceFiles(.{
            .files = (try findCSources(b.allocator, b.path("src/thread/stdcpp/"))).cpp,
            .flags = c_flags.items,
        }),
        .ngage => lib.addCSourceFiles(.{
            .files = (try findCSources(b.allocator, b.path("src/thread/ngage/"))).cpp,
            .flags = c_flags.items,
        }),
        //Windows implementation of thread requires parts of the generic implementation,
        //not sure if this is fully correct (or if we need to define SDL_THREAD_GENERIC_COND_SUFFIX)
        //due to a linker error on Windows that happens earlier on, but it seems fine enough for now, and can be tested later
        .windows => {
            lib.addCSourceFile(.{ .file = b.path("src/thread/generic/SDL_syscond.c"), .flags = c_flags.items });
            lib.addCSourceFiles(.{ .files = (try findCSources(b.allocator, b.path("src/thread/windows/"))).c, .flags = c_flags.items });
        },
        inline else => |value| {
            lib.addCSourceFiles(.{ .files = (try findCSources(b.allocator, b.path("src/thread/" ++ @tagName(value) ++ "/"))).c, .flags = c_flags.items });
        },
    }

    if (sdl_options.power_implementation) |chosen| {
        switch (chosen) {
            //TODO: uikit uses a .m file, we should handle that!
            .winrt => lib.addCSourceFile(.{ .file = .{ .path = root_path ++ "src/power/winrt/SDL_syspower.cpp" }, .flags = c_flags.items }),
            else => |value| {
                const path = try std.mem.concat(b.allocator, u8, &.{ root_path, "src/power/", @tagName(value), "/SDL_syspower.c" });
                lib.addCSourceFile(.{ .file = .{ .path = path }, .flags = c_flags.items });
            },
        }
    } else {
        //if theres no power implementation, disable SDL_Power alltogether
        lib.defineCMacro("SDL_POWER_DISABLED", "1");
    }

    switch (sdl_options.timer_implementation) {
        .ngage => lib.addCSourceFile(.{ .file = .{ .path = root_path ++ "src/timer/ngage/SDL_systimer.cpp" }, .flags = c_flags.items }),
        else => |value| {
            const path = try std.mem.concat(b.allocator, u8, &.{ root_path, "src/timer/", @tagName(value), "/SDL_systimer.c" });
            lib.addCSourceFile(.{ .file = .{ .path = path }, .flags = c_flags.items });
        },
    }

    switch (sdl_options.loadso_implementation) {
        else => |value| {
            lib.defineCMacro(b.fmt("SDL_LOADSO_{s}", .{try lazyToUpper(b.allocator, @tagName(value))}), "1");

            const path = try std.mem.concat(b.allocator, u8, &.{ root_path, "src/loadso/", @tagName(value), "/SDL_sysloadso.c" });
            lib.addCSourceFile(.{ .file = .{ .path = path }, .flags = c_flags.items });
        },
    }

    switch (sdl_options.locale_implementation) {
        //haiku is a .cc file (cpp?)
        .haiku => lib.addCSourceFile(.{ .file = .{ .path = root_path ++ "src/locale/haiku/SDL_syslocale.cc" }, .flags = c_flags.items }),
        //macos is a .m file (obj-c)
        .macosx => lib.addCSourceFile(.{ .file = .{ .path = root_path ++ "src/locale/macosx/SDL_syslocale.m" }, .flags = try std.mem.concat(b.allocator, []const u8, &.{ c_flags.items, &.{"-fobjc-arc"} }) }),
        else => |value| {
            const path = try std.mem.concat(b.allocator, u8, &.{ root_path, "src/locale/", @tagName(value), "/SDL_syslocale.c" });
            lib.addCSourceFile(.{ .file = .{ .path = path }, .flags = c_flags.items });
        },
    }

    { //video implementations
        if (sdl_options.video_implementations.x11) {
            lib.linkSystemLibrary("X11");
            lib.linkSystemLibrary("Xext");

            const src_files = try findCSources(b.allocator, b.path("src/video/x11/"));

            lib.addCSourceFiles(.{ .files = src_files.c, .flags = c_flags.items });
        }

        if (sdl_options.video_implementations.wayland) {
            //TODO: fix linker errors here from the wayland headers,

            lib.linkSystemLibrary("wayland-client");
            lib.linkSystemLibrary("wayland-cursor");
            lib.linkSystemLibrary("wayland-egl");
            lib.linkSystemLibrary("xkbcommon");

            lib.addIncludePath(.{ .path = root_path ++ "include/wayland-protocols" });

            const src_files = try findCSources(b.allocator, b.path("src/video/wayland/"));
            lib.addCSourceFiles(.{ .files = src_files.c, .flags = c_flags.items });
        }

        if (sdl_options.video_implementations.windows) {
            const src_files = try findCSources(b.allocator, b.path("src/video/windows/"));

            lib.addCSourceFiles(.{ .files = src_files.c, .flags = c_flags.items });
        }

        if (sdl_options.video_implementations.android) {
            const src_files = try findCSources(b.allocator, b.path("src/video/android/"));

            lib.addCSourceFiles(.{ .files = src_files.c, .flags = c_flags.items });
        }

        //TODO: the rest of the video implementations
    } //video implementations

    { //joystick implementations
        if (sdl_options.joystick_implementations.dummy) {
            lib.addCSourceFile(.{ .file = .{ .path = root_path ++ "src/joystick/dummy/SDL_sysjoystick.c" }, .flags = c_flags.items });
        }

        if (sdl_options.joystick_implementations.linux) {
            lib.addCSourceFile(.{ .file = .{ .path = root_path ++ "src/joystick/linux/SDL_sysjoystick.c" }, .flags = c_flags.items });
        }

        if (sdl_options.joystick_implementations.android) {
            lib.addCSourceFile(.{ .file = .{ .path = root_path ++ "src/joystick/android/SDL_sysjoystick.c" }, .flags = c_flags.items });
        }

        if (sdl_options.joystick_implementations.darwin) {
            lib.addCSourceFile(.{ .file = .{ .path = root_path ++ "src/joystick/darwin/SDL_iokitjoystick.c" }, .flags = c_flags.items });
        }

        if (sdl_options.joystick_implementations.bsd) {
            lib.addCSourceFile(.{ .file = .{ .path = root_path ++ "src/joystick/bsd/SDL_bsdjoystick.c" }, .flags = c_flags.items });
        }

        if (sdl_options.joystick_implementations.emscripten) {
            lib.addCSourceFile(.{ .file = .{ .path = root_path ++ "src/joystick/emscripten/SDL_sysjoystick.c" }, .flags = c_flags.items });
        }

        if (sdl_options.joystick_implementations.emscripten) {
            lib.addCSourceFile(.{ .file = .{ .path = root_path ++ "src/joystick/emscripten/SDL_sysjoystick.c" }, .flags = c_flags.items });
        }

        if (sdl_options.joystick_implementations.haiku) {
            lib.addCSourceFile(.{ .file = .{ .path = root_path ++ "src/joystick/haiku/SDL_haikujoystick.cc" }, .flags = c_flags.items });
        }

        if (sdl_options.joystick_implementations.n3ds) {
            lib.addCSourceFile(.{ .file = .{ .path = root_path ++ "src/joystick/n3ds/SDL_sysjoystick.c" }, .flags = c_flags.items });
        }

        if (sdl_options.joystick_implementations.os2) {
            lib.addCSourceFile(.{ .file = .{ .path = root_path ++ "src/joystick/os2/SDL_os2joystick.c" }, .flags = c_flags.items });
        }

        if (sdl_options.joystick_implementations.ps2) {
            lib.addCSourceFile(.{ .file = .{ .path = root_path ++ "src/joystick/ps2/SDL_sysjoystick.c" }, .flags = c_flags.items });
        }

        if (sdl_options.joystick_implementations.psp) {
            lib.addCSourceFile(.{ .file = .{ .path = root_path ++ "src/joystick/psp/SDL_sysjoystick.c" }, .flags = c_flags.items });
        }

        if (sdl_options.joystick_implementations.virtual) {
            lib.addCSourceFile(.{ .file = .{ .path = root_path ++ "src/joystick/virtual/SDL_virtualjoystick.c" }, .flags = c_flags.items });
        }

        if (sdl_options.joystick_implementations.vita) {
            lib.addCSourceFile(.{ .file = .{ .path = root_path ++ "src/joystick/vita/SDL_sysjoystick.c" }, .flags = c_flags.items });
        }

        if (sdl_options.joystick_implementations.iphoneos) {
            lib.addCSourceFile(.{
                .file = .{ .path = root_path ++ "src/joystick/iphoneos/SDL_mfijoystick.m" },
                .flags = try std.mem.concat(b.allocator, []const u8, &.{
                    &.{"-fobjc-arc"},
                    c_flags.items,
                }),
            });
        }

        if (sdl_options.joystick_implementations.apple) {
            lib.addCSourceFile(.{
                .file = .{ .path = root_path ++ "src/joystick/apple/SDL_mfijoystick.c" },
                .flags = try std.mem.concat(b.allocator, []const u8, &.{
                    &.{"-fobjc-arc"},
                    c_flags.items,
                }),
            });
        }

        //dinput, xinput, and rawinput are all windows exclusives, so if any of them are on, we need the windows joystick
        if (sdl_options.joystick_implementations.dinput or sdl_options.joystick_implementations.xinput or sdl_options.joystick_implementations.rawinput) {
            lib.addCSourceFile(.{ .file = .{ .path = root_path ++ "src/joystick/windows/SDL_windowsjoystick.c" }, .flags = c_flags.items });
        }

        if (sdl_options.joystick_implementations.dinput) {
            lib.addCSourceFile(.{ .file = .{ .path = root_path ++ "src/joystick/windows/SDL_dinputjoystick.c" }, .flags = c_flags.items });
        }

        if (sdl_options.joystick_implementations.xinput) {
            lib.addCSourceFile(.{ .file = .{ .path = root_path ++ "src/joystick/windows/SDL_xinputjoystick.c" }, .flags = c_flags.items });
        }

        if (sdl_options.joystick_implementations.rawinput) {
            lib.addCSourceFile(.{ .file = .{ .path = root_path ++ "src/joystick/windows/SDL_rawinputjoystick.c" }, .flags = c_flags.items });
        }

        if (sdl_options.joystick_implementations.wgi) {
            lib.addCSourceFile(.{ .file = .{ .path = root_path ++ "src/joystick/windows/windows_gaming_input.c" }, .flags = c_flags.items });
        }

        if (sdl_options.joystick_implementations.steam) {
            lib.addCSourceFile(.{ .file = .{ .path = root_path ++ "src/joystick/steam/SDL_steamcontroller.c" }, .flags = c_flags.items });
        }
    } //joystick implementations

    { //haptic implementations
        if (sdl_options.haptic_implementation == .android) {
            lib.addCSourceFile(.{ .file = .{ .path = root_path ++ "src/haptic/android/SDL_syshaptic.c" }, .flags = c_flags.items });
        }

        if (sdl_options.haptic_implementation == .darwin) {
            lib.addCSourceFile(.{ .file = .{ .path = root_path ++ "src/haptic/darwin/SDL_syshaptic.c" }, .flags = c_flags.items });
        }

        if (sdl_options.haptic_implementation == .dummy) {
            lib.addCSourceFile(.{ .file = .{ .path = root_path ++ "src/haptic/dummy/SDL_syshaptic.c" }, .flags = c_flags.items });
        }

        if (sdl_options.haptic_implementation == .linux) {
            lib.addCSourceFile(.{ .file = .{ .path = root_path ++ "src/haptic/linux/SDL_syshaptic.c" }, .flags = c_flags.items });
        }

        if (sdl_options.haptic_implementation == .windows) {
            lib.addCSourceFile(.{ .file = .{ .path = root_path ++ "src/haptic/windows/SDL_dinputhaptic.c" }, .flags = c_flags.items });
            lib.addCSourceFile(.{ .file = .{ .path = root_path ++ "src/haptic/windows/SDL_windowshaptic.c" }, .flags = c_flags.items });
            lib.addCSourceFile(.{ .file = .{ .path = root_path ++ "src/haptic/windows/SDL_xinputhaptic.c" }, .flags = c_flags.items });
        }
    } //haptic implementations

    { //audio implementations
        if (sdl_options.audio_implementations.aaudio) {
            lib.addCSourceFile(.{ .file = .{ .path = root_path ++ "src/audio/aaudio/SDL_aaudio.c" }, .flags = c_flags.items });
        }

        if (sdl_options.audio_implementations.alsa) {
            lib.addCSourceFile(.{ .file = .{ .path = root_path ++ "src/audio/alsa/SDL_alsa_audio.c" }, .flags = c_flags.items });
        }

        if (sdl_options.audio_implementations.android) {
            lib.addCSourceFile(.{ .file = .{ .path = root_path ++ "src/audio/android/SDL_androidaudio.c" }, .flags = c_flags.items });
        }

        if (sdl_options.audio_implementations.arts) {
            lib.addCSourceFile(.{ .file = .{ .path = root_path ++ "src/audio/arts/SDL_artsaudio.c" }, .flags = c_flags.items });
        }

        if (sdl_options.audio_implementations.coreaudio) {
            lib.addCSourceFile(.{
                .file = .{ .path = root_path ++ "src/audio/coreaudio/SDL_coreaudio.m" },
                .flags = try std.mem.concat(b.allocator, []const u8, &.{
                    &.{"-fobjc-arc"},
                    c_flags.items,
                }),
            });
        }

        if (sdl_options.audio_implementations.directsound) {
            lib.addCSourceFile(.{ .file = .{ .path = root_path ++ "src/audio/directsound/SDL_directsound.c" }, .flags = c_flags.items });
        }

        if (sdl_options.audio_implementations.disk) {
            lib.addCSourceFile(.{ .file = .{ .path = root_path ++ "src/audio/disk/SDL_diskaudio.c" }, .flags = c_flags.items });
        }

        if (sdl_options.audio_implementations.dsp) {
            lib.addCSourceFile(.{ .file = .{ .path = root_path ++ "src/audio/dsp/SDL_dspaudio.c" }, .flags = c_flags.items });
        }

        if (sdl_options.audio_implementations.dummy) {
            lib.addCSourceFile(.{ .file = .{ .path = root_path ++ "src/audio/dummy/SDL_dummyaudio.c" }, .flags = c_flags.items });
        }

        if (sdl_options.audio_implementations.emscripten) {
            lib.addCSourceFile(.{ .file = .{ .path = root_path ++ "src/audio/emscripten/SDL_emscriptenaudio.c" }, .flags = c_flags.items });
        }

        if (sdl_options.audio_implementations.esd) {
            lib.addCSourceFile(.{ .file = .{ .path = root_path ++ "src/audio/esd/SDL_esdaudio.c" }, .flags = c_flags.items });
        }

        if (sdl_options.audio_implementations.fusionsound) {
            lib.addCSourceFile(.{ .file = .{ .path = root_path ++ "src/audio/fusionsound/SDL_fsaudio.c" }, .flags = c_flags.items });
        }

        if (sdl_options.audio_implementations.haiku) {
            lib.addCSourceFile(.{ .file = .{ .path = root_path ++ "src/audio/haiku/SDL_haikuaudio.cc" }, .flags = c_flags.items });
        }

        if (sdl_options.audio_implementations.jack) {
            lib.addCSourceFile(.{ .file = .{ .path = root_path ++ "src/audio/jack/SDL_jackaudio.c" }, .flags = c_flags.items });
        }

        if (sdl_options.audio_implementations.n3ds) {
            lib.addCSourceFile(.{ .file = .{ .path = root_path ++ "src/audio/n3ds/SDL_n3dsaudio.c" }, .flags = c_flags.items });
        }

        if (sdl_options.audio_implementations.nacl) {
            lib.addCSourceFile(.{ .file = .{ .path = root_path ++ "src/audio/nacl/SDL_naclaudio.c" }, .flags = c_flags.items });
        }

        if (sdl_options.audio_implementations.nas) {
            lib.addCSourceFile(.{ .file = .{ .path = root_path ++ "src/audio/nas/SDL_nasaudio.c" }, .flags = c_flags.items });
        }

        if (sdl_options.audio_implementations.netbsd) {
            lib.addCSourceFile(.{ .file = .{ .path = root_path ++ "src/audio/netbsd/SDL_netbsdaudio.c" }, .flags = c_flags.items });
        }

        if (sdl_options.audio_implementations.openslES) {
            lib.addCSourceFile(.{ .file = .{ .path = root_path ++ "src/audio/openslES/SDL_openslES.c" }, .flags = c_flags.items });
            lib.linkSystemLibrary("OpenSLES");
        }

        if (sdl_options.audio_implementations.os2) {
            lib.addCSourceFile(.{ .file = .{ .path = root_path ++ "src/audio/os2/SDL_os2audio.c" }, .flags = c_flags.items });
        }

        if (sdl_options.audio_implementations.paudio) {
            lib.addCSourceFile(.{ .file = .{ .path = root_path ++ "src/audio/paudio/SDL_paudio.c" }, .flags = c_flags.items });
        }

        if (sdl_options.audio_implementations.pipewire) {
            lib.addCSourceFile(.{ .file = .{ .path = root_path ++ "src/audio/pipewire/SDL_pipewire.c" }, .flags = c_flags.items });
        }

        if (sdl_options.audio_implementations.ps2) {
            lib.addCSourceFile(.{ .file = .{ .path = root_path ++ "src/audio/ps2/SDL_ps2audio.c" }, .flags = c_flags.items });
        }

        if (sdl_options.audio_implementations.psp) {
            lib.addCSourceFile(.{ .file = .{ .path = root_path ++ "src/audio/psp/SDL_pspaudio.c" }, .flags = c_flags.items });
        }

        if (sdl_options.audio_implementations.pulseaudio) {
            lib.addCSourceFile(.{ .file = .{ .path = root_path ++ "src/audio/pulseaudio/SDL_pulseaudio.c" }, .flags = c_flags.items });
        }

        if (sdl_options.audio_implementations.qsa) {
            lib.addCSourceFile(.{ .file = .{ .path = root_path ++ "src/audio/qsa/SDL_qsa_audio.c" }, .flags = c_flags.items });
        }

        if (sdl_options.audio_implementations.sndio) {
            lib.addCSourceFile(.{ .file = .{ .path = root_path ++ "src/audio/sndio/SDL_sndioaudio.c" }, .flags = c_flags.items });
        }

        if (sdl_options.audio_implementations.sun) {
            lib.addCSourceFile(.{ .file = .{ .path = root_path ++ "src/audio/sun/SDL_sunaudio.c" }, .flags = c_flags.items });
        }

        if (sdl_options.audio_implementations.vita) {
            lib.addCSourceFile(.{ .file = .{ .path = root_path ++ "src/audio/vita/SDL_vitaaudio.c" }, .flags = c_flags.items });
        }

        if (sdl_options.audio_implementations.wasapi) {
            lib.addCSourceFile(.{ .file = .{ .path = root_path ++ "src/audio/wasapi/SDL_wasapi.c" }, .flags = c_flags.items });
            lib.addCSourceFile(.{ .file = .{ .path = root_path ++ "src/audio/wasapi/SDL_wasapi_win32.c" }, .flags = c_flags.items });
            lib.addCSourceFile(.{ .file = .{ .path = root_path ++ "src/audio/wasapi/SDL_wasapi_winrt.c" }, .flags = c_flags.items });
        }

        if (sdl_options.audio_implementations.winmm) {
            lib.addCSourceFile(.{ .file = .{ .path = root_path ++ "src/audio/winmm/SDL_winmm.c" }, .flags = c_flags.items });
        }
    } //audio implementations

    { //render implementations
        if (sdl_options.render_implementations.software) {
            const source = try findCSources(b.allocator, b.path("src/render/software/"));

            lib.addCSourceFiles(.{
                .files = source.c,
                .flags = c_flags.items,
            });
        }

        if (sdl_options.render_implementations.direct3d) {
            lib.addCSourceFiles(.{
                .files = (try findCSources(b.allocator, b.path("src/render/direct3d/"))).c,
                .flags = c_flags.items,
            });
        }

        if (sdl_options.render_implementations.direct3d11) {
            lib.addCSourceFiles(.{
                .files = (try findCSources(b.allocator, b.path("src/render/direct3d11/"))).c,
                .flags = c_flags.items,
            });
        }

        if (sdl_options.render_implementations.direct3d12) {
            lib.addCSourceFiles(.{
                .files = (try findCSources(b.allocator, b.path("src/render/direct3d12/"))).c,
                .flags = c_flags.items,
            });
        }

        if (sdl_options.render_implementations.metal) {
            lib.addCSourceFile(.{
                .file = .{ .path = root_path ++ "src/render/metal/SDL_render_metal.m" },
                .flags = try std.mem.concat(b.allocator, []const u8, &.{
                    &.{"-fobjc-arc"},
                    c_flags.items,
                }),
            });
        }

        if (sdl_options.render_implementations.opengl) {
            lib.addCSourceFiles(.{
                .files = (try findCSources(b.allocator, b.path("src/render/opengl/"))).c,
                .flags = c_flags.items,
            });
        }

        if (sdl_options.render_implementations.opengles) {
            lib.addCSourceFiles(.{
                .files = (try findCSources(b.allocator, b.path("src/render/opengles/"))).c,
                .flags = c_flags.items,
            });
        }

        if (sdl_options.render_implementations.opengles2) {
            lib.addCSourceFiles(.{
                .files = (try findCSources(b.allocator, b.path("src/render/opengles2/"))).c,
                .flags = c_flags.items,
            });
        }

        if (sdl_options.render_implementations.ps2) {
            lib.addCSourceFiles(.{
                .files = (try findCSources(b.allocator, b.path("src/render/ps2/"))).c,
                .flags = c_flags.items,
            });
        }

        if (sdl_options.render_implementations.psp) {
            lib.addCSourceFiles(.{
                .files = (try findCSources(b.allocator, b.path("src/render/psp/"))).c,
                .flags = c_flags.items,
            });
        }

        if (sdl_options.render_implementations.vitagxm) {
            lib.addCSourceFiles(.{
                .files = (try findCSources(b.allocator, b.path("src/render/vitagxm/"))).c,
                .flags = c_flags.items,
            });
        }
    } //render implementations

    lib.installHeadersDirectory(b.path("include"), "SDL2", .{});

    return lib;
}

pub fn applyLinkerArgs(b: *std.Build, target: std.Build.ResolvedTarget, lib: *std.Build.Step.Compile, sdl_options: SdlOptions) !void {
    switch (target.result.os.tag) {
        .linux => {
            //Return early, android doesnt need anything from here
            if (target.result.abi == .android) {
                return;
            }

            if (sdl_options.linux_sdk_path) |linux_sdk_path| {
                //If the last char is '/', throw an error
                if (linux_sdk_path[linux_sdk_path.len - 1] == '/') {
                    @panic("Linux SDK path must not end with '/'");
                }

                //Check if path is absolute
                if (!std.fs.path.isAbsolute(linux_sdk_path)) {
                    @panic("Linux SDK must be an absolute path!");
                }

                lib.addIncludePath(.{ .path = b.fmt("{s}/include", .{linux_sdk_path}) });
                lib.addLibraryPath(.{ .path = b.fmt("{s}/lib/{s}", .{ linux_sdk_path, try target.result.linuxTriple(b.allocator) }) });
            } else if (!target.query.isNative()) {
                @panic("Linux SDK path must be provided when cross compiling!");
            }

            if (sdl_options.audio_implementations.pipewire) {
                if (target.query.isNative()) {
                    lib.linkSystemLibrary("libpipewire-0.3");
                } else {
                    lib.linkSystemLibrary("pipewire-0.3");
                }
            }
            if (sdl_options.audio_implementations.alsa) {
                lib.linkSystemLibrary("asound");
            }
            if (sdl_options.audio_implementations.jack) {
                lib.linkSystemLibrary("jack");
            }
            if (sdl_options.audio_implementations.pulseaudio) {
                lib.linkSystemLibrary("pulse");
            }
        },
        .macos => {
            if (sdl_options.osx_sdk_path) |osx_sdk_path| {
                //If the last char is '/', throw an error
                if (osx_sdk_path[osx_sdk_path.len - 1] == '/') {
                    @panic("MacOS SDK path must not end with '/'");
                }

                //Check if path is absolute
                if (!std.fs.path.isAbsolute(osx_sdk_path)) {
                    @panic("MacOS SDK must be an absolute path!");
                }

                lib.addFrameworkPath(.{ .path = b.fmt("{s}/System/Library/Frameworks", .{osx_sdk_path}) });
                lib.addSystemIncludePath(.{ .path = b.fmt("{s}/usr/include", .{osx_sdk_path}) });
                lib.addLibraryPath(.{ .path = b.fmt("{s}/usr/lib", .{osx_sdk_path}) });
            } else if (!target.query.isNative()) {
                @panic("MacOS SDK path must be provided when cross compiling!");
            }

            lib.linkSystemLibrary("objc");

            lib.linkFramework("AppKit");
            lib.linkFramework("OpenGL");
            lib.linkFramework("CoreFoundation");
            lib.linkFramework("CoreServices");
            lib.linkFramework("CoreGraphics");
            lib.linkFramework("Metal");
            lib.linkFramework("CoreVideo");
            lib.linkFramework("Cocoa");
            lib.linkFramework("IOKit");
            lib.linkFramework("ForceFeedback");
            lib.linkFramework("Carbon");
            lib.linkFramework("CoreAudio");
            lib.linkFramework("AudioToolbox");
            lib.linkFramework("Foundation");
        },
        else => {},
    }
}

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    var options = getDefaultOptionsForTarget(target.result);

    const disable_audio = b.option(bool, "disable_audio", "Disables the audio subsystems") orelse false;
    const disable_render = b.option(bool, "disable_render", "Disables the render subsystems") orelse false;
    const disable_joystick = b.option(bool, "disable_joystick", "Disables the joystick subsystems") orelse false;
    const disable_video_sub_implementations = b.option(bool, "disable_video_sub_implementations", "Disables the sub video implementations") orelse false;

    if (disable_audio) options.audio_implementations = .{};
    if (disable_render) options.render_implementations = .{
        .software = false,
    };
    if (disable_joystick) {
        options.joystick_implementations = .{};
        options.haptic_implementation = .dummy;
    }
    if (disable_video_sub_implementations) options.video_sub_implementations = .{};

    options.shared = b.option(bool, "shared", "Whether to build a shared or static library") orelse false;

    options.osx_sdk_path = b.option([]const u8, "osx_sdk_path", "Path to a MacOS SDK, for cross compilation");
    options.linux_sdk_path = b.option([]const u8, "linux_sdk_path", "Path to a Linux SDK, for cross compilation");

    const sdl = try createSDL(b, target, optimize, options);

    b.installArtifact(sdl);

    var example = b.addExecutable(.{
        .name = "simple_example",
        .root_source_file = .{ .path = "examples/simple.zig" },
        .target = target,
    });
    //Link against SDL
    example.linkLibrary(sdl);

    b.installArtifact(example);

    var example_run_artifact = b.addRunArtifact(example);

    var example_run_step = b.step("simple_example", "Run the simple example");
    example_run_step.dependOn(&example_run_artifact.step);
}

///Finds all c/cpp sources in a folder recursively
///Each type of file is split into its own array so that caller can specify specific compilation flags for each filetype
///Caller owns returned memory (but that doesnt really matter in the build script, we just dont clear anything :^)
fn findCSources(allocator: std.mem.Allocator, lazy_path: std.Build.LazyPath) !struct { c: []const []const u8, cpp: []const []const u8 } {
    var c_list = std.ArrayList([]const u8).init(allocator);
    var cpp_list = std.ArrayList([]const u8).init(allocator);

    var dir = try std.fs.openDirAbsolute(lazy_path.getPath(lazy_path.src_path.owner), .{
        .iterate = true,
    });
    defer dir.close();

    var walker: std.fs.Dir.Walker = try dir.walk(allocator);
    defer walker.deinit();

    var itr_next: ?std.fs.Dir.Walker.Entry = try walker.next();
    while (itr_next != null) {
        const next: std.fs.Dir.Walker.Entry = itr_next.?;

        //if the file is a c source file
        if (std.mem.endsWith(u8, next.path, ".c")) {
            var item = try allocator.alloc(u8, next.path.len + lazy_path.src_path.sub_path.len);

            //copy the root first
            @memcpy(item[0..lazy_path.src_path.sub_path.len], lazy_path.src_path.sub_path);

            //copy the filepath next
            @memcpy(item[lazy_path.src_path.sub_path.len..], next.path);

            try c_list.append(item);
        }

        //if the file is a cpp source file
        if (std.mem.endsWith(u8, next.path, ".cpp")) {
            var item = try allocator.alloc(u8, next.path.len + lazy_path.src_path.sub_path.len);

            //copy the root first
            @memcpy(item[0..lazy_path.src_path.sub_path.len], lazy_path.src_path.sub_path);

            //copy the filepath next
            @memcpy(item[lazy_path.src_path.sub_path.len..], next.path);

            try cpp_list.append(item);
        }

        itr_next = try walker.next();
    }

    return .{ .c = try c_list.toOwnedSlice(), .cpp = try cpp_list.toOwnedSlice() };
}

fn root() []const u8 {
    return std.fs.path.dirname(@src().file) orelse ".";
}

const root_path = root() ++ "/";

const audio_src_files = [_][]const u8{
    "src/audio/SDL_audio.c",
    "src/audio/SDL_audiocvt.c",
    "src/audio/SDL_audiodev.c",
    "src/audio/SDL_audiotypecvt.c",
    "src/audio/SDL_mixer.c",
    "src/audio/SDL_wave.c",
};

const render_src_files = [_][]const u8{
    "src/render/SDL_d3dmath.c",
    "src/render/SDL_render.c",
    "src/render/SDL_yuv_sw.c",
};

const video_src_files = [_][]const u8{
    "src/video/SDL_RLEaccel.c",
    "src/video/SDL_blit.c",
    "src/video/SDL_blit_0.c",
    "src/video/SDL_blit_1.c",
    "src/video/SDL_blit_A.c",
    "src/video/SDL_blit_N.c",
    "src/video/SDL_blit_auto.c",
    "src/video/SDL_blit_copy.c",
    "src/video/SDL_blit_slow.c",
    "src/video/SDL_bmp.c",
    "src/video/SDL_clipboard.c",
    "src/video/SDL_egl.c",
    "src/video/SDL_fillrect.c",
    "src/video/SDL_pixels.c",
    "src/video/SDL_rect.c",
    "src/video/SDL_shape.c",
    "src/video/SDL_stretch.c",
    "src/video/SDL_surface.c",
    "src/video/SDL_video.c",
    "src/video/SDL_vulkan_utils.c",
    "src/video/SDL_yuv.c",
    "src/video/yuv2rgb/yuv_rgb.c",

    "src/video/dummy/SDL_nullevents.c",
    "src/video/dummy/SDL_nullframebuffer.c",
    "src/video/dummy/SDL_nullvideo.c",
};

const generic_src_files = [_][]const u8{
    "src/SDL.c",
    "src/SDL_assert.c",
    "src/SDL_dataqueue.c",
    "src/SDL_error.c",
    "src/SDL_guid.c",
    "src/SDL_hints.c",
    "src/SDL_list.c",
    "src/SDL_log.c",
    "src/SDL_utils.c",
    "src/atomic/SDL_atomic.c",
    "src/atomic/SDL_spinlock.c",
    "src/cpuinfo/SDL_cpuinfo.c",
    "src/dynapi/SDL_dynapi.c",
    "src/events/SDL_clipboardevents.c",
    "src/events/SDL_displayevents.c",
    "src/events/SDL_dropevents.c",
    "src/events/SDL_events.c",
    "src/events/SDL_gesture.c",
    "src/events/SDL_keyboard.c",
    "src/events/SDL_keysym_to_scancode.c",
    "src/events/SDL_mouse.c",
    "src/events/SDL_quit.c",
    "src/events/SDL_scancode_tables.c",
    "src/events/SDL_touch.c",
    "src/events/SDL_windowevents.c",
    "src/events/imKStoUCS.c",
    "src/file/SDL_rwops.c",
    "src/haptic/SDL_haptic.c",
    "src/hidapi/SDL_hidapi.c",

    "src/joystick/SDL_gamecontroller.c",
    "src/joystick/SDL_joystick.c",
    "src/joystick/controller_type.c",
    // "src/joystick/virtual/SDL_virtualjoystick.c",

    "src/libm/e_atan2.c",
    "src/libm/e_exp.c",
    "src/libm/e_fmod.c",
    "src/libm/e_log.c",
    "src/libm/e_log10.c",
    "src/libm/e_pow.c",
    "src/libm/e_rem_pio2.c",
    "src/libm/e_sqrt.c",
    "src/libm/k_cos.c",
    "src/libm/k_rem_pio2.c",
    "src/libm/k_sin.c",
    "src/libm/k_tan.c",
    "src/libm/s_atan.c",
    "src/libm/s_copysign.c",
    "src/libm/s_cos.c",
    "src/libm/s_fabs.c",
    "src/libm/s_floor.c",
    "src/libm/s_scalbn.c",
    "src/libm/s_sin.c",
    "src/libm/s_tan.c",
    "src/locale/SDL_locale.c",
    "src/misc/SDL_url.c",
    "src/power/SDL_power.c",
    "src/sensor/SDL_sensor.c",
    "src/stdlib/SDL_crc16.c",
    "src/stdlib/SDL_crc32.c",
    "src/stdlib/SDL_getenv.c",
    "src/stdlib/SDL_iconv.c",
    "src/stdlib/SDL_malloc.c",
    "src/stdlib/SDL_mslibc.c",
    "src/stdlib/SDL_qsort.c",
    "src/stdlib/SDL_stdlib.c",
    "src/stdlib/SDL_string.c",
    "src/stdlib/SDL_strtokr.c",
    "src/thread/SDL_thread.c",
    "src/timer/SDL_timer.c",

    // "src/render/software/SDL_blendfillrect.c",
    // "src/render/software/SDL_blendline.c",
    // "src/render/software/SDL_blendpoint.c",
    // "src/render/software/SDL_drawline.c",
    // "src/render/software/SDL_drawpoint.c",
    // "src/render/software/SDL_render_sw.c",
    // "src/render/software/SDL_rotate.c",
    // "src/render/software/SDL_triangle.c",

    // "src/audio/dummy/SDL_dummyaudio.c",

    "src/joystick/hidapi/SDL_hidapi_combined.c",
    "src/joystick/hidapi/SDL_hidapi_gamecube.c",
    "src/joystick/hidapi/SDL_hidapi_luna.c",
    "src/joystick/hidapi/SDL_hidapi_ps3.c",
    "src/joystick/hidapi/SDL_hidapi_ps4.c",
    "src/joystick/hidapi/SDL_hidapi_ps5.c",
    "src/joystick/hidapi/SDL_hidapi_rumble.c",
    "src/joystick/hidapi/SDL_hidapi_shield.c",
    "src/joystick/hidapi/SDL_hidapi_stadia.c",
    "src/joystick/hidapi/SDL_hidapi_steam.c",
    "src/joystick/hidapi/SDL_hidapi_switch.c",
    "src/joystick/hidapi/SDL_hidapi_wii.c",
    "src/joystick/hidapi/SDL_hidapi_xbox360.c",
    "src/joystick/hidapi/SDL_hidapi_xbox360w.c",
    "src/joystick/hidapi/SDL_hidapi_xboxone.c",
    "src/joystick/hidapi/SDL_hidapijoystick.c",
};

const windows_src_files = [_][]const u8{
    "src/core/windows/SDL_hid.c",
    "src/core/windows/SDL_immdevice.c",
    "src/core/windows/SDL_windows.c",
    "src/core/windows/SDL_xinput.c",
    "src/filesystem/windows/SDL_sysfilesystem.c",
    // "src/hidapi/windows/hid.c",
    // This can be enabled when Zig updates to the next mingw-w64 release,
    // which will make the headers gain `windows.gaming.input.h`.
    // Also revert the patch 2c79fd8fd04f1e5045cbe5978943b0aea7593110.
    //"src/joystick/windows/SDL_windows_gaming_input.c",

    "src/loadso/windows/SDL_sysloadso.c",
    // "src/main/windows/SDL_windows_main.c",
    "src/misc/windows/SDL_sysurl.c",
    "src/sensor/windows/SDL_windowssensor.c",

    // "src/render/direct3d/SDL_render_d3d.c",
    // "src/render/direct3d/SDL_shaders_d3d.c",
    // "src/render/direct3d11/SDL_render_d3d11.c",
    // "src/render/direct3d11/SDL_shaders_d3d11.c",
    // "src/render/direct3d12/SDL_render_d3d12.c",
    // "src/render/direct3d12/SDL_shaders_d3d12.c",

    // "src/audio/directsound/SDL_directsound.c",
    // "src/audio/wasapi/SDL_wasapi.c",
    // "src/audio/wasapi/SDL_wasapi_win32.c",
    // "src/audio/winmm/SDL_winmm.c",
    // "src/audio/disk/SDL_diskaudio.c",

    // "src/render/opengl/SDL_render_gl.c",
    // "src/render/opengl/SDL_shaders_gl.c",
    // "src/render/opengles/SDL_render_gles.c",
    // "src/render/opengles2/SDL_render_gles2.c",
    // "src/render/opengles2/SDL_shaders_gles2.c",
};

const linux_src_files = [_][]const u8{
    "src/core/linux/SDL_dbus.c",
    "src/core/linux/SDL_evdev.c",
    "src/core/linux/SDL_evdev_capabilities.c",
    "src/core/linux/SDL_evdev_kbd.c",
    "src/core/linux/SDL_ibus.c",
    "src/core/linux/SDL_ime.c",
    "src/core/linux/SDL_sandbox.c",
    "src/core/linux/SDL_threadprio.c",
    "src/core/linux/SDL_udev.c",
    // "src/core/linux/SDL_fcitx.c",
    "src/core/unix/SDL_poll.c",

    "src/hidapi/linux/hid.c",

    "src/sensor/dummy/SDL_dummysensor.c",

    "src/misc/unix/SDL_sysurl.c",

    // "src/audio/alsa/SDL_alsa_audio.c",
    // "src/audio/jack/SDL_jackaudio.c",
    // "src/audio/pulseaudio/SDL_pulseaudio.c",
};

const android_src_files = [_][]const u8{
    "src/core/android/SDL_android.c",
    // "src/core/unix/SDL_poll.c",

    "src/hidapi/android/hid.cpp",

    "src/sensor/dummy/SDL_dummysensor.c",

    "src/misc/android/SDL_sysurl.c",

    // "src/audio/alsa/SDL_alsa_audio.c",
    // "src/audio/jack/SDL_jackaudio.c",
    // "src/audio/pulseaudio/SDL_pulseaudio.c",
};

const darwin_src_files = [_][]const u8{
    // "src/joystick/darwin/SDL_iokitjoystick.c",
    // "src/power/macosx/SDL_syspower.c",
    "src/loadso/dlopen/SDL_sysloadso.c",
    // "src/audio/disk/SDL_diskaudio.c",
    // "src/render/opengl/SDL_render_gl.c",
    // "src/render/opengl/SDL_shaders_gl.c",
    // "src/render/opengles/SDL_render_gles.c",
    // "src/render/opengles2/SDL_render_gles2.c",
    // "src/render/opengles2/SDL_shaders_gles2.c",
    "src/sensor/dummy/SDL_dummysensor.c",
};

const objective_c_src_files = [_][]const u8{
    // "src/audio/coreaudio/SDL_coreaudio.m",
    "src/file/cocoa/SDL_rwopsbundlesupport.m",
    "src/filesystem/cocoa/SDL_sysfilesystem.m",
    //"src/hidapi/testgui/mac_support_cocoa.m",
    // This appears to be for SDL3 only.
    //"src/joystick/apple/SDL_mfijoystick.m",
    "src/misc/macosx/SDL_sysurl.m",
    // "src/power/uikit/SDL_syspower.m",
    // "src/render/metal/SDL_render_metal.m",
    "src/sensor/coremotion/SDL_coremotionsensor.m",
    "src/video/cocoa/SDL_cocoaclipboard.m",
    "src/video/cocoa/SDL_cocoaevents.m",
    "src/video/cocoa/SDL_cocoakeyboard.m",
    "src/video/cocoa/SDL_cocoamessagebox.m",
    "src/video/cocoa/SDL_cocoametalview.m",
    "src/video/cocoa/SDL_cocoamodes.m",
    "src/video/cocoa/SDL_cocoamouse.m",
    "src/video/cocoa/SDL_cocoaopengl.m",
    "src/video/cocoa/SDL_cocoaopengles.m",
    "src/video/cocoa/SDL_cocoashape.m",
    "src/video/cocoa/SDL_cocoavideo.m",
    "src/video/cocoa/SDL_cocoavulkan.m",
    "src/video/cocoa/SDL_cocoawindow.m",
    "src/video/uikit/SDL_uikitappdelegate.m",
    "src/video/uikit/SDL_uikitclipboard.m",
    "src/video/uikit/SDL_uikitevents.m",
    "src/video/uikit/SDL_uikitmessagebox.m",
    "src/video/uikit/SDL_uikitmetalview.m",
    "src/video/uikit/SDL_uikitmodes.m",
    "src/video/uikit/SDL_uikitopengles.m",
    "src/video/uikit/SDL_uikitopenglview.m",
    "src/video/uikit/SDL_uikitvideo.m",
    "src/video/uikit/SDL_uikitview.m",
    "src/video/uikit/SDL_uikitviewcontroller.m",
    "src/video/uikit/SDL_uikitvulkan.m",
    "src/video/uikit/SDL_uikitwindow.m",
};

const ios_src_files = [_][]const u8{
    "src/hidapi/ios/hid.m",
    "src/misc/ios/SDL_sysurl.m",
    "src/joystick/iphoneos/SDL_mfijoystick.m",
};

const unknown_src_files = [_][]const u8{
    "src/audio/aaudio/SDL_aaudio.c",
    "src/audio/android/SDL_androidaudio.c",
    "src/audio/arts/SDL_artsaudio.c",
    "src/audio/dsp/SDL_dspaudio.c",
    "src/audio/emscripten/SDL_emscriptenaudio.c",
    "src/audio/esd/SDL_esdaudio.c",
    "src/audio/fusionsound/SDL_fsaudio.c",
    "src/audio/n3ds/SDL_n3dsaudio.c",
    "src/audio/nacl/SDL_naclaudio.c",
    "src/audio/nas/SDL_nasaudio.c",
    "src/audio/netbsd/SDL_netbsdaudio.c",
    "src/audio/openslES/SDL_openslES.c",
    "src/audio/os2/SDL_os2audio.c",
    "src/audio/paudio/SDL_paudio.c",
    "src/audio/pipewire/SDL_pipewire.c",
    "src/audio/ps2/SDL_ps2audio.c",
    "src/audio/psp/SDL_pspaudio.c",
    "src/audio/qsa/SDL_qsa_audio.c",
    "src/audio/sndio/SDL_sndioaudio.c",
    "src/audio/sun/SDL_sunaudio.c",
    "src/audio/vita/SDL_vitaaudio.c",

    "src/core/android/SDL_android.c",
    "src/core/freebsd/SDL_evdev_kbd_freebsd.c",
    "src/core/openbsd/SDL_wscons_kbd.c",
    "src/core/openbsd/SDL_wscons_mouse.c",
    "src/core/os2/SDL_os2.c",
    "src/core/os2/geniconv/geniconv.c",
    "src/core/os2/geniconv/os2cp.c",
    "src/core/os2/geniconv/os2iconv.c",
    "src/core/os2/geniconv/sys2utf8.c",
    "src/core/os2/geniconv/test.c",

    "src/file/n3ds/SDL_rwopsromfs.c",

    "src/filesystem/android/SDL_sysfilesystem.c",
    "src/filesystem/dummy/SDL_sysfilesystem.c",
    "src/filesystem/emscripten/SDL_sysfilesystem.c",
    "src/filesystem/n3ds/SDL_sysfilesystem.c",
    "src/filesystem/nacl/SDL_sysfilesystem.c",
    "src/filesystem/os2/SDL_sysfilesystem.c",
    "src/filesystem/ps2/SDL_sysfilesystem.c",
    "src/filesystem/psp/SDL_sysfilesystem.c",
    "src/filesystem/riscos/SDL_sysfilesystem.c",
    "src/filesystem/unix/SDL_sysfilesystem.c",
    "src/filesystem/vita/SDL_sysfilesystem.c",

    "src/hidapi/libusb/hid.c",
    "src/hidapi/mac/hid.c",

    "src/joystick/android/SDL_sysjoystick.c",
    "src/joystick/bsd/SDL_bsdjoystick.c",
    "src/joystick/dummy/SDL_sysjoystick.c",
    "src/joystick/emscripten/SDL_sysjoystick.c",
    "src/joystick/n3ds/SDL_sysjoystick.c",
    "src/joystick/os2/SDL_os2joystick.c",
    "src/joystick/ps2/SDL_sysjoystick.c",
    "src/joystick/psp/SDL_sysjoystick.c",
    "src/joystick/steam/SDL_steamcontroller.c",
    "src/joystick/vita/SDL_sysjoystick.c",

    "src/loadso/dummy/SDL_sysloadso.c",
    "src/loadso/os2/SDL_sysloadso.c",

    "src/main/android/SDL_android_main.c",
    "src/main/dummy/SDL_dummy_main.c",
    "src/main/gdk/SDL_gdk_main.c",
    "src/main/n3ds/SDL_n3ds_main.c",
    "src/main/nacl/SDL_nacl_main.c",
    "src/main/ps2/SDL_ps2_main.c",
    "src/main/psp/SDL_psp_main.c",
    "src/main/uikit/SDL_uikit_main.c",

    "src/misc/android/SDL_sysurl.c",
    "src/misc/dummy/SDL_sysurl.c",
    "src/misc/emscripten/SDL_sysurl.c",
    "src/misc/riscos/SDL_sysurl.c",
    "src/misc/unix/SDL_sysurl.c",
    "src/misc/vita/SDL_sysurl.c",

    // "src/power/android/SDL_syspower.c",
    // "src/power/emscripten/SDL_syspower.c",
    // "src/power/haiku/SDL_syspower.c",
    // "src/power/n3ds/SDL_syspower.c",
    // "src/power/psp/SDL_syspower.c",
    // "src/power/vita/SDL_syspower.c",

    "src/sensor/android/SDL_androidsensor.c",
    "src/sensor/n3ds/SDL_n3dssensor.c",
    "src/sensor/vita/SDL_vitasensor.c",

    "src/test/SDL_test_assert.c",
    "src/test/SDL_test_common.c",
    "src/test/SDL_test_compare.c",
    "src/test/SDL_test_crc32.c",
    "src/test/SDL_test_font.c",
    "src/test/SDL_test_fuzzer.c",
    "src/test/SDL_test_harness.c",
    "src/test/SDL_test_imageBlit.c",
    "src/test/SDL_test_imageBlitBlend.c",
    "src/test/SDL_test_imageFace.c",
    "src/test/SDL_test_imagePrimitives.c",
    "src/test/SDL_test_imagePrimitivesBlend.c",
    "src/test/SDL_test_log.c",
    "src/test/SDL_test_md5.c",
    "src/test/SDL_test_memory.c",
    "src/test/SDL_test_random.c",

    "src/video/android/SDL_androidclipboard.c",
    "src/video/android/SDL_androidevents.c",
    "src/video/android/SDL_androidgl.c",
    "src/video/android/SDL_androidkeyboard.c",
    "src/video/android/SDL_androidmessagebox.c",
    "src/video/android/SDL_androidmouse.c",
    "src/video/android/SDL_androidtouch.c",
    "src/video/android/SDL_androidvideo.c",
    "src/video/android/SDL_androidvulkan.c",
    "src/video/android/SDL_androidwindow.c",
    "src/video/directfb/SDL_DirectFB_WM.c",
    "src/video/directfb/SDL_DirectFB_dyn.c",
    "src/video/directfb/SDL_DirectFB_events.c",
    "src/video/directfb/SDL_DirectFB_modes.c",
    "src/video/directfb/SDL_DirectFB_mouse.c",
    "src/video/directfb/SDL_DirectFB_opengl.c",
    "src/video/directfb/SDL_DirectFB_render.c",
    "src/video/directfb/SDL_DirectFB_shape.c",
    "src/video/directfb/SDL_DirectFB_video.c",
    "src/video/directfb/SDL_DirectFB_vulkan.c",
    "src/video/directfb/SDL_DirectFB_window.c",
    "src/video/emscripten/SDL_emscriptenevents.c",
    "src/video/emscripten/SDL_emscriptenframebuffer.c",
    "src/video/emscripten/SDL_emscriptenmouse.c",
    "src/video/emscripten/SDL_emscriptenopengles.c",
    "src/video/emscripten/SDL_emscriptenvideo.c",
    "src/video/kmsdrm/SDL_kmsdrmdyn.c",
    "src/video/kmsdrm/SDL_kmsdrmevents.c",
    "src/video/kmsdrm/SDL_kmsdrmmouse.c",
    "src/video/kmsdrm/SDL_kmsdrmopengles.c",
    "src/video/kmsdrm/SDL_kmsdrmvideo.c",
    "src/video/kmsdrm/SDL_kmsdrmvulkan.c",
    "src/video/n3ds/SDL_n3dsevents.c",
    "src/video/n3ds/SDL_n3dsframebuffer.c",
    "src/video/n3ds/SDL_n3dsswkb.c",
    "src/video/n3ds/SDL_n3dstouch.c",
    "src/video/n3ds/SDL_n3dsvideo.c",
    "src/video/nacl/SDL_naclevents.c",
    "src/video/nacl/SDL_naclglue.c",
    "src/video/nacl/SDL_naclopengles.c",
    "src/video/nacl/SDL_naclvideo.c",
    "src/video/nacl/SDL_naclwindow.c",
    "src/video/offscreen/SDL_offscreenevents.c",
    "src/video/offscreen/SDL_offscreenframebuffer.c",
    "src/video/offscreen/SDL_offscreenopengles.c",
    "src/video/offscreen/SDL_offscreenvideo.c",
    "src/video/offscreen/SDL_offscreenwindow.c",
    "src/video/os2/SDL_os2dive.c",
    "src/video/os2/SDL_os2messagebox.c",
    "src/video/os2/SDL_os2mouse.c",
    "src/video/os2/SDL_os2util.c",
    "src/video/os2/SDL_os2video.c",
    "src/video/os2/SDL_os2vman.c",
    "src/video/pandora/SDL_pandora.c",
    "src/video/pandora/SDL_pandora_events.c",
    "src/video/ps2/SDL_ps2video.c",
    "src/video/psp/SDL_pspevents.c",
    "src/video/psp/SDL_pspgl.c",
    "src/video/psp/SDL_pspmouse.c",
    "src/video/psp/SDL_pspvideo.c",
    "src/video/qnx/gl.c",
    "src/video/qnx/keyboard.c",
    "src/video/qnx/video.c",
    "src/video/raspberry/SDL_rpievents.c",
    "src/video/raspberry/SDL_rpimouse.c",
    "src/video/raspberry/SDL_rpiopengles.c",
    "src/video/raspberry/SDL_rpivideo.c",
    "src/video/riscos/SDL_riscosevents.c",
    "src/video/riscos/SDL_riscosframebuffer.c",
    "src/video/riscos/SDL_riscosmessagebox.c",
    "src/video/riscos/SDL_riscosmodes.c",
    "src/video/riscos/SDL_riscosmouse.c",
    "src/video/riscos/SDL_riscosvideo.c",
    "src/video/riscos/SDL_riscoswindow.c",
    "src/video/vita/SDL_vitaframebuffer.c",
    "src/video/vita/SDL_vitagl_pvr.c",
    "src/video/vita/SDL_vitagles.c",
    "src/video/vita/SDL_vitagles_pvr.c",
    "src/video/vita/SDL_vitakeyboard.c",
    "src/video/vita/SDL_vitamessagebox.c",
    "src/video/vita/SDL_vitamouse.c",
    "src/video/vita/SDL_vitatouch.c",
    "src/video/vita/SDL_vitavideo.c",
    "src/video/vivante/SDL_vivanteopengles.c",
    "src/video/vivante/SDL_vivanteplatform.c",
    "src/video/vivante/SDL_vivantevideo.c",
    "src/video/vivante/SDL_vivantevulkan.c",

    "src/render/opengl/SDL_render_gl.c",
    "src/render/opengl/SDL_shaders_gl.c",
    "src/render/opengles/SDL_render_gles.c",
    "src/render/opengles2/SDL_render_gles2.c",
    "src/render/opengles2/SDL_shaders_gles2.c",
    "src/render/ps2/SDL_render_ps2.c",
    "src/render/psp/SDL_render_psp.c",
    "src/render/vitagxm/SDL_render_vita_gxm.c",
    "src/render/vitagxm/SDL_render_vita_gxm_memory.c",
    "src/render/vitagxm/SDL_render_vita_gxm_tools.c",
};
