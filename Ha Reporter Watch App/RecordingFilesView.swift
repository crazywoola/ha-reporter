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
    
    // Banana theme colors
    private let bananaYellow = Color(red: 1.0, green: 0.87, blue: 0.0)
    private let bananaBrown = Color(red: 0.4, green: 0.3, blue: 0.1)
    
    var body: some View {
        ZStack {
            // Banana gradient background
            LinearGradient(
                colors: [
                    Color(red: 0.15, green: 0.12, blue: 0.0),
                    Color.black
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 16) {
                    // Upload status banner
                    if let message = audioRecorder.uploadMessage {
                        HStack(spacing: 4) {
                            if audioRecorder.isUploading {
                                ProgressView()
                                    .scaleEffect(0.6)
                                    .tint(bananaYellow)
                            } else {
                                Image(systemName: audioRecorder.uploadSuccess ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .font(.system(size: 12))
                                    .foregroundStyle(audioRecorder.uploadSuccess ? bananaYellow : .red)
                            }
                            
                            Text(message)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(audioRecorder.uploadSuccess ? bananaYellow : .red)
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill((audioRecorder.uploadSuccess ? bananaYellow : Color.red).opacity(0.15))
                        )
                        .padding(.horizontal, 4)
                    }
                    
                    // Current Recording Section
                    if let currentURL = audioRecorder.getCurrentRecordingURL() {
                        VStack(spacing: 6) {
                            HStack(spacing: 4) {
                                Text("🍌")
                                    .font(.system(size: 12))
                                Text("Current")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(bananaYellow)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 4)
                            
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
                                isUploading: audioRecorder.isUploading,
                                isCurrent: true
                            )
                        }
                    }
                    
                    // Saved Recordings Section
                    if !audioRecorder.savedRecordings.isEmpty {
                        VStack(spacing: 6) {
                            HStack(spacing: 4) {
                                Text("📁")
                                    .font(.system(size: 12))
                                Text("Saved")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(bananaYellow.opacity(0.8))
                                Spacer()
                                Text("\(audioRecorder.savedRecordings.count)")
                                    .font(.system(size: 10, weight: .bold, design: .rounded))
                                    .foregroundStyle(bananaYellow)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(
                                        Capsule()
                                            .fill(bananaYellow.opacity(0.2))
                                    )
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 4)
                            
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
                                    isUploading: audioRecorder.isUploading,
                                    isCurrent: false
                                )
                            }
                        }
                    }
                    
                    // Empty state
                    if audioRecorder.savedRecordings.isEmpty && audioRecorder.getCurrentRecordingURL() == nil {
                        VStack(spacing: 8) {
                            Text("🍌")
                                .font(.system(size: 40))
                                .opacity(0.5)
                            Text("No recordings yet")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(bananaYellow.opacity(0.6))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    }
                    
                    // Delete All Button
                    if !audioRecorder.savedRecordings.isEmpty {
                        Button(role: .destructive) {
                            audioPlayer.stop()
                            audioRecorder.deleteAllRecordings()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "trash.fill")
                                    .font(.system(size: 10))
                                Text("Clear All")
                                    .font(.system(size: 11, weight: .semibold))
                            }
                            .foregroundStyle(.red.opacity(0.9))
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.red.opacity(0.15))
                            )
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 8)
                    }
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 4)
            }
        }
        .navigationTitle("Recordings")
        .navigationBarTitleDisplayMode(.inline)
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
    let isCurrent: Bool
    
    // Banana theme colors
    private let bananaYellow = Color(red: 1.0, green: 0.87, blue: 0.0)
    private let bananaBrown = Color(red: 0.4, green: 0.3, blue: 0.1)
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                // Play/Pause button - consistent size
                Button(action: onPlayPause) {
                    ZStack {
                        Circle()
                            .fill(isPlaying ? bananaYellow.opacity(0.2) : bananaBrown.opacity(0.3))
                            .frame(width: 32, height: 32)
                        
                        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(isPlaying ? bananaYellow : bananaYellow.opacity(0.8))
                    }
                }
                .buttonStyle(.plain)
                .disabled(isUploading)
                
                // File info
                VStack(spacing: 2) {
                    // Duration
                    if let duration = duration {
                        Text(formatTime(duration))
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(bananaYellow)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        Text("--:--")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(bananaYellow.opacity(0.5))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    // File size and date
                    HStack(spacing: 4) {
                        if let size = try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                            Text(formatFileSize(size))
                                .font(.system(size: 9, weight: .medium))
                                .foregroundStyle(.gray)
                        }
                        
                        Text("•")
                            .font(.system(size: 8))
                            .foregroundStyle(.gray.opacity(0.5))
                        
                        Text(extractTime(from: url.lastPathComponent))
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(.gray)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                Spacer()
                
                // Upload button - consistent size
                Button(action: onUpload) {
                    ZStack {
                        Circle()
                            .fill(bananaYellow.opacity(0.15))
                            .frame(width: 28, height: 28)
                        
                        if isUploading {
                            ProgressView()
                                .scaleEffect(0.6)
                                .tint(bananaYellow)
                        } else {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(bananaYellow.opacity(0.9))
                        }
                    }
                }
                .buttonStyle(.plain)
                .disabled(isUploading)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            
            // Progress bar (if playing)
            if isPlaying || currentTime > 0 {
                VStack(spacing: 3) {
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // Background
                            RoundedRectangle(cornerRadius: 1.5)
                                .fill(bananaBrown.opacity(0.3))
                                .frame(height: 3)
                            
                            // Progress
                            if let duration = duration, duration > 0 {
                                RoundedRectangle(cornerRadius: 1.5)
                                    .fill(
                                        LinearGradient(
                                            colors: [bananaYellow, bananaYellow.opacity(0.8)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: geometry.size.width * CGFloat(currentTime / duration), height: 3)
                            }
                        }
                    }
                    .frame(height: 3)
                    
                    // Time labels
                    HStack {
                        Text(formatTime(currentTime))
                        Spacer()
                        if let duration = duration {
                            Text(formatTime(duration - currentTime))
                        }
                    }
                    .font(.system(size: 8, weight: .medium, design: .rounded))
                    .foregroundStyle(bananaYellow.opacity(0.7))
                }
                .padding(.horizontal, 10)
                .padding(.bottom, 6)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    isCurrent 
                        ? LinearGradient(
                            colors: [
                                bananaYellow.opacity(0.12),
                                bananaYellow.opacity(0.08)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        : LinearGradient(
                            colors: [
                                bananaBrown.opacity(0.15),
                                bananaBrown.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            isPlaying ? bananaYellow.opacity(0.4) : Color.clear,
                            lineWidth: 1.5
                        )
                )
        )
        .padding(.horizontal, 4)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            if let onDelete = onDelete {
                Button(role: .destructive, action: onDelete) {
                    Label("Delete", systemImage: "trash.fill")
                }
            }
        }
    }
    
    private func formatFileSize(_ bytes: Int) -> String {
        let kb = Double(bytes) / 1024
        if kb < 1024 {
            return String(format: "%.0f KB", kb)
        }
        let mb = kb / 1024
        return String(format: "%.1f MB", mb)
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private func extractTime(from filename: String) -> String {
        // Extract time from filename like "2024-01-28_14-30-45.m4a"
        let components = filename.replacingOccurrences(of: ".m4a", with: "").split(separator: "_")
        if components.count >= 2 {
            let timeString = String(components[1])
            let timeParts = timeString.split(separator: "-")
            if timeParts.count == 3 {
                return "\(timeParts[0]):\(timeParts[1])"
            }
        }
        return "Recording"
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
