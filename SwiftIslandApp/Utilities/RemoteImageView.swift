//
// Created by Niels van Hoorn for the use in the Swift Island app
// Copyright © 2025 AppTrix AB. All rights reserved.
//
import SwiftUI
import SwiftIslandDataLogic

struct RemoteImageView: View {
    let imagePath: String?
    let fallbackImageName: String
    
    @State private var uiImage: UIImage?
    @State private var isLoading = true
    
    var body: some View {
        Group {
            if let uiImage = uiImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
            } else if isLoading {
                // Show fallback while loading
                Image(fallbackImageName)
                    .resizable()
                    .opacity(0.7)
                    .overlay(
                        ProgressView()
                            .scaleEffect(0.8)
                    )
            } else {
                // Show fallback if loading failed
                Image(fallbackImageName)
                    .resizable()
            }
        }
        .task {
            await loadImage()
        }
    }
    
    private func loadImage() async {
        guard let imagePath = imagePath else {
            isLoading = false
            return
        }
        
        do {
            // Check if image is already cached locally
            let localURL = DataSync.localImageURL(for: imagePath)
            if DataSync.hasLocalImage(for: imagePath) {
                // Load from local cache
                if let data = try? Data(contentsOf: localURL),
                   let image = UIImage(data: data) {
                    await MainActor.run {
                        self.uiImage = image
                        self.isLoading = false
                    }
                    return
                }
            }
            
            // Download the image
            let imageData = try await DataSync.fetchImage(imagePath)
            if let image = UIImage(data: imageData) {
                await MainActor.run {
                    self.uiImage = image
                    self.isLoading = false
                }
            } else {
                await MainActor.run {
                    self.isLoading = false
                }
            }
        } catch {
            print("Failed to load image at \(imagePath): \(error)")
            await MainActor.run {
                self.isLoading = false
            }
        }
    }
}
