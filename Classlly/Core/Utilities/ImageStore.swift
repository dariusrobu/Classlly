import SwiftUI // <-- ADD THIS
import UIKit

struct ImageStore {
    static func save(image: UIImage) -> String? {
        let fileName = UUID().uuidString + ".jpg"
        guard let docDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
        let fileURL = docDir.appendingPathComponent(fileName)
        
        guard let data = image.jpegData(compressionQuality: 0.8) else { return nil }
        
        try? data.write(to: fileURL)
        return fileName
    }
    
    static func load(fileName: String) -> UIImage? {
        guard let docDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
        let fileURL = docDir.appendingPathComponent(fileName)
        return UIImage(contentsOfFile: fileURL.path)
    }
    
    static func delete(fileName: String) {
        guard let docDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let fileURL = docDir.appendingPathComponent(fileName)
        try? FileManager.default.removeItem(at: fileURL)
    }
}
