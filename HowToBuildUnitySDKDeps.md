# How to Build LiveKit Unity SDK Dependencies from Source

This guide explains how to build the dependencies for the LiveKit Unity SDK from source, with a particular focus on Android native libraries.

## Prerequisites

Before you begin, make sure you have the following installed:

- [Rust](https://www.rust-lang.org/tools/install) (latest stable version)
- [Cargo](https://doc.rust-lang.org/cargo/getting-started/installation.html) (comes with Rust)
- [Android NDK](https://developer.android.com/ndk/downloads) (version r21 or later recommended)
- [Android SDK](https://developer.android.com/studio) (API level 29 or later)
- [Git](https://git-scm.com/downloads)
- [Python 3](https://www.python.org/downloads/)

## Android Requirements Detail

The codebase is configured to use Android API level 29 by default. While the build system can work with various NDK versions, it has been tested and works well with NDK r21 through r25. If you encounter issues with newer NDK versions, consider using NDK r23.

The build system will attempt to automatically find the highest version of your installed NDK if you don't explicitly set `ANDROID_NDK_HOME`, but it's recommended to explicitly set this environment variable to avoid any potential issues.

## Setting Up the Environment

1. Clone the LiveKit Rust SDKs repository:

```bash
git clone https://github.com/livekit/client-sdk-rust.git
cd client-sdk-rust
```

2. Set up environment variables for Android builds:

```bash
export ANDROID_HOME=/path/to/your/android/sdk
export ANDROID_NDK_HOME=/path/to/your/android/ndk
export PATH=$PATH:$ANDROID_HOME/platform-tools
```

3. Install Rust targets for Android:

```bash
rustup target add armv7-linux-androideabi   # for 32-bit ARM
rustup target add aarch64-linux-android     # for 64-bit ARM
rustup target add x86_64-linux-android      # for 64-bit x86
```

4. Install cargo-ndk:

```bash
cargo install cargo-ndk
```

## Building WebRTC for Android

The first step is to build the WebRTC library, which is a key dependency:

1. Navigate to the webrtc-sys directory:

```bash
cd webrtc-sys/libwebrtc
```

2. Build WebRTC for each target architecture:

```bash
# For 32-bit ARM (armv7)
./build_android.sh --arch arm --profile release

# For 64-bit ARM (arm64)
./build_android.sh --arch arm64 --profile release

# For 64-bit x86 (x64)
./build_android.sh --arch x64 --profile release
```

Each build will take significant time and requires substantial disk space.

## Building the LiveKit FFI Library for Android

After building WebRTC, build the LiveKit FFI (Foreign Function Interface) library:

1. Return to the repository root:

```bash
cd ../../
```

2. Build the FFI library for all Android architectures:

```bash
cargo ndk -t armeabi-v7a -t arm64-v8a -t x86_64 -o ./android-libs build --release -p livekit-ffi
```

This will generate shared libraries (.so files) for each architecture in the `android-libs` directory.

## Packaging for Unity

After building the libraries, you need to organize them for Unity:

1. Create the directory structure for Unity:

```bash
mkdir -p unity-output/Runtime/Plugins/ffi-android-armv7
mkdir -p unity-output/Runtime/Plugins/ffi-android-arm64
mkdir -p unity-output/Runtime/Plugins/ffi-android-x86_64
```

2. Copy the built libraries to the Unity directory structure:

```bash
# Copy ARM 32-bit libraries
cp android-libs/armeabi-v7a/liblivekit_ffi.so unity-output/Runtime/Plugins/ffi-android-armv7/
cp webrtc-sys/libwebrtc/android-arm-release/libwebrtc.jar unity-output/Runtime/Plugins/ffi-android-armv7/

# Copy ARM 64-bit libraries
cp android-libs/arm64-v8a/liblivekit_ffi.so unity-output/Runtime/Plugins/ffi-android-arm64/
cp webrtc-sys/libwebrtc/android-arm64-release/libwebrtc.jar unity-output/Runtime/Plugins/ffi-android-arm64/

# Copy x86_64 libraries
cp android-libs/x86_64/liblivekit_ffi.so unity-output/Runtime/Plugins/ffi-android-x86_64/
cp webrtc-sys/libwebrtc/android-x64-release/libwebrtc.jar unity-output/Runtime/Plugins/ffi-android-x86_64/
```

## Integrating with Unity

1. Copy the `unity-output/Runtime/Plugins` directory to your Unity project's Assets folder.

2. In Unity, ensure that each .so file has the correct platform settings:
   - Select each .so file in the Project view
   - In the Inspector, ensure "Android" is selected as the platform
   - Set the correct CPU architecture (ARMv7, ARM64, or x86_64)
   - Set "Android Shared Library Type" to "Executable"

## Notes on Building for Other Platforms

### iOS

For iOS, you'll need to build on a macOS system:

```bash
cd webrtc-sys/libwebrtc
./build_ios.sh --arch arm64 --profile release
cd ../../
cargo build --release -p livekit-ffi --target aarch64-apple-ios
```

### Windows, macOS, and Linux

For desktop platforms, the build process is more straightforward:

```bash
# Build for the current platform
cargo build --release -p livekit-ffi
```

## Troubleshooting

- If you encounter "command not found" errors, ensure that all required tools are in your PATH
- If you see linker errors, check that NDK is properly set up and the correct targets are installed
- For WebRTC build issues, check the WebRTC build logs in the output directories
- If experiencing issues with newer NDK versions (r25+), try using NDK r23 which is known to be compatible

## References

- [LiveKit Rust SDKs Repository](https://github.com/livekit/client-sdk-rust)
- [LiveKit Unity SDK Repository](https://github.com/livekit/client-sdk-unity)
- [Android NDK Documentation](https://developer.android.com/ndk/guides)
- [Rust Cross-Compilation Guide](https://rust-lang.github.io/rustup/cross-compilation.html) 