//
//  RecordingAccessExamples.swift
//  Ha Reporter Watch App
//
//  Examples of how to access and use recording files
//

import Foundation
import SwiftUI

/*
 
 EXAMPLE 1: Get the current recording file path
 ============================================
 
 Call this after recording (when paused or after upload):
 
 */

func example1_GetCurrentRecordingPath(audioRecorder: AudioRecorderViewModel) {
    if let recordingURL = audioRecorder.getCurrentRecordingURL() {
        print("📄 Recording file location:")
        print("   Full path: \(recordingURL.path)")
        print("   Filename: \(recordingURL.lastPathComponent)")
        print("   Extension: \(recordingURL.pathExtension)")
        
        // You can use this URL to:
        // - Play the audio
        // - Copy it somewhere else
        // - Share it
        // - Process it further
    } else {
        print("No recording available")
    }
}

/*
 
 EXAMPLE 2: Get detailed info about the current recording
 ========================================================
 
 */

func example2_GetRecordingInfo(audioRecorder: AudioRecorderViewModel) {
    guard let recordingURL = audioRecorder.getCurrentRecordingURL() else {
        print("No recording available")
        return
    }
    
    if let info = audioRecorder.getRecordingInfo(for: recordingURL) {
        print("📊 Recording details:")
        print("   Path: \(info["path"] ?? "unknown")")
        print("   Filename: \(info["filename"] ?? "unknown")")
        print("   Size: \(info["size"] ?? 0) bytes")
        print("   Created: \(info["creationDate"] ?? "unknown")")
    }
}

/*
 
 EXAMPLE 3: Save current recording with a custom name
 ===================================================
 
 */

func example3_SaveWithCustomName(audioRecorder: AudioRecorderViewModel) {
    let customName = "my_important_recording_\(Date().timeIntervalSince1970)"
    
    if let savedURL = audioRecorder.saveCurrentRecordingAs(name: customName) {
        print("✅ Recording saved to: \(savedURL.path)")
        
        // The file is now permanently saved and won't be deleted
        // even after resetting the recording
    }
}

/*
 
 EXAMPLE 4: List all saved recordings
 ===================================
 
 */

func example4_ListAllRecordings(audioRecorder: AudioRecorderViewModel) {
    audioRecorder.loadSavedRecordings()
    
    print("📁 You have \(audioRecorder.savedRecordings.count) saved recordings:")
    
    for (index, url) in audioRecorder.savedRecordings.enumerated() {
        print("\(index + 1). \(url.lastPathComponent)")
        
        if let size = try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize {
            print("   Size: \(size) bytes")
        }
    }
}

/*
 
 EXAMPLE 5: Read recording file data
 ==================================
 
 */

func example5_ReadRecordingData(audioRecorder: AudioRecorderViewModel) {
    guard let recordingURL = audioRecorder.getCurrentRecordingURL() else {
        print("No recording available")
        return
    }
    
    do {
        let audioData = try Data(contentsOf: recordingURL)
        print("✅ Read \(audioData.count) bytes of audio data")
        
        // You can now:
        // - Process the audio data
        // - Send it to another API
        // - Save it somewhere else
        // - Analyze it
        
    } catch {
        print("❌ Failed to read audio data: \(error)")
    }
}

/*
 
 EXAMPLE 6: Play the recorded audio
 =================================
 
 */

import AVFoundation

class RecordingPlayer: NSObject, AVAudioPlayerDelegate {
    var audioPlayer: AVAudioPlayer?
    
    func playRecording(url: URL) {
        do {
            // Configure audio session for playback
            try AVAudioSession.sharedInstance().setCategory(.playback)
            try AVAudioSession.sharedInstance().setActive(true)
            
            // Create and play
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.play()
            
            print("▶️ Playing: \(url.lastPathComponent)")
            print("   Duration: \(audioPlayer?.duration ?? 0) seconds")
            
        } catch {
            print("❌ Failed to play audio: \(error)")
        }
    }
    
    func stopPlaying() {
        audioPlayer?.stop()
        print("⏹️ Stopped playback")
    }
    
    // Delegate method called when playback finishes
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        print("✅ Playback finished")
    }
}

/*
 
 EXAMPLE 7: Copy recording to a shared container
 ==============================================
 
 (Useful if you have an iOS companion app)
 
 */

func example7_CopyToSharedContainer(audioRecorder: AudioRecorderViewModel, appGroupID: String = "group.com.yourapp.recordings") {
    guard let recordingURL = audioRecorder.getCurrentRecordingURL() else {
        print("No recording available")
        return
    }
    
    guard let sharedContainer = FileManager.default.containerURL(
        forSecurityApplicationGroupIdentifier: appGroupID
    ) else {
        print("❌ Shared container not available")
        return
    }
    
    let destinationURL = sharedContainer.appendingPathComponent(recordingURL.lastPathComponent)
    
    do {
        // Remove if exists
        try? FileManager.default.removeItem(at: destinationURL)
        
        // Copy to shared location
        try FileManager.default.copyItem(at: recordingURL, to: destinationURL)
        
        print("✅ Copied to shared container:")
        print("   \(destinationURL.path)")
        
    } catch {
        print("❌ Failed to copy: \(error)")
    }
}

/*
 
 EXAMPLE 8: Configure whether to keep recordings after upload
 ===========================================================
 
 By default, recordings are now KEPT after upload.
 You can change this behavior:
 
 */

// In your AudioRecorderViewModel, the property is:
// private var keepRecordingAfterUpload = true

// To delete recordings after upload, you would change it to false
// Or add a method to toggle it:

extension AudioRecorderViewModel {
    func setKeepRecordingsAfterUpload(_ keep: Bool) {
        // Note: You'd need to make keepRecordingAfterUpload non-private
        // keepRecordingAfterUpload = keep
        print(keep ? "💾 Will keep recordings after upload" : "🗑️ Will delete recordings after upload")
    }
}

/*
 
 EXAMPLE 9: Use in SwiftUI View
 =============================
 
 */

struct RecordingAccessExample: View {
    @StateObject private var audioRecorder = AudioRecorderViewModel()
    @State private var showingFiles = false
    
    var body: some View {
        VStack {
            // Your recording UI here
            
            Button("View Saved Recordings") {
                showingFiles = true
            }
            .sheet(isPresented: $showingFiles) {
                RecordingFilesView(audioRecorder: audioRecorder)
            }
            
            // Button to manually save with custom name
            if audioRecorder.hasRecording {
                Button("Save Recording") {
                    let name = "recording_\(Date().timeIntervalSince1970)"
                    if audioRecorder.saveCurrentRecordingAs(name: name) != nil {
                        print("Saved!")
                    }
                }
            }
            
            // Show current recording path
            if let url = audioRecorder.getCurrentRecordingURL() {
                Text("Current: \(url.lastPathComponent)")
                    .font(.caption)
            }
        }
    }
}

/*
 
 QUICK REFERENCE: All Available Methods
 ======================================
 
 audioRecorder.getCurrentRecordingURL() -> URL?
     - Returns the URL of the current recording
 
 audioRecorder.getCurrentRecordingPath() -> String?
     - Returns the file path as a string
 
 audioRecorder.getRecordingInfo(for: URL) -> [String: Any]?
     - Get detailed info about a recording file
 
 audioRecorder.loadSavedRecordings()
     - Refresh the list of saved recordings
 
 audioRecorder.savedRecordings -> [URL]
     - Array of all saved recording URLs
 
 audioRecorder.saveCurrentRecordingAs(name: String) -> URL?
     - Save current recording with a custom name
 
 audioRecorder.deleteRecording(at: URL)
     - Delete a specific recording
 
 audioRecorder.deleteAllRecordings()
     - Delete all saved recordings
 
 */
