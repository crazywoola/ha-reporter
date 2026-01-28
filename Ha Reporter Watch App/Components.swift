//
//  Components.swift
//  Ha Reporter Watch App
//
//  Reusable UI components
//

import SwiftUI

// MARK: - Circular Icon Button

struct CircularIconButton: View {
    let icon: String
    let size: CGFloat
    let backgroundColor: Color
    let foregroundColor: Color
    let action: () -> Void
    let isDisabled: Bool
    
    init(
        icon: String,
        size: CGFloat = 32,
        backgroundColor: Color = BananaTheme.brown.opacity(0.3),
        foregroundColor: Color = BananaTheme.yellow,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.size = size
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
        self.isDisabled = isDisabled
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(backgroundColor)
                    .frame(width: size, height: size)
                
                Image(systemName: icon)
                    .font(.system(size: size * 0.375, weight: .bold))
                    .foregroundStyle(foregroundColor)
            }
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
    }
}

// MARK: - Audio Bar

struct AudioBar: View {
    let level: CGFloat
    let maxHeight: CGFloat = 55
    let minHeight: CGFloat = 20
    
    private var height: CGFloat {
        level * maxHeight + minHeight
    }
    
    var body: some View {
        ZStack {
            Capsule()
                .fill(BananaTheme.barGradient)
                .frame(width: 10, height: height)
                .shadow(color: BananaTheme.yellow.opacity(0.3), radius: 3)
            
            Circle()
                .fill(BananaTheme.brown)
                .frame(width: 4, height: 4)
                .offset(y: -height / 2)
        }
        .animation(.easeInOut(duration: 0.3), value: level)
    }
}

// MARK: - Progress Bar

struct AudioProgressBar: View {
    let currentTime: TimeInterval
    let duration: TimeInterval
    
    private var progress: CGFloat {
        guard duration > 0 else { return 0 }
        return CGFloat(currentTime / duration)
    }
    
    var body: some View {
        VStack(spacing: 3) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(BananaTheme.brown.opacity(0.3))
                        .frame(height: 3)
                    
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(
                            LinearGradient(
                                colors: [BananaTheme.yellow, BananaTheme.yellow.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * progress, height: 3)
                }
            }
            .frame(height: 3)
            
            HStack {
                Text(TimeFormatter.formatCompact(currentTime))
                Spacer()
                Text(TimeFormatter.formatCompact(duration - currentTime))
            }
            .font(.system(size: 8, weight: .medium, design: .rounded))
            .foregroundStyle(BananaTheme.yellow.opacity(0.7))
        }
    }
}

// MARK: - Section Header

struct SectionHeader: View {
    let emoji: String
    let title: String
    let count: Int?
    
    init(emoji: String, title: String, count: Int? = nil) {
        self.emoji = emoji
        self.title = title
        self.count = count
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Text(emoji)
                .font(.system(size: 12))
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(BananaTheme.yellow.opacity(0.9))
            
            if let count = count {
                Spacer()
                Text("\(count)")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(BananaTheme.yellow)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(BananaTheme.yellow.opacity(0.2)))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
