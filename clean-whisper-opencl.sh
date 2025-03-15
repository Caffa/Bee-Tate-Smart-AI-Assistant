#!/bin/bash

# This script removes OpenCL, CANN, and SYCL-related files from the project to avoid build errors

echo "Cleaning up problematic backend files from whisper-cpp..."

# Path to the whisper-cpp directory
WHISPER_DIR="Bee Tate AI Assistant/whisper-cpp"
GGML_DIR="$WHISPER_DIR/ggml"

# Remove OpenCL kernel files
echo "Removing OpenCL files..."
rm -rf "$GGML_DIR/src/ggml-opencl"

# Remove CANN files
echo "Removing CANN files..."
rm -rf "$GGML_DIR/src/ggml-cann"

# Remove SYCL files
echo "Removing SYCL files..."
rm -rf "$GGML_DIR/src/ggml-sycl"

# Remove any other problematic files
find "$GGML_DIR" -name "*.cl" -delete
find "$GGML_DIR" -name "kernel_operator.h" -delete

# Run the clean-whisper-deps.sh script to ensure proper setup
echo "Running clean-whisper-deps.sh to ensure proper setup..."
./clean-whisper-deps.sh

echo "Problematic backend files have been removed."
echo ""
echo "If the build still fails, please do the following in Xcode:"
echo "1. Remove any problematic folder references from the project navigator"
echo "2. Make sure the ExcludeCMakeLists.xcconfig file is properly included in your project"
echo ""
echo "Done."

