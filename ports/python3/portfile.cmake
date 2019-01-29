if (VCPKG_LIBRARY_LINKAGE STREQUAL dynamic AND VCPKG_CRT_LINKAGE STREQUAL static)
    message(STATUS "Warning: Dynamic library with static CRT is not supported. Building static library.")
    set(VCPKG_LIBRARY_LINKAGE static)
endif()

set(PYTHON_VERSION_MAJOR  3)
set(PYTHON_VERSION_MINOR  7)
set(PYTHON_VERSION_PATCH  2)
set(PYTHON_VERSION        ${PYTHON_VERSION_MAJOR}.${PYTHON_VERSION_MINOR}.${PYTHON_VERSION_PATCH})

include(vcpkg_common_functions)

set(PATCHES)
if (VCPKG_LIBRARY_LINKAGE STREQUAL static)
    set(PATCHES 0001-Static-library.patch)
endif()
if (VCPKG_CRT_LINKAGE STREQUAL static)
    set(PATCHES 0002-Static-CRT.patch)
endif()

vcpkg_from_github(
    OUT_SOURCE_PATH TEMP_SOURCE_PATH
    REPO python/cpython
    REF v${PYTHON_VERSION}
    SHA512 5a07f61248b757bba0688d9022f199d964af1372d02ffd05bb04d86339b4cb8b12d26246627f6e277e0b7ab385cdfdf337596a84a9ab0476e8cd0c3864943a8b
    HEAD_REF master
    PATCHES ${PATCHES}
)

# We need per-triplet directories because we need to patch the project files differently based on the linkage
# Because the patches patch the same file, they have to be applied in the correct order
set(SOURCE_PATH "${TEMP_SOURCE_PATH}-Lib-${VCPKG_LIBRARY_LINKAGE}-crt-${VCPKG_CRT_LINKAGE}")
file(REMOVE_RECURSE ${SOURCE_PATH})
file(RENAME "${TEMP_SOURCE_PATH}" ${SOURCE_PATH})

if (VCPKG_TARGET_ARCHITECTURE MATCHES "x86")
    set(BUILD_ARCH "Win32")
    set(OUT_DIR "win32")
elseif (VCPKG_TARGET_ARCHITECTURE MATCHES "x64")
    set(BUILD_ARCH "x64")
    set(OUT_DIR "amd64")
else()
    message(FATAL_ERROR "Unsupported architecture: ${VCPKG_TARGET_ARCHITECTURE}")
endif()

vcpkg_build_msbuild(
    PROJECT_PATH ${SOURCE_PATH}/PCBuild/pythoncore.vcxproj
    PLATFORM ${BUILD_ARCH})

if (VCPKG_LIBRARY_LINKAGE STREQUAL static)
    vcpkg_apply_patches(
        SOURCE_PATH ${SOURCE_PATH}
        PATCHES
            ${CMAKE_CURRENT_LIST_DIR}/0003-Fix-header-for-static-linkage.patch
    )
endif()

file(GLOB HEADERS ${SOURCE_PATH}/Include/*.h)
file(COPY ${HEADERS} ${SOURCE_PATH}/PC/pyconfig.h DESTINATION ${CURRENT_PACKAGES_DIR}/include/python${PYTHON_VERSION_MAJOR}.${PYTHON_VERSION_MINOR})

file(COPY ${SOURCE_PATH}/Lib DESTINATION ${CURRENT_PACKAGES_DIR}/share/python${PYTHON_VERSION_MAJOR})

file(COPY ${SOURCE_PATH}/PCBuild/${OUT_DIR}/python${PYTHON_VERSION_MAJOR}${PYTHON_VERSION_MINOR}.lib DESTINATION ${CURRENT_PACKAGES_DIR}/lib)
file(COPY ${SOURCE_PATH}/PCBuild/${OUT_DIR}/python${PYTHON_VERSION_MAJOR}${PYTHON_VERSION_MINOR}_d.lib DESTINATION ${CURRENT_PACKAGES_DIR}/debug/lib)
if (VCPKG_LIBRARY_LINKAGE STREQUAL dynamic)
    file(COPY ${SOURCE_PATH}/PCBuild/${OUT_DIR}/python${PYTHON_VERSION_MAJOR}${PYTHON_VERSION_MINOR}.dll DESTINATION ${CURRENT_PACKAGES_DIR}/bin)
    file(COPY ${SOURCE_PATH}/PCBuild/${OUT_DIR}/python${PYTHON_VERSION_MAJOR}${PYTHON_VERSION_MINOR}_d.dll DESTINATION ${CURRENT_PACKAGES_DIR}/debug/bin)
endif()

# Handle copyright
file(COPY ${SOURCE_PATH}/LICENSE DESTINATION ${CURRENT_PACKAGES_DIR}/share/python${PYTHON_VERSION_MAJOR})
file(RENAME ${CURRENT_PACKAGES_DIR}/share/python${PYTHON_VERSION_MAJOR}/LICENSE ${CURRENT_PACKAGES_DIR}/share/python${PYTHON_VERSION_MAJOR}/copyright)

vcpkg_copy_pdbs()
