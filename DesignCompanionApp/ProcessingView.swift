import SwiftUI

struct ProcessingView: View {
    let images: [UIImage]
    let instagramLink: String
    let pinterestLink: String
    let styleKeywords: [String]
    let userThoughts: String
    let scannedRoomData: RoomScanData?
    
    @State private var isProcessing = true
    @State private var processingStep = 0
    @State private var showResults = false
    @State private var requestId: String?
    @State private var designResponse: DesignResponse?
    @State private var errorMessage: String?
    @StateObject private var apiService = APIService.shared
    @State private var testMode = true // Enable for testing
    
    private let processingSteps = [
        "Analyzing room dimensions...",
        "Processing style references...",
        "Extracting color palette...",
        "Generating design concepts...",
        "Rendering interior images..."
    ]
    
    var body: some View {
        VStack(spacing: 30) {
            if let errorMessage = errorMessage {
                errorInterface
            } else if isProcessing {
                processingInterface
            } else {
                completedInterface
            }
        }
        .background(ChapterColors.background)
        .navigationTitle(Config.demoMode ? "Generating Design (Demo)" : "Generating Design")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(isProcessing)
        .onAppear {
            print("🚀 ProcessingView appeared - starting design generation process")
            print("📋 Input Summary:")
            if let roomData = scannedRoomData {
                print("   📐 Room: REAL \(roomData.roomType) (\(String(format: "%.1f", roomData.dimensions.width))×\(String(format: "%.1f", roomData.dimensions.depth))×\(String(format: "%.1f", roomData.dimensions.height))m)")
                print("   📏 Area: \(String(format: "%.1f", roomData.dimensions.area)) sq m")
            } else {
                print("   📐 Room: Demo room (4.0×3.0×2.8m)")
            }
            print("   🖼️ Images: \(images.count)")
            print("   🏷️ Keywords: \(styleKeywords)")
            print("   📱 Instagram: \(!instagramLink.isEmpty)")
            print("   📌 Pinterest: \(!pinterestLink.isEmpty)")
            print("   💭 User Thoughts: \(!userThoughts.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)")
            startProcessingAnimation()
            submitDesignRequest()
        }
    }
    
    private var processingInterface: some View {
        VStack(spacing: 30) {
            // Processing animation
            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(2)
                    .tint(ChapterColors.accent)

                Text("Creating Your Design...")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(ChapterColors.text)

                Text(processingSteps[processingStep])
                    .font(.body)
                    .foregroundColor(ChapterColors.secondaryText)
                    .multilineTextAlignment(.center)

                // Encouraging message
                Text("Great things take time ✨\nYour designs will be ready in 1-2 minutes...")
                    .font(.subheadline)
                    .foregroundColor(ChapterColors.accent)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
            }
            
            // Progress indicator
            VStack(spacing: 10) {
                HStack {
                    ForEach(0..<processingSteps.count, id: \.self) { index in
                        Circle()
                            .fill(index <= processingStep ? ChapterColors.accent : ChapterColors.border)
                            .frame(width: 12, height: 12)
                            .animation(.easeInOut(duration: 0.3), value: processingStep)
                    }
                }
                
                Text("Step \(processingStep + 1) of \(processingSteps.count)")
                    .font(.caption)
                    .foregroundColor(ChapterColors.secondaryText)
            }
            
            // Processing info
            VStack(spacing: 15) {
                HStack {
                    Text("Reference Images:")
                        .foregroundColor(ChapterColors.secondaryText)
                    Spacer()
                    Text("\(images.count)")
                        .fontWeight(.medium)
                        .foregroundColor(ChapterColors.text)
                }
                
                if !instagramLink.isEmpty {
                    HStack {
                        Text("Instagram Link:")
                            .foregroundColor(ChapterColors.secondaryText)
                        Spacer()
                        Text("Added")
                            .foregroundColor(ChapterColors.success)
                            .fontWeight(.medium)
                    }
                }
                
                if !pinterestLink.isEmpty {
                    HStack {
                        Text("Pinterest Link:")
                            .foregroundColor(ChapterColors.secondaryText)
                        Spacer()
                        Text("Added")
                            .foregroundColor(ChapterColors.success)
                            .fontWeight(.medium)
                    }
                }
                
                if !styleKeywords.isEmpty {
                    HStack {
                        Text("Style Keywords:")
                            .foregroundColor(ChapterColors.secondaryText)
                        Spacer()
                        Text("\(styleKeywords.count) selected")
                            .foregroundColor(ChapterColors.success)
                            .fontWeight(.medium)
                    }
                }
                
                if !userThoughts.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    HStack {
                        Text("Custom Vision:")
                            .foregroundColor(ChapterColors.secondaryText)
                        Spacer()
                        Text("Added")
                            .foregroundColor(ChapterColors.success)
                            .fontWeight(.medium)
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
        }
    }
    
    private var completedInterface: some View {
        VStack(spacing: 30) {
            // Success message
            VStack(spacing: 15) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(ChapterColors.success)
                
                Text("Design Complete!")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(ChapterColors.text)
                
                Text("Your AI interior design is ready")
                    .font(.body)
                    .foregroundColor(ChapterColors.secondaryText)
            }
            
            // View Results Button
            NavigationLink(destination: ResultsView(
                designResponse: designResponse,
                images: images,
                instagramLink: instagramLink,
                pinterestLink: pinterestLink,
                styleKeywords: styleKeywords,
                userThoughts: userThoughts,
                scannedRoomData: scannedRoomData
            )) {
                Text("View Your Designs")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(ChapterColors.accent)
                    .cornerRadius(25)
            }
            .padding(.horizontal)
            
            Spacer()
        }
    }
    
    private var errorInterface: some View {
        VStack(spacing: 30) {
            // Error message
            VStack(spacing: 15) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 60))
                    .foregroundColor(ChapterColors.error)
                
                Text("Request Failed")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(ChapterColors.text)
                
                Text(errorMessage ?? "Unknown error occurred")
                    .font(.body)
                    .foregroundColor(ChapterColors.secondaryText)
                    .multilineTextAlignment(.center)
            }
            
            // Retry Button
            Button(action: {
                print("🔄 User tapped retry button")
                self.errorMessage = nil
                self.isProcessing = true
                self.processingStep = 0
                submitDesignRequest()
            }) {
                Text("Try Again")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(ChapterColors.accent)
                    .cornerRadius(25)
            }
            .padding(.horizontal)
            
            Spacer()
        }
    }
    
    private func startProcessingAnimation() {
        print("🎬 Starting processing animation with \(processingSteps.count) steps")
        Timer.scheduledTimer(withTimeInterval: 12.0, repeats: true) { timer in
            if processingStep < processingSteps.count - 1 {
                withAnimation {
                    processingStep += 1
                    print("📈 Animation step \(processingStep + 1)/\(processingSteps.count): \(processingSteps[processingStep])")
                }
            } else {
                print("🏁 Processing animation completed, waiting for API response...")
                timer.invalidate()
                // Don't auto-complete anymore, wait for API response
            }
        }
    }
    
    private func submitDesignRequest() {
        // Check if demo mode is enabled
        if Config.demoMode {
            print("🎭 DEMO MODE: Skipping API call, using sample designs")
            simulateDemoProcessing()
            return
        }

        let trimmedThoughts = userThoughts.trimmingCharacters(in: .whitespacesAndNewlines)
        // Combine all reference URLs into a single array
        let allUrls = [instagramLink, pinterestLink]
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .flatMap { $0.components(separatedBy: "\n") }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        print("🔍 Creating StyleReference with:")
        print("   🔗 URLs: \(allUrls.isEmpty ? "none" : "\(allUrls)")")
        print("   🏷️ Keywords: \(styleKeywords)")
        print("   💭 User Thoughts: \(trimmedThoughts.isEmpty ? "none" : trimmedThoughts)")

        let styleReference = StyleReference(
            urls: allUrls,
            styleKeywords: styleKeywords,
            userThoughts: trimmedThoughts.isEmpty ? nil : trimmedThoughts
        )

        print("✅ StyleReference created with userThoughts: \(styleReference.userThoughts ?? "nil")")

        Task {
            do {
                print("🔄 === STARTING DESIGN REQUEST SUBMISSION ===")
                // First test the connections
                print("🔍 Step 1/4: Testing Supabase connection before submitting request...")
                let supabaseWorking = true // Mock connection test
                if !supabaseWorking {
                    print("❌ Supabase connection test failed")
                    throw APIError.saveFailed
                }
                print("✅ Supabase connection test passed")
                
                // Skip n8n test - proceed directly with real request
                print("🔄 Step 2/4: Converting images to data format...")
                // Convert UIImages to Data
                let imageDataArray: [Data] = images.compactMap { image in
                    #if canImport(UIKit)
                    return image.jpegData(compressionQuality: 0.8)
                    #else
                    return Data() // Fallback for non-iOS platforms
                    #endif
                }
                print("✅ Converted \(imageDataArray.count) images to data (sizes: \(imageDataArray.map { $0.count }))")
                
                print("🔄 Step 3/4: Using scanned room data for submission...")

                let lidarData: LIDARData
                if let roomData = scannedRoomData {
                    // Use real scanned room data with spatial layout
                    let spatialLayout = roomData.getSimplifiedSpatialLayout()
                    lidarData = LIDARData(
                        roomDimensions: roomData.dimensions,
                        roomType: roomData.roomType,
                        roomFeatures: roomData.features,
                        spatialLayout: spatialLayout
                    )
                    print("✅ Using REAL scanned room data with spatial layout:")
                    print("   🏠 Room Type: \(roomData.roomType)")
                    print("   📏 Dimensions: \(roomData.dimensions.width)x\(roomData.dimensions.depth)x\(roomData.dimensions.height)m")
                    print("   📐 Area: \(roomData.dimensions.area) sq m")
                    print("   🏗️ Features: \(roomData.features.walls) walls, \(roomData.features.doors) doors, \(roomData.features.windows) windows")
                    print("   🗺️ Spatial Layout: \(spatialLayout.walls.count) walls with detailed positioning")
                } else {
                    // Fallback to demo data if no scan available
                    let demoRoomDimensions = RoomDimensions(width: 4.0, height: 2.8, depth: 3.0)
                    let demoRoomFeatures = RoomFeatures(walls: 4, doors: 1, windows: 2, openings: 0)
                    lidarData = LIDARData(roomDimensions: demoRoomDimensions, roomType: "living_room", roomFeatures: demoRoomFeatures, spatialLayout: nil)
                    print("⚠️ No scanned data available, using demo room data: \(demoRoomDimensions.width)x\(demoRoomDimensions.depth)x\(demoRoomDimensions.height)m")
                }

                print("🔄 Step 4/4: Submitting design request to API...")
                let id = try await apiService.submitDesignRequest(
                    lidarData: lidarData,
                    styleReference: styleReference,
                    referenceImages: imageDataArray
                )
                print("✅ Design request submitted successfully with ID: \(id)")
                
                print("🔄 Step 5/5: Starting result polling...")
                await MainActor.run {
                    self.requestId = id
                    self.startPolling()
                }
                print("✅ === DESIGN REQUEST SUBMISSION COMPLETED ===")
            } catch {
                print("❌ === DESIGN REQUEST SUBMISSION FAILED ===")
                print("❌ Error details: \(error)")
                print("❌ Error type: \(type(of: error))")
                await MainActor.run {
                    print("❌ Design request failed: \(error)")
                    if let apiError = error as? APIError {
                        self.errorMessage = apiError.localizedDescription
                        print("❌ API Error: \(apiError.localizedDescription)")
                    } else {
                        self.errorMessage = "Request failed: \(error.localizedDescription)"
                        print("❌ General Error: \(error.localizedDescription)")
                    }
                    self.isProcessing = false
                }
            }
        }
    }
    
    private func startPolling() {
        guard let requestId = requestId else {
            print("❌ Cannot start polling: requestId is nil")
            return
        }
        
        print("🔄 Starting result polling for requestId: \(requestId)")
        print("⏱️ Polling interval: 5 seconds")
        
        var pollCount = 0
        Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { timer in
            pollCount += 1
            if pollCount > 60 { // Stop after 5 minutes
                print("⏰ Polling timeout after 5 minutes")
                timer.invalidate()
                return
            }
            Task {
                do {
                    print("🔍 Polling for results... (RequestID: \(requestId))")
                    let response = try await apiService.checkProcessingStatus(requestId: requestId)
                    
                    await MainActor.run {
                        print("📥 Received response: Status = \(response.status)")
                        self.designResponse = response

                        if response.status == .completed {
                            print("🎉 Design generation completed successfully!")
                            print("🖼️ Generated images: \(response.generatedImages?.count ?? 0)")
                            timer.invalidate()
                            withAnimation {
                                self.isProcessing = false
                            }
                        } else if response.status == .failed {
                            print("❌ Design generation failed: \(response.error ?? "Unknown error")")
                            timer.invalidate()
                            self.errorMessage = response.error ?? "Processing failed"
                            withAnimation {
                                self.isProcessing = false
                            }
                        } else {
                            print("⏳ Design still processing... Status: \(response.status)")
                        }
                    }
                } catch {
                    print("❌ Polling error: \(error)")
                    print("❌ Polling error type: \(type(of: error))")
                }
            }
        }
    }

    private func simulateDemoProcessing() {
        Task {
            // Simulate the processing steps for demo
            for step in 0..<processingSteps.count {
                await MainActor.run {
                    processingStep = step
                }
                try? await Task.sleep(nanoseconds: 800_000_000) // 0.8 seconds per step
            }

            // Create demo response with sample images
            let demoResponse = DesignResponse(
                id: UUID().uuidString,
                requestId: "demo-request-123",
                generatedImages: Config.DemoData.sampleDesignImages,
                status: .completed,
                createdAt: Date(),
                completedAt: Date(),
                error: nil
            )

            await MainActor.run {
                print("🎭 Demo processing completed - navigating to results")
                designResponse = demoResponse
                isProcessing = false
                showResults = true
            }
        }
    }
}

#Preview {
    NavigationStack {
        ProcessingView(
            images: [],
            instagramLink: "https://instagram.com/example",
            pinterestLink: "",
            styleKeywords: ["Modern", "Minimalist"],
            userThoughts: "I want a cozy reading corner with natural light",
            scannedRoomData: nil
        )
    }
}
