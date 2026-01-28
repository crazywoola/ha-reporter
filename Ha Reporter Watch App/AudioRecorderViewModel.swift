//
//  AudioRecorderViewModel.swift
//  Ha Reporter Watch App
//
//  Created by 蕉泥座人 on 2026/1/27.
//

import Foundation
import AVFoundation
import Combine
import WatchKit

@MainActor
class AudioRecorderViewModel: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var recordingTime: TimeInterval = 0
    @Published var hasRecording = false
    @Published var isUploading = false
    @Published var uploadMessage: String?
    @Published var uploadSuccess = false
    @Published var savedRecordings: [URL] = []
    
    private var audioRecorder: AVAudioRecorder?
    private var timer: Timer?
    private var recordingURL: URL?
    private var keepRecordingAfterUpload = true // Set to true to keep files
    
    private let apiKey = "app-ucSda6dZimrDkoYlD51IpKIS"
    private let uploadEndpoint = "https://api.dify.ai/v1/files/upload"
    private let workflowEndpoint = "https://api.dify.ai/v1/workflows/run"
    
    var formattedTime: String {
        let minutes = Int(recordingTime) / 60
        let seconds = Int(recordingTime) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var statusText: String {
        if isUploading {
            return "Uploading..."
        } else if isRecording {
            return "Recording"
        } else if hasRecording {
            return "Paused"
        } else {
            return "Ready"
        }
    }
    
    override init() {
        super.init()
        setupAudioSession()
        cleanupSmallRecordings() // Clean up small files on startup
        loadSavedRecordings()
    }
    
    func requestPermission() {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            if !granted {
                DispatchQueue.main.async {
                    self.uploadMessage = "Microphone access denied"
                }
            }
        }
    }
    
    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .default, options: [])
            try session.setActive(true)
            print("✅ Audio session setup successfully")
            print("   Category: \(session.category)")
            print("   Available inputs: \(session.availableInputs?.map { $0.portName } ?? [])")
        } catch {
            print("❌ Failed to setup audio session: \(error)")
        }
    }
    
    func toggleRecording() {
        if isRecording {
            pauseRecording()
        } else {
            startRecording()
        }
    }
    
    private func startRecording() {
        // Clear previous messages
        uploadMessage = nil
        uploadSuccess = false
        
        // If we already have a recorder (resuming from pause), just resume it
        if let recorder = audioRecorder, hasRecording {
            print("▶️ Resuming existing recording")
            if recorder.record() {
                isRecording = true
                startTimer()
                print("✅ Recording resumed successfully")
                print("   Current time: \(recorder.currentTime)s")
            } else {
                print("❌ Failed to resume recording")
                uploadMessage = "Failed to resume recording"
            }
            return
        }
        
        // Otherwise, start a new recording
        let audioFilename = getDocumentsDirectory().appendingPathComponent("recording_\(Date().timeIntervalSince1970).m4a")
        recordingURL = audioFilename
        
        // Optimized settings for watchOS
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 16000.0, // Lower sample rate for watchOS
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue,
            AVEncoderBitRateKey: 32000 // Explicit bit rate
        ]
        
        print("🎙️ Starting new recording with settings:")
        print("   File: \(audioFilename.lastPathComponent)")
        print("   Sample rate: 16000 Hz")
        print("   Channels: 1 (mono)")
        print("   Quality: medium")
        print("   Bit rate: 32000")
        
        do {
            // Reactivate audio session before recording
            let session = AVAudioSession.sharedInstance()
            try session.setActive(true)
            
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.isMeteringEnabled = true
            
            // Prepare and check if ready
            if audioRecorder?.prepareToRecord() == true {
                print("   Recorder prepared successfully")
            } else {
                print("⚠️ Recorder prepare returned false")
            }
            
            if audioRecorder?.record() == true {
                isRecording = true
                hasRecording = true
                startTimer()
                print("✅ Recording started successfully")
            } else {
                print("❌ Recording failed to start")
                uploadMessage = "Recording failed to start"
            }
        } catch {
            print("❌ Failed to start recording: \(error)")
            print("   Error details: \(error.localizedDescription)")
            uploadMessage = "Recording failed: \(error.localizedDescription)"
        }
    }
    
    private func pauseRecording() {
        audioRecorder?.pause()
        isRecording = false
        stopTimer()
        
        print("⏸️ Recording paused")
        if let recorder = audioRecorder {
            print("   Current time: \(recorder.currentTime)s")
            print("   Is recording: \(recorder.isRecording)")
            
            // Check metering levels to verify audio is being captured
            recorder.updateMeters()
            let averagePower = recorder.averagePower(forChannel: 0)
            let peakPower = recorder.peakPower(forChannel: 0)
            print("   Average power: \(averagePower) dB")
            print("   Peak power: \(peakPower) dB")
            
            if averagePower < -60 {
                print("⚠️ Warning: Very low audio levels detected. Microphone may not be working.")
            }
        }
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                self.recordingTime = self.audioRecorder?.currentTime ?? 0
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    // MARK: - Recording File Management
    
    /// Load all saved recordings from the documents directory
    func loadSavedRecordings() {
        do {
            let documentsURL = getDocumentsDirectory()
            let fileURLs = try FileManager.default.contentsOfDirectory(
                at: documentsURL,
                includingPropertiesForKeys: [.creationDateKey, .fileSizeKey],
                options: .skipsHiddenFiles
            )
            
            let minFileSize = 50 * 1024 // 50KB minimum to show in list
            
            // Filter for audio files and exclude current recording
            savedRecordings = fileURLs.filter { url in
                // Must be an audio file
                guard ["wav", "m4a", "mp3", "aac"].contains(url.pathExtension.lowercased()) else {
                    return false
                }
                
                // Skip current recording (will be shown separately)
                if url == recordingURL {
                    return false
                }
                
                // Check file size - exclude very small files
                if let size = try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                    if size < minFileSize {
                        print("⚠️ Skipping small file: \(url.lastPathComponent) (\(size) bytes)")
                        return false
                    }
                }
                
                return true
            }.sorted { url1, url2 in
                // Sort by creation date, newest first
                let date1 = (try? url1.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast
                let date2 = (try? url2.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast
                return date1 > date2
            }
            
            print("📁 Loaded \(savedRecordings.count) saved recordings")
            for url in savedRecordings {
                if let size = try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                    print("   - \(url.lastPathComponent) (\(size) bytes / \(Double(size) / 1024.0) KB)")
                }
            }
        } catch {
            print("❌ Error loading saved recordings: \(error)")
        }
    }
    
    /// Get the current recording file URL (if exists)
    func getCurrentRecordingURL() -> URL? {
        print("📄 Current recording URL: \(recordingURL?.path ?? "none")")
        return recordingURL
    }
    
    /// Get the size of the current recording in bytes
    func getCurrentRecordingSize() -> Int? {
        guard let audioURL = recordingURL else { return nil }
        
        guard let fileSize = try? FileManager.default.attributesOfItem(atPath: audioURL.path)[.size] as? Int else {
            return nil
        }
        
        return fileSize
    }
    
    /// Check if current recording is too small to upload
    func isCurrentRecordingTooSmall() -> Bool {
        guard let fileSize = getCurrentRecordingSize() else { return true }
        
        let minFileSize = 50 * 1024 // 50KB
        return fileSize < minFileSize
    }
    
    /// Get the path to the current recording
    func getCurrentRecordingPath() -> String? {
        return recordingURL?.path
    }
    
    /// Delete a specific recording
    func deleteRecording(at url: URL) {
        do {
            try FileManager.default.removeItem(at: url)
            print("🗑️ Deleted recording: \(url.lastPathComponent)")
            loadSavedRecordings()
        } catch {
            print("❌ Failed to delete recording: \(error)")
        }
    }
    
    /// Delete all recordings
    func deleteAllRecordings() {
        for url in savedRecordings {
            try? FileManager.default.removeItem(at: url)
        }
        savedRecordings.removeAll()
        print("🗑️ Deleted all recordings")
    }
    
    /// Clean up small or incomplete recordings
    func cleanupSmallRecordings() {
        do {
            let documentsURL = getDocumentsDirectory()
            let fileURLs = try FileManager.default.contentsOfDirectory(
                at: documentsURL,
                includingPropertiesForKeys: [.fileSizeKey],
                options: .skipsHiddenFiles
            )
            
            let minFileSize = 50 * 1024 // 50KB
            var deletedCount = 0
            
            for url in fileURLs {
                // Only process audio files
                guard ["wav", "m4a", "mp3", "aac"].contains(url.pathExtension.lowercased()) else {
                    continue
                }
                
                // Skip current recording
                if url == recordingURL {
                    continue
                }
                
                // Delete small files
                if let size = try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize, size < minFileSize {
                    try? FileManager.default.removeItem(at: url)
                    print("🗑️ Cleaned up small file: \(url.lastPathComponent) (\(size) bytes)")
                    deletedCount += 1
                }
            }
            
            if deletedCount > 0 {
                print("✅ Cleaned up \(deletedCount) small recordings")
                loadSavedRecordings()
            }
        } catch {
            print("❌ Error during cleanup: \(error)")
        }
    }
    
    /// Copy current recording to a permanent location with a custom name
    func saveCurrentRecordingAs(name: String) -> URL? {
        guard let currentURL = recordingURL else {
            print("⚠️ No current recording to save")
            return nil
        }
        
        let fileExtension = currentURL.pathExtension
        let permanentURL = getDocumentsDirectory().appendingPathComponent("\(name).\(fileExtension)")
        
        do {
            // Copy instead of move to preserve the original
            try FileManager.default.copyItem(at: currentURL, to: permanentURL)
            print("💾 Saved recording as: \(permanentURL.lastPathComponent)")
            loadSavedRecordings()
            return permanentURL
        } catch {
            print("❌ Failed to save recording: \(error)")
            return nil
        }
    }
    
    /// Get file info for debugging
    func getRecordingInfo(for url: URL) -> [String: Any]? {
        guard FileManager.default.fileExists(atPath: url.path) else {
            print("⚠️ File does not exist: \(url.path)")
            return nil
        }
        
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            let resourceValues = try url.resourceValues(forKeys: [.creationDateKey, .contentModificationDateKey])
            
            let info: [String: Any] = [
                "path": url.path,
                "filename": url.lastPathComponent,
                "extension": url.pathExtension,
                "size": attributes[.size] as? Int ?? 0,
                "creationDate": resourceValues.creationDate ?? "unknown",
                "modificationDate": resourceValues.contentModificationDate ?? "unknown"
            ]
            
            print("ℹ️ Recording info:")
            for (key, value) in info {
                print("   \(key): \(value)")
            }
            
            return info
        } catch {
            print("❌ Failed to get recording info: \(error)")
            return nil
        }
    }
    
    func uploadAudio() {
        guard let audioURL = recordingURL, !isUploading else {
            print("⚠️ Upload blocked: audioURL=\(recordingURL?.path ?? "nil"), isUploading=\(isUploading)")
            return
        }
        
        // Must stop recording completely to finalize the file
        if let recorder = audioRecorder, recorder.isRecording {
            pauseRecording()
        }
        
        // Stop the recorder to finalize the audio file
        if let recorder = audioRecorder {
            recorder.stop()
            print("🛑 Stopped recorder to finalize audio file before upload")
        }
        
        uploadAudioFile(audioURL, resetAfterSuccess: true)
    }
    
    /// Stop recording and upload immediately (for long press gesture)
    func stopAndUploadAudio() {
        guard let audioURL = recordingURL, !isUploading else {
            print("⚠️ Upload blocked: audioURL=\(recordingURL?.path ?? "nil"), isUploading=\(isUploading)")
            return
        }
        
        // Stop recording if active
        if let recorder = audioRecorder, recorder.isRecording {
            pauseRecording()
        }
        
        // Stop the recorder to finalize the audio file
        if let recorder = audioRecorder {
            recorder.stop()
            print("🛑 Stopped recorder to finalize audio file before upload")
        }
        
        uploadAudioFile(audioURL, resetAfterSuccess: true)
    }
    
    /// Upload any audio file (current recording or saved recording)
    func uploadAudioFile(_ audioURL: URL, resetAfterSuccess: Bool = false) {
        guard !isUploading else {
            print("⚠️ Upload already in progress")
            return
        }
        
        // If uploading the current recording, must stop it first to finalize the file
        if audioURL == recordingURL {
            if let recorder = audioRecorder, recorder.isRecording {
                pauseRecording()
            }
            
            if let recorder = audioRecorder {
                recorder.stop()
                print("🛑 Stopped recorder to finalize audio file before upload")
            }
        }
        
        // Check file size before uploading
        guard let fileSize = try? FileManager.default.attributesOfItem(atPath: audioURL.path)[.size] as? Int else {
            print("❌ Cannot determine file size")
            uploadMessage = "Cannot read file"
            return
        }
        
        // Minimum file size check (50KB = ~3 seconds of audio at 16kHz/32kbps)
        let minFileSize = 50 * 1024 // 50KB
        guard fileSize >= minFileSize else {
            print("⚠️ File too small to upload: \(fileSize) bytes (minimum: \(minFileSize) bytes)")
            uploadMessage = "Recording too short (min 3 seconds)"
            return
        }
        
        print("📤 Starting upload process...")
        print("   Audio file: \(audioURL.path)")
        print("   File size: \(fileSize) bytes (\(Double(fileSize) / 1024.0) KB)")
        
        isUploading = true
        uploadMessage = "Uploading audio..."
        uploadSuccess = false
        
        Task {
            do {
                let fileId = try await uploadFile(url: audioURL)
                print("✅ File uploaded successfully with ID: \(fileId)")
                
                try await sendToWorkflow(fileId: fileId)
                print("✅ Workflow completed successfully")
                
                await MainActor.run {
                    uploadMessage = "Upload successful!"
                    uploadSuccess = true
                    isUploading = false
                    
                    // Reset after success if requested
                    if resetAfterSuccess {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            self.resetRecording()
                        }
                    } else {
                        // Clear message after a delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            self.uploadMessage = nil
                            self.uploadSuccess = false
                        }
                    }
                }
            } catch {
                print("❌ Upload failed: \(error)")
                print("   Error details: \(error.localizedDescription)")
                await MainActor.run {
                    uploadMessage = "Upload failed: \(error.localizedDescription)"
                    uploadSuccess = false
                    isUploading = false
                }
            }
        }
    }
    
    private func uploadFile(url: URL) async throws -> String {
        print("📤 Uploading file to: \(uploadEndpoint)")
        
        // Verify file exists and is readable
        guard FileManager.default.fileExists(atPath: url.path) else {
            print("❌ File does not exist: \(url.path)")
            throw NSError(domain: "Upload", code: -1, userInfo: [NSLocalizedDescriptionKey: "File not found"])
        }
        
        // Try to read the file data first to ensure it's accessible
        guard let audioData = try? Data(contentsOf: url) else {
            print("❌ Cannot read file data from: \(url.path)")
            throw NSError(domain: "Upload", code: -1, userInfo: [NSLocalizedDescriptionKey: "Cannot read file"])
        }
        
        guard audioData.count > 0 else {
            print("❌ File is empty: \(url.path)")
            throw NSError(domain: "Upload", code: -1, userInfo: [NSLocalizedDescriptionKey: "File is empty"])
        }
        
        print("   File data read successfully: \(audioData.count) bytes")
        
        var request = URLRequest(url: URL(string: uploadEndpoint)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        // Get file metadata
        let fileAttributes = try FileManager.default.attributesOfItem(atPath: url.path)
        let resourceValues = try url.resourceValues(forKeys: [.creationDateKey, .contentModificationDateKey])
        
        let fileSize = fileAttributes[.size] as? Int ?? audioData.count
        let creationDate = resourceValues.creationDate ?? Date()
        let filename = url.lastPathComponent
        
        // Try to get audio file properties (may fail if file is corrupted)
        var sampleRate: Double = 16000
        var channels: UInt32 = 1
        var duration: Double = 0
        
        do {
            let audioFile = try AVAudioFile(forReading: url)
            let format = audioFile.processingFormat
            sampleRate = format.sampleRate
            channels = format.channelCount
            duration = Double(audioFile.length) / sampleRate
            
            print("   📊 File metadata:")
            print("      Filename: \(filename)")
            print("      Size: \(fileSize) bytes (\(Double(fileSize) / 1024.0) KB)")
            print("      Sample rate: \(sampleRate) Hz")
            print("      Channels: \(channels)")
            print("      Duration: \(duration) seconds")
            print("      Created: \(creationDate)")
        } catch {
            print("⚠️ Warning: Could not read audio file properties: \(error)")
            print("   This may indicate a corrupted file. Attempting upload anyway...")
            
            // Estimate duration based on file size and bitrate
            // 32000 bits/sec = 4000 bytes/sec
            duration = Double(fileSize) / 4000.0
            
            print("   📊 File metadata (estimated):")
            print("      Filename: \(filename)")
            print("      Size: \(fileSize) bytes (\(Double(fileSize) / 1024.0) KB)")
            print("      Estimated duration: \(duration) seconds")
            print("      Created: \(creationDate)")
        }
        
        var body = Data()
        
        // Add file with correct MIME type
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/x-m4a\r\n".data(using: .utf8)!)
        body.append("Content-Length: \(audioData.count)\r\n\r\n".data(using: .utf8)!)
        body.append(audioData)
        body.append("\r\n".data(using: .utf8)!)
        
        // Add user
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"user\"\r\n\r\n".data(using: .utf8)!)
        body.append("watch-app-user".data(using: .utf8)!)
        body.append("\r\n".data(using: .utf8)!)
        
        // Add metadata fields
        
        // Duration
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"duration\"\r\n\r\n".data(using: .utf8)!)
        body.append(String(format: "%.2f", duration).data(using: .utf8)!)
        body.append("\r\n".data(using: .utf8)!)
        
        // Sample rate
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"sample_rate\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(Int(sampleRate))".data(using: .utf8)!)
        body.append("\r\n".data(using: .utf8)!)
        
        // Channels
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"channels\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(channels)".data(using: .utf8)!)
        body.append("\r\n".data(using: .utf8)!)
        
        // Format
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"format\"\r\n\r\n".data(using: .utf8)!)
        body.append("m4a".data(using: .utf8)!)
        body.append("\r\n".data(using: .utf8)!)
        
        // Codec
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"codec\"\r\n\r\n".data(using: .utf8)!)
        body.append("aac".data(using: .utf8)!)
        body.append("\r\n".data(using: .utf8)!)
        
        // Bitrate
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"bitrate\"\r\n\r\n".data(using: .utf8)!)
        body.append("32000".data(using: .utf8)!)
        body.append("\r\n".data(using: .utf8)!)
        
        // Source device
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"source\"\r\n\r\n".data(using: .utf8)!)
        body.append("Apple Watch".data(using: .utf8)!)
        body.append("\r\n".data(using: .utf8)!)
        
        // Recording timestamp
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"timestamp\"\r\n\r\n".data(using: .utf8)!)
        let iso8601Formatter = ISO8601DateFormatter()
        body.append(iso8601Formatter.string(from: creationDate).data(using: .utf8)!)
        body.append("\r\n".data(using: .utf8)!)
        
        // App version
        if let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"app_version\"\r\n\r\n".data(using: .utf8)!)
            body.append(appVersion.data(using: .utf8)!)
            body.append("\r\n".data(using: .utf8)!)
        }
        
        // Platform
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"platform\"\r\n\r\n".data(using: .utf8)!)
        body.append("watchOS".data(using: .utf8)!)
        body.append("\r\n".data(using: .utf8)!)
        
        // OS version
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"os_version\"\r\n\r\n".data(using: .utf8)!)
        let osVersion = WKInterfaceDevice.current().systemVersion
        body.append(osVersion.data(using: .utf8)!)
        body.append("\r\n".data(using: .utf8)!)
        
        // Device model
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"device_model\"\r\n\r\n".data(using: .utf8)!)
        let deviceModel = WKInterfaceDevice.current().model
        body.append(deviceModel.data(using: .utf8)!)
        body.append("\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        print("   Total payload size: \(body.count) bytes")
        
        print("🌐 Sending request...")
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ Invalid response type")
            throw NSError(domain: "Upload", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        print("📥 Response received:")
        print("   Status code: \(httpResponse.statusCode)")
        print("   Headers: \(httpResponse.allHeaderFields)")
        
        if let responseString = String(data: data, encoding: .utf8) {
            print("   Response body: \(responseString)")
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            print("❌ Server returned error status: \(httpResponse.statusCode)")
            throw NSError(domain: "Upload", code: -1, userInfo: [NSLocalizedDescriptionKey: "Server error"])
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        print("   Parsed JSON: \(json ?? [:])")
        
        guard let fileId = json?["id"] as? String else {
            print("❌ No file ID in response")
            throw NSError(domain: "Upload", code: -2, userInfo: [NSLocalizedDescriptionKey: "No file ID"])
        }
        
        print("✅ File ID extracted: \(fileId)")
        return fileId
    }
    
    private func sendToWorkflow(fileId: String) async throws {
        print("🔄 Sending to workflow: \(workflowEndpoint)")
        
        var request = URLRequest(url: URL(string: workflowEndpoint)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload: [String: Any] = [
            "inputs": [
                "audio": [
                    "transfer_method": "local_file",
                    "upload_file_id": fileId,
                    "type": "audio"
                ]
            ],
            "response_mode": "streaming",
            "user": "watch-app-user"
        ]
        
        let payloadData = try JSONSerialization.data(withJSONObject: payload, options: .prettyPrinted)
        if let payloadString = String(data: payloadData, encoding: .utf8) {
            print("   Payload: \(payloadString)")
        }
        
        request.httpBody = payloadData
        
        print("🌐 Sending workflow request...")
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ Invalid workflow response type")
            throw NSError(domain: "Workflow", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        print("📥 Workflow response received:")
        print("   Status code: \(httpResponse.statusCode)")
        print("   Headers: \(httpResponse.allHeaderFields)")
        
        if let responseString = String(data: data, encoding: .utf8) {
            print("   Response body: \(responseString)")
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            print("❌ Workflow returned error status: \(httpResponse.statusCode)")
            throw NSError(domain: "Workflow", code: -1, userInfo: [NSLocalizedDescriptionKey: "Workflow failed"])
        }
        
        print("✅ Workflow request completed successfully")
    }
    
    private func resetRecording() {
        recordingTime = 0
        hasRecording = false
        uploadMessage = nil
        uploadSuccess = false
        
        // Optionally keep or delete the recording
        if let url = recordingURL {
            if keepRecordingAfterUpload {
                print("💾 Keeping recording file: \(url.lastPathComponent)")
                loadSavedRecordings() // Refresh the list
            } else {
                try? FileManager.default.removeItem(at: url)
                print("🗑️ Deleted recording file: \(url.lastPathComponent)")
            }
        }
        recordingURL = nil
        audioRecorder = nil
    }
}

// MARK: - AVAudioRecorderDelegate
extension AudioRecorderViewModel: AVAudioRecorderDelegate {
    nonisolated func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            Task { @MainActor in
                self.uploadMessage = "Recording failed"
            }
        }
    }
    
    nonisolated func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        Task { @MainActor in
            self.uploadMessage = "Encoding error"
        }
    }
}
