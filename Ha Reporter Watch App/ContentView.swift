//
//  ContentView.swift
//  Ha Reporter Watch App
//
//  Created by 蕉泥座人 on 2026/1/27.
//

import SwiftUI
import AVFoundation

struct ContentView: View {
    @StateObject private var audioRecorder = AudioRecorderViewModel()
    @State private var showRecordingsList = false
    @State private var audioLevels: [CGFloat] = .randomLevels(count: 5)
    @State private var crownValue = 0.0
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Spacer()
                
                // Audio visualization
                recordingStateView
                    .frame(height: 110)
                    .padding(.vertical, 5)
                
                Spacer()
                
                // Timer and control button
                timerControlView
                
                // Status messages
                statusView
            }
            .bananaBackground()
            .toolbar(.hidden, for: .navigationBar)
            .onAppear {
                audioRecorder.requestPermission()
                startAudioLevelAnimation()
            }
            .sheet(isPresented: $showRecordingsList) {
                NavigationStack {
                    RecordingFilesView(audioRecorder: audioRecorder)
                }
            }
            // Digital Crown gesture to show recordings list
            .focusable()
            .digitalCrownRotation(detent: $crownValue, from: 0, through: 10, by: 1, sensitivity: .low, isContinuous: false, isHapticFeedbackEnabled: true, onIdle:  {
                // When crown is rotated beyond threshold, show the list
                if crownValue >= 3 {
                    showRecordingsList = true
                    crownValue = 0 // Reset
                }
            })
        }
    }
    
    // MARK: - View Components
    
    @ViewBuilder
    private var recordingStateView: some View {
        if audioRecorder.isRecording {
            HStack(spacing: 6) {
                ForEach(0..<5, id: \.self) { index in
                    AudioBar(level: audioLevels[index])
                }
            }
        } else if audioRecorder.hasRecording {
            pausedStateView
        } else {
            readyStateView
        }
    }
    
    private var pausedStateView: some View {
        VStack(spacing: 6) {
            Text("🍌")
                .font(.system(size: 44))
            Text("Paused")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(BananaTheme.yellow)
        }
    }
    
    private var readyStateView: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [BananaTheme.yellow.opacity(0.2), Color.clear],
                            center: .center,
                            startRadius: 5,
                            endRadius: 35
                        )
                    )
                    .frame(width: 70, height: 70)
                
                Text("🍌🎙️")
                    .font(.system(size: 36))
            }
            Text("Tap to start")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(BananaTheme.yellow)
        }
    }
    
    private var timerControlView: some View {
        HStack(alignment: .center, spacing: 8) {
            HStack(spacing: 2) {
                Text(audioRecorder.formattedTime)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(BananaTheme.yellow)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                if audioRecorder.isRecording {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 7, height: 7)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            stopButton
        }
        .padding(.bottom, 8)
        .padding(.horizontal, 10)
    }
    
    private var stopButton: some View {
        Button(action: audioRecorder.toggleRecording) {
            ZStack {
                Circle()
                    .fill(BananaTheme.yellow.opacity(0.3))
                    .frame(width: 48, height: 48)
                    .blur(radius: 3)
                
                Circle()
                    .fill(BananaTheme.buttonGradient)
                    .frame(width: 44, height: 44)
                    .overlay(
                        Circle().stroke(BananaTheme.yellow.opacity(0.5), lineWidth: 2)
                    )
                
                RoundedRectangle(cornerRadius: 3)
                    .fill(BananaTheme.yellow)
                    .frame(width: 15, height: 15)
                    .shadow(color: BananaTheme.yellow.opacity(0.5), radius: 2)
            }
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.5)
                .onEnded { _ in
                    guard audioRecorder.hasRecording,
                          !audioRecorder.isCurrentRecordingTooSmall() else { return }
                    audioRecorder.stopAndUploadAudio()
                }
        )
        .disabled(audioRecorder.isUploading)
    }
    
    @ViewBuilder
    private var statusView: some View {
        Group {
            if audioRecorder.isUploading {
                uploadingView
            } else if audioRecorder.uploadMessage != nil {
                uploadMessageView
            } else if audioRecorder.hasRecording && audioRecorder.isCurrentRecordingTooSmall() {
                warningView
            } else {
                Color.clear
            }
        }
        .frame(height: 32)
        .padding(.bottom, 8)
    }
    
    private var uploadingView: some View {
        VStack(spacing: 3) {
            ProgressView()
                .progressViewStyle(.circular)
                .tint(BananaTheme.yellow)
                .scaleEffect(0.7)
            HStack(spacing: 2) {
                Text("🍌")
                    .font(.system(size: 11))
                Text("Uploading...")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(BananaTheme.yellow)
            }
        }
    }
    
    private var uploadMessageView: some View {
        HStack(spacing: 3) {
            Image(systemName: audioRecorder.uploadSuccess ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: 11))
            Text(audioRecorder.uploadMessage ?? "")
                .font(.system(size: 11, weight: .medium))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            if audioRecorder.uploadSuccess {
                Text("🎉")
                    .font(.system(size: 11))
            }
        }
        .foregroundStyle(audioRecorder.uploadSuccess ? BananaTheme.yellow : .red)
    }
    
    private var warningView: some View {
        HStack(spacing: 2) {
            Text("⚠️")
                .font(.system(size: 11))
            Text("Record more (min 50 KB)")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.orange)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }
    
    // MARK: - Helpers
    
    private func startAudioLevelAnimation() {
        Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { _ in
            guard audioRecorder.isRecording else { return }
            withAnimation {
                audioLevels = .randomLevels(count: 5)
            }
        }
    }
}

#Preview {
    ContentView()
}
