-- libgo xmake configuration
-- A stackful coroutine library for collaborative scheduling written in C++ 11

-- Project metadata (root scope)
set_project("libgo")
set_version("3.2.4")
set_license("MIT")
set_description("A stackful coroutine library for collaborative scheduling")

-- Platform and architecture restrictions (root scope)
set_allowedplats("linux", "macosx", "windows")
set_allowedarchs("x86", "x86_64", "arm64")

-- Set C++ standard
set_languages("c++11")

-- Add project rules
add_rules("mode.debug", "mode.release", "mode.releasedbg", "mode.profile")

-- Project configuration
set_config("build_dynamic", false)
set_config("enable_debugger", false)
set_config("disable_hook", false)
set_config("include_static_hook", true)

-- Define options
option("build_dynamic")
    set_default(false)
    set_description("Build dynamic library")
    set_category("Build Options")

option("enable_debugger")
    set_default(false)
    set_description("Enable debugger support")
    set_category("Features")

option("disable_hook")
    set_default(false)
    set_description("Disable hook for network IO")
    set_category("Features")

option("include_static_hook")
    set_default(true)
    set_description("Include static_hook in main library")
    set_category("Features")

-- Main target
target("libgo")
    set_kind("static")
    add_headerfiles("libgo/**.h")
    add_includedirs(".")

    -- Platform-specific configurations
    if is_plat("linux", "macosx") then
        -- Common flags for Unix-like systems
        add_cxxflags("-fPIC", "-fno-strict-aliasing", "-Wall", "-Wno-nonnull-compare")
        add_defines("__const__=__unused__")
        
        -- Release optimization (match CMake exactly)
        if is_mode("release") then
            add_cxxflags("-g", "-O3", "-DNDEBUG")
        end
        
        -- Debug symbols
        if is_mode("debug") then
            add_cxxflags("-g")
        end
        
        -- Profile flags
        if is_mode("profile") then
            add_cxxflags("-pg", "-g")
        end
        
        -- Add assembly source files (placeholder for actual selection logic)
        -- Note: In a real implementation, you'd need to replicate the shell script logic
        add_files("libgo/context/*.S")
        
        -- Hook implementation
        if not get_config("disable_hook") then
            -- Add main netio files (excluding static_hook)
            add_files("libgo/netio/unix/hook.cpp")
            add_files("libgo/netio/unix/hook_helper.cpp")
            add_files("libgo/netio/unix/epoll_reactor.cpp")
            add_files("libgo/netio/unix/kqueue_reactor.cpp")
            add_files("libgo/netio/unix/reactor.cpp")
            add_files("libgo/netio/unix/reactor_element.cpp")
            add_files("libgo/netio/unix/fd_context.cpp")
            add_files("libgo/netio/unix/errno_hook.cpp")
            
            -- Conditionally include static_hook in main library
            if get_config("include_static_hook") then
                add_files("libgo/netio/unix/static_hook/static_hook.cpp")
            end
        else
            add_files("libgo/netio/disable_hook/**.cpp")
        end
        
        -- Link libraries
        add_syslinks("pthread", "dl")
        
    elseif is_plat("windows") then
        -- Windows specific configurations
        add_defines("_CRT_SECURE_NO_WARNINGS")
        add_cxxflags("/MT")
        if is_mode("debug") then
            add_cxxflags("/MTd")
        end
        
        -- Windows hook implementation
        if not get_config("disable_hook") then
            add_includedirs("libgo/netio/windows")
            add_files("libgo/netio/windows/**.cpp")
            add_files("libgo/context/fiber/**.cpp")
        else
            add_files("libgo/netio/disable_hook/**.cpp")
        end
        
        -- Suppress specific warnings
        add_cxxflags("/wd4819", "/wd4267")
    end

    -- Common source files for all platforms
    add_files("libgo/common/*.cpp")
    add_files("libgo/cls/*.cpp")
    add_files("libgo/context/*.cpp") -- Exclude .S files already added separately
    add_files("libgo/debug/*.cpp")
    add_files("libgo/defer/*.cpp")
    add_files("libgo/pool/*.cpp")
    add_files("libgo/routine_sync_libgo/*.cpp")
    add_files("libgo/scheduler/*.cpp")
    add_files("libgo/task/*.cpp")
    add_files("libgo/timer/*.cpp")

    -- Generate config header
    add_configfiles("libgo/common/cmake_config.h.in", {pattern = "@(.-)@"})

    -- Conditionally add debugger support
    if get_config("enable_debugger") then
        add_defines("ENABLE_DEBUGGER=1")
    else
        add_defines("ENABLE_DEBUGGER=0")
    end

    -- Conditionally add hook support
    if get_config("disable_hook") then
        add_defines("ENABLE_HOOK=0")
    else
        add_defines("ENABLE_HOOK=1")
    end

    -- Always enable routine_sync
    add_defines("USE_ROUTINE_SYNC=1")

-- Dynamic library target (optional)
if get_config("build_dynamic") then
    target("libgo_dynamic")
        set_kind("shared")
        add_deps("libgo")
        add_headerfiles("libgo/**.h")
        add_includedirs(".")
        
        if is_plat("linux", "macosx") then
            add_syslinks("pthread", "dl")
        end
end

-- Static hook target (Unix only)
if is_plat("linux", "macosx") then
    target("static_hook")
        set_kind("static")
        add_files("libgo/netio/unix/static_hook/static_hook.cpp")
        add_defines("ENABLE_HOOK=0")
        -- Override include path to avoid main config conflicts
        add_includedirs("libgo/common")
        
        -- Add description about usage
        on_load(function (target)
            if get_config("include_static_hook") then
                cprint("${green}Note: static_hook is already included in main library.")
                cprint("${green}Use this target only if you need standalone static_hook library.")
            else
                cprint("${yellow}Note: static_hook is NOT included in main library.")
                cprint("${yellow}Link with libstatic_hook.a if you need static_hook functionality.")
            end
        end)
end

-- Installation settings
on_install(function (target)
    -- Install headers
    os.cp("libgo", target:installdir().."/include/libgo")
    
    -- Install libraries
    if target:is_plat("linux", "macosx") then
        os.cp("build/liblibgo.a", target:installdir().."/lib/")
        if get_config("build_dynamic") then
            os.cp("build/liblibgo.so", target:installdir().."/lib/")
        end
        os.cp("build/libstatic_hook.a", target:installdir().."/lib/")
    end
end)

-- Custom targets for build type switching
task("debug")
    on_run(function ()
        set_mode("debug")
        cprint("${bright}Switched to debug mode")
    end)

task("release")
    on_run(function ()
        set_mode("release")
        cprint("${bright}Switched to release mode")
    end)

task("profile")
    on_run(function ()
        set_mode("profile")
        cprint("${bright}Switched to profile mode")
    end)