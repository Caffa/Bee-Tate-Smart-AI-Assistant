#!/bin/bash

# Define source and destination directories
SOURCE_DIR="Resources/whisper-cpp"
DEST_DIR="Bee Tate AI Assistant/whisper-cpp"

echo "Setting up whisper.cpp library files..."

# Create destination directory if it doesn't exist
mkdir -p "$DEST_DIR"
echo "Created directory: $DEST_DIR"

# Copy core whisper files
echo "Copying main whisper files..."
cp "$SOURCE_DIR/include/whisper.h" "$DEST_DIR/"
cp "$SOURCE_DIR/src/whisper.cpp" "$DEST_DIR/"

# First, let's find where the ggml files are located
echo "Locating ggml files..."
GGML_DIR=$(find "$SOURCE_DIR" -type d -name "ggml" | head -n 1)

if [ -z "$GGML_DIR" ]; then
    echo "Error: Could not find ggml directory. Please check the repository structure."
    exit 1
fi

echo "Found ggml directory at: $GGML_DIR"

# Copy ggml core files
echo "Copying ggml files..."
mkdir -p "$DEST_DIR/ggml"

# Try to find ggml.h and ggml.c, could be in different locations
GGML_H=$(find "$GGML_DIR" -name "ggml.h" | head -n 1)
GGML_C=$(find "$GGML_DIR" -name "ggml.c" | head -n 1)

if [ -f "$GGML_H" ]; then
    echo "Copying $GGML_H"
    cp "$GGML_H" "$DEST_DIR/ggml/"
else
    echo "Warning: Could not find ggml.h"
fi

if [ -f "$GGML_C" ]; then
    echo "Copying $GGML_C"
    cp "$GGML_C" "$DEST_DIR/ggml/"
else
    echo "Warning: Could not find ggml.c"
fi

# Try to find other necessary ggml files
for file in "ggml-alloc.h" "ggml-alloc.c" "ggml-backend.h" "ggml-backend.c" "ggml-backend-impl.h"; do
    FOUND_FILE=$(find "$GGML_DIR" -name "$file" | head -n 1)
    if [ -f "$FOUND_FILE" ]; then
        echo "Copying $FOUND_FILE"
        cp "$FOUND_FILE" "$DEST_DIR/ggml/"
    else
        echo "Warning: Could not find $file"
    fi
done

# Create include directory for other necessary headers
echo "Copying any needed include files..."
mkdir -p "$DEST_DIR/include"

# Copy any unicode headers if they exist
UNICODE_H=$(find "$SOURCE_DIR" -name "unicode.h" | head -n 1)
UNICODE_DATA_H=$(find "$SOURCE_DIR" -name "unicode-data.h" | head -n 1)

if [ -f "$UNICODE_H" ]; then
    echo "Copying $UNICODE_H"
    cp "$UNICODE_H" "$DEST_DIR/include/"
else
    echo "Warning: Could not find unicode.h"
fi

if [ -f "$UNICODE_DATA_H" ]; then
    echo "Copying $UNICODE_DATA_H"
    cp "$UNICODE_DATA_H" "$DEST_DIR/include/"
else
    echo "Warning: Could not find unicode-data.h"
fi

echo "Done copying files."
echo ""
echo "=== NEXT STEPS ==="
echo "1. Add these files to your Xcode project:"
echo "   - Right-click on your project in Xcode"
echo "   - Select 'Add Files to \"Bee Tate AI Assistant\"'"
echo "   - Navigate to $DEST_DIR"
echo "   - Select all files and directories and click 'Add'"
echo ""
echo "2. Configure your project build settings:"
echo "   - Go to project settings > Build Settings"
echo "   - Set 'Header Search Paths' to include:"
echo "     \$(PROJECT_DIR)/Bee Tate AI Assistant/whisper-cpp"
echo "     \$(PROJECT_DIR)/Bee Tate AI Assistant/whisper-cpp/ggml"
echo "     \$(PROJECT_DIR)/Bee Tate AI Assistant/whisper-cpp/include"
echo ""
echo "3. Set your Objective-C Bridging Header in Build Settings:"
echo "   - Set 'Objective-C Bridging Header' to:"
echo "     Bee Tate AI Assistant/Whisper-Bridging-Header.h"
echo ""
echo "4. For better performance, add to 'Other C Flags':"
echo "   -DGGML_USE_ACCELERATE"
echo ""

