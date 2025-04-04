#!/bin/bash -eu

# Setup logging
LOG_FILE="rename_namespace.log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "Starting namespace relocation process at $(date '+%Y-%m-%d %H:%M:%S')"

# Define directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ORIGINAL_SRC_DIR=$(pwd)/src
SHADED_SRC_DIR=$(pwd)/src-shaded
PATCHES_DIR="$SCRIPT_DIR/patches"

# Check if original source directory exists
if [ ! -d "$ORIGINAL_SRC_DIR" ]; then
    echo "Error: Source directory '$ORIGINAL_SRC_DIR' not found"
    exit 1
fi

# Check if shaded directory already exists
if [ -d "$SHADED_SRC_DIR" ]; then
    echo "Error: Shaded directory '$SHADED_SRC_DIR' already exists. Please remove it first."
    exit 1
fi

# Check if patches directory exists
if [ ! -d "$PATCHES_DIR" ]; then
    echo "Error: Patches directory '$PATCHES_DIR' not found"
    exit 1
fi

echo "Step 0: Creating copy of source directory..."
echo "Copying $ORIGINAL_SRC_DIR to $SHADED_SRC_DIR..."
cp -r "$ORIGINAL_SRC_DIR" "$SHADED_SRC_DIR"

if [ ! -d "$SHADED_SRC_DIR" ]; then
    echo "Error: Failed to create shaded directory"
    exit 1
fi

echo "Successfully created shaded directory. Proceeding with namespace relocation..."

# Define working directories based on shaded copy
SRC_DIR="$SHADED_SRC_DIR"
SDK_DIR="$SHADED_SRC_DIR/sdk/android"
RTC_BASE_DIR="$SHADED_SRC_DIR/rtc_base"
MODULES_DIR="$SHADED_SRC_DIR/modules"
TEST_DIR="$SHADED_SRC_DIR/test"
JNI_DIR="$SHADED_SRC_DIR/sdk/android/src/jni"
EXAMPLES_DIR="$SHADED_SRC_DIR/examples"

# Process SDK directory
cd "$SDK_DIR"
echo "Processing SDK directory..."
sed -i 's/api\/org\/webrtc/api\/xyz\/webrtc/g' BUILD.gn
sed -i 's/java\/org\/webrtc/java\/xyz\/webrtc/g' BUILD.gn
sed -i 's/native_unittests\/org\/webrtc/native_unittests\/xyz\/webrtc/g' BUILD.gn
sed -i 's/tests\/src\/org\/webrtc/tests\/src\/xyz\/webrtc/g' BUILD.gn
sed -i 's/instrumentationtests\/src\/org\/webrtc/instrumentationtests\/src\/xyz\/webrtc/g' BUILD.gn

# Create directories if they don't exist
mkdir -p "$SDK_DIR/api/xyz"
mkdir -p "$SDK_DIR/src/java/xyz"
mkdir -p "$SDK_DIR/native_unittests/xyz"
mkdir -p "$SDK_DIR/tests/src/xyz"
mkdir -p "$SDK_DIR/instrumentationtests/src/xyz"

# Move directories
if [ -d "$SDK_DIR/api/org/webrtc" ]; then
    mv "$SDK_DIR/api/org/webrtc" "$SDK_DIR/api/xyz/webrtc"
fi

if [ -d "$SDK_DIR/src/java/org/webrtc" ]; then
    mv "$SDK_DIR/src/java/org/webrtc" "$SDK_DIR/src/java/xyz/webrtc"
fi

if [ -d "$SDK_DIR/native_unittests/org/webrtc" ]; then
    mv "$SDK_DIR/native_unittests/org/webrtc" "$SDK_DIR/native_unittests/xyz/webrtc"
fi

if [ -d "$SDK_DIR/tests/src/org/webrtc" ]; then
    mv "$SDK_DIR/tests/src/org/webrtc" "$SDK_DIR/tests/src/xyz/webrtc"
fi

if [ -d "$SDK_DIR/instrumentationtests/src/org/webrtc" ]; then
    mv "$SDK_DIR/instrumentationtests/src/org/webrtc" "$SDK_DIR/instrumentationtests/src/xyz/webrtc"
fi

# Process RTC Base directory
cd "$RTC_BASE_DIR"
echo "Processing RTC Base directory..."
mkdir -p "$RTC_BASE_DIR/java/src/xyz"
if [ -d "$RTC_BASE_DIR/java/src/org/webrtc" ]; then
    mv "$RTC_BASE_DIR/java/src/org/webrtc" "$RTC_BASE_DIR/java/src/xyz/webrtc"
fi
sed -i 's/java\/src\/org\/webrtc/java\/src\/xyz\/webrtc/g' BUILD.gn

# Process Test directory
cd "$TEST_DIR"
echo "Processing Test directory..."
sed -i 's/android\/org\/webrtc/android\/xyz\/webrtc/g' BUILD.gn
mkdir -p "$TEST_DIR/android/xyz"
if [ -d "$TEST_DIR/android/org/webrtc" ]; then
    mv "$TEST_DIR/android/org/webrtc" "$TEST_DIR/android/xyz/webrtc"
fi

# Process Modules directory (specific identified issues)
echo "Processing Modules directory..."
cd "$MODULES_DIR"

# Fix modules/video_coding/codecs/test/android_codec_factory_helper.cc
if [ -f "video_coding/codecs/test/android_codec_factory_helper.cc" ]; then
    sed -i 's/org\.webrtc/xyz\.webrtc/g' video_coding/codecs/test/android_codec_factory_helper.cc
    sed -i 's/org_webrtc/xyz_webrtc/g' video_coding/codecs/test/android_codec_factory_helper.cc
fi

# Fix modules/utility/source/jvm_android.cc and include/jvm_android.h
if [ -f "utility/source/jvm_android.cc" ]; then
    sed -i 's/org\.webrtc/xyz\.webrtc/g' utility/source/jvm_android.cc
    sed -i 's/org_webrtc/xyz_webrtc/g' utility/source/jvm_android.cc
    sed -i 's/Lorg\/webrtc\//Lxyz\/webrtc\//g' utility/source/jvm_android.cc
fi

if [ -f "utility/include/jvm_android.h" ]; then
    sed -i 's/org\.webrtc/xyz\.webrtc/g' utility/include/jvm_android.h
    sed -i 's/org_webrtc/xyz_webrtc/g' utility/include/jvm_android.h
    sed -i 's/Lorg\/webrtc\//Lxyz\/webrtc\//g' utility/include/jvm_android.h
fi

# Process Examples directory
echo "Processing Examples directory..."
cd "$EXAMPLES_DIR"

# Fix BUILD.gn files in examples
find . -name "BUILD.gn" -exec sed -i 's/org\.webrtc/xyz\.webrtc/g' {} \;
find . -name "BUILD.gn" -exec sed -i 's/org\/webrtc/xyz\/webrtc/g' {} \;

# Process Java files in specific directories that might have been missed
echo "Processing Java files in examples..."
find . -type f -name "*.java" -exec sed -i 's/org\.webrtc/xyz\.webrtc/g' {} \;
find . -type f -name "*.java" -exec sed -i 's/package org\.webrtc/package xyz\.webrtc/g' {} \;
find . -type f -name "*.java" -exec sed -i 's/import org\.webrtc/import xyz\.webrtc/g' {} \;

# Process all Java files
echo "Processing all Java files..."
cd "$SRC_DIR"
find . -type f -name "*.java" -exec sed -i 's/org\.webrtc/xyz\.webrtc/g' {} \;
find . -type f -name "*.java" -exec sed -i 's/package org\.webrtc/package xyz\.webrtc/g' {} \;
find . -type f -name "*.java" -exec sed -i 's/import org\.webrtc/import xyz\.webrtc/g' {} \;

# Process C++ files
echo "Processing C++ files..."
cd "$SRC_DIR"
find . -type f -name "*.cc" -exec sed -i 's/org\.webrtc/xyz\.webrtc/g' {} \;
find . -type f -name "*.h" -exec sed -i 's/org\.webrtc/xyz\.webrtc/g' {} \;
find . -type f -name "*.cpp" -exec sed -i 's/org\.webrtc/xyz\.webrtc/g' {} \;
find . -type f -name "*.cc" -exec sed -i 's/org_webrtc/xyz_webrtc/g' {} \;
find . -type f -name "*.h" -exec sed -i 's/org_webrtc/xyz_webrtc/g' {} \;
find . -type f -name "*.cpp" -exec sed -i 's/org_webrtc/xyz_webrtc/g' {} \;

# Handle JNI method signatures explicitly
find . -type f -name "*.h" -exec sed -i 's/Lorg\/webrtc\//Lxyz\/webrtc\//g' {} \;
find . -type f -name "*.cc" -exec sed -i 's/Lorg\/webrtc\//Lxyz\/webrtc\//g' {} \;
find . -type f -name "*.cpp" -exec sed -i 's/Lorg\/webrtc\//Lxyz\/webrtc\//g' {} \;

# Additional specific files that were found with remaining references
echo "Processing network.h in rtc_base..."
if [ -f "$RTC_BASE_DIR/network.h" ]; then
    sed -i 's/org\.webrtc/xyz\.webrtc/g' "$RTC_BASE_DIR/network.h"
    sed -i 's/org_webrtc/xyz_webrtc/g' "$RTC_BASE_DIR/network.h"
fi

# Additional JNI signature formats that might have been missed
echo "Handling additional JNI signature formats..."
find "$SRC_DIR" -type f \( -name "*.cc" -o -name "*.h" -o -name "*.cpp" \) -exec sed -i 's/"org\/webrtc/"xyz\/webrtc/g' {} \;
find "$SRC_DIR" -type f \( -name "*.cc" -o -name "*.h" -o -name "*.cpp" \) -exec sed -i 's/"org\/webrtc\/"/"xyz\/webrtc\//g' {} \;
find "$SRC_DIR" -type f \( -name "*.cc" -o -name "*.h" -o -name "*.cpp" \) -exec sed -i 's/Lorg\/webrtc\;/Lxyz\/webrtc\;/g' {} \;

# Specific FileVideoCapturerTest.java fix
if [ -f "$SDK_DIR/instrumentationtests/src/xyz/webrtc/FileVideoCapturerTest.java" ]; then
    echo "Fixing FileVideoCapturerTest.java..."
    sed -i 's/org\.webrtc/xyz\.webrtc/g' "$SDK_DIR/instrumentationtests/src/xyz/webrtc/FileVideoCapturerTest.java"
fi

# Find any remaining references and report them
echo "Checking for any remaining references..."
REMAINING=$(find "$SRC_DIR" -type f \( -name "*.java" -o -name "*.cc" -o -name "*.h" -o -name "*.cpp" -o -name "BUILD.gn" \) -exec grep -l "org\.webrtc\|org/webrtc\|org_webrtc" {} \; | wc -l)

if [ "$REMAINING" -gt 0 ]; then
    echo "Warning: $REMAINING files still contain references to org.webrtc. A manual review may be necessary."
    # List the first 10 files that still have references
    echo "Sample of files with remaining references:"
    find "$SRC_DIR" -type f \( -name "*.java" -o -name "*.cc" -o -name "*.h" -o -name "*.cpp" -o -name "BUILD.gn" \) -exec grep -l "org\.webrtc\|org/webrtc\|org_webrtc" {} \; | head -10
fi

echo "Namespace relocation completed at $(date '+%Y-%m-%d %H:%M:%S')"
echo
echo "SUCCESS: All changes have been made to $SHADED_SRC_DIR"
echo "The original source code remains unchanged in $ORIGINAL_SRC_DIR"
echo
echo "To verify the changes, examine the contents of $SHADED_SRC_DIR"
echo "If satisfied with the changes, you can:"
echo "1. Backup the original: mv $ORIGINAL_SRC_DIR ${ORIGINAL_SRC_DIR}.backup"
echo "2. Move the shaded version: mv $SHADED_SRC_DIR $ORIGINAL_SRC_DIR"
