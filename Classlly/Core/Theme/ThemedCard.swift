import SwiftUI

struct ThemedCard<Content: View>: View {
    let content: Content
    var color: Color = .themeSurface
    
    init(color: Color = .themeSurface, @ViewBuilder content: () -> Content) {
        self.color = color
        self.content = content()
    }
    
    var body: some View {
        content
            .padding()
            .background(color)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}
