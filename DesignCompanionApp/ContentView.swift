import SwiftUI
import RoomPlan

struct ContentView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                // Chapter background
                ChapterColors.background
                    .ignoresSafeArea()

                VStack(spacing: 40) {
                    Spacer()

                    // Chapter Logo
                    VStack(spacing: 20) {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(ChapterColors.accent)
                            .frame(width: 120, height: 120)
                            .overlay(
                                Text("C")
                                    .font(.system(size: 48, weight: .bold))
                                    .foregroundColor(.white)
                            )

                        Text("Chapter")
                            .font(.system(size: 36, weight: .bold, design: .default))
                            .foregroundColor(ChapterColors.text)
                    }

                    // Tagline
                    VStack(spacing: 12) {
                        Text("Interior Design. Reimagined.")
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundColor(ChapterColors.text)

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