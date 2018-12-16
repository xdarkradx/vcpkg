include(vcpkg_common_functions)

if(VCPKG_CMAKE_SYSTEM_NAME STREQUAL WindowsStore)
    message(FATAL_ERROR "WindowsStore not supported")
endif()

set(VERSION 0.8.5)
vcpkg_download_distfile(ARCHIVE
    URLS "https://www.libssh.org/files/0.8/libssh-${VERSION}.tar.xz"
    FILENAME "libssh-${VERSION}.tar.xz"
    SHA512 f1e90a5046e006d44a48ab36675167761d8e308ada7a1d7a1f7ba2825d222a2fab7e19dbc78b1371fee9ba74d9c55d9856a623f97842c9b9ad4c79215e344124
)

vcpkg_extract_source_archive_ex(
    OUT_SOURCE_PATH SOURCE_PATH
    ARCHIVE ${ARCHIVE}
    REF ${VERSION})

string(COMPARE EQUAL "${VCPKG_LIBRARY_LINKAGE}" "static" WITH_STATIC_LIB)

vcpkg_configure_cmake(
    SOURCE_PATH ${SOURCE_PATH}
    PREFER_NINJA
    OPTIONS
        -DWITH_STATIC_LIB=${WITH_STATIC_LIB}
        -DWITH_EXAMPLES=OFF
        -DWITH_TESTING=OFF
        -DWITH_NACL=OFF
        -DWITH_GSSAPI=OFF
)

vcpkg_install_cmake()
vcpkg_copy_pdbs()

if(VCPKG_LIBRARY_LINKAGE STREQUAL "static")
    if(EXISTS ${CURRENT_PACKAGES_DIR}/lib/static/ssh.lib)
        file(RENAME ${CURRENT_PACKAGES_DIR}/lib/static/ssh.lib ${CURRENT_PACKAGES_DIR}/lib/ssh.lib)
    endif()
    if(EXISTS ${CURRENT_PACKAGES_DIR}/debug/lib/static/ssh.lib)
        file(RENAME ${CURRENT_PACKAGES_DIR}/debug/lib/static/ssh.lib ${CURRENT_PACKAGES_DIR}/debug/lib/ssh.lib)
    endif()
    file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/bin ${CURRENT_PACKAGES_DIR}/debug/bin)

    file(READ ${CURRENT_PACKAGES_DIR}/include/libssh/libssh.h _contents)
    string(REPLACE "#ifdef LIBSSH_STATIC" "#if 1" _contents "${_contents}")
    file(WRITE ${CURRENT_PACKAGES_DIR}/include/libssh/libssh.h "${_contents}")
endif()

file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/lib/static ${CURRENT_PACKAGES_DIR}/debug/lib/static)
file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/debug/include)

# The installed cmake config files are nonfunctional (0.7.5)
file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/debug/cmake ${CURRENT_PACKAGES_DIR}/cmake)
file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/debug/lib/cmake ${CURRENT_PACKAGES_DIR}/lib/cmake)

file(INSTALL ${SOURCE_PATH}/COPYING DESTINATION ${CURRENT_PACKAGES_DIR}/share/libssh RENAME copyright)
