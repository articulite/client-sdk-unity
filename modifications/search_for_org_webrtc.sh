#!/bin/bash -u

# Define the source directories
# SRC_DIR=$(pwd)/src
SRC_DIR=$(pwd)/src-shaded

# Check if the source directory exists
if [ ! -d "$SRC_DIR" ]; then
  echo "Error: Source directory '$SRC_DIR' not found."
  exit 1
fi

echo "Searching for relevant patterns in specific files..."

found_something=false

# Define directories to exclude (including unityplugin)
EXCLUDE_DIRS="--exclude-dir=androidapp --exclude-dir=androidjunit --exclude-dir=androidtests --exclude-dir=androidvoip --exclude-dir=androidnativeapi --exclude-dir=examples/unityplugin"

# Search for 'org.webrtc' in BUILD.gn files
echo
echo "--- Searching for 'org.webrtc' or 'org/webrtc' in BUILD.gn files ---"
if grep -rnI --include='BUILD.gn' $EXCLUDE_DIRS -E 'org\.webrtc|org/webrtc' "$SRC_DIR" --color=never 2>/dev/null; then
    found_something=true
else
    echo "No occurrences found in BUILD.gn files."
fi

# Search for 'org.webrtc' in Java files
echo
echo "--- Searching for 'org.webrtc' or 'org/webrtc' in *.java files ---"
if grep -rnI --include='*.java' $EXCLUDE_DIRS -E 'org\.webrtc|org/webrtc' "$SRC_DIR" --color=never 2>/dev/null; then
    found_something=true
else
    echo "No occurrences found in *.java files."
fi

# Search for 'org.webrtc', 'org_webrtc', or 'org/webrtc' in C++ files (*.cc, *.h, *.cpp)
echo
echo "--- Searching for 'org.webrtc', 'org_webrtc', or 'org/webrtc' in *.cc, *.h, and *.cpp files ---"
if grep -rnIE --include='*.cc' --include='*.h' --include='*.cpp' $EXCLUDE_DIRS 'org\.webrtc|org_webrtc|org/webrtc' "$SRC_DIR" --color=never 2>/dev/null; then
    found_something=true
else
    echo "No occurrences found in *.cc, *.h, or *.cpp files."
fi

# Final summary message
if [ "$found_something" = false ]; then
    echo "Overall: No occurrences of the specified patterns were found in the target file types."
fi

echo "Search complete."