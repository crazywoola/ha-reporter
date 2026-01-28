# 🍌 Ha Reporter

A beautiful, intuitive watchOS audio recording app with real-time visualization and cloud upload capabilities.

<div align="center">

![watchOS](https://img.shields.io/badge/watchOS-10.0+-black.svg?style=flat-square&logo=apple)
![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg?style=flat-square&logo=swift)
![SwiftUI](https://img.shields.io/badge/SwiftUI-Latest-blue.svg?style=flat-square)
![License](https://img.shields.io/badge/License-MIT-green.svg?style=flat-square)

</div>

## ✨ Features

### 🎙️ Recording
- **One-tap recording** - Simple, intuitive interface
- **Real-time audio visualization** - 5 animated banana bars showing audio levels
- **Pause & resume** - Continue recording seamlessly
- **Long-press to upload** - Quick upload gesture
- **Minimum file size protection** - Prevents accidental uploads

### 📁 File Management
- **Beautiful recordings list** - Clean, organized interface
- **Swipe to delete** - Natural gesture-based deletion
- **Playback controls** - Play/pause with progress bar
- **File information** - Duration and size at a glance
- **Current vs. Saved** - Clear visual separation

### ☁️ Cloud Integration & AI Transcription
- **Automatic upload to Dify.ai** - Seamless cloud storage
- **AI-powered transcription** - Gemini 3 Flash for accurate text conversion
- **Speaker detection** - Automatically distinguishes different speakers
- **Timestamp generation** - Precise timing for each speech segment
- **Markdown formatting** - Clean, structured output
- **Upload progress** - Real-time feedback
- **Success/failure notifications** - Clear status messages
- **Batch operations** - Delete all recordings at once

### 🎨 Design
- **Banana theme** - Unique, cohesive visual style
- **Dark mode optimized** - Beautiful gradient backgrounds
- **Smooth animations** - Polished, professional feel
- **Apple Watch native** - Designed specifically for watchOS

## 🏗️ Architecture

Built with modern iOS development practices:

- **SwiftUI** - Declarative UI framework
- **MVVM Architecture** - Clear separation of concerns
- **Functional Programming** - Pure functions, immutability, composition
- **Reusable Components** - `Theme.swift`, `Components.swift`, `Formatters.swift`
- **AVFoundation** - Native audio recording and playback
- **Combine** - Reactive state management

### Project Structure

```
Ha Reporter/
├── Theme.swift              # Centralized colors & styles
├── Components.swift         # Reusable UI components
├── Formatters.swift         # Pure formatting functions
├── ContentView.swift        # Main recording interface
├── RecordingFilesView.swift # Recordings list & playback
└── AudioRecorderViewModel.swift # Business logic
```

See [ARCHITECTURE.md](ARCHITECTURE.md) for detailed architecture documentation.

## 🚀 Getting Started

### Prerequisites

- Xcode 15.0+
- watchOS 10.0+
- Apple Watch (any model)
- macOS 14.0+ (for development)
- Dify.ai account (for cloud transcription)

### ⚠️ Security Notice

**IMPORTANT**: This project currently contains a hardcoded API key in the source code. This is **NOT SAFE** for production use.

```swift
// ❌ NOT SAFE - Hardcoded API key
private let apiKey = "app-ucSda6dZimrDkoYlD51IpKIS"
```

**Before using this app:**
1. ✅ Follow the setup instructions below to get your own API key
2. ✅ Replace the hardcoded key in the source code
3. ✅ Never commit API keys to version control
4. ✅ Consider using environment variables or secure storage

### Dify Workflow Setup

This app uses a Dify.ai workflow for audio transcription. The workflow (`Ha Reporter.yml`) transcribes audio with speaker detection and timestamps.

#### 1. Import the Workflow

1. Go to [Dify.ai](https://dify.ai) and sign in
2. Navigate to **Studio** → **Import DSL**
3. Upload the `Ha Reporter.yml` file from this repository
4. The workflow will be imported with:
   - Audio file input
   - Gemini 3 Flash for transcription
   - Speaker detection (Speaker A, B, etc.)
   - Timestamp formatting
   - Markdown output

#### 2. Get Your API Key

1. Open the imported workflow in Dify
2. Click **Publish** button (top right)
3. Click **Run** or **API** tab
4. Copy your **API Key** (starts with `app-...`)
5. Copy the **Workflow Endpoint URL**

#### 3. Configure the App

Edit `AudioRecorderViewModel.swift` and replace:

```swift
// Replace with YOUR API key from Dify
private let apiKey = "YOUR_API_KEY_HERE"

// Replace with YOUR workflow endpoint
private let uploadEndpoint = "https://api.dify.ai/v1/files/upload"
private let workflowEndpoint = "YOUR_WORKFLOW_ENDPOINT_HERE"
```

**Example:**
```swift
private let apiKey = "app-ABC123xyz..."  // Your actual key
private let workflowEndpoint = "https://api.dify.ai/v1/workflows/run"
```

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/crazywoola/ha-reporter.git
   cd ha-reporter
   ```

2. **Setup Dify Workflow** (Required)
   - Follow the **Dify Workflow Setup** instructions above
   - Import `Ha Reporter.yml` to your Dify account
   - Get your API key and configure the app

3. **Open in Xcode**
   ```bash
   open "Ha Reporter.xcodeproj"
   ```

4. **Build and Run**
   - Select your Apple Watch as the target device
   - Press `Cmd + R` to build and run

## 🔧 Configuration

### API Setup

⚠️ **See "Dify Workflow Setup" section above for detailed instructions on:**
- Importing the workflow
- Getting your API key
- Configuring the app securely

### Recording Settings

Adjust recording parameters in `AudioRecorderViewModel.swift`:

```swift
settings = [
    AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
    AVSampleRateKey: 44100,
    AVNumberOfChannelsKey: 1,
    AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
]
```

## 🎯 Usage

### Recording Audio

1. **Start Recording** - Tap the stop button to begin
2. **View Audio Levels** - Watch the animated banana bars
3. **Pause** - Tap again to pause recording
4. **Resume** - Tap once more to continue
5. **Upload** - Long-press the button to upload to cloud

### Managing Recordings

1. **View List** - Rotate the Digital Crown to open recordings
2. **Play Recording** - Tap the play button
3. **Delete** - Swipe left and tap delete
4. **Upload** - Tap the upload button
5. **Clear All** - Tap "Clear All" at the bottom

## 🛠️ Development

### Code Quality

This project follows strict code quality standards:

- ✅ **Zero duplication** - DRY principle
- ✅ **Functional programming** - Pure functions, immutability
- ✅ **Proper abstraction** - Reusable components
- ✅ **Clean architecture** - Separation of concerns
- ✅ **Type safety** - Leverages Swift's type system
- ✅ **No linter errors** - Clean, maintainable code

See [REFACTORING_SUMMARY.md](REFACTORING_SUMMARY.md) for refactoring details.

### Testing

```bash
# Run tests
cmd + U in Xcode

# Run on simulator
Select watchOS Simulator and press cmd + R
```

## 📚 Documentation

- [ARCHITECTURE.md](ARCHITECTURE.md) - System architecture & design patterns
- [REFACTORING_SUMMARY.md](REFACTORING_SUMMARY.md) - Code refactoring report
- [PLAYBACK_GUIDE.md](Ha%20Reporter%20Watch%20App/PLAYBACK_GUIDE.md) - Audio playback documentation
- [Ha Reporter.yml](Ha%20Reporter.yml) - Dify workflow configuration (import this!)

## 📦 Project Files

- **`Ha Reporter.yml`** - Dify workflow for AI transcription
  - Audio to text conversion
  - Speaker detection
  - Timestamp generation
  - Markdown output formatting
- **`LICENSE`** - MIT License
- **`.gitignore`** - iOS/watchOS development exclusions

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Built with [SwiftUI](https://developer.apple.com/xcode/swiftui/)
- Audio processing with [AVFoundation](https://developer.apple.com/av-foundation/)
- Cloud storage via [Dify.ai](https://dify.ai/)
- Icon design inspired by banana aesthetics 🍌

## 📧 Contact

**crazywoola** - [@crazywoola](https://github.com/crazywoola)

Project Link: [https://github.com/crazywoola/ha-reporter](https://github.com/crazywoola/ha-reporter)

---

<div align="center">

Made with ❤️ and 🍌

</div>
