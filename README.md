# SqueezeBar

A lightweight macOS menu bar application for quick and easy file compression. Drop files, compress them with customizable quality settings, and save disk space instantly.

![macOS](https://img.shields.io/badge/macOS-12.0+-blue.svg)
![Swift](https://img.shields.io/badge/Swift-5.0+-orange.svg)
![License](https://img.shields.io/badge/license-AGPL--3.0-blue.svg)

## Features

### Supported File Types

- **Images**: JPEG, PNG, HEIC, HEIF, BMP, TIFF
- **Videos**: MP4, MOV, QuickTime formats
- **Documents**: PDF files

### Compression Modes

**1. Quality Mode**
- Choose from preset quality levels (Maximum, High, Balanced, Small File)
- Custom quality slider for fine-tuned control
- Best for when you want to maintain specific visual quality

**2. Target Size Mode**
- Set a maximum file size in MB
- App automatically calculates optimal quality to reach target
- Perfect for file size requirements (email attachments, upload limits)

**3. Percentage Mode**
- Reduce file size by a specific percentage
- Predictable size reduction
- Useful for batch processing with consistent results

### User Experience

- **Menu Bar Integration**: Always accessible from the menu bar
- **Drag & Drop**: Simply drop files onto the menu bar icon or popover window
- **File Picker**: Click to browse and select files
- **Instant Feedback**: Real-time progress and compression statistics
- **Auto-cleanup**: Automatically removes processed files from the drop zone
- **Quick Access**: Open the output folder directly from the app

## Installation

### Requirements

- macOS 12.0 or later
- Apple Silicon or Intel processor

### Building from Source

1. Clone the repository:
```bash
git clone https://github.com/yourusername/SqueezeBar.git
cd SqueezeBar
```

2. Open the project in Xcode:
```bash
open SqueezeBar.xcodeproj
```

3. Build and run (⌘R)

### App Store

Coming soon!

## Usage

### Basic Workflow

1. **Launch SqueezeBar** - The app icon appears in your menu bar
2. **Click the menu bar icon** - Opens the compression interface
3. **Add a file**:
   - Drag and drop a file onto the window
   - Click "Tap to add file" to browse
4. **Configure compression** (optional):
   - Click the gear icon to access settings
   - Choose compression mode and quality level
   - Select output folder
5. **Compress** - Click the "Compress" button
6. **Done** - View compression results and access your file

### Settings

Access settings by clicking the gear icon in the popover window:

- **Compression Mode**: Choose between Quality, Target Size, or Percentage
- **Quality Settings**: Adjust quality based on selected mode
- **Output Folder**: Choose where compressed files are saved
- **Open Folder**: Quick access to your output directory

### Compression Results

After compression, you'll see:
- Size saved (in MB/KB)
- Percentage reduction
- Quick link to open the output folder

## How It Works

### Image Compression

- Uses native ImageIO and CoreGraphics frameworks
- Smart format selection (converts lossless formats to JPEG when beneficial)
- Preserves image orientation and metadata
- Optional downsampling for very low quality settings
- Falls back to original if compression doesn't help

### Video Compression

- Leverages AVFoundation for efficient encoding
- Adaptive preset selection based on quality settings
- Maintains aspect ratio and video properties
- Hardware acceleration when available

### PDF Compression

- Utilizes Ghostscript for optimal PDF reduction
- Intelligent quality mapping to Ghostscript presets
- Preserves document structure and readability
- Multiple compression strategies based on content type

## Technical Highlights

- **Architecture**: MVVM pattern with Strategy design pattern for compression
- **Concurrency**: Swift async/await for responsive UI
- **Sandbox**: Fully sandboxed for App Store compliance
- **Security**: Secure-scoped bookmarks for file access
- **Performance**: Optimized file I/O and memory management

## Project Structure

```
SqueezeBar/
├── App/
│   ├── SqueezeBarApp.swift      # App entry point
│   └── AppDelegate.swift         # Menu bar setup
├── Views/
│   ├── MainPopoverView.swift    # Main interface
│   ├── SettingsView.swift       # Settings screen
│   └── Components/              # Reusable UI components
├── ViewModels/
│   └── MainViewModel.swift      # Business logic
├── Models/
│   ├── AppSettings.swift        # User preferences
│   ├── CompressionLevel.swift   # Quality definitions
│   └── CompressionResult.swift  # Result data
├── Logic/
│   ├── CompressionManager.swift # Compression coordinator
│   └── Strategies/              # File type handlers
│       ├── ImageCompressor.swift
│       ├── VideoCompressor.swift
│       └── PDFCompressor.swift
└── Resources/
    ├── Binaries/                # External tools (Ghostscript)
    └── Design/                  # UI constants and extensions
```

## Configuration

### Default Settings

- **Compression Mode**: Quality
- **Quality Level**: Balanced (60%)
- **Output Folder**: User's Desktop

### Customization

All settings are persisted using UserDefaults and secure bookmarks, ensuring your preferences are saved between sessions.

## Privacy

SqueezeBar:
- Does not collect any user data
- Does not send files to external servers
- Processes all files locally on your Mac
- Only accesses files you explicitly provide
- Requests minimal permissions (file access only)

## Troubleshooting

### App doesn't appear in menu bar
- Check System Settings → General → Login Items
- Restart SqueezeBar

### Compression fails
- Verify output folder permissions
- Ensure sufficient disk space
- Check file isn't corrupted or in use

### "Cannot access save location" error
- Re-select the output folder in Settings
- Choose a folder you have write permissions for

### File size doesn't reduce much
- Some files are already highly compressed
- Try lowering the quality setting
- Consider if the file type supports compression well

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Roadmap

- [ ] Batch file compression
- [ ] More file format support (audio, archives)
- [ ] Compression presets
- [ ] Before/after preview
- [ ] Keyboard shortcuts
- [ ] Dark mode refinements

## License

This project is licensed under the GNU Affero General Public License v3.0 (AGPL-3.0)

## Acknowledgments

- Built with Swift and SwiftUI
- Uses Ghostscript for PDF compression
- Inspired by the need for quick, easy file compression on macOS

## Support

If you encounter any issues or have suggestions:
- Open an issue on GitHub
- Email: dimaswisodewo98@gmail.com

## Author

**Dimas Wisodewo**
- GitHub: [@dimaswisodewo](https://github.com/dimaswisodewo)
- Website: [dimasw.com](https://dimasw.com)

---

Made with ❤️ for macOS
