# Integrating whisper.cpp with the Bee Tate AI Assistant

This document provides detailed instructions for integrating whisper.cpp with the Swift application.

## Setup Instructions

### 1. Clone and Build whisper.cpp

First, clone the whisper.cpp repository and build it:

```bash
# Clone the repository
git clone https://github.com/ggerganov/whisper.cpp.git
cd whisper.cpp

# Build the library (for macOS)
make
```

### 2. Download the large-v3 model

```bash
# Download the large-v3 model (approximately 4GB)
bash ./models/download-ggml-model.sh large-v3
```

### 3. Add the C library to the Xcode project

1. In Xcode, right-click on your project and select "Add Files to [ProjectName]"
2. Navigate to and select the following files from the whisper.cpp repository:
   - `whisper.h`
   - `whisper.cpp`
   - `ggml.h`
   - `ggml.c`

3. When prompted, ensure "Copy items if needed" is checked and add to your target.

### 4. Configure Build Settings

1. In Xcode, select your target and go to Build Settings
2. Add the following to "Header Search Paths":
   - Path to where whisper.h and ggml.h are located
3. Set "Enable Modules (C and Objective-C)" to Yes
4. Add the bridging header path in "Objective-C Bridging Header"
5. For optimizations, consider adding these flags to "Other C Flags":
   - `-O3` (for release builds)
   - `-DGGML_USE_ACCELERATE` (to use Apple's Accelerate framework)

### 5. Set up the Model

The large-v3 model should be placed in the app's Documents directory:

1. First run will check for model presence
2. If missing, provide a mechanism to download it
3. Consider bundling a smaller model for initial use

### 6. Using the Code

The WhisperService provides a simple API:

```swift
let whisperService = WhisperService()

// Transcribe an audio file
whisperService.transcribeAudio(from: audioFileURL) { result in
    switch result {
    case .success(let transcript):
        print("Transcription: \(transcript)")
    case .failure(let error):
        print("Error: \(error)")
    }
}
```

## Performance Considerations

- Processing occurs on the CPU and can be intensive
- The large-v3 model requires ~4GB RAM during transcription
- Consider providing visual feedback during processing
- For longer files (>30 seconds), consider chunking the audio

## Troubleshooting

### Common Issues:

1. **Build Errors**:
   - Ensure C/C++ files are properly included
   - Check header search paths

2. **Model Loading Failures**:
   - Verify model path is correct
   - Check model file integrity
   - Ensure app has permission to access the file

3. **Audio Format Issues**:
   - whisper.cpp requires 16kHz mono PCM audio
   - Use the provided converter function

4. **Memory Issues**:
   - The large model requires significant memory
   - Consider using a smaller model for low-memory devices

## Advanced Usage

For more control, configure WhisperParams:

```swift
var params = WhisperProcessor.WhisperParams()
params.language = "en"  // Force English language
params.translate = true // Translate to English
params.beamSize = 5     // Adjust beam size for accuracy vs. speed
params.threads = 4      // Control CPU usage

whisperProcessor.transcribe(audioPath: path, modelPath: modelPath, params: params)
```

