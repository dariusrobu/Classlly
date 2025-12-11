//
//  PhotoRow.swift
//  Classlly
//
//  Created by Robu Darius on 11.12.2025.
//


import SwiftUI

struct PhotoRow: View {
    let item: PhotoItem
    @State private var loadedImage: UIImage?
    
    var body: some View {
        HStack {
            // Image Logic
            if let image = loadedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 60, height: 60)
                    .overlay {
                        ProgressView()
                    }
                    .onAppear {
                        // Load asynchronously to keep UI smooth
                        DispatchQueue.global(qos: .userInitiated).async {
                            let img = ImageStore.load(fileName: item.imageID)
                            DispatchQueue.main.async {
                                self.loadedImage = img
                            }
                        }
                    }
            }
            
            VStack(alignment: .leading) {
                Text(item.title)
                    .font(.headline)
                Text(item.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}