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
    set(RELEASE_SHA512 "cafa6a2bd3ef2365b8c44607863ce5cb401a5dc507228b3c11002e0515e5fce14ed1d3e82c67f1d53e872de92f120d8eeda1c1a6d2533b31583601185524dd3c")
    set(DEBUG_SHA512 "204b4cddcf7f79034676dc5446caab3c839e5ce7f6d8a6f2b9a87e8e5d349fabb0fee73d5457d90b0593438818210477e41bba42ebea888b64b10644812260bc")
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