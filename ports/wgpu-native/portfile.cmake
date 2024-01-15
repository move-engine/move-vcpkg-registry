# Set VCPKG_POLICY_DLLS_IN_STATIC_LIBRARY instead of using `vcpkg_check_linkage` because
# these DLLs don't link with a CRT.
set(VCPKG_POLICY_DLLS_IN_STATIC_LIBRARY enabled)

if (NOT VCPKG_LIBRARY_LINKAGE STREQUAL "dynamic")
   message(STATUS "Note: ${PORT} always requires dynamic library linkage at runtime.")
endif()

# First part of the above URL with the correct variables
set(DOWNLOAD_URL "https://github.com/gfx-rs/wgpu-native/releases/download/v${VERSION}")
set(ARCHITECTURE_STRING "${VCPKG_TARGET_ARCHITECTURE}")
set(OS_TARGET)

if (WIN32)
    set(OS_TARGET "windows")
elseif (APPLE)
    set(OS_TARGET "macos")
elseif (UNIX)
    set(OS_TARGET "linux")
endif()

if (ARCHITECTURE_STRING STREQUAL "x86")
    set(ARCHITECTURE_STRING "i686")
elseif(ARCHITECTURE_STRING STREQUAL "x64")
    set(ARCHITECTURE_STRING "x86_64")
elseif(ARCHITECTURE_STRING STREQUAL "arm64")
    set(ARCHITECTURE_STRING "aarch64")
elseif(ARCHITECTURE_STRING STREQUAL "arm")
    set(ARCHITECTURE_STRING "aarch32")
endif()

set(DOWNLOAD_FILENAME "wgpu-${OS_TARGET}-${ARCHITECTURE_STRING}-release.zip")
set(DEBUG_DOWNLOAD_FILENAME "wgpu-${OS_TARGET}-${ARCHITECTURE_STRING}-debug.zip")
string(TOLOWER ${DOWNLOAD_FILENAME} DOWNLOAD_FILENAME)

set(DEBUG_SHA512 "0")
set(RELEASE_SHA512 "0")
if (DOWNLOAD_FILENAME STREQUAL "wgpu-linux-aarch64-release.zip")
    set(RELEASE_SHA512 "0")
    set(DEBUG_SHA512 "0")
elseif(DOWNLOAD_FILENAME STREQUAL "wgpu-linux-x86_64-release.zip")
    set(RELEASE_SHA512 "0")
    set(DEBUG_SHA512 "0")
elseif(DOWNLOAD_FILENAME STREQUAL "wgpu-macos-aarch64-release.zip")
    set(RELEASE_SHA512 "0")
    set(DEBUG_SHA512 "0")
elseif(DOWNLOAD_FILENAME STREQUAL "wgpu-macos-x86_64.zip")
    set(RELEASE_SHA512 "0")
    set(DEBUG_SHA512 "0")
elseif(DOWNLOAD_FILENAME STREQUAL "wgpu-windows-i686-release.zip")
    set(RELEASE_SHA512 "0")
    set(DEBUG_SHA512 "0")
elseif(DOWNLOAD_FILENAME STREQUAL "wgpu-windows-x86_64-release.zip")
    set(RELEASE_SHA512 "cebdcca7ad37cfaed74af1ac64ea49392d800fa25a41cff85376f4033acbbe289cba0e07ee8211af9147755aa5de5c789c04ceb10bea4bee4f51936f4e18969e")
    set(DEBUG_SHA512 "c264d26d951e4dcdab3cb19ef89bfbd9f58ef7744f000acc235abd99aaaecf81c91133a1360148b9d9d2c67772a0beb98567c04dfe876e587fbc709528906d02")
endif()

vcpkg_download_distfile(ARCHIVE
    URLS "${DOWNLOAD_URL}/${DOWNLOAD_FILENAME}"
    FILENAME "${DOWNLOAD_FILENAME}"
    SHA512 "${RELEASE_SHA512}"
)

vcpkg_download_distfile(DEBUG_ARCHIVE
    URLS "${DOWNLOAD_URL}/${DEBUG_DOWNLOAD_FILENAME}"
    FILENAME "${DEBUG_DOWNLOAD_FILENAME}"
    SHA512 "${DEBUG_SHA512}"
)

vcpkg_extract_source_archive(
    PACKAGE_PATH
    ARCHIVE ${ARCHIVE}
    NO_REMOVE_ONE_LEVEL
)

vcpkg_extract_source_archive(
    DEBUG_PACKAGE_PATH
    ARCHIVE ${ARCHIVE}
    NO_REMOVE_ONE_LEVEL
)

if (VCPKG_TARGET_IS_LINUX)
    message(FATAL_ERROR "Linux is not supported yet")
else()
    file(INSTALL
        "${PACKAGE_PATH}/webgpu.h"
        "${PACKAGE_PATH}/wgpu.h"
        DESTINATION "${CURRENT_PACKAGES_DIR}/include"
    )
    file(INSTALL
        "${PACKAGE_PATH}/webgpu.h"
        "${PACKAGE_PATH}/wgpu.h"
        DESTINATION "${CURRENT_PACKAGES_DIR}/include/webgpu"
    )
    file(INSTALL
        "${PACKAGE_PATH}/wgpu_native.dll.lib"
        "${PACKAGE_PATH}/wgpu_native.lib"
        DESTINATION "${CURRENT_PACKAGES_DIR}/lib"
    )
    file(COPY "${PACKAGE_PATH}/wgpu_native.dll" DESTINATION "${CURRENT_PACKAGES_DIR}/bin")

    file(INSTALL
        "${DEBUG_PACKAGE_PATH}/wgpu_native.dll.lib"
        "${DEBUG_PACKAGE_PATH}/wgpu_native.lib"
        DESTINATION "${CURRENT_PACKAGES_DIR}/debug/lib"
    )
    file(COPY "${DEBUG_PACKAGE_PATH}/wgpu_native.dll" DESTINATION "${CURRENT_PACKAGES_DIR}/debug/bin")
endif()

vcpkg_install_copyright(FILE_LIST "${CMAKE_CURRENT_LIST_DIR}/LICENSE")

file(INSTALL "${CMAKE_CURRENT_LIST_DIR}/usage" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}")
# vcpkg_install_copyright(FILE_LIST "${PACKAGE_PATH}/LICENSE.txt")

configure_file("${CMAKE_CURRENT_LIST_DIR}/wgpu-native-config.cmake.in" "${CURRENT_PACKAGES_DIR}/share/${PORT}/${PORT}-config.cmake" COPYONLY)