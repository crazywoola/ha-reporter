# 🍌 Ha Reporter

A beautiful watchOS audio recording app with AI-powered transcription.

<div align="center">

![watchOS](https://img.shields.io/badge/watchOS-10.0+-black.svg?style=flat-square&logo=apple)
![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg?style=flat-square&logo=swift)
![License](https://img.shields.io/badge/License-MIT-green.svg?style=flat-square)

</div>

## ✨ Features

- 🎙️ **One-tap recording** with real-time audio visualization
- ⏸️ **Pause & resume** - Continue recording seamlessly
- 🤖 **AI transcription** - Speaker detection and timestamps via Dify.ai
- 📁 **Playback & management** - Swipe to delete, tap to play
- 🍌 **Banana theme** - Beautiful, cohesive design
- ⌚ **Native watchOS** - Optimized for Apple Watch

## 🚀 Quick Start

### Prerequisites

- Xcode 15.0+
- watchOS 10.0+
- [Dify.ai](https://dify.ai) account

### ⚠️ Security Notice

**This project contains a hardcoded API key. Replace it before use!**

### Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/crazywoola/ha-reporter.git
   cd ha-reporter
   ```

2. **Import Dify Workflow**
   - Sign in to [Dify.ai](https://dify.ai)
   - Go to **Studio** → **Import DSL**
   - Upload `Ha Reporter.yml`
   - Click **Publish** and copy your **API Key**

3. **Configure API Key**
   
   Edit `AudioRecorderViewModel.swift`:
   ```swift
   private let apiKey = "YOUR_API_KEY_HERE"
   ```

4. **Build and Run**
   ```bash
   open "Ha Reporter.xcodeproj"
   # Select Apple Watch target and press Cmd + R
   ```

## 🎯 Usage

- **Start/Pause** - Tap the button
- **Upload** - Long-press the button
- **View recordings** - Rotate Digital Crown
- **Play/Delete** - Tap play or swipe left

## 🏗️ Architecture

Built with **SwiftUI**, **MVVM**, and **Functional Programming** principles.

```
Ha Reporter/
├── Theme.swift              # Colors & styles
├── Components.swift         # Reusable UI
├── Formatters.swift         # Pure functions
├── ContentView.swift        # Main UI
├── RecordingFilesView.swift # Recordings list
└── AudioRecorderViewModel.swift # Business logic
```

See [ARCHITECTURE.md](ARCHITECTURE.md) for details.

## 📚 Documentation

- [ARCHITECTURE.md](ARCHITECTURE.md) - System design patterns
- [PLAYBACK_GUIDE.md](Ha%20Reporter%20Watch%20App/PLAYBACK_GUIDE.md) - Audio playback docs
- [Ha Reporter.yml](Ha%20Reporter.yml) - Dify workflow (import this!)

## 🤝 Contributing

Contributions welcome! Please submit a Pull Request.

## 📝 License

MIT License - see [LICENSE](LICENSE) file.

## 🙏 Acknowledgments

Built with [SwiftUI](https://developer.apple.com/xcode/swiftui/), [AVFoundation](https://developer.apple.com/av-foundation/), and [Dify.ai](https://dify.ai/) 🍌

---

<div align="center">

Made with ❤️ and 🍌

</div>
