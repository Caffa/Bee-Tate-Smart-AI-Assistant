#pragma once

#include "ggml.h"

#ifdef __cplusplus
extern "C" {
#endif

// AMX backend for GGML
// This is a minimal header to satisfy the include requirement

// Check if AMX is supported
bool ggml_cpu_has_amx(void);

#ifdef __cplusplus
}
#endif

