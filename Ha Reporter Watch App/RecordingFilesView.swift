//
//  RecordingFilesView.swift
//  Ha Reporter Watch App
//
//  Created on 2026/1/28.
//

import SwiftUI
import AVFoundation
import Combine

/// View to display and manage saved recordings with playback
struct RecordingFilesView: View {
    @ObservedObject var audioRecorder: AudioRecorderViewModel
    @StateObject private var audioPlayer = AudioPlayerViewModel()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Upload status banner
                if let message = audioRecorder.uploadMessage {
                    HStack(spacing: 6) {
                        if audioRecorder.isUploading {
                            ProgressView()
                                .scaleEffect(0.7)
                        } else {
                            Image(systemName: audioRecorder.uploadSuccess ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundStyle(audioRecorder.uploadSuccess ? .green : .red)
                        }
                        
                        Text(message)
                            .font(.caption2)
                            .foregroundStyle(audioRecorder.uploadSuccess ? .green : .red)
                    }
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill((audioRecorder.uploadSuccess ? Color.green : Color.red).opacity(0.15))
                    )
                    .padding(.horizontal)
                }
                
                // Current Recording Section
                if let currentURL = audioRecorder.getCurrentRecordingURL() {
                    VStack(spacing: 8) {
                        Text("Current Recording")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        RecordingRow(
                            url: currentURL,
                            isPlaying: audioPlayer.isPlaying && audioPlayer.currentURL == currentURL,
                            currentTime: audioPlayer.currentURL == currentURL ? audioPlayer.currentTime : 0,
                            duration: audioPlayer.currentURL == currentURL ? audioPlayer.duration : nil,
                            onPlayPause: {
                                handlePlayPause(url: currentURL)
                            },
                            onUpload: {
                                audioRecorder.uploadAudioFile(currentURL)
                            },
                            onDelete: nil,
                            isUploading: audioRecorder.isUploading
                        )
                    }
                    .padding(.horizontal)
                    
                    Divider()
                        .padding(.vertical, 4)
                }
                
                // Saved Recordings Section
                VStack(spacing: 8) {
                    HStack {
                        Text("Saved Recordings")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Spacer()
                        
                        Text("\(audioRecorder.savedRecordings.count)")
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }
                    .padding(.horizontal)
                    
                    if audioRecorder.savedRecordings.isEmpty {
                        Text("No saved recordings")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding()
                    } else {
                        ForEach(audioRecorder.savedRecordings, id: \.self) { url in
                            RecordingRow(
                                url: url,
                                isPlaying: audioPlayer.isPlaying && audioPlayer.currentURL == url,
                                currentTime: audioPlayer.currentURL == url ? audioPlayer.currentTime : 0,
                                duration: audioPlayer.currentURL == url ? audioPlayer.duration : nil,
                                onPlayPause: {
                                    handlePlayPause(url: url)
                                },
                                onUpload: {
                                    audioRecorder.uploadAudioFile(url)
                                },
                                onDelete: {
                                    deleteRecording(url: url)
                                },
                                isUploading: audioRecorder.isUploading
                            )
                        }
                    }
                }
                
                // Delete All Button
                if !audioRecorder.savedRecordings.isEmpty {
                    Button(role: .destructive) {
                        audioPlayer.stop()
                        audioRecorder.deleteAllRecordings()
                    } label: {
                        Label("Delete All", systemImage: "trash")
                            .font(.caption)
                    }
                    .padding(.top, 8)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Recordings")
        .onAppear {
            audioRecorder.loadSavedRecordings()
        }
        .onDisappear {
            audioPlayer.stop()
        }
    }
    
    private func handlePlayPause(url: URL) {
        if audioPlayer.currentURL == url && audioPlayer.isPlaying {
            audioPlayer.pause()
        } else {
            audioPlayer.play(url: url)
        }
    }
    
    private func deleteRecording(url: URL) {
        if audioPlayer.currentURL == url {
            audioPlayer.stop()
        }
        audioRecorder.deleteRecording(at: url)
    }
}

// MARK: - Recording Row View
struct RecordingRow: View {
    let url: URL
    let isPlaying: Bool
    let currentTime: TimeInterval
    let duration: TimeInterval?
    let onPlayPause: () -> Void
    let onUpload: () -> Void
    let onDelete: (() -> Void)?
    let isUploading: Bool
    
    var body: some View {
        VStack(spacing: 6) {
            // File name
            Text(url.lastPathComponent)
                .font(.caption)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // File info
            HStack(spacing: 8) {
                if let size = try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                    Text(formatFileSize(size))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                
                if let duration = duration {
                    Text(formatTime(duration))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Playback controls
            HStack(spacing: 12) {
                // Play/Pause button
                Button(action: onPlayPause) {
                    Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.title2)
                        .foregroundStyle(isPlaying ? .red : .blue)
                }
                .buttonStyle(.plain)
                .disabled(isUploading)
                
                // Progress bar (if playing)
                if isPlaying || currentTime > 0 {
                    VStack(spacing: 2) {
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                // Background
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(.gray.opacity(0.3))
                                    .frame(height: 4)
                                
                                // Progress
                                if let duration = duration, duration > 0 {
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(.blue)
                                        .frame(width: geometry.size.width * CGFloat(currentTime / duration), height: 4)
                                }
                            }
                        }
                        .frame(height: 4)
                        
                        // Time labels
                        HStack {
                            Text(formatTime(currentTime))
                            Spacer()
                            if let duration = duration {
                                Text(formatTime(duration))
                            }
                        }
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                // Upload button
                Button(action: onUpload) {
                    if isUploading {
                        ProgressView()
                            .scaleEffect(0.7)
                    } else {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.green)
                    }
                }
                .buttonStyle(.plain)
                .disabled(isUploading)
                
                // Delete button
                if let onDelete = onDelete {
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(.plain)
                    .disabled(isUploading)
                }
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isPlaying ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
        )
        .padding(.horizontal)
    }
    
    private func formatFileSize(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Audio Player View Model
@MainActor
class AudioPlayerViewModel: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published var isPlaying = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var currentURL: URL?
    
    private var audioPlayer: AVAudioPlayer?
    private var timer: Timer?
    
    func play(url: URL) {
        print("▶️ Playing: \(url.lastPathComponent)")
        
        // Stop current playback if any
        stop()
        
        do {
            // Configure audio session for playback
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)
            
            // Create and configure player
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            
            duration = audioPlayer?.duration ?? 0
            currentURL = url
            
            // Start playback
            audioPlayer?.play()
            isPlaying = true
            startTimer()
            
            print("   Duration: \(duration) seconds")
            
        } catch {
            print("❌ Failed to play audio: \(error)")
        }
    }
    
    func pause() {
        print("⏸️ Paused playback")
        audioPlayer?.pause()
        isPlaying = false
        stopTimer()
    }
    
    func stop() {
        print("⏹️ Stopped playback")
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
        currentTime = 0
        duration = 0
        currentURL = nil
        stopTimer()
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                self.currentTime = self.audioPlayer?.currentTime ?? 0
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    // MARK: - AVAudioPlayerDelegate
    
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            print("✅ Playback finished")
            self.stop()
        }
    }
    
    nonisolated func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        Task { @MainActor in
            print("❌ Playback error: \(error?.localizedDescription ?? "unknown")")
            self.stop()
        }
    }
}

#Preview {
    NavigationStack {
        RecordingFilesView(audioRecorder: AudioRecorderViewModel())
    }
}
