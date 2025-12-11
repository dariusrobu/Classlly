import SwiftUI
import SwiftData
import PhotosUI

struct ContentView: View {
    // SwiftData Context
    @Environment(\.modelContext) private var modelContext
    
    // Query fetches data from disk automatically
    @Query(sort: \PhotoItem.createdAt, order: .reverse) private var photos: [PhotoItem]
    
    // Picker State
    @State private var selectedItem: PhotosPickerItem?
    
    var body: some View {
        NavigationStack {
            List {
                if photos.isEmpty {
                    ContentUnavailableView("No Photos", systemImage: "photo.on.rectangle.angled", description: "Tap the + button to save your first photo permanently.")
                }
                
                ForEach(photos) { photo in
                    PhotoRow(item: photo)
                }
                .onDelete(perform: deleteItems)
            }
            .navigationTitle("PhotoKeeper")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    // Photo Picker Button
                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        Image(systemName: "plus")
                    }
                }
            }
            // Listen for image selection
            .onChange(of: selectedItem) { _, newItem in
                Task {
                    if let newItem = newItem,
                       let data = try? await newItem.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        savePhoto(image: uiImage)
                    }
                    // Reset selection
                    selectedItem = nil
                }
            }
        }
    }
    
    // Logic: Save to Disk -> Create Model -> Save to DB
    private func savePhoto(image: UIImage) {
        // 1. Save binary to file system
        if let filename = ImageStore.save(image: image) {
            
            // 2. Create metadata record
            let newPhoto = PhotoItem(title: "My Photo", imageID: filename)
            
            // 3. Save to SwiftData
            modelContext.insert(newPhoto)
            try? modelContext.save()
            print("Successfully saved photo + metadata")
        }
    }
    
    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                let photo = photos[index]
                
                // Cleanup file from disk
                ImageStore.delete(fileName: photo.imageID)
                
                // Delete from DB
                modelContext.delete(photo)
            }
        }
    }
}
