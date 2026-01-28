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
    @State private var audioLevels: [CGFloat] = [0.3, 0.5, 0.4, 0.6, 0.5]
    @State private var crownValue = 0.0
    
    // Banana theme colors
    private let bananaYellow = Color(red: 1.0, green: 0.87, blue: 0.0)
    private let bananaBright = Color(red: 0.8, green: 0.95, blue: 0.3)
    private let bananaGreen = Color(red: 0.6, green: 0.8, blue: 0.2)
    private let bananaBrown = Color(red: 0.4, green: 0.3, blue: 0.1)
    
    var body: some View {
        NavigationStack {
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
                
                VStack(spacing: 0) {
                    Spacer()
                    
                    // Audio level bars - banana themed
                    if audioRecorder.isRecording {
                        VStack(spacing: 6) {
                            // Animated banana bunch
                            HStack(spacing: 6) {
                                ForEach(0..<5, id: \.self) { index in
                                    ZStack {
                                        // Banana shape
                                        Capsule()
                                            .fill(
                                                LinearGradient(
                                                    colors: [bananaYellow, bananaBright],
                                                    startPoint: .top,
                                                    endPoint: .bottom
                                                )
                                            )
                                            .frame(width: 10, height: audioLevels[index] * 55 + 20)
                                            .shadow(color: bananaYellow.opacity(0.3), radius: 3)
                                            .animation(.easeInOut(duration: 0.3), value: audioLevels[index])
                                        
                                        // Brown tip
                                        Circle()
                                            .fill(bananaBrown)
                                            .frame(width: 4, height: 4)
                                            .offset(y: -(audioLevels[index] * 55 + 20) / 2)
                                            .animation(.easeInOut(duration: 0.3), value: audioLevels[index])
                                    }
                                }
                            }
                        }
                        .frame(height: 110)
                        .padding(.vertical, 5)
                    } else if audioRecorder.hasRecording {
                        // Paused state - show banana bunch
                        VStack(spacing: 6) {
                            Text("🍌")
                                .font(.system(size: 44))
                            Text("Paused")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(bananaYellow)
                        }
                        .frame(height: 110)
                        .padding(.vertical, 5)
                    } else {
                        // Ready state - show banana with microphone
                        VStack(spacing: 6) {
                            ZStack {
                                Circle()
                                    .fill(
                                        RadialGradient(
                                            colors: [bananaYellow.opacity(0.2), Color.clear],
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
                                .foregroundStyle(bananaYellow)
                        }
                        .frame(height: 110)
                        .padding(.vertical, 5)
                    }
                    
                    Spacer()
                    
                    // Bottom section with timer and button
                    HStack(alignment: .center, spacing: 8) {
                        // Timer with banana theme
                        HStack(spacing: 2) {
                            Text(audioRecorder.formattedTime)
                                .font(.system(size: 26, weight: .bold, design: .rounded))
                                .monospacedDigit()
                                .foregroundStyle(bananaYellow)
                                .minimumScaleFactor(0.6)
                                .lineLimit(1)
                            if audioRecorder.isRecording {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 7, height: 7)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // Banana-themed stop button
                        Button(action: {
                            handleButtonTap()
                        }) {
                            ZStack {
                                // Outer glow
                                Circle()
                                    .fill(bananaYellow.opacity(0.3))
                                    .frame(width: 48, height: 48)
                                    .blur(radius: 3)
                                
                                // Button background
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color(red: 0.45, green: 0.4, blue: 0.15),
                                                Color(red: 0.3, green: 0.25, blue: 0.1)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 44, height: 44)
                                    .overlay(
                                        Circle()
                                            .stroke(bananaYellow.opacity(0.5), lineWidth: 2)
                                    )
                                
                                // Stop icon (banana styled)
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(bananaYellow)
                                    .frame(width: 15, height: 15)
                                    .shadow(color: bananaYellow.opacity(0.5), radius: 2)
                            }
                        }
                        .buttonStyle(.plain)
                        .simultaneousGesture(
                            LongPressGesture(minimumDuration: 0.5)
                                .onEnded { _ in
                                    if audioRecorder.hasRecording && !audioRecorder.isCurrentRecordingTooSmall() {
                                        audioRecorder.stopAndUploadAudio()
                                    }
                                }
                        )
                        .disabled(audioRecorder.isUploading)
                    }
                    .padding(.bottom, 8)
                    .padding(.horizontal, 10)
                    
                    // Status messages with banana theme
                    if audioRecorder.isUploading {
                        VStack(spacing: 3) {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(bananaYellow)
                                .scaleEffect(0.7)
                            HStack(spacing: 2) {
                                Text("🍌")
                                    .font(.system(size: 11))
                                Text("Uploading...")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(bananaYellow)
                            }
                        }
                        .frame(height: 32)
                        .padding(.bottom, 8)
                    } else if let message = audioRecorder.uploadMessage {
                        HStack(spacing: 3) {
                            Image(systemName: audioRecorder.uploadSuccess ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .font(.system(size: 11))
                            Text(message)
                                .font(.system(size: 11, weight: .medium))
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                            if audioRecorder.uploadSuccess {
                                Text("🎉")
                                    .font(.system(size: 11))
                            }
                        }
                        .foregroundStyle(audioRecorder.uploadSuccess ? bananaYellow : .red)
                        .frame(height: 32)
                        .padding(.bottom, 8)
                    } else if audioRecorder.hasRecording && audioRecorder.isCurrentRecordingTooSmall() {
                        HStack(spacing: 2) {
                            Text("⚠️")
                                .font(.system(size: 11))
                            Text("Record more (min 50 KB)")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(.orange)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        .frame(height: 32)
                        .padding(.bottom, 8)
                    } else {
                        Color.clear
                            .frame(height: 32)
                            .padding(.bottom, 8)
                    }
                }
            }
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
    
    private func handleButtonTap() {
        if !audioRecorder.hasRecording {
            // Start recording
            audioRecorder.toggleRecording()
        } else {
            // Toggle pause/resume
            audioRecorder.toggleRecording()
        }
    }
    
    private func startAudioLevelAnimation() {
        Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { _ in
            if audioRecorder.isRecording {
                withAnimation {
                    audioLevels = (0..<5).map { _ in CGFloat.random(in: 0.3...1.0) }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
