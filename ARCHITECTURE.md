# Ha Reporter - Architecture Overview

## File Structure

```
Ha Reporter Watch App/
├── 🎨 Theme & Styling
│   ├── Theme.swift              # Colors, gradients, view modifiers
│   └── Components.swift         # Reusable UI components
│
├── 🔧 Utilities
│   └── Formatters.swift         # Pure formatting functions
│
├── 📱 Views
│   ├── ContentView.swift        # Main recording interface
│   └── RecordingFilesView.swift # Recordings list & playback
│
├── 🎙️ Business Logic
│   └── AudioRecorderViewModel.swift  # Recording state & API
│
└── 🚀 App Entry
    └── Ha_ReporterApp.swift     # App lifecycle
```

## Dependency Graph

```
┌─────────────────────────────────────────────┐
│           Ha_ReporterApp.swift              │
└──────────────────┬──────────────────────────┘
                   │
        ┌──────────┴──────────┐
        ▼                     ▼
┌──────────────┐      ┌──────────────────┐
│ ContentView  │      │ RecordingFilesView│
└──────┬───────┘      └─────────┬─────────┘
       │                        │
       │    ┌───────────────────┤
       │    │                   │
       ▼    ▼                   ▼
┌────────────────────┐   ┌─────────────┐
│ AudioRecorderVM    │   │ AudioPlayer │
└────────────────────┘   └─────────────┘
       │                        │
       └────────┬───────────────┘
                ▼
    ┌───────────────────────┐
    │  Shared Dependencies  │
    ├───────────────────────┤
    │  • Theme.swift        │
    │  • Components.swift   │
    │  • Formatters.swift   │
    └───────────────────────┘
```

## Component Hierarchy

### ContentView (Main Recording)
```
ContentView
├── Background (.bananaBackground())
└── VStack
    ├── RecordingStateView (@ViewBuilder)
    │   ├── Recording: HStack of AudioBar × 5
    │   ├── Paused: Banana emoji + text
    │   └── Ready: Banana + microphone
    │
    ├── TimerControlView
    │   ├── Timer display
    │   └── StopButton (circular)
    │
    └── StatusView (@ViewBuilder)
        ├── Uploading spinner
        ├── Upload message
        └── Warning message
```

### RecordingFilesView (Recordings List)
```
RecordingFilesView
├── Background (.bananaBackground())
└── ScrollView
    ├── UploadBanner (conditional)
    ├── CurrentRecordingSection
    │   ├── SectionHeader("🍌", "Current")
    │   └── RecordingRow
    │
    ├── SavedRecordingsSection
    │   ├── SectionHeader("📁", "Saved", count)
    │   └── ForEach RecordingRow
    │
    ├── EmptyStateView (conditional)
    └── DeleteAllButton (conditional)
```

### RecordingRow (Playback Item)
```
RecordingRow
├── CardBackground (BananaTheme.cardGradient)
└── VStack
    ├── HStack
    │   ├── CircularIconButton (play/pause)
    │   ├── FileInfoView
    │   │   ├── Duration (TimeFormatter)
    │   │   └── Size (FileSizeFormatter)
    │   └── CircularIconButton (upload)
    │
    └── AudioProgressBar (conditional)
        ├── Progress bar
        └── Time labels
```

## Data Flow

### Recording Flow
```
User Tap
    ↓
ContentView.stopButton.onTap
    ↓
AudioRecorderViewModel.toggleRecording()
    ↓
AVAudioRecorder (start/pause)
    ↓
@Published State Updates
    ↓
ContentView Re-renders
    ↓
RecordingStateView Updates
    ↓
AudioBar Animations
```

### Playback Flow
```
User Tap
    ↓
RecordingRow.playPauseButton
    ↓
RecordingFilesView.handlePlayPause()
    ↓
AudioPlayerViewModel.play() or .pause()
    ↓
AVAudioPlayer
    ↓
Timer Updates currentTime
    ↓
@Published State Updates
    ↓
RecordingRow Re-renders
    ↓
AudioProgressBar Updates
```

## Functional Programming Patterns

### Pure Functions (No Side Effects)
```swift
// All formatters are pure
TimeFormatter.format(120)      // → "02:00"
FileSizeFormatter.format(1024) // → "1 KB"
[CGFloat].randomLevels(count: 5) // → [0.5, 0.8, ...]
```

### Higher-Order Functions
```swift
// Map, filter, reduce patterns
audioLevels.map { $0 * 55 + 20 }
recordings.filter { $0.fileSize > 50_000 }
```

### Composition
```swift
// Views composed of smaller views
RecordingRow = CircularIconButton + FileInfo + AudioProgressBar

// View modifiers compose
view
    .bananaBackground()
    .padding()
    .onAppear(perform: loadData)
```

### Immutability
```swift
// Enums for constants (immutable)
BananaTheme.yellow  // Cannot be modified

// Formatters as static functions
enum TimeFormatter {
    static func format(_:) -> String
}
```

## Theme System

### Color Palette
```swift
BananaTheme {
    yellow     #FFDE00  Primary accent
    bright     #CCAF28  Highlights
    green      #99CC33  (Unused reserve)
    brown      #66511A  Shadows/tips
    darkBg     #262014  Background top
    black      #000000  Background bottom
}
```

### Gradients
```swift
.backgroundGradient  // darkBg → black (vertical)
.barGradient         // yellow → bright (vertical)
.buttonGradient      // brown shades (diagonal)
.cardGradient(bool)  // yellow or brown tinted
```

## State Management

### Published Properties
```swift
AudioRecorderViewModel:
    @Published isRecording: Bool
    @Published recordingTime: TimeInterval
    @Published hasRecording: Bool
    @Published isUploading: Bool
    @Published uploadMessage: String?

AudioPlayerViewModel:
    @Published isPlaying: Bool
    @Published currentTime: TimeInterval
    @Published duration: TimeInterval
    @Published currentURL: URL?
```

### State Ownership
```
ContentView
    @StateObject audioRecorder
    @State audioLevels
    @State showRecordingsList

RecordingFilesView
    @ObservedObject audioRecorder (passed)
    @StateObject audioPlayer (owned)
```

## Performance Optimizations

1. **Computed Properties** - Lazy evaluation
2. **@ViewBuilder** - Efficient conditional rendering
3. **Identifiable** - SwiftUI diff optimization
4. **Animation** - Only on changed values
5. **Pure Functions** - Memoization-friendly
6. **Functional Arrays** - Lazy sequences

## Testing Strategy

### Unit Tests (Pure Functions)
```swift
✅ TimeFormatter.format()
✅ FileSizeFormatter.format()
✅ [CGFloat].randomLevels()
```

### View Tests (SwiftUI Previews)
```swift
✅ Theme.swift components
✅ Components.swift widgets
✅ ContentView states
✅ RecordingRow variations
```

### Integration Tests
```swift
✅ AudioRecorderViewModel recording flow
✅ AudioPlayerViewModel playback flow
✅ File upload/delete operations
```

---

**Architecture Principles:**
- Separation of Concerns
- Single Responsibility
- DRY (Don't Repeat Yourself)
- Composition over Inheritance
- Functional Core, Imperative Shell
- Declarative > Imperative
- Immutable by Default
