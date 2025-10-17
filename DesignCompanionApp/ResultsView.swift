import SwiftUI

struct ResultsView: View {
    let designResponse: DesignResponse?
    let images: [UIImage]
    let instagramLink: String
    let pinterestLink: String
    let styleKeywords: [String]
    let userThoughts: String
    
    @State private var selectedImageIndex = 0
    @State private var showImageViewer = false
    
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
                Button("Save Designs") {
                    print("Saving designs...")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .cornerRadius(25)
                .padding(.horizontal)
                
                Button("Generate More Variations") {
                    print("Generating more...")
                }
                .font(.headline)
                .foregroundColor(.blue)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(25)
                .padding(.horizontal)
            }
        }
        .background(ChapterColors.background)
        .navigationTitle("Results")
        .navigationBarTitleDisplayMode(.inline)
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
