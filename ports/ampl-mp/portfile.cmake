include(vcpkg_common_functions)

vcpkg_check_linkage(ONLY_STATIC_LIBRARY)

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO ampl/mp
    REF 0e030e07110939df8720f5c0aa1749b8c6d63b31
    SHA512 eca6aec83882144a28a6f29f81c11fb06ad4b3fa68ea6355d28155f1831a9041b279231bfa8c6e7438d2a40c0c2e12f8aba5ed9e6422336e1e9b82572cb2c8e5
    HEAD_REF master
    PATCHES
    fix-dl.patch
    workaround-msvc-optimizer-ice.patch
    install-targets.patch
)

vcpkg_configure_cmake(
    SOURCE_PATH ${SOURCE_PATH}
    OPTIONS
    -DBUILD=asl
    -DBUILD_TESTING=OFF
)

vcpkg_install_cmake()
vcpkg_fixup_cmake_targets(
    CONFIG_PATH share/unofficial-mp
    TARGET_PATH share/unofficial-mp
)

file(MAKE_DIRECTORY ${CURRENT_PACKAGES_DIR}/tools)
file(RENAME ${CURRENT_PACKAGES_DIR}/bin ${CURRENT_PACKAGES_DIR}/tools/${PORT})
file(REMOVE_RECURSE
    ${CURRENT_PACKAGES_DIR}/debug/bin
    ${CURRENT_PACKAGES_DIR}/debug/include
    ${CURRENT_PACKAGES_DIR}/debug/share)

configure_file(${SOURCE_PATH}/LICENSE.rst
    ${CURRENT_PACKAGES_DIR}/share/${PORT}/copyright COPYONLY)

vcpkg_copy_pdbs()
vcpkg_test_cmake(PACKAGE_NAME unofficial-mp)
