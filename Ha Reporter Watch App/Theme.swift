//
//  Theme.swift
//  Ha Reporter Watch App
//
//  Centralized theme constants and styles
//

import SwiftUI

// MARK: - Theme Colors

enum BananaTheme {
    static let yellow = Color(red: 1.0, green: 0.87, blue: 0.0)
    static let bright = Color(red: 0.8, green: 0.95, blue: 0.3)
    static let green = Color(red: 0.6, green: 0.8, blue: 0.2)
    static let brown = Color(red: 0.4, green: 0.3, blue: 0.1)
    static let darkBg = Color(red: 0.15, green: 0.12, blue: 0.0)
    
    // MARK: - Gradients
    
    static var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [darkBg, .black],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    static var barGradient: LinearGradient {
        LinearGradient(
            colors: [yellow, bright],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    static var buttonGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.45, green: 0.4, blue: 0.15),
                Color(red: 0.3, green: 0.25, blue: 0.1)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    static func cardGradient(isCurrent: Bool) -> LinearGradient {
        LinearGradient(
            colors: isCurrent 
                ? [yellow.opacity(0.12), yellow.opacity(0.08)]
                : [brown.opacity(0.15), brown.opacity(0.1)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Reusable View Modifiers

struct BananaBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        ZStack {
            BananaTheme.backgroundGradient.ignoresSafeArea()
            content
        }
    }
}

extension View {
    func bananaBackground() -> some View {
        modifier(BananaBackgroundModifier())
    }
}
