
//
//  GameColor.swift
//  Classlly
//
//  Created by Robu Darius on 25.11.2025.
//


import SwiftUI
import UIKit

// MARK: - Gamified Colors & Gradients
struct GameColor {
    // The deep black background for the neon look
    static let background = Color(hex: "000000")
    
    // The dark gray card background (for surface cards)
    static let darkSurface = Color(hex: "1C1C1E")
    
    // Vibrant Highlight Colors
    static let electricBlue = Color(hex: "2E86DE")
    static let neonOrange = Color(hex: "FF9F43")
    static let emeraldGreen = Color(hex: "2ECC71")
    static let purpleHaze = Color(hex: "A55EEA")
    
    // Text Colors
    static let text = Color.white
    static let secondaryText = Color.white.opacity(0.7)
    
    // Standard Adaptive Colors (Legacy support if needed)
    static var adaptiveBackground: Color {
        Color(light: UIColor(hex: "FFF9F0"), dark: UIColor(hex: "121212"))
    }
    
    static var adaptiveSurface: Color {
        Color(light: .white, dark: UIColor(hex: "1C1C1E"))
    }
    
    static let accent = Color(hex: "FF6B6B")
}

// MARK: - Game Gradients
struct GameGradient {
    static func linear(base: Color) -> LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                base.opacity(0.8), // Slightly lighter top
                base // Pure color bottom
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Gamified View Modifiers

struct GamifiedCardModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            .background(GameColor.darkSurface)
            .cornerRadius(20)
            .shadow(
                color: Color.black.opacity(0.5),
                radius: 10,
                x: 0,
                y: 5
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
    }
}

struct GamifiedButtonModifier: ViewModifier {
    let color: Color
    
    func body(content: Content) -> some View {
        content
            .font(.system(.headline, design: .rounded))
            .foregroundColor(.white)
            .padding()
            .background(color)
            .cornerRadius(16)
            .shadow(color: color.opacity(0.4), radius: 0, x: 0, y: 4)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.3), lineWidth: 2)
            )
    }
}

// MARK: - Extensions for Hex Colors

// 1. UIColor Extension
extension UIColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            red: CGFloat(r) / 255,
            green: CGFloat(g) / 255,
            blue: CGFloat(b) / 255,
            alpha: CGFloat(a) / 255
        )
    }
}

// 2. SwiftUI Color Extension
extension Color {
    init(hex: String) {
        self.init(uiColor: UIColor(hex: hex))
    }
}
