# Set VCPKG_POLICY_DLLS_IN_STATIC_LIBRARY instead of using `vcpkg_check_linkage` because
# these DLLs don't link with a CRT.
set(VCPKG_POLICY_DLLS_IN_STATIC_LIBRARY enabled)

# https://github.com/gfx-rs/wgpu-native/releases/download/v{version}/wgpu-{ostarget}-{x86_64|i686|aarch64}-{debug|release}.zip

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

set(FILENAME "wgpu-${OS_TARGET}-${ARCHITECTURE_STRING}-release.zip")
string(TOLOWER ${FILENAME} FILENAME)

set(SHA512 "0")
if (FILENAME STREQUAL "wgpu-linux-aarch64-release.zip")
    set(SHA512 "0")
elseif(FILENAME STREQUAL "wgpu-linux-x86_64-release.zip")
    set(SHA512 "0")
elseif(FILENAME STREQUAL "wgpu-macos-aarch64-release.zip")
    set(SHA512 "0")
elseif(FILENAME STREQUAL "wgpu-macos-x86_64.zip")
    set(SHA512 "0")
elseif(FILENAME STREQUAL "wgpu-windows-i686-release.zip")
    set(SHA512 "0")
elseif(FILENAME STREQUAL "wgpu-windows-x86_64-release.zip")
    set(SHA512 "cebdcca7ad37cfaed74af1ac64ea49392d800fa25a41cff85376f4033acbbe289cba0e07ee8211af9147755aa5de5c789c04ceb10bea4bee4f51936f4e18969e")
endif()

vcpkg_download_distfile(ARCHIVE
    URLS "${DOWNLOAD_URL}/${FILENAME}"
    FILENAME "${FILENAME}"
    SHA512 "${SHA512}"
)

vcpkg_extract_source_archive(
    PACKAGE_PATH
    ARCHIVE ${ARCHIVE}
    NO_REMOVE_ONE_LEVEL
)

file(INSTALL "${PACKAGE_PATH}/webgpu.h" DESTINATION "${CURRENT_PACKAGES_DIR}/include")
file(INSTALL "${PACKAGE_PATH}/wgpu_native.dll.lib" DESTINATION "${CURRENT_PACKAGES_DIR}/lib")
file(INSTALL "${PACKAGE_PATH}/wgpu_native.lib" DESTINATION "${CURRENT_PACKAGES_DIR}/lib")
file(COPY "${PACKAGE_PATH}/wgpu_native.dll" DESTINATION "${CURRENT_PACKAGES_DIR}/bin")

file(MAKE_DIRECTORY "${CURRENT_PACKAGES_DIR}/debug")
file(COPY "${CURRENT_PACKAGES_DIR}/bin" "${CURRENT_PACKAGES_DIR}/lib" DESTINATION "${CURRENT_PACKAGES_DIR}/debug")
vcpkg_install_copyright(FILE_LIST "${CMAKE_CURRENT_LIST_DIR}/LICENSE")

file(INSTALL "${CMAKE_CURRENT_LIST_DIR}/usage" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}")
# vcpkg_install_copyright(FILE_LIST "${PACKAGE_PATH}/LICENSE.txt")

configure_file("${CMAKE_CURRENT_LIST_DIR}/wgpu-native-config.cmake.in" "${CURRENT_PACKAGES_DIR}/share/${PORT}/wgpu_native-config.cmake" COPYONLY)