import SwiftUI
import Photos

struct ResultsView: View {
    let designResponse: DesignResponse?
    let images: [UIImage]
    let instagramLink: String
    let pinterestLink: String
    let styleKeywords: [String]
    let userThoughts: String
    
    @State private var selectedImageIndex = 0
    @State private var showImageViewer = false
    @State private var showShareSheet = false
    @State private var downloadedImages: [UIImage] = []
    @State private var isDownloading = false
    @State private var showingSaveAlert = false
    @State private var saveAlertMessage = ""
    @State private var singleImageToShare: UIImage?
    @State private var showSingleImageShare = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Your AI Designs")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(ChapterColors.text)
                .padding(.top)
            
            if let designResponse = designResponse {
                if designResponse.status == .completed && !(designResponse.generatedImages?.isEmpty ?? true) {
                    // Real generated designs
                    designsGridView(imageUrls: designResponse.generatedImages ?? [])
                } else if designResponse.status == .failed {
                    errorView(message: designResponse.error ?? "Processing failed")
                } else {
                    processingView()
                }
            } else {
                // Fallback to mock data for testing
                mockDesignsView()
            }
            
            // Actions
            VStack(spacing: 12) {
                // Save to Photos Button
                Button(action: {
                    saveAllImagesToPhotos()
                }) {
                    HStack {
                        Image(systemName: isDownloading ? "arrow.down.circle" : "square.and.arrow.down")
                        Text(isDownloading ? "Saving..." : "Save to Photos")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(ChapterColors.accent)
                    .cornerRadius(25)
                }
                .disabled(isDownloading)
                .padding(.horizontal)

                // Share and Generate More Row
                HStack(spacing: 12) {
                    // Share Button
                    Menu {
                        Button("Share All Images") {
                            shareDesigns()
                        }

                        if let designResponse = designResponse,
                           let imageUrls = designResponse.generatedImages,
                           !imageUrls.isEmpty {
                            ForEach(Array(imageUrls.enumerated()), id: \.offset) { index, _ in
                                Button("Share Design \(index + 1)") {
                                    shareSingleImage(at: index)
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .font(.title2)
                            .foregroundColor(ChapterColors.accent)
                            .padding()
                            .background(ChapterColors.cardBackground)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(ChapterColors.border, lineWidth: 1)
                            )
                    }

                    // Generate More Button
                    Button("Generate More Variations") {
                        print("Generating more...")
                    }
                    .font(.headline)
                    .foregroundColor(ChapterColors.accent)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(ChapterColors.cardBackground)
                    .cornerRadius(25)
                    .overlay(
                        RoundedRectangle(cornerRadius: 25)
                            .stroke(ChapterColors.border, lineWidth: 1)
                    )
                }
                .padding(.horizontal)
            }
        }
        .background(ChapterColors.background)
        .navigationTitle("Results")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showShareSheet) {
            if !downloadedImages.isEmpty {
                ShareSheet(items: createShareItems(for: downloadedImages, isMultiple: true))
            }
        }
        .sheet(isPresented: $showSingleImageShare) {
            if let image = singleImageToShare {
                ShareSheet(items: createShareItems(for: [image], isMultiple: false))
            }
        }
        .alert("Save Status", isPresented: $showingSaveAlert) {
            Button("OK") { }
        } message: {
            Text(saveAlertMessage)
        }
    }

    private func designsGridView(imageUrls: [String]) -> some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 15) {
                ForEach(0..<imageUrls.count, id: \.self) { index in
                    AsyncImage(url: URL(string: imageUrls[index])) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .overlay(
                                ProgressView()
                                    .tint(.orange)
                            )
                    }
                    .frame(height: 150)
                    .clipped()
                    .cornerRadius(15)
                    .onTapGesture {
                        selectedImageIndex = index
                        showImageViewer = true
                    }
                }
            }
            .padding(.horizontal)
        }
        .sheet(isPresented: $showImageViewer) {
            ImageViewerView(imageUrls: imageUrls, selectedIndex: selectedImageIndex)
        }
    }
    
    private func mockDesignsView() -> some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 15) {
                ForEach(0..<4, id: \.self) { index in
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .aspectRatio(1, contentMode: .fit)
                        .overlay(
                            VStack {
                                Image(systemName: "photo")
                                    .font(.title)
                                    .foregroundColor(.gray)
                                Text("AI Design \(index + 1)")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        )
                        .cornerRadius(15)
                }
            }
            .padding(.horizontal)
        }
    }
    
    private func processingView() -> some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(ChapterColors.accent)
            
            Text("Still processing your designs...")
                .font(.body)
                .foregroundColor(ChapterColors.secondaryText)
                .multilineTextAlignment(.center)
            
            Text("This usually takes 2-5 minutes")
                .font(.caption)
                .foregroundColor(ChapterColors.secondaryText)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
    }
    
    private func errorView(message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(ChapterColors.error)
            
            Text("Processing Failed")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(ChapterColors.text)
            
            Text(message)
                .font(.body)
                .foregroundColor(ChapterColors.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
    }

    // MARK: - Save & Share Functions

    private func saveAllImagesToPhotos() {
        guard let designResponse = designResponse,
              let imageUrls = designResponse.generatedImages,
              !imageUrls.isEmpty else {
            saveAlertMessage = "No images to save"
            showingSaveAlert = true
            return
        }

        // Request Photos permission
        PHPhotoLibrary.requestAuthorization { status in
            DispatchQueue.main.async {
                if status == .authorized || status == .limited {
                    downloadAndSaveImages(imageUrls)
                } else {
                    saveAlertMessage = "Please allow Photos access in Settings to save images"
                    showingSaveAlert = true
                }
            }
        }
    }

    private func downloadAndSaveImages(_ imageUrls: [String]) {
        isDownloading = true
        var savedCount = 0
        let totalCount = imageUrls.count

        for imageUrl in imageUrls {
            guard let url = URL(string: imageUrl) else { continue }

            URLSession.shared.dataTask(with: url) { data, response, error in
                DispatchQueue.main.async {
                    if let data = data, let image = UIImage(data: data) {
                        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                        savedCount += 1
                    }

                    if savedCount == totalCount {
                        isDownloading = false
                        saveAlertMessage = "Successfully saved \(savedCount) designs to Photos"
                        showingSaveAlert = true
                    }
                }
            }.resume()
        }
    }

    private func shareDesigns() {
        guard let designResponse = designResponse,
              let imageUrls = designResponse.generatedImages,
              !imageUrls.isEmpty else {
            saveAlertMessage = "No images to share"
            showingSaveAlert = true
            return
        }

        isDownloading = true
        downloadedImages = []

        for imageUrl in imageUrls {
            guard let url = URL(string: imageUrl) else { continue }

            URLSession.shared.dataTask(with: url) { data, response, error in
                DispatchQueue.main.async {
                    if let data = data, let image = UIImage(data: data) {
                        downloadedImages.append(image)
                    }

                    if downloadedImages.count == imageUrls.count {
                        isDownloading = false
                        showShareSheet = true
                    }
                }
            }.resume()
        }
    }

    private func shareSingleImage(at index: Int) {
        guard let designResponse = designResponse,
              let imageUrls = designResponse.generatedImages,
              index < imageUrls.count else {
            saveAlertMessage = "No image to share"
            showingSaveAlert = true
            return
        }

        guard let url = URL(string: imageUrls[index]) else { return }

        isDownloading = true

        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                isDownloading = false
                if let data = data, let image = UIImage(data: data) {
                    singleImageToShare = image
                    showSingleImageShare = true
                } else {
                    saveAlertMessage = "Failed to load image for sharing"
                    showingSaveAlert = true
                }
            }
        }.resume()
    }

    private func createShareItems(for images: [UIImage], isMultiple: Bool) -> [Any] {
        let shareText = isMultiple ?
            "Check out my AI-generated interior designs! 🏠✨" :
            "Check out my AI-generated interior design! 🏠✨"

        var shareItems: [Any] = [shareText]
        shareItems.append(contentsOf: images)
        return shareItems
    }
}

struct ImageViewerView: View {
    let imageUrls: [String]
    @State var selectedIndex: Int
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            TabView(selection: $selectedIndex) {
                ForEach(0..<imageUrls.count, id: \.self) { index in
                    AsyncImage(url: URL(string: imageUrls[index])) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } placeholder: {
                        ProgressView()
                            .tint(.orange)
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(.page)
            .navigationTitle("Design \(selectedIndex + 1) of \(imageUrls.count)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let activityController = UIActivityViewController(activityItems: items, applicationActivities: nil)

        // Configure to support more social media apps
        activityController.excludedActivityTypes = [
            .assignToContact,
            .addToReadingList,
            .openInIBooks
        ]

        return activityController
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    NavigationStack {
        ResultsView(
            designResponse: nil,
            images: [],
            instagramLink: "",
            pinterestLink: "",
            styleKeywords: ["Modern", "Scandinavian"],
            userThoughts: "I love natural textures and want a peaceful atmosphere"
        )
    }
}
