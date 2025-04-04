#!/bin/bash
# Script to check if all prerequisites for building LiveKit Unity SDK dependencies are met

# Set text colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo "Checking prerequisites for building LiveKit Unity SDK dependencies..."
echo

# Function to check if a command exists
check_command() {
    local cmd=$1
    local name=$2
    local url=$3
    
    echo -n "Checking for $name... "
    if command -v $cmd &>/dev/null; then
        echo -e "${GREEN}Found $(eval $cmd --version | head -n 1)${NC}"
        return 0
    else
        echo -e "${RED}Not found${NC}"
        echo -e "${YELLOW}Please install $name: $url${NC}"
        return 1
    fi
}

# Function to check Rust targets
check_rust_target() {
    local target=$1
    
    echo -n "Checking for Rust target $target... "
    if rustup target list --installed | grep -q "$target"; then
        echo -e "${GREEN}Installed${NC}"
        return 0
    else
        echo -e "${RED}Not installed${NC}"
        echo -e "${YELLOW}Please install with: rustup target add $target${NC}"
        return 1
    fi
}

# Check basic commands
MISSING_PREREQS=0

check_command git "Git" "https://git-scm.com/downloads" || ((MISSING_PREREQS++))
check_command python3 "Python 3" "https://www.python.org/downloads/" || ((MISSING_PREREQS++))
check_command rustc "Rust" "https://www.rust-lang.org/tools/install" || ((MISSING_PREREQS++))
check_command cargo "Cargo" "https://doc.rust-lang.org/cargo/getting-started/installation.html" || ((MISSING_PREREQS++))
check_command cargo-ndk "cargo-ndk" "Install with: cargo install cargo-ndk" || ((MISSING_PREREQS++))

# Check Rust targets if Rust is installed
if command -v rustc &>/dev/null; then
    echo
    echo "Checking Rust targets for Android..."
    check_rust_target "armv7-linux-androideabi" || ((MISSING_PREREQS++))
    check_rust_target "aarch64-linux-android" || ((MISSING_PREREQS++))
    check_rust_target "x86_64-linux-android" || ((MISSING_PREREQS++))
fi

# Check Android SDK and NDK
echo
echo "Checking Android SDK and NDK..."

if [ -z "$ANDROID_HOME" ]; then
    echo -e "${RED}ANDROID_HOME environment variable is not set${NC}"
    echo -e "${YELLOW}Please set ANDROID_HOME to your Android SDK location${NC}"
    ((MISSING_PREREQS++))
else
    echo -e "ANDROID_HOME is set to: ${GREEN}$ANDROID_HOME${NC}"
    
    # Check if the directory exists
    if [ ! -d "$ANDROID_HOME" ]; then
        echo -e "${RED}Android SDK directory does not exist at $ANDROID_HOME${NC}"
        ((MISSING_PREREQS++))
    fi
    
    # Check for platform-tools
    if [ ! -d "$ANDROID_HOME/platform-tools" ]; then
        echo -e "${RED}platform-tools not found in Android SDK${NC}"
        echo -e "${YELLOW}Please install Android SDK platform-tools${NC}"
        ((MISSING_PREREQS++))
    else
        echo -e "Android platform-tools: ${GREEN}Found${NC}"
    fi
fi

if [ -z "$ANDROID_NDK_HOME" ]; then
    echo -e "${RED}ANDROID_NDK_HOME environment variable is not set${NC}"
    echo -e "${YELLOW}Please set ANDROID_NDK_HOME to your Android NDK location${NC}"
    ((MISSING_PREREQS++))
else
    echo -e "ANDROID_NDK_HOME is set to: ${GREEN}$ANDROID_NDK_HOME${NC}"
    
    # Check if the directory exists
    if [ ! -d "$ANDROID_NDK_HOME" ]; then
        echo -e "${RED}Android NDK directory does not exist at $ANDROID_NDK_HOME${NC}"
        ((MISSING_PREREQS++))
    else
        # Check if crucial NDK files exist
        if [ ! -f "$ANDROID_NDK_HOME/build/cmake/android.toolchain.cmake" ]; then
            echo -e "${RED}Android NDK seems incomplete or invalid${NC}"
            ((MISSING_PREREQS++))
        else
            echo -e "Android NDK: ${GREEN}Found${NC}"
        fi
    fi
fi

# Check disk space
echo
echo "Checking available disk space..."
FREE_SPACE=$(df -h . | awk 'NR==2 {print $4}')
echo -e "Available space: ${GREEN}$FREE_SPACE${NC}"
echo -e "${YELLOW}Note: Building WebRTC requires at least 15GB of free disk space!${NC}"

# Summary
echo
if [ $MISSING_PREREQS -eq 0 ]; then
    echo -e "${GREEN}All prerequisites are met! You can proceed with building.${NC}"
    exit 0
else
    echo -e "${RED}$MISSING_PREREQS prerequisite(s) are missing.${NC}"
    echo -e "${YELLOW}Please install the missing prerequisites before continuing.${NC}"
    exit 1
fi 