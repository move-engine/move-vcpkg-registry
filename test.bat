@echo off

vcpkg install wgpu-native --overlay-ports .\ports\ && vcpkg remove wgpu-native

