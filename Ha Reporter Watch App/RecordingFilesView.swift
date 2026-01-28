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
                VStack(spacing: 16) {
                // Upload status banner
                if let message = audioRecorder.uploadMessage {
                        uploadBanner(message: message)
                }
                
                // Current Recording Section
                if let currentURL = audioRecorder.getCurrentRecordingURL() {
                        currentRecordingSection(url: currentURL)
                }
                
                // Saved Recordings Section
                    if !audioRecorder.savedRecordings.isEmpty {
                        savedRecordingsSection
                    }
                    
                    // Empty state
                    if audioRecorder.savedRecordings.isEmpty && audioRecorder.getCurrentRecordingURL() == nil {
                        emptyStateView
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
        .bananaBackground()
        .navigationTitle("Recordings")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: audioRecorder.loadSavedRecordings)
        .onDisappear(perform: audioPlayer.stop)
    }
    
    // MARK: - View Components
    
    private func uploadBanner(message: String) -> some View {
        let isSuccess = audioRecorder.uploadSuccess
        let color = isSuccess ? BananaTheme.yellow : Color.red
        
        return HStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 32, height: 32)
                
                if audioRecorder.isUploading {
                    ProgressView()
                        .scaleEffect(0.6)
                        .tint(BananaTheme.yellow)
                } else {
                    Image(systemName: isSuccess ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(color)
                }
            }
            
            Text(message)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(color)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 12).fill(color.opacity(0.15)))
        .padding(.horizontal, 4)
    }
    
    private func currentRecordingSection(url: URL) -> some View {
        VStack(spacing: 6) {
            SectionHeader(emoji: "🍌", title: "Current")
                .padding(.horizontal, 4)
            
            recordingRow(for: url, isCurrent: true)
        }
    }
    
    private var savedRecordingsSection: some View {
        VStack(spacing: 6) {
            SectionHeader(emoji: "📁", title: "Saved", count: audioRecorder.savedRecordings.count)
                .padding(.horizontal, 4)
            
            ForEach(audioRecorder.savedRecordings, id: \.self) { url in
                recordingRow(for: url, isCurrent: false)
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 8) {
            Text("🍌")
                .font(.system(size: 40))
                .opacity(0.5)
            Text("No recordings yet")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(BananaTheme.yellow.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    private func recordingRow(for url: URL, isCurrent: Bool) -> some View {
        RecordingRow(
            url: url,
            isPlaying: audioPlayer.isPlaying && audioPlayer.currentURL == url,
            currentTime: audioPlayer.currentURL == url ? audioPlayer.currentTime : 0,
            duration: audioPlayer.currentURL == url ? audioPlayer.duration : nil,
            onPlayPause: { handlePlayPause(url: url) },
            onUpload: { audioRecorder.uploadAudioFile(url) },
            onDelete: isCurrent ? nil : { deleteRecording(url: url) },
            isUploading: audioRecorder.isUploading,
            isCurrent: isCurrent
        )
    }
    
    // MARK: - Actions
    
    private func handlePlayPause(url: URL) {
        audioPlayer.currentURL == url && audioPlayer.isPlaying
            ? audioPlayer.pause()
            : audioPlayer.play(url: url)
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
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                playPauseButton
                fileInfoView
                Spacer()
                uploadButton
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            
            if isPlaying || currentTime > 0, let duration = duration {
                AudioProgressBar(currentTime: currentTime, duration: duration)
                    .padding(.horizontal, 10)
                    .padding(.bottom, 6)
            }
        }
        .background(cardBackground)
        .padding(.horizontal, 4)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            if let onDelete = onDelete {
                Button(role: .destructive, action: onDelete) {
                    Label("Delete", systemImage: "trash.fill")
                }
            }
        }
    }
    
    // MARK: - View Components
    
    private var playPauseButton: some View {
        CircularIconButton(
            icon: isPlaying ? "pause.fill" : "play.fill",
            size: 32,
            backgroundColor: isPlaying ? BananaTheme.yellow.opacity(0.2) : BananaTheme.brown.opacity(0.3),
            foregroundColor: isPlaying ? BananaTheme.yellow : BananaTheme.yellow.opacity(0.8),
            isDisabled: isUploading,
            action: onPlayPause
        )
    }
    
    private var fileInfoView: some View {
        VStack(spacing: 2) {
            Text(duration.map { TimeFormatter.formatCompact($0) } ?? "--:--")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(BananaTheme.yellow.opacity(duration == nil ? 0.5 : 1.0))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            if let size = url.fileSize {
                Text(FileSizeFormatter.format(size))
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.gray)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
    
    private var uploadButton: some View {
        CircularIconButton(
            icon: "arrow.up.circle.fill",
            size: 28,
            backgroundColor: BananaTheme.yellow.opacity(0.15),
            foregroundColor: BananaTheme.yellow.opacity(0.9),
            isDisabled: isUploading
        ) {
            if !isUploading {
                onUpload()
            }
        }
        .overlay(
            isUploading
                ? ProgressView()
                    .scaleEffect(0.6)
                    .tint(BananaTheme.yellow)
                : nil
        )
    }
    
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(BananaTheme.cardGradient(isCurrent: isCurrent))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isPlaying ? BananaTheme.yellow.opacity(0.4) : Color.clear, lineWidth: 1.5)
            )
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
