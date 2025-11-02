import SwiftUI

struct DesignReportView: View {
    let scannedRoomData: RoomScanData?
    let styleKeywords: [String]
    let userThoughts: String
    let referenceImages: [UIImage]
    let referenceUrls: [String]

    @Environment(\.dismiss) private var dismiss
    @State private var rating: Int = 0
    @State private var feedbackText: String = ""
    @State private var showingShareSheet = false
    @State private var reportImage: UIImage?
    @State private var showingFeedbackSubmitted = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Text("Your Design Journey")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(ChapterColors.text)

                        Text("with Chapter")
                            .font(.title3)
                            .foregroundColor(ChapterColors.accent)

                        Divider()
                            .background(ChapterColors.border)
                            .padding(.horizontal)
                    }
                    .padding(.top)

                    // Room Analysis Section
                    reportSection(icon: "ruler", title: "Room Analysis") {
                        if let roomData = scannedRoomData {
                            VStack(alignment: .leading, spacing: 8) {
                                InfoRow(label: "Room Type", value: roomData.roomType.replacingOccurrences(of: "_", with: " ").capitalized)
                                InfoRow(label: "Dimensions", value: String(format: "%.1fm × %.1fm × %.1fm", roomData.dimensions.width, roomData.dimensions.depth, roomData.dimensions.height))
                                InfoRow(label: "Floor Area", value: String(format: "%.1f sq m", roomData.dimensions.area))
                                InfoRow(label: "Features", value: "\(roomData.features.windows) windows, \(roomData.features.doors) doors")
                            }
                        } else {
                            Text("Demo room data used")
                                .font(.body)
                                .foregroundColor(ChapterColors.secondaryText)
                        }
                    }

                    // Your Vision Section
                    if !userThoughts.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        reportSection(icon: "lightbulb.fill", title: "Your Vision") {
                            Text(userThoughts)
                                .font(.body)
                                .foregroundColor(ChapterColors.text)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(ChapterColors.lightCream)
                                .cornerRadius(12)
                        }
                    }

                    // Style Keywords Section
                    if !styleKeywords.isEmpty {
                        reportSection(icon: "tag.fill", title: "Style Keywords") {
                            FlowLayout(spacing: 8) {
                                ForEach(styleKeywords, id: \.self) { keyword in
                                    Text(keyword)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(ChapterColors.accent)
                                        .cornerRadius(16)
                                }
                            }
                        }
                    }

                    // Your Inspiration Section
                    if !referenceImages.isEmpty || !referenceUrls.isEmpty {
                        reportSection(icon: "photo.on.rectangle.angled", title: "Your Inspiration") {
                            VStack(spacing: 12) {
                                if !referenceImages.isEmpty {
                                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                                        ForEach(Array(referenceImages.prefix(6).enumerated()), id: \.offset) { index, image in
                                            Image(uiImage: image)
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: 80, height: 80)
                                                .clipped()
                                                .cornerRadius(8)
                                        }
                                    }

                                    Text("\(referenceImages.count) reference \(referenceImages.count == 1 ? "photo" : "photos")")
                                        .font(.caption)
                                        .foregroundColor(ChapterColors.secondaryText)
                                }

                                if !referenceUrls.isEmpty {
                                    Text("\(referenceUrls.count) inspiration \(referenceUrls.count == 1 ? "link" : "links")")
                                        .font(.caption)
                                        .foregroundColor(ChapterColors.secondaryText)
                                }
                            }
                        }
                    }

                    // Why This Design Section
                    reportSection(icon: "sparkles", title: "Why This Design?") {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(generateDesignRationale())
                                .font(.body)
                                .foregroundColor(ChapterColors.text)
                                .lineSpacing(4)
                        }
                    }

                    // Rate Your Experience Section
                    reportSection(icon: "star.fill", title: "Rate Your Experience") {
                        VStack(spacing: 16) {
                            // Star rating
                            HStack(spacing: 12) {
                                ForEach(1...5, id: \.self) { index in
                                    Button(action: {
                                        rating = index
                                    }) {
                                        Image(systemName: index <= rating ? "star.fill" : "star")
                                            .font(.title)
                                            .foregroundColor(index <= rating ? .yellow : ChapterColors.border)
                                    }
                                }
                            }

                            // Feedback text
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Share your thoughts (optional)")
                                    .font(.caption)
                                    .foregroundColor(ChapterColors.secondaryText)

                                TextField("Tell us about your experience...", text: $feedbackText, axis: .vertical)
                                    .padding()
                                    .background(Color.white)
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(ChapterColors.border, lineWidth: 1)
                                    )
                                    .lineLimit(3...5)
                            }

                            // Submit button
                            Button(action: submitFeedback) {
                                Text("Submit Feedback")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(rating > 0 ? ChapterColors.accent : ChapterColors.border)
                                    .cornerRadius(12)
                            }
                            .disabled(rating == 0)
                        }
                    }

                    // Share Report Button
                    Button(action: shareReport) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share This Report")
                        }
                        .font(.headline)
                        .foregroundColor(ChapterColors.accent)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(ChapterColors.cardBackground)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(ChapterColors.border, lineWidth: 1)
                        )
                    }
                    .padding(.horizontal)

                    Spacer(minLength: 40)
                }
                .padding(.horizontal)
            }
            .background(ChapterColors.background)
            .navigationTitle("Design Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                if let reportImage = reportImage {
                    ShareSheet(items: [
                        "Check out my Chapter Design Report! 🏠✨",
                        reportImage
                    ])
                }
            }
            .alert("Thank You!", isPresented: $showingFeedbackSubmitted) {
                Button("OK") { }
            } message: {
                Text("Your feedback helps us improve. We appreciate you!")
            }
        }
    }

    // MARK: - Helper Views

    private func reportSection<Content: View>(icon: String, title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(ChapterColors.accent)
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(ChapterColors.text)
            }

            content()
        }
        .padding()
        .background(ChapterColors.cardBackground)
        .cornerRadius(15)
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(ChapterColors.border, lineWidth: 1)
        )
    }

    private func generateDesignRationale() -> String {
        var rationale = ""

        if let roomData = scannedRoomData {
            let roomType = roomData.roomType.replacingOccurrences(of: "_", with: " ")
            let area = String(format: "%.1f", roomData.dimensions.area)

            rationale += "Based on your \(roomType) with \(area) square meters of space"

            if roomData.features.windows > 0 {
                rationale += " and \(roomData.features.windows) \(roomData.features.windows == 1 ? "window" : "windows") providing natural light"
            }

            rationale += ", "
        }

        if !styleKeywords.isEmpty {
            let styles = styleKeywords.prefix(2).joined(separator: " and ")
            rationale += "we crafted a \(styles.lowercased()) design that "
        } else {
            rationale += "we created a design that "
        }

        if !userThoughts.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            rationale += "aligns with your vision for the space. "
        } else {
            rationale += "maximizes the potential of your space. "
        }

        rationale += "Our AI analyzed your room's dimensions, natural light patterns, and style preferences to generate personalized design concepts that transform your space while respecting its architectural features."

        return rationale
    }

    // MARK: - Actions

    private func submitFeedback() {
        print("⭐ User submitted feedback:")
        print("   Rating: \(rating) stars")
        print("   Feedback: \(feedbackText.isEmpty ? "none" : feedbackText)")

        // TODO: Send feedback to backend/analytics

        showingFeedbackSubmitted = true
    }

    @MainActor
    private func shareReport() {
        // Create a view for rendering (without navigation and interactive elements)
        let reportContent = reportContentForSharing()
        let renderer = ImageRenderer(content: reportContent)
        renderer.scale = 3.0 // Higher resolution

        if let image = renderer.uiImage {
            reportImage = image
            showingShareSheet = true
        }
    }

    @ViewBuilder
    private func reportContentForSharing() -> some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 8) {
                Text("Your Design Journey")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(ChapterColors.text)

                Text("with Chapter")
                    .font(.title3)
                    .foregroundColor(ChapterColors.accent)
            }
            .padding(.top, 20)

            // Room Analysis
            if let roomData = scannedRoomData {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "ruler")
                            .foregroundColor(ChapterColors.accent)
                        Text("Room Analysis")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }

                    InfoRow(label: "Room Type", value: roomData.roomType.replacingOccurrences(of: "_", with: " ").capitalized)
                    InfoRow(label: "Dimensions", value: String(format: "%.1fm × %.1fm × %.1fm", roomData.dimensions.width, roomData.dimensions.depth, roomData.dimensions.height))
                    InfoRow(label: "Floor Area", value: String(format: "%.1f sq m", roomData.dimensions.area))
                }
                .padding()
                .background(ChapterColors.cardBackground)
                .cornerRadius(12)
            }

            // Style Keywords
            if !styleKeywords.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "tag.fill")
                            .foregroundColor(ChapterColors.accent)
                        Text("Style Keywords")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }

                    FlowLayout(spacing: 8) {
                        ForEach(styleKeywords, id: \.self) { keyword in
                            Text(keyword)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(ChapterColors.accent)
                                .cornerRadius(12)
                        }
                    }
                }
                .padding()
                .background(ChapterColors.cardBackground)
                .cornerRadius(12)
            }

            // Rating
            if rating > 0 {
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundColor(ChapterColors.accent)
                        Text("Experience Rating")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }

                    HStack(spacing: 8) {
                        ForEach(1...5, id: \.self) { index in
                            Image(systemName: index <= rating ? "star.fill" : "star")
                                .font(.title3)
                                .foregroundColor(index <= rating ? .yellow : ChapterColors.border)
                        }
                    }
                }
                .padding()
                .background(ChapterColors.cardBackground)
                .cornerRadius(12)
            }

            // Footer
            Text("Generated with ❤️ by Chapter")
                .font(.caption)
                .foregroundColor(ChapterColors.secondaryText)
                .padding(.bottom, 20)
        }
        .padding(.horizontal, 20)
        .frame(width: 600)
        .background(ChapterColors.background)
    }
}

// MARK: - Supporting Views

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.body)
                .foregroundColor(ChapterColors.secondaryText)
            Spacer()
            Text(value)
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(ChapterColors.text)
        }
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.replacingUnspecifiedDimensions().width, subviews: subviews, spacing: spacing)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x, y: bounds.minY + result.positions[index].y), proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += lineHeight + spacing
                    lineHeight = 0
                }

                positions.append(CGPoint(x: x, y: y))
                lineHeight = max(lineHeight, size.height)
                x += size.width + spacing
            }

            self.size = CGSize(width: maxWidth, height: y + lineHeight)
        }
    }
}

#Preview {
    DesignReportView(
        scannedRoomData: nil,
        styleKeywords: ["Modern", "Minimalist", "Scandinavian"],
        userThoughts: "I want a cozy reading corner with natural light and warm textures",
        referenceImages: [],
        referenceUrls: ["https://pinterest.com/example"]
    )
}
