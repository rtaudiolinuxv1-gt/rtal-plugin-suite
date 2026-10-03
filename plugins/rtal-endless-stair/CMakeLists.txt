cmake_minimum_required(VERSION 3.16)
project(rtal_endless_stair VERSION 1.0.0 LANGUAGES NONE)

find_program(BASH_EXECUTABLE bash REQUIRED)

set(RTAL_EXPORTER "${CMAKE_CURRENT_SOURCE_DIR}/scripts/export.sh")
set(RTAL_INSTALLER "${CMAKE_CURRENT_SOURCE_DIR}/scripts/install.sh")
set(RTAL_PACKAGER "${CMAKE_CURRENT_SOURCE_DIR}/scripts/package.sh")

option(BUILD_LV2 "Build LV2 target" ON)
option(BUILD_STANDALONE "Build standalone target" ON)
option(BUILD_VST2 "Build VST2 target" ON)
option(PORTABLE_X86_64 "Build portable x86_64 binaries" ON)
set(RTAL_CFLAGS "$ENV{CFLAGS}" CACHE STRING "Extra compiler flags passed to Faust export tools")
set(VST2_SDK_DIR "$ENV{VST2_SDK_DIR}" CACHE PATH "Path to the VST2 SDK")

if(NOT VST2_SDK_DIR)
    set(VST2_SDK_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../vstsdk2.4" CACHE PATH "Path to the VST2 SDK" FORCE)
endif()

set(RTAL_EFFECTIVE_CFLAGS "${RTAL_CFLAGS}")
if(PORTABLE_X86_64 AND CMAKE_SYSTEM_PROCESSOR MATCHES "x86_64|X86_64|amd64|AMD64")
    string(APPEND RTAL_EFFECTIVE_CFLAGS " -march=x86-64 -mtune=generic -msse2 -mfpmath=sse")
endif()
string(STRIP "${RTAL_EFFECTIVE_CFLAGS}" RTAL_EFFECTIVE_CFLAGS)

set(RTAL_BUILD_LV2 0)
if(BUILD_LV2)
    set(RTAL_BUILD_LV2 1)
endif()

set(RTAL_BUILD_STANDALONE 0)
if(BUILD_STANDALONE)
    set(RTAL_BUILD_STANDALONE 1)
endif()

set(RTAL_BUILD_VST2 0)
if(BUILD_VST2)
    set(RTAL_BUILD_VST2 1)
endif()

set(RTAL_COMMON_ENV
    "CFLAGS=${RTAL_EFFECTIVE_CFLAGS}"
    "CXXFLAGS=${RTAL_EFFECTIVE_CFLAGS}"
    "BUILD_LV2=${RTAL_BUILD_LV2}"
    "BUILD_STANDALONE=${RTAL_BUILD_STANDALONE}"
    "BUILD_VST2=${RTAL_BUILD_VST2}"
    "PORTABLE_X86_64=$<IF:$<BOOL:${PORTABLE_X86_64}>,1,0>"
    "SDK=${VST2_SDK_DIR}"
)

add_custom_target(rtal-endless-stair-meta
    COMMAND "${CMAKE_COMMAND}" -E env ${RTAL_COMMON_ENV} "${BASH_EXECUTABLE}" "${RTAL_EXPORTER}" meta
    WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
    COMMENT "Generating rtal-endless-stair Faust metadata"
)

set(RTAL_ALL_DEPS rtal-endless-stair-meta)

if(BUILD_LV2)
    add_custom_target(rtal-endless-stair-lv2
        COMMAND "${CMAKE_COMMAND}" -E env ${RTAL_COMMON_ENV} "${BASH_EXECUTABLE}" "${RTAL_EXPORTER}" lv2
        WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
        COMMENT "Exporting rtal-endless-stair LV2"
    )
    list(APPEND RTAL_ALL_DEPS rtal-endless-stair-lv2)
endif()

if(BUILD_STANDALONE)
    add_custom_target(rtal-endless-stair-standalone
        COMMAND "${CMAKE_COMMAND}" -E env ${RTAL_COMMON_ENV} "${BASH_EXECUTABLE}" "${RTAL_EXPORTER}" standalone
        WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
        COMMENT "Exporting rtal-endless-stair JACK standalone"
    )
    list(APPEND RTAL_ALL_DEPS rtal-endless-stair-standalone)
endif()

if(BUILD_VST2)
    add_custom_target(rtal-endless-stair-vst2
        COMMAND "${CMAKE_COMMAND}" -E env ${RTAL_COMMON_ENV} "${BASH_EXECUTABLE}" "${RTAL_EXPORTER}" vst2
        WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
        COMMENT "Exporting rtal-endless-stair VST2"
    )
    list(APPEND RTAL_ALL_DEPS rtal-endless-stair-vst2)
endif()

add_custom_target(rtal-endless-stair-all ALL
    DEPENDS ${RTAL_ALL_DEPS}
    COMMENT "Exporting enabled rtal-endless-stair plugin targets"
)

add_custom_target(rtal-endless-stair-install-user
    COMMAND "${CMAKE_COMMAND}" -E env ${RTAL_COMMON_ENV} "${BASH_EXECUTABLE}" "${RTAL_INSTALLER}" user
    WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
    COMMENT "Installing enabled rtal-endless-stair targets to user plugin directories"
)

add_custom_target(rtal-endless-stair-package
    COMMAND "${CMAKE_COMMAND}" -E env ${RTAL_COMMON_ENV} "${BASH_EXECUTABLE}" "${RTAL_PACKAGER}"
    WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
    COMMENT "Packaging enabled rtal-endless-stair release artifacts"
)
