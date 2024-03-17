function Get-UrlSha512 {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Url
    )

    # Define a temporary file path
    $tempFilePath = [System.IO.Path]::GetTempFileName()

    try {
        # Download the file
        Invoke-WebRequest -Uri $Url -OutFile $tempFilePath

        # Calculate and output the SHA512 hash
        $hash = Get-FileHash -Path $tempFilePath -Algorithm SHA512
        Write-Output $hash.Hash
    }
    catch {
        Write-Error "An error occurred: $_"
    }
    finally {
        # Clean up: Delete the downloaded file
        Remove-Item -Path $tempFilePath -ErrorAction SilentlyContinue
    }
}

function Get-VersionFromJson {
    param (
        [Parameter(Mandatory = $true)]
        [string]$FileName
    )

    try {
        # Read the content of the JSON file
        $jsonContent = Get-Content -Path $FileName -Raw | ConvertFrom-Json

        # Output the version number
        Write-Output $jsonContent.version
    }
    catch {
        Write-Error "An error occurred: $_"
    }
}

function Update-VersionCmake {
    param (
        [string]$JsonFilePath = "ports/wgpu-native/vcpkg.json",
        [string]$CMakeFilePath = "ports/wgpu-native/version.cmake"
    )

    # Get version from JSON
    $version = Get-VersionFromJson -FileName $JsonFilePath
    $baseUri = "https://github.com/gfx-rs/wgpu-native/releases/download/v$version/wgpu-"

    # Define all OS-architecture combinations
    $combinations = @(
        @{ "OS" = "linux"; "Arch" = "aarch64" },
        @{ "OS" = "linux"; "Arch" = "x86_64" },
        @{ "OS" = "macos"; "Arch" = "aarch64" },
        @{ "OS" = "macos"; "Arch" = "x86_64" },
        @{ "OS" = "windows"; "Arch" = "i686" },
        @{ "OS" = "windows"; "Arch" = "x86_64" }
    )

    # Initialize CMake content
    $cmakeContent = @"

set(DOWNLOAD_FILENAME "wgpu-${OS_TARGET}-${ARCHITECTURE_STRING}-release.zip")
set(DEBUG_DOWNLOAD_FILENAME "wgpu-${OS_TARGET}-${ARCHITECTURE_STRING}-debug.zip")
string(TOLOWER ${DOWNLOAD_FILENAME} DOWNLOAD_FILENAME)

set(DEBUG_SHA512 "0")
set(RELEASE_SHA512 "0")
"@

    $functions = {
        function Get-UrlSha512 {
            param (
                [Parameter(Mandatory = $true)]
                [string]$Url
            )

            # Define a temporary file path
            $tempFilePath = [System.IO.Path]::GetTempFileName()

            try {
                # Download the file
                Invoke-WebRequest -Uri $Url -OutFile $tempFilePath

                # Calculate and output the SHA512 hash
                $hash = Get-FileHash -Path $tempFilePath -Algorithm SHA512
                Write-Output $hash.Hash
            }
            catch {
                Write-Error "An error occurred: $_"
            }
            finally {
                # Clean up: Delete the downloaded file
                Remove-Item -Path $tempFilePath -ErrorAction SilentlyContinue
            }
        }
    }

    # Generate SHA512 hashes in parallel
    $hashTasks = @()
    foreach ($combination in $combinations) {
        $os = $combination.OS
        $arch = $combination.Arch
        $releaseUrl = $baseUri + "$os-$arch-release.zip"
        $debugUrl = $baseUri + "$os-$arch-debug.zip"

        $releaseTask = Start-Job -InitializationScript $functions -ScriptBlock {
            param($Url)
            Get-UrlSha512 -Url $Url
        } -ArgumentList $releaseUrl

        $debugTask = Start-Job -InitializationScript $functions -ScriptBlock {
            param($Url)
            Get-UrlSha512 -Url $Url
        } -ArgumentList $debugUrl
    
        $hashTasks += @($releaseTask, $debugTask)

        # Get-UrlSha512 -Url $releaseUrl
        # Get-UrlSha512 -Url $debugUrl
    }

    # Wait for all tasks to complete and collect results
    $hashResults = $hashTasks | Wait-Job | Receive-Job

    # Clean up the jobs
    $hashTasks | Remove-Job

    # Build the conditional statements for the CMake file
    for ($i = 0; $i -lt $hashResults.Count; $i += 2) {
        $index = $i / 2
        $os = $combinations[$index].OS
        $arch = $combinations[$index].Arch
        $releaseHash = $hashResults[$i]
        $debugHash = $hashResults[$i + 1]

        $cmakeContent += @"
elseif(DOWNLOAD_FILENAME STREQUAL "wgpu-$os-$arch-release.zip")
    set(RELEASE_SHA512 "$releaseHash")
    set(DEBUG_SHA512 "$debugHash")
"@
    }

    $cmakeContent += @"
endif()
"@

    # Write the content to the CMake file
    $cmakeContent | Out-File -FilePath $CMakeFilePath
}

Update-VersionCmake