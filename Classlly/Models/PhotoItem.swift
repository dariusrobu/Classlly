import Foundation
import SwiftData // <-- ADD THIS

@Model
final class PhotoItem {
    @Attribute(.unique) var id: UUID
    var title: String
    var createdAt: Date
    var imageID: String
    
    init(title: String, imageID: String) {
        self.id = UUID()
        self.title = title
        self.createdAt = Date()
        self.imageID = imageID
    }
}
