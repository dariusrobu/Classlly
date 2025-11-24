import SwiftUI

struct DashboardCard: View {
    // MARK: - Properties
    let title: String
    let icon: String
    let count: Int
    // CHANGED: Now accepts an array of colors for the gradient
    let gradientColors: [Color]
    let isGamifiedMode: Bool
    
    // MARK: - Body
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Top Section: Icon and Count
            HStack {
                ZStack {
                    Circle()
                        .fill(iconBackgroundColor)
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(iconColor)
                }
                
                Spacer()
                
                Text("\(count)")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(textColor)
            }
            
            // Bottom Section: Title
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(secondaryTextColor)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(backgroundView)
        .cornerRadius(20)
        .shadow(
            // Softer shadow using the first color of the gradient
            color: isGamifiedMode ? (gradientColors.first ?? .blue).opacity(0.3) : Color.black.opacity(0.05),
            radius: isGamifiedMode ? 12 : 4,
            x: 0,
            y: isGamifiedMode ? 6 : 2
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(isGamifiedMode ? Color.white.opacity(0.2) : Color.clear, lineWidth: 1)
        )
    }
    
    // MARK: - Computed Styles
    
    @ViewBuilder
    private var backgroundView: some View {
        if isGamifiedMode {
            LinearGradient(
                gradient: Gradient(colors: gradientColors),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            Color.themeSurface
        }
    }
    
    private var textColor: Color {
        isGamifiedMode ? .white : .themeTextPrimary
    }
    
    private var secondaryTextColor: Color {
        isGamifiedMode ? .white.opacity(0.9) : .themeTextSecondary
    }
    
    private var iconColor: Color {
        // In minimalist mode, use the first color (primary)
        isGamifiedMode ? .white : (gradientColors.first ?? .blue)
    }
    
    private var iconBackgroundColor: Color {
        // Glass effect in gamified mode
        isGamifiedMode ? .white.opacity(0.2) : (gradientColors.first ?? .blue).opacity(0.1)
    }
}
