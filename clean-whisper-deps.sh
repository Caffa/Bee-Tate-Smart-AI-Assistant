#!/bin/bash

# This script cleans up problematic whisper-cpp dependencies and sets up appropriate header links

echo "Cleaning up problematic whisper-cpp dependencies..."

# Path to the whisper-cpp directory
WHISPER_DIR="Bee Tate AI Assistant/whisper-cpp"
GGML_DIR="$WHISPER_DIR/ggml"

# 1. Remove OpenCL files (known to cause issues)
echo "Removing OpenCL files..."
rm -rf "$GGML_DIR/src/ggml-opencl"

# 2. Remove CANN and SYCL files (not needed for iOS)
echo "Removing CANN and SYCL files..."
rm -rf "$GGML_DIR/src/ggml-cann"
rm -rf "$GGML_DIR/src/ggml-sycl"
rm -rf "$GGML_DIR/src/ggml-cpu/kleidiai"

# 3. Create necessary symbolic links for Metal
echo "Creating symbolic links for Metal..."
mkdir -p "$GGML_DIR/src/ggml-metal/include"

# Make sure the source files exist before creating symlinks
if [ -f "$GGML_DIR/src/ggml-common.h" ]; then
    cp "$GGML_DIR/src/ggml-common.h" "$GGML_DIR/src/ggml-metal/ggml-common.h"
fi

if [ -f "$GGML_DIR/src/ggml.h" ]; then
    cp "$GGML_DIR/src/ggml.h" "$GGML_DIR/src/ggml-metal/ggml.h"
fi

if [ -f "$GGML_DIR/src/ggml-backend-impl.h" ]; then
    cp "$GGML_DIR/src/ggml-backend-impl.h" "$GGML_DIR/src/ggml-metal/ggml-backend-impl.h"
fi

if [ -f "$GGML_DIR/src/ggml-impl.h" ]; then
    cp "$GGML_DIR/src/ggml-impl.h" "$GGML_DIR/src/ggml-metal/ggml-impl.h"
fi

# 4. Create a header directory with all necessary includes
echo "Creating central header directory..."
mkdir -p "$WHISPER_DIR/include_all"

# Create header guard template
HEADER_GUARD_TEMPLATE="#ifndef WHISPER_INCLUDE_GUARD_
#define WHISPER_INCLUDE_GUARD_

// Original content below
"

# Function to add header guards
add_header_guards() {
    local file="$1"
    local guard_name="$(basename "$file" | tr '.-' '_' | tr '[:lower:]' '[:upper:]')_INCLUDED"
    if ! grep -q "#ifndef $guard_name" "$file"; then
        local temp_file="$(mktemp)"
        echo "#ifndef $guard_name" > "$temp_file"
        echo "#define $guard_name" >> "$temp_file"
        echo "" >> "$temp_file"
        cat "$file" >> "$temp_file"
        echo "" >> "$temp_file"
        echo "#endif // $guard_name" >> "$temp_file"
        mv "$temp_file" "$file"
    fi
}

# Copy and process ggml headers
for header in ggml.h ggml-common.h ggml-backend-impl.h ggml-impl.h ggml-backend.h; do
    find "$GGML_DIR" -name "$header" -exec cp {} "$WHISPER_DIR/include_all/" \;
    if [ -f "$WHISPER_DIR/include_all/$header" ]; then
        add_header_guards "$WHISPER_DIR/include_all/$header"
    fi
done

# Copy and process whisper.h
if [ -f "$WHISPER_DIR/whisper.h" ]; then
    cp "$WHISPER_DIR/whisper.h" "$WHISPER_DIR/include_all/"
    add_header_guards "$WHISPER_DIR/include_all/whisper.h"
fi

# Create or process ggml-cpu.h
if [ ! -f "$WHISPER_DIR/include_all/ggml-cpu.h" ]; then
    if ! find "$GGML_DIR" -name "ggml-cpu.h" -exec cp {} "$WHISPER_DIR/include_all/" \;; then
        echo "#ifndef GGML_CPU_H_INCLUDED" > "$WHISPER_DIR/include_all/ggml-cpu.h"
        echo "#define GGML_CPU_H_INCLUDED" >> "$WHISPER_DIR/include_all/ggml-cpu.h"
        echo "" >> "$WHISPER_DIR/include_all/ggml-cpu.h"
        echo "// Empty ggml-cpu.h file created by clean-whisper-deps.sh" >> "$WHISPER_DIR/include_all/ggml-cpu.h"
        echo "" >> "$WHISPER_DIR/include_all/ggml-cpu.h"
        echo "#endif // GGML_CPU_H_INCLUDED" >> "$WHISPER_DIR/include_all/ggml-cpu.h"
    else
        add_header_guards "$WHISPER_DIR/include_all/ggml-cpu.h"
    fi
fi

# 5. Update the ExcludeCMakeLists.xcconfig file to disable problematic backends
echo "Updating configuration file..."

cat > "ExcludeCMakeLists.xcconfig" << 'EOL'
// Configuration for excluding problematic files in the whisper-cpp library

// Disable problematic backends
OTHER_CFLAGS = -DGGML_USE_ACCELERATE=1 -DGGML_USE_METAL=1 -DGGML_USE_OPENCL=0 -DGGML_USE_CUBLAS=0 -DGGML_USE_CANN=0

// Additional include paths
HEADER_SEARCH_PATHS = ${inherited} "${SRCROOT}/Bee Tate AI Assistant/whisper-cpp/include_all"

// Exclude problematic build files
EXCLUDED_SOURCE_FILE_NAMES = CMakeLists.txt *.cl kernel_operator.h ggml-alloc.c ggml-opencl.* ggml-cann.* ggml-sycl.* kernels.cpp

// Make sure we use Metal and Accelerate framework for best performance
OTHER_LDFLAGS = -framework Metal -framework MetalKit -framework Accelerate ${inherited}
EOL

echo "Done."

