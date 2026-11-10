# Native components

The recipient does not need a compiler. This package includes Apple Silicon executables, ad-hoc signed without an Apple Developer ID.

ASR engine source: `transcribe-cpp-sys 0.2.4` / transcribe.cpp, ggml0.25.3. Entry point source is `native/src/asr-worker.cpp`. Build the upstream static engine with:

```text
CMAKE_BUILD_TYPE=Release
BUILD_SHARED_LIBS=OFF
GGML_NATIVE=OFF
GGML_CPU_ARM_ARCH=armv8-a
GGML_OPENMP=OFF
GGML_METAL=ON
GGML_METAL_EMBED_LIBRARY=ON
TRANSCRIBE_BUILD_TESTS=OFF
TRANSCRIBE_BUILD_EXAMPLES=OFF
CMAKE_OSX_DEPLOYMENT_TARGET=26.0
```

Link the entry point with libtranscribe, libggml, libggml-cpu, libggml-metal and libggml-base, using `-std=c++17 -O2 -march=armv8-a` and Apple Accelerate/Foundation/Metal/MetalKit frameworks. No Homebrew dylib is required by this executable. Build paths in diagnostic strings are anonymized, and the output is ad-hoc re-signed.

The floating window is AppKit code in `native/src/voice-panel.swift`, compiled with Swift and AppKit for arm64/macOS26. It is a transparent nonactivating NSPanel. Microphone capture and the session bridge stay in Harness.

No M5-specific `-mcpu=native`, SME or I8MM CPU target is enabled in the distributed ASR. Running the conservative build on the author's Mac is verified; physical M1/M2/M3/M4 test coverage is not claimed.
