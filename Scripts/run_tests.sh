#!/bin/bash

# Test runner script for MagicGlide

echo "=== MagicGlide Test Suite ==="
echo ""

# Run tests using Swift Package Manager
echo "🧪 Running tests with Swift Package Manager..."
mkdir -p build/.tmp build/.module-cache build/.spm-build
TMPDIR="$PWD/build/.tmp" CLANG_MODULE_CACHE_PATH="$PWD/build/.module-cache" swift test --disable-sandbox --scratch-path build/.spm-build

if [ $? -eq 0 ]; then
    echo ""
    echo "🎉 All tests passed!"
    exit 0
else
    echo ""
    echo "💔 Some tests failed"
    exit 1
fi
