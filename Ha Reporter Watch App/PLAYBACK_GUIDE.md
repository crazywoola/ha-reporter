# 🎵 Recording Playback Guide

## Overview
Your Ha Reporter Watch App now has a complete recordings management system with playback functionality!

## ✨ Features Added

### 1. **Recordings List View** (`RecordingFilesView.swift`)
A beautiful, watchOS-optimized interface showing:
- Current recording
- All saved recordings
- File sizes
- Playback controls
- Delete options

### 2. **Audio Player** (`AudioPlayerViewModel`)
Full-featured audio player with:
- Play/Pause controls
- Real-time progress bar
- Time display (current/duration)
- Automatic cleanup when finished

### 3. **Integration with Main App**
- "Recordings" button appears when you have saved files
- Shows count of saved recordings
- Opens as a modal sheet

## 🎮 How to Use

### Access Recordings List
1. Record some audio in the main app
2. Upload it (long press - now just 0.4 seconds!)
3. Tap the "Recordings (N)" button at the bottom
4. Browse your recordings

### Play a Recording
1. Open the recordings list
2. Tap the **play button** (▶️) on any recording
3. Watch the progress bar fill up
4. Tap **pause button** (⏸️) to pause
5. Playback automatically stops when finished

### Delete Recordings
- **Single recording**: Tap the trash icon on any recording row
- **All recordings**: Scroll to bottom and tap "Delete All" button

## 🎯 UI Components

### RecordingRow Features
Each recording shows:
- **Filename** - Full recording name
- **File size** - Human-readable format (KB, MB)
- **Duration** - Total length when playing
- **Progress bar** - Visual playback progress
- **Time labels** - Current time / Total duration
- **Play/Pause button** - Large, easy to tap
- **Delete button** - Quick removal

### Visual Feedback
- ✅ Blue highlight when playing
- ✅ Red pause icon when active
- ✅ Smooth progress animation
- ✅ Automatic UI updates

## 🔧 Technical Details

### AudioPlayerViewModel
```swift
@Published var isPlaying: Bool        // Currently playing?
@Published var currentTime: TimeInterval  // Current position
@Published var duration: TimeInterval     // Total length
@Published var currentURL: URL?          // Which file?

// Methods
func play(url: URL)    // Start playback
func pause()           // Pause playback
func stop()            // Stop and reset
```

### Audio Session Management
- Automatically switches to `.playback` category
- Activates audio session for playback
- Properly cleans up resources
- Handles errors gracefully

## 📱 Usage in Code

### Access from ContentView
```swift
@State private var showRecordingsList = false

Button {
    showRecordingsList = true
} label: {
    Text("Recordings (\(audioRecorder.savedRecordings.count))")
}
.sheet(isPresented: $showRecordingsList) {
    NavigationStack {
        RecordingFilesView(audioRecorder: audioRecorder)
    }
}
```

### Standalone Usage
```swift
// Create a player instance
@StateObject private var audioPlayer = AudioPlayerViewModel()

// Play a recording
audioPlayer.play(url: recordingURL)

// Check state
if audioPlayer.isPlaying {
    print("Currently playing: \(audioPlayer.currentURL?.lastPathComponent ?? "")")
    print("Progress: \(audioPlayer.currentTime) / \(audioPlayer.duration)")
}

// Stop playback
audioPlayer.stop()
```

## 🎨 Customization

### Change Colors
In `RecordingRow`, modify:
```swift
.foregroundStyle(isPlaying ? .red : .blue)  // Play button color
.fill(isPlaying ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))  // Background
```

### Adjust Progress Bar
```swift
.frame(height: 4)  // Progress bar thickness
RoundedRectangle(cornerRadius: 2)  // Progress bar style
```

### Modify Time Format
```swift
private func formatTime(_ time: TimeInterval) -> String {
    let minutes = Int(time) / 60
    let seconds = Int(time) % 60
    return String(format: "%d:%02d", minutes, seconds)
}
```

## 🐛 Debugging

### Check Playback Issues
The player logs everything:
```
▶️ Playing: recording_123456.wav
   Duration: 45.3 seconds
⏸️ Paused playback
⏹️ Stopped playback
✅ Playback finished
❌ Failed to play audio: [error]
```

### Verify File Access
```swift
if let url = audioRecorder.getCurrentRecordingURL() {
    let exists = FileManager.default.fileExists(atPath: url.path)
    print("File exists: \(exists)")
    
    if let info = audioRecorder.getRecordingInfo(for: url) {
        print("File info: \(info)")
    }
}
```

### Test Audio Player
```swift
let player = AudioPlayerViewModel()
player.play(url: testURL)

// Monitor state
print("Is playing: \(player.isPlaying)")
print("Duration: \(player.duration)")
print("Current: \(player.currentTime)")
```

## 💡 Tips

1. **Playback stops when view disappears** - Resources are automatically cleaned up
2. **Only one recording plays at a time** - Starting new playback stops the previous
3. **Progress updates 10x per second** - Smooth animation (0.1s intervals)
4. **Automatic finish detection** - Player resets when audio completes
5. **Memory efficient** - Streams audio, doesn't load entire file into memory

## 🚀 Performance

- **Lazy loading**: Recordings list loads on demand
- **Efficient updates**: Only active playback updates frequently
- **Resource cleanup**: Timers and players properly disposed
- **Battery friendly**: Minimal background activity

## 📋 Checklist

After implementing, verify:
- [ ] Can see list of recordings
- [ ] Play button starts playback
- [ ] Progress bar animates smoothly
- [ ] Time labels update correctly
- [ ] Pause button works
- [ ] Delete removes files
- [ ] "Delete All" clears everything
- [ ] Playback stops when leaving view
- [ ] Audio is audible through watch speaker
- [ ] UI responds immediately to taps

## 🎉 What's New in Your App

1. ✅ **Full playback system** - Listen to your recordings
2. ✅ **Visual progress tracking** - See playback position
3. ✅ **File management** - Keep or delete recordings
4. ✅ **Integrated UI** - Seamless with main recording interface
5. ✅ **Robust error handling** - Graceful failures with logging
6. ✅ **watchOS optimized** - Designed for small screen

Enjoy your new recording playback feature! 🎧
