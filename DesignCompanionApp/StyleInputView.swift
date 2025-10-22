import SwiftUI
import PhotosUI

struct StyleInputView: View {
    var scannedRoomData: RoomScanData?

    @State private var selectedImages: [PhotosPickerItem] = []
    @State private var referenceImages: [UIImage] = []
    @State private var referenceLinks: [String] = []
    @State private var newLinkInput = ""
    @State private var selectedStyleKeywords: Set<String> = []
    @State private var userThoughts = ""

    private let availableStyleKeywords = [
        "Modern", "Minimalist", "Scandinavian",
        "Industrial", "Bohemian", "Farmhouse",
        "Mid-Century", "Traditional", "Coastal"
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

                    Text("Tap to select up to 5 images from your gallery")
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

            // Your Vision - moved here after reference images
            VStack(spacing: 16) {
                Text("Your Vision")
                    .font(.headline)
                    .foregroundColor(ChapterColors.text)

                Text("Describe your dream space, style preferences, or specific ideas")
                    .font(.caption)
                    .foregroundColor(ChapterColors.secondaryText)

                ZStack(alignment: .topLeading) {
                    TextField("", text: $userThoughts, axis: .vertical)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 12)
                        .background(Color.white)
                        .foregroundColor(ChapterColors.text)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(ChapterColors.border, lineWidth: 1)
                        )
                        .frame(minHeight: 100, maxHeight: 200)
                        .lineLimit(5...10)
                        .accentColor(ChapterColors.accent)
                        .tint(ChapterColors.accent)

                    if userThoughts.isEmpty {
                        Text("Example: I want a cozy reading corner with natural light, warm textures, and plants...")
                            .font(.caption)
                            .foregroundColor(ChapterColors.secondaryText)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 16)
                            .allowsHitTesting(false)
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

            // Reference Links
            VStack(spacing: 16) {
                Text("Design Inspiration Links")
                    .font(.headline)
                    .foregroundColor(ChapterColors.text)

                Text("Add links from Pinterest, Instagram, Houzz, or any design websites")
                    .font(.caption)
                    .foregroundColor(ChapterColors.secondaryText)

                // Add new link input
                HStack {
                    Image(systemName: "link")
                        .foregroundColor(ChapterColors.accent)
                        .frame(width: 24)

                    ZStack(alignment: .leading) {
                        TextField("", text: $newLinkInput)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(Color.white)
                            .foregroundColor(ChapterColors.text)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(ChapterColors.border, lineWidth: 1)
                            )
                            .accentColor(ChapterColors.accent)
                            .tint(ChapterColors.accent)
                            .onSubmit {
                                addReferenceLink()
                            }

                        if newLinkInput.isEmpty {
                            Text("Paste Pinterest, Instagram, or design links...")
                                .font(.caption)
                                .foregroundColor(ChapterColors.secondaryText)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .allowsHitTesting(false)
                        }
                    }

                    Button("Add") {
                        addReferenceLink()
                    }
                    .disabled(newLinkInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(newLinkInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? ChapterColors.border : ChapterColors.accent)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }

                // Display added links as chips
                if !referenceLinks.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Added Links:")
                            .font(.caption)
                            .foregroundColor(ChapterColors.secondaryText)

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 1), spacing: 8) {
                            ForEach(Array(referenceLinks.enumerated()), id: \.offset) { index, link in
                                HStack {
                                    Image(systemName: linkIcon(for: link))
                                        .foregroundColor(ChapterColors.accent)
                                        .frame(width: 16)

                                    Text(linkDisplayName(for: link))
                                        .font(.body)
                                        .foregroundColor(ChapterColors.text)
                                        .lineLimit(1)

                                    Spacer()

                                    Button(action: {
                                        removeReferenceLink(at: index)
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(ChapterColors.error)
                                            .frame(width: 20, height: 20)
                                    }
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(ChapterColors.lightCream)
                                .cornerRadius(20)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(ChapterColors.border, lineWidth: 1)
                                )
                            }
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

            // Style keywords
            VStack(spacing: 16) {
                Text("Style Keywords")
                    .font(.headline)
                    .foregroundColor(ChapterColors.text)

                Text("Select design styles that match your preferences")
                    .font(.caption)
                    .foregroundColor(ChapterColors.secondaryText)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 10) {
                    ForEach(availableStyleKeywords, id: \.self) { keyword in
                        Button(action: {
                            if selectedStyleKeywords.contains(keyword) {
                                selectedStyleKeywords.remove(keyword)
                            } else {
                                selectedStyleKeywords.insert(keyword)
                            }
                        }) {
                            Text(keyword)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(selectedStyleKeywords.contains(keyword) ? .white : ChapterColors.text)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
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


            Spacer()

            // Generate Design Button
                NavigationLink(destination: ProcessingView(
                        images: referenceImages,
                    instagramLink: referenceLinks.joined(separator: "\n"),
                    pinterestLink: "",
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
        .scrollDismissesKeyboard(.interactively)
        .background(ChapterColors.background)
        .navigationTitle("Style References")
        .navigationBarTitleDisplayMode(.inline)
        .onTapGesture {
            // Dismiss keyboard when tapping outside
            hideKeyboard()
        }
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

    // MARK: - Reference Links Helper Functions

    private func addReferenceLink() {
        let trimmedLink = newLinkInput.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedLink.isEmpty else { return }

        // Check if it's a valid URL or add https:// if missing
        let validatedLink = validateAndFormatURL(trimmedLink)

        // Avoid duplicates
        guard !referenceLinks.contains(validatedLink) else {
            newLinkInput = ""
            return
        }

        referenceLinks.append(validatedLink)
        newLinkInput = ""
    }

    private func removeReferenceLink(at index: Int) {
        guard index < referenceLinks.count else { return }
        referenceLinks.remove(at: index)
    }

    private func validateAndFormatURL(_ url: String) -> String {
        if url.lowercased().hasPrefix("http://") || url.lowercased().hasPrefix("https://") {
            return url
        } else {
            return "https://" + url
        }
    }

    private func linkIcon(for url: String) -> String {
        let lowercaseURL = url.lowercased()

        if lowercaseURL.contains("pinterest") {
            return "pin.fill"
        } else if lowercaseURL.contains("instagram") {
            return "camera.fill"
        } else if lowercaseURL.contains("houzz") {
            return "house.fill"
        } else if lowercaseURL.contains("dezeen") || lowercaseURL.contains("architecturaldigest") {
            return "newspaper.fill"
        } else {
            return "link"
        }
    }

    private func linkDisplayName(for url: String) -> String {
        let lowercaseURL = url.lowercased()

        if lowercaseURL.contains("pinterest") {
            return "Pinterest"
        } else if lowercaseURL.contains("instagram") {
            return "Instagram"
        } else if lowercaseURL.contains("houzz") {
            return "Houzz"
        } else if lowercaseURL.contains("dezeen") {
            return "Dezeen"
        } else if lowercaseURL.contains("architecturaldigest") {
            return "AD"
        } else {
            // Extract domain name
            if let host = URL(string: url)?.host {
                return host.replacingOccurrences(of: "www.", with: "").capitalized
            }
            return "Design Link"
        }
    }

    // MARK: - Keyboard Management

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

#Preview {
    NavigationStack {
        StyleInputView()
    }
}