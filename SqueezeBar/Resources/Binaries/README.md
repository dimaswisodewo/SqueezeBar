# Binaries Directory

This directory contains bundled binaries for SqueezeBar.

## Ghostscript Binary

The `gs` (Ghostscript) binary should be placed here for PDF compression.

### Building Ghostscript for ARM64

```bash
# Clone Ghostscript
git clone https://github.com/ArtifexSoftware/ghostpdl.git
cd ghostpdl

# Configure for ARM64 macOS with static linking
./configure \
  --host=arm64-apple-darwin \
  --disable-dynamic \
  --enable-static \
  --without-x \
  --without-tesseract \
  CFLAGS="-arch arm64 -mmacosx-version-min=14.6" \
  LDFLAGS="-arch arm64 -mmacosx-version-min=14.6"

# Build
make

# Strip debug symbols to reduce size
strip bin/gs

# Verify architecture
file bin/gs  # Should show: Mach-O 64-bit executable arm64

# Copy to this directory
cp bin/gs /path/to/SqueezeBar/Resources/Binaries/gs
chmod +x /path/to/SqueezeBar/Resources/Binaries/gs
```

### License

Ghostscript is licensed under AGPL v3.
Copyright (C) Artifex Software, Inc.
https://www.ghostscript.com/

This is compatible with SqueezeBar's open-source license.
