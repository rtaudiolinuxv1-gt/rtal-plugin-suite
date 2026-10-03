cmake_minimum_required(VERSION 3.16)
project(rtal_plugin_suite VERSION 1.0.0 LANGUAGES NONE)

find_program(BASH_EXECUTABLE bash REQUIRED)

if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE RELEASE CACHE STRING "Build type" FORCE)
endif()

set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS RELEASE DEBUG)
set(RTAL_BUILD_MODE "RELEASE" CACHE STRING "Suite build mode")
set_property(CACHE RTAL_BUILD_MODE PROPERTY STRINGS RELEASE DEBUG)

option(BUILD_LV2 "Build LV2 targets" ON)
option(BUILD_STANDALONE "Build standalone targets" ON)
option(BUILD_VST2 "Build VST2 targets" OFF)
option(BUILD_BINARY_PACKAGE "Enable creation of the suite binary package target" ON)
option(PORTABLE_X86_64 "Build portable x86_64 binaries" ON)

set(RTAL_EXTRA_CFLAGS "$ENV{CFLAGS}" CACHE STRING "Extra compiler flags passed to all plugin exports")
set(VST2_SDK_DIR "$ENV{VST2_SDK_DIR}" CACHE PATH "Path to the VST2 SDK")

if(NOT VST2_SDK_DIR)
    set(VST2_SDK_DIR "${CMAKE_SOURCE_DIR}/../vstsdk2.4" CACHE PATH "Path to the VST2 SDK" FORCE)
endif()

if(RTAL_BUILD_MODE STREQUAL "DEBUG")
    set(RTAL_MODE_CFLAGS "-O0 -g3 -DDEBUG")
else()
    set(RTAL_BUILD_MODE "RELEASE" CACHE STRING "Suite build mode" FORCE)
    set(RTAL_MODE_CFLAGS "-O2 -DNDEBUG")
endif()

set(RTAL_COMBINED_CFLAGS "${RTAL_MODE_CFLAGS} ${RTAL_EXTRA_CFLAGS}")
string(STRIP "${RTAL_COMBINED_CFLAGS}" RTAL_COMBINED_CFLAGS)
set(RTAL_CFLAGS "${RTAL_COMBINED_CFLAGS}" CACHE STRING "Computed compiler flags passed to plugin export scripts" FORCE)

option(ENABLE_RTAL_GUITAR_SHADOW "Enable rtal-guitar-shadow" ON)
option(ENABLE_RTAL_IN_BLOOM "Enable rtal-In_Bloom" ON)
option(ENABLE_RTAL_LIVE_FOREVER "Enable rtal-live-forever" ON)
option(ENABLE_RTAL_MESTOPHELIES "Enable rtal-mestophelies" ON)
option(ENABLE_PRERELEASE_RTAL_DYNAMIC_DISTORTION "Enable prerelease rtal-dynamic-distortion" ON)
option(ENABLE_PRERELEASE_RTAL_CRYSTAL_PLUCK "Enable prerelease rtal-crystal-pluck" ON)
option(ENABLE_PRERELEASE_RTAL_SHITE_AMP "Enable prerelease rtal-shite_amp" ON)
option(ENABLE_PRERELEASE_RTAL_SILKCUT_CHOIR "Enable prerelease rtal-silkcut-choir" ON)
option(ENABLE_PRERELEASE_RTAL_DREAMS_OF_ELECTRIC_CABINETS "Enable prerelease rtal-dreams-of-electric-cabinets" ON)
option(ENABLE_PRERELEASE_RTAL_TAPE_GHOST "Enable prerelease rtal-tape-ghost" ON)
option(ENABLE_PRERELEASE_RTAL_ORBIT_PHASER "Enable prerelease rtal-orbit-phaser" ON)
option(ENABLE_PRERELEASE_RTAL_BARBERPOLE_SHIFT "Enable prerelease rtal-barberpole-shift" ON)
option(ENABLE_PRERELEASE_RTAL_SYMPATHETIC_STRINGS "Enable prerelease rtal-sympathetic-strings" ON)
option(ENABLE_PRERELEASE_RTAL_GLITTER_GRAINS "Enable prerelease rtal-glitter-grains" ON)
option(ENABLE_PRERELEASE_RTAL_LESLIE_WEATHER "Enable prerelease rtal-leslie-weather" ON)
option(ENABLE_PRERELEASE_RTAL_BACKWARDS_SUNDAY "Enable prerelease rtal-backwards-sunday" ON)
option(ENABLE_PRERELEASE_RTAL_DRIP_TANK "Enable prerelease rtal-drip-tank" ON)
option(ENABLE_PRERELEASE_RTAL_SUB_ORBIT "Enable prerelease rtal-sub-orbit" ON)
option(ENABLE_PRERELEASE_RTAL_VOWEL_MOUTH "Enable prerelease rtal-vowel-mouth" ON)
option(ENABLE_PRERELEASE_RTAL_CATHEDRAL_SHIMMER "Enable prerelease rtal-cathedral-shimmer" ON)
option(ENABLE_PRERELEASE_RTAL_STUTTER_GATE "Enable prerelease rtal-stutter-gate" ON)

set(RTAL_GOOD_PLUGINS "")
set(RTAL_PRERELEASE_PLUGINS "")
set(RTAL_SUITE_DEPS "")

function(rtal_add_plugin option_name category plugin_dir plugin_target)
    if(${option_name})
        add_subdirectory("${plugin_dir}")
        list(APPEND RTAL_SUITE_DEPS "${plugin_target}-all")
        if("${category}" STREQUAL "good")
            list(APPEND RTAL_GOOD_PLUGINS "${plugin_target}")
        else()
            list(APPEND RTAL_PRERELEASE_PLUGINS "${plugin_target}")
        endif()
        set(RTAL_SUITE_DEPS "${RTAL_SUITE_DEPS}" PARENT_SCOPE)
        set(RTAL_GOOD_PLUGINS "${RTAL_GOOD_PLUGINS}" PARENT_SCOPE)
        set(RTAL_PRERELEASE_PLUGINS "${RTAL_PRERELEASE_PLUGINS}" PARENT_SCOPE)
    endif()
endfunction()

rtal_add_plugin(ENABLE_RTAL_GUITAR_SHADOW good "plugins/rtal-guitar-shadow" "rtal-guitar-shadow")
rtal_add_plugin(ENABLE_RTAL_IN_BLOOM good "plugins/rtal-In_Bloom" "rtal-In_Bloom")
rtal_add_plugin(ENABLE_RTAL_LIVE_FOREVER good "plugins/rtal-live-forever" "rtal-live-forever")
rtal_add_plugin(ENABLE_RTAL_MESTOPHELIES good "plugins/rtal-mestophelies" "rtal-mestophelies")

rtal_add_plugin(ENABLE_PRERELEASE_RTAL_DYNAMIC_DISTORTION prerelease "plugins/rtal-dynamic-distortion" "rtal-dynamic-distortion")
rtal_add_plugin(ENABLE_PRERELEASE_RTAL_CRYSTAL_PLUCK prerelease "plugins/rtal-crystal-pluck" "rtal-crystal-pluck")
rtal_add_plugin(ENABLE_PRERELEASE_RTAL_SHITE_AMP prerelease "plugins/rtal-shite_amp" "rtal-shite_amp")
rtal_add_plugin(ENABLE_PRERELEASE_RTAL_SILKCUT_CHOIR prerelease "plugins/rtal-silkcut-choir" "rtal-silkcut-choir")
rtal_add_plugin(ENABLE_PRERELEASE_RTAL_DREAMS_OF_ELECTRIC_CABINETS prerelease "plugins/rtal-dreams-of-electric-cabinets" "rtal-dreams-of-electric-cabinets")
rtal_add_plugin(ENABLE_PRERELEASE_RTAL_TAPE_GHOST prerelease "plugins/rtal-tape-ghost" "rtal-tape-ghost")
rtal_add_plugin(ENABLE_PRERELEASE_RTAL_ORBIT_PHASER prerelease "plugins/rtal-orbit-phaser" "rtal-orbit-phaser")
rtal_add_plugin(ENABLE_PRERELEASE_RTAL_BARBERPOLE_SHIFT prerelease "plugins/rtal-barberpole-shift" "rtal-barberpole-shift")
rtal_add_plugin(ENABLE_PRERELEASE_RTAL_SYMPATHETIC_STRINGS prerelease "plugins/rtal-sympathetic-strings" "rtal-sympathetic-strings")
rtal_add_plugin(ENABLE_PRERELEASE_RTAL_GLITTER_GRAINS prerelease "plugins/rtal-glitter-grains" "rtal-glitter-grains")
rtal_add_plugin(ENABLE_PRERELEASE_RTAL_LESLIE_WEATHER prerelease "plugins/rtal-leslie-weather" "rtal-leslie-weather")
rtal_add_plugin(ENABLE_PRERELEASE_RTAL_BACKWARDS_SUNDAY prerelease "plugins/rtal-backwards-sunday" "rtal-backwards-sunday")
rtal_add_plugin(ENABLE_PRERELEASE_RTAL_DRIP_TANK prerelease "plugins/rtal-drip-tank" "rtal-drip-tank")
rtal_add_plugin(ENABLE_PRERELEASE_RTAL_SUB_ORBIT prerelease "plugins/rtal-sub-orbit" "rtal-sub-orbit")
rtal_add_plugin(ENABLE_PRERELEASE_RTAL_VOWEL_MOUTH prerelease "plugins/rtal-vowel-mouth" "rtal-vowel-mouth")
rtal_add_plugin(ENABLE_PRERELEASE_RTAL_CATHEDRAL_SHIMMER prerelease "plugins/rtal-cathedral-shimmer" "rtal-cathedral-shimmer")
rtal_add_plugin(ENABLE_PRERELEASE_RTAL_STUTTER_GATE prerelease "plugins/rtal-stutter-gate" "rtal-stutter-gate")

if(NOT RTAL_SUITE_DEPS)
    add_custom_target(rtal-suite-all
        COMMENT "No plugins are enabled"
    )
else()
    add_custom_target(rtal-suite-all ALL
        DEPENDS ${RTAL_SUITE_DEPS}
        COMMENT "Building enabled RTAL suite plugins"
    )
endif()

list(JOIN RTAL_GOOD_PLUGINS "," RTAL_GOOD_PLUGINS_JOINED)
list(JOIN RTAL_PRERELEASE_PLUGINS "," RTAL_PRERELEASE_PLUGINS_JOINED)

if(BUILD_BINARY_PACKAGE)
    add_custom_target(rtal-suite-package ALL
        COMMAND "${CMAKE_COMMAND}" -E env
            "BUILD_LV2=$<IF:$<BOOL:${BUILD_LV2}>,1,0>"
            "BUILD_STANDALONE=$<IF:$<BOOL:${BUILD_STANDALONE}>,1,0>"
            "BUILD_VST2=$<IF:$<BOOL:${BUILD_VST2}>,1,0>"
            "PORTABLE_X86_64=$<IF:$<BOOL:${PORTABLE_X86_64}>,1,0>"
            "RTAL_BUILD_MODE=${RTAL_BUILD_MODE}"
            "RTAL_CFLAGS=${RTAL_CFLAGS}"
            "VST2_SDK_DIR=${VST2_SDK_DIR}"
            "GOOD_PLUGINS=${RTAL_GOOD_PLUGINS_JOINED}"
            "PRERELEASE_PLUGINS=${RTAL_PRERELEASE_PLUGINS_JOINED}"
            "${BASH_EXECUTABLE}" "${CMAKE_SOURCE_DIR}/scripts/package-suite.sh"
        WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
        DEPENDS rtal-suite-all
        COMMENT "Packaging enabled RTAL suite binaries"
    )
endif()
