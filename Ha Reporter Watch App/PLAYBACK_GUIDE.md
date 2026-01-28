# Audio Playback Guide

## Overview

This guide explains how audio playback works in Ha Reporter Watch App.

## Architecture

### AudioPlayerViewModel

The `AudioPlayerViewModel` class handles all audio playback functionality:

- **State Management**: Uses `@Published` properties for SwiftUI integration
- **AVAudioPlayer**: Native iOS audio playback
- **Timer-based Updates**: Real-time progress tracking

### Key Features

1. **Play/Pause Control**
   - `play(url:)` - Start playback from URL
   - `pause()` - Pause current playback
   - `stop()` - Stop and reset playback

2. **Progress Tracking**
   - Real-time `currentTime` updates every 0.1 seconds
   - Total `duration` calculation
   - Current file tracking via `currentURL`

3. **Delegate Methods**
   - `audioPlayerDidFinishPlaying` - Auto-stop when finished
   - `audioPlayerDecodeErrorDidOccur` - Error handling

## Usage in RecordingFilesView

```swift
@StateObject private var audioPlayer = AudioPlayerViewModel()

// Play or pause
audioPlayer.currentURL == url && audioPlayer.isPlaying
    ? audioPlayer.pause()
    : audioPlayer.play(url: url)

// Stop on delete
if audioPlayer.currentURL == url {
    audioPlayer.stop()
}
```

## UI Integration

The `AudioProgressBar` component displays:
- Progress bar with banana theme gradient
- Current time and remaining time
- Smooth animations

## Audio Session Configuration

```swift
let session = AVAudioSession.sharedInstance()
try session.setCategory(.playback, mode: .default)
try session.setActive(true)
```

This configuration allows audio playback on Apple Watch.

## Best Practices

1. **Always stop playback** before deleting a file
2. **Use `@StateObject`** for AudioPlayerViewModel lifecycle
3. **Clean up on view disappear** with `onDisappear(perform: audioPlayer.stop)`
4. **Check `currentURL`** before operations to ensure correct file

## Error Handling

All errors are logged to console with emoji prefixes:
- ✅ Successful operations
- ❌ Errors and failures
- ▶️ Play actions
- ⏸️ Pause actions
- ⏹️ Stop actions
