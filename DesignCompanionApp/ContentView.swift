import SwiftUI
import RoomPlan

struct ContentView: View {
    @State private var currentWordIndex = 0
    @State private var animateWord = false

    private let rotatingWords = [
        "Reimagined",
        "Transformed",
        "Elevated",
        "Personalized",
        "Simplified"
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                // Chapter background
                ChapterColors.background
                    .ignoresSafeArea()

                VStack(spacing: 20) {
                    Spacer()

                    // Chapter Logo
                    VStack(spacing: 8) {
                        Image("ChapterLogo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 180, height: 180)

                        Text("Start a new Chapter!")
                            .font(.system(size: 36, weight: .bold, design: .default))
                            .foregroundColor(ChapterColors.text)
                    }

                    // Tagline
                    VStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Text("Interior Design.")
                                .font(.title3)
                                .fontWeight(.light)
                                .foregroundColor(ChapterColors.text)

                            Text(rotatingWords[currentWordIndex])
                                .font(.title3)
                                .fontWeight(.light)
                                .foregroundColor(ChapterColors.accent)
                                .opacity(animateWord ? 1 : 0)
                                .offset(y: animateWord ? 0 : 10)
                        }

                        Text("Transform your space with AI-powered design")
                            .font(.body)
                            .foregroundColor(ChapterColors.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal)

                    Spacer()

                    // Features highlight
                    VStack(spacing: 16) {
                        FeatureRow(icon: "house", title: "Room Setup", description: "Quick room configuration")
                        FeatureRow(icon: "wand.and.rays", title: "AI Style Generation", description: "Personalized design concepts")
                        FeatureRow(icon: "photo.on.rectangle", title: "Visual References", description: "Upload inspiration photos")
                    }
                    .padding(.horizontal)

                    Spacer()

                    // Get Started Button
                    Group {
                        if #available(iOS 16.0, *) {
                            NavigationLink(destination: RoomScanView { capturedRoom in
                                // Navigate to style input after successful scan
                                print("Room scan completed, navigating to style input...")
                            }) {
                                Text("Start Your Design Journey")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(ChapterColors.accent)
                                    .cornerRadius(25)
                            }
                        } else {
                            NavigationLink(destination: StyleInputView()) {
                                VStack {
                                    Text("Start Your Design Journey")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                    Text("(LiDAR requires iOS 16+)")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.8))
                                }
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(ChapterColors.accent)
                                .cornerRadius(25)
                            }
                        }
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarBackButtonHidden(true)
            .onAppear {
                startWordRotation()
            }
        }
    }

    private func startWordRotation() {
        // Initial animation
        withAnimation(.easeInOut(duration: 0.5)) {
            animateWord = true
        }

        // Start timer to rotate words
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            // Fade out
            withAnimation(.easeInOut(duration: 0.3)) {
                animateWord = false
            }

            // Change word after fade out
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                currentWordIndex = (currentWordIndex + 1) % rotatingWords.count

                // Fade in
                withAnimation(.easeInOut(duration: 0.5)) {
                    animateWord = true
                }
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(ChapterColors.accent)
                .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(ChapterColors.text)

                Text(description)
                    .font(.caption)
                    .foregroundColor(ChapterColors.secondaryText)
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(ChapterColors.cardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(ChapterColors.border, lineWidth: 0.5)
        )
    }
}

#Preview {
    ContentView()
}
