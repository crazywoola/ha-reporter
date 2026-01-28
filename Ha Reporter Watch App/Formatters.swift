//
//  Formatters.swift
//  Ha Reporter Watch App
//
//  Pure formatting functions (functional programming style)
//

import Foundation

// MARK: - Time Formatting

enum TimeFormatter {
    /// Format time interval to MM:SS
    static func format(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    /// Format time interval to M:SS (compact)
    static func formatCompact(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - File Size Formatting

enum FileSizeFormatter {
    /// Format bytes to human-readable string
    static func format(_ bytes: Int) -> String {
        let kb = Double(bytes) / 1024
        if kb < 1024 {
            return String(format: "%.0f KB", kb)
        }
        let mb = kb / 1024
        return String(format: "%.1f MB", mb)
    }
}

// MARK: - Functional Utilities

extension Array where Element == CGFloat {
    /// Generate random audio levels
    static func randomLevels(count: Int, range: ClosedRange<CGFloat> = 0.3...1.0) -> [CGFloat] {
        (0..<count).map { _ in CGFloat.random(in: range) }
    }
}

extension URL {
    /// Get file size safely
    var fileSize: Int? {
        try? resourceValues(forKeys: [.fileSizeKey]).fileSize
    }
}
