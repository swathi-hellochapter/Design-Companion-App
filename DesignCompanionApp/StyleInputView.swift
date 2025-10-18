import SwiftUI
import PhotosUI

struct StyleInputView: View {
    var scannedRoomData: RoomScanData?

    @State private var selectedImages: [PhotosPickerItem] = []
    @State private var referenceImages: [UIImage] = []
    @State private var instagramLink = ""
    @State private var pinterestLink = ""
    @State private var selectedStyleKeywords: Set<String> = []
    @State private var userThoughts = ""

    private let availableStyleKeywords = [
        "Modern", "Minimalist", "Scandinavian", "Industrial", "Bohemian",
        "Farmhouse", "Mid-Century", "Traditional", "Contemporary", "Rustic",
        "Art Deco", "Mediterranean", "Coastal", "Eclectic", "Vintage"
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Add Your Style References")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(ChapterColors.text)
                    .padding(.top)

            // Photo picker
            PhotosPicker(
                selection: $selectedImages,
                maxSelectionCount: 5,
                matching: .images
            ) {
                VStack {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 40))
                        .foregroundColor(ChapterColors.accent)

                    Text("Add Reference Photos")
                        .font(.headline)
                        .foregroundColor(ChapterColors.text)

                    Text("Tap to select up to 5 images")
                        .font(.caption)
                        .foregroundColor(ChapterColors.secondaryText)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(ChapterColors.cardBackground)
                .cornerRadius(15)
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(ChapterColors.border, lineWidth: 1)
                )
            }
            .padding(.horizontal)
            .onChange(of: selectedImages) { items in
                loadSelectedImages()
            }

            // Display selected images
            if !referenceImages.isEmpty {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 10) {
                    ForEach(Array(referenceImages.enumerated()), id: \.offset) { index, image in
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 80, height: 80)
                            .clipped()
                            .cornerRadius(10)
                    }
                }
                .padding(.horizontal)
            }

            // Social media links
            VStack(spacing: 16) {
                Text("Social Media References")
                    .font(.headline)
                    .foregroundColor(ChapterColors.text)

                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "camera.fill")
                            .foregroundColor(ChapterColors.accent)
                        TextField("Instagram URL", text: $instagramLink)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }

                    HStack {
                        Image(systemName: "pin.fill")
                            .foregroundColor(ChapterColors.accent)
                        TextField("Pinterest URL", text: $pinterestLink)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                }
            }
            .padding()
            .background(ChapterColors.cardBackground)
            .cornerRadius(15)
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(ChapterColors.border, lineWidth: 1)
            )
            .padding(.horizontal)

            // Style keywords
            VStack(spacing: 16) {
                Text("Style Keywords")
                    .font(.headline)
                    .foregroundColor(ChapterColors.text)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 10) {
                    ForEach(availableStyleKeywords, id: \.self) { keyword in
                        Button(action: {
                            if selectedStyleKeywords.contains(keyword) {
                                selectedStyleKeywords.remove(keyword)
                            } else {
                                selectedStyleKeywords.insert(keyword)
                            }
                        }) {
                            Text(keyword)
                                .font(.body)
                                .foregroundColor(selectedStyleKeywords.contains(keyword) ? .white : ChapterColors.text)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(selectedStyleKeywords.contains(keyword) ? ChapterColors.accent : ChapterColors.cardBackground)
                                .cornerRadius(20)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(ChapterColors.border, lineWidth: selectedStyleKeywords.contains(keyword) ? 0 : 1)
                                )
                        }
                    }
                }
            }
            .padding()
            .background(ChapterColors.cardBackground)
            .cornerRadius(15)
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(ChapterColors.border, lineWidth: 1)
            )
            .padding(.horizontal)

            // User thoughts
            VStack(spacing: 16) {
                Text("Your Vision")
                    .font(.headline)
                    .foregroundColor(ChapterColors.text)

                TextField("Describe your dream space...", text: $userThoughts, axis: .vertical)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(minHeight: 80)
            }
            .padding()
            .background(ChapterColors.cardBackground)
            .cornerRadius(15)
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(ChapterColors.border, lineWidth: 1)
            )
            .padding(.horizontal)

            Spacer()

            // Generate Design Button
                NavigationLink(destination: ProcessingView(
                        images: referenceImages,
                    instagramLink: instagramLink,
                    pinterestLink: pinterestLink,
                    styleKeywords: Array(selectedStyleKeywords),
                    userThoughts: userThoughts,
                    scannedRoomData: scannedRoomData
                )) {
                    Text("Generate Design")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(ChapterColors.accent)
                        .cornerRadius(25)
                }
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
        }
        .background(ChapterColors.background)
        .navigationTitle("Style References")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func loadSelectedImages() {
        Task {
            var newImages: [UIImage] = []

            for item in selectedImages {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    newImages.append(image)
                }
            }

            await MainActor.run {
                referenceImages = newImages
            }
        }
    }
}

#Preview {
    NavigationStack {
        StyleInputView()
    }
}