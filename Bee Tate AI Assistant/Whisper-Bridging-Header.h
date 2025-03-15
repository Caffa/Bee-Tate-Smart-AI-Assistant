#ifndef Whisper_Bridging_Header_h
#define Whisper_Bridging_Header_h

// Include the necessary whisper.cpp headers
#include "whisper.h"
#include "ggml/ggml.h"
#include "ggml/ggml-metal.h"

// Explicitly define the sampling strategy enum for Swift
#ifdef __cplusplus
extern "C" {
#endif

// Ensure these are available to Swift
WHISPER_API struct whisper_context * whisper_init_from_file(const char * path_model);
WHISPER_API void whisper_free(struct whisper_context * ctx);
WHISPER_API struct whisper_full_params whisper_full_default_params(enum whisper_sampling_strategy strategy);
WHISPER_API int whisper_full(struct whisper_context * ctx, struct whisper_full_params params, const float * samples, int n_samples);
WHISPER_API int whisper_full_n_segments(struct whisper_context * ctx);
WHISPER_API const char * whisper_full_get_segment_text(struct whisper_context * ctx, int i);

// Define the sampling strategy enum values
enum whisper_sampling_strategy {
    WHISPER_SAMPLING_GREEDY = 0,      // similar to OpenAI's GreedyDecoder
    WHISPER_SAMPLING_BEAM_SEARCH = 1, // similar to OpenAI's BeamSearchDecoder
};

#ifdef __cplusplus
}
#endif

#endif /* Whisper_Bridging_Header_h */

