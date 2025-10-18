import SwiftUI
import RoomPlan
import AVFoundation

extension Notification.Name {
    static let roomScanCompleted = Notification.Name("roomScanCompleted")
}

@available(iOS 16.0, *)
class RoomPlanCoordinator: NSObject, RoomCaptureViewDelegate {
    func encode(with coder: NSCoder) {
        // No encoding needed for our use case
    }

    required init?(coder: NSCoder) {
        // Create dummy bindings for decoding - this shouldn't be called in practice
        self.isPresented = .constant(false)
        self.scanResult = .constant(nil)
        self.scanError = .constant(nil)
        super.init()
    }
    
    var isPresented: Binding<Bool>
    var scanResult: Binding<CapturedRoom?>
    var scanError: Binding<String?>

    init(isPresented: Binding<Bool>, scanResult: Binding<CapturedRoom?>, scanError: Binding<String?>) {
        self.isPresented = isPresented
        self.scanResult = scanResult
        self.scanError = scanError
        super.init()
    }

    func captureView(shouldPresent roomDataForProcessing: CapturedRoomData, error: Error?) -> Bool {
        print("🏠 RoomPlan: Capture completed")
        if let error = error {
            print("❌ RoomPlan error: \(error)")
            DispatchQueue.main.async {
                self.scanError.wrappedValue = error.localizedDescription
            }
            return false
        }
        return true
    }

    func captureView(didPresent processedResult: CapturedRoom, error: Error?) {
        print("🏠 RoomPlan: Processing completed")
        DispatchQueue.main.async {
            if let error = error {
                print("❌ RoomPlan processing error: \(error)")
                self.scanError.wrappedValue = error.localizedDescription
                self.isPresented.wrappedValue = false
            } else {
                print("✅ RoomPlan: Successfully captured room")
                // Let RoomPlan finish naturally - the 3D animation happens here automatically
                self.scanResult.wrappedValue = processedResult
                NotificationCenter.default.post(name: .roomScanCompleted, object: processedResult)
                self.isPresented.wrappedValue = false
            }
        }
    }
}

@available(iOS 16.0, *)
struct RoomPlanScannerView: UIViewRepresentable {
    @Binding var isPresented: Bool
    @Binding var scanResult: CapturedRoom?
    @Binding var scanError: String?

    func makeUIView(context: Context) -> RoomCaptureView {
        print("🏠 Creating RoomCaptureView...")
        let captureView = RoomCaptureView()
        captureView.delegate = context.coordinator
        print("🏠 RoomCaptureView created and delegate set")

        // Start the capture session
        DispatchQueue.main.async {
            print("🏠 Starting capture session...")
            captureView.captureSession.run(configuration: RoomCaptureSession.Configuration())
            print("🏠 ✅ Capture session started")
        }

        return captureView
    }

    func updateUIView(_ uiView: RoomCaptureView, context: Context) {
        // No updates needed
    }

    func makeCoordinator() -> RoomPlanCoordinator {
        RoomPlanCoordinator(isPresented: $isPresented, scanResult: $scanResult, scanError: $scanError)
    }
}

@available(iOS 16.0, *)
struct RoomPlanScannerViewWithRef: UIViewRepresentable {
    @Binding var isPresented: Bool
    @Binding var scanResult: CapturedRoom?
    @Binding var scanError: String?
    @Binding var captureViewRef: RoomCaptureView?

    func makeUIView(context: Context) -> RoomCaptureView {
        print("🏠 Creating RoomCaptureView...")
        let captureView = RoomCaptureView()
        captureView.delegate = context.coordinator
        print("🏠 RoomCaptureView created and delegate set")

        // Store reference for stop button
        DispatchQueue.main.async {
            captureViewRef = captureView
        }

        // Start the capture session
        DispatchQueue.main.async {
            print("🏠 Starting capture session...")
            captureView.captureSession.run(configuration: RoomCaptureSession.Configuration())
            print("🏠 ✅ Capture session started")
        }

        return captureView
    }

    func updateUIView(_ uiView: RoomCaptureView, context: Context) {
        // No updates needed
    }

    func makeCoordinator() -> RoomPlanCoordinator {
        RoomPlanCoordinator(isPresented: $isPresented, scanResult: $scanResult, scanError: $scanError)
    }
}

@available(iOS 16.0, *)
struct RoomScannerWithControls: View {
    @Binding var isPresented: Bool
    @Binding var scanResult: CapturedRoom?
    @Binding var scanError: String?
    @State private var captureView: RoomCaptureView?

    var body: some View {
        ZStack {
            // The scanning view (full screen)
            RoomPlanScannerViewWithRef(
                isPresented: $isPresented,
                scanResult: $scanResult,
                scanError: $scanError,
                captureViewRef: $captureView
            )
            .ignoresSafeArea()

            // Stop button overlay (top right)
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        print("🏠 Stop scan button tapped")
                        stopScanAndFinish()
                    }) {
                        Text("Stop Scan")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(Color.red)
                            .cornerRadius(25)
                    }
                    .padding(.trailing, 20)
                    .padding(.top, 20)
                }
                Spacer()
            }
        }
    }

    private func stopScanAndFinish() {
        print("🏠 Stopping capture session...")
        if let captureView = captureView {
            print("🏠 ⏱️ Letting scan complete naturally with extended animation...")
            captureView.captureSession.stop()
            print("🏠 ✅ Capture session stopped - RoomPlan will now show extended 3D animation...")
        } else {
            print("🏠 ❌ No capture view reference - just closing")
            isPresented = false
        }
    }
}

// MARK: - Scanning Interface View
@available(iOS 16.0, *)
struct RoomScanView: View {
    @State private var isScanning = false
    @State private var scanResult: CapturedRoom?
    @State private var scanError: String?
    @State private var showingScanner = false
    @State private var scanCompletedId = UUID()
    @State private var navigateToStyleInput = false
    @State private var scannedRoom: CapturedRoom?

    let onScanComplete: (CapturedRoom) -> Void

    var body: some View {
        VStack(spacing: 30) {
            // Header
            VStack(spacing: 15) {
                Image(systemName: "viewfinder.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(ChapterColors.accent)

                Text("Scan Your Room")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(ChapterColors.text)

                Text("Use your iPhone's LiDAR to capture room dimensions")
                    .font(.body)
                    .foregroundColor(ChapterColors.secondaryText)
                    .multilineTextAlignment(.center)
            }

            // Scan Instructions
            VStack(alignment: .leading, spacing: 15) {
                instructionRow(icon: "1.circle.fill", text: "Point your phone at the room corners")
                instructionRow(icon: "2.circle.fill", text: "Move slowly around the room")
                instructionRow(icon: "3.circle.fill", text: "Capture all walls and openings")
                instructionRow(icon: "4.circle.fill", text: "Tap done when complete")
            }
            .padding()
            .background(ChapterColors.cardBackground)
            .cornerRadius(15)
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(ChapterColors.border, lineWidth: 1)
            )

            Spacer()

            // Scan Button
            Button(action: {
                print("🏠 === STARTING ROOM SCAN ===")
                requestCameraPermission()
            }) {
                HStack {
                    Image(systemName: "viewfinder")
                    Text("Start Room Scan")
                        .fontWeight(.semibold)
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(ChapterColors.accent)
                .cornerRadius(25)
            }
            .disabled(isScanning)
        }
        .padding()
        .background(ChapterColors.background)
        .sheet(isPresented: $showingScanner) {
            print("🏠 === SHEET IS BEING PRESENTED ===")
            return RoomScannerWithControls(
                isPresented: $showingScanner,
                scanResult: $scanResult,
                scanError: $scanError
            )
        }
        .onReceive(NotificationCenter.default.publisher(for: .roomScanCompleted)) { notification in
            if let room = notification.object as? CapturedRoom {
                print("✅ Scan completed, processing result...")
                scannedRoom = room
                navigateToStyleInput = true
                onScanComplete(room)
            }
        }
        .navigationDestination(isPresented: $navigateToStyleInput) {
            if let room = scannedRoom {
                StyleInputViewWithRoom(capturedRoom: room)
            }
        }
    }

    private func requestCameraPermission() {
        print("🏠 Requesting camera permission...")
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                if granted {
                    print("🏠 ✅ Camera permission granted")
                    print("🏠 Button tapped, setting showingScanner = true")
                    showingScanner = true
                    print("🏠 showingScanner is now: \(showingScanner)")
                } else {
                    print("🏠 ❌ Camera permission denied")
                    scanError = "Camera access is required for room scanning"
                }
            }
        }
    }

    private func instructionRow(icon: String, text: String) -> some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(ChapterColors.accent)
                .frame(width: 30)

            Text(text)
                .font(.body)
                .foregroundColor(ChapterColors.text)

            Spacer()
        }
    }
}

@available(iOS 16.0, *)
struct StyleInputViewWithRoom: View {
    let capturedRoom: CapturedRoom
    @State private var showingSummary = true

    var body: some View {
        if showingSummary {
            RoomScanSummaryView(capturedRoom: capturedRoom) {
                showingSummary = false
            }
        } else {
            StyleInputView()
                .onAppear {
                    print("🏠 ✅ Navigated to StyleInputView with scanned room data!")
                    let roomData = RoomScanData(from: capturedRoom)
                    print("🏠 📊 Room description: \(roomData.roomDescription)")
                }
        }
    }
}


@available(iOS 16.0, *)
struct RoomScanSummaryView: View {
    let capturedRoom: CapturedRoom
    let onContinue: () -> Void
    @State private var roomData: RoomScanData

    init(capturedRoom: CapturedRoom, onContinue: @escaping () -> Void) {
        self.capturedRoom = capturedRoom
        self.onContinue = onContinue
        self._roomData = State(initialValue: RoomScanData(from: capturedRoom))
    }

    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            // Success Header
            VStack(spacing: 15) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(ChapterColors.success)

                Text("Room Scan Complete!")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(ChapterColors.text)

                Text("Here's what we discovered about your space")
                    .font(.body)
                    .foregroundColor(ChapterColors.secondaryText)
                    .multilineTextAlignment(.center)
            }

            // Room Details Card
            VStack(spacing: 20) {
                // Room Type
                HStack {
                    Image(systemName: "house.fill")
                        .foregroundColor(ChapterColors.accent)
                        .frame(width: 24)

                    Text("Room Type:")
                        .foregroundColor(ChapterColors.secondaryText)

                    Spacer()

                    Text(roomData.roomType.replacingOccurrences(of: "_", with: " ").capitalized)
                        .fontWeight(.semibold)
                        .foregroundColor(ChapterColors.text)
                }

                Divider()

                // Dimensions
                HStack {
                    Image(systemName: "ruler")
                        .foregroundColor(ChapterColors.accent)
                        .frame(width: 24)

                    Text("Dimensions:")
                        .foregroundColor(ChapterColors.secondaryText)

                    Spacer()

                    Text("\(String(format: "%.1f", roomData.dimensions.width))m × \(String(format: "%.1f", roomData.dimensions.depth))m × \(String(format: "%.1f", roomData.dimensions.height))m")
                        .fontWeight(.semibold)
                        .foregroundColor(ChapterColors.text)
                }

                Divider()

                // Floor Area
                HStack {
                    Image(systemName: "square.grid.3x1.folder.badge.plus")
                        .foregroundColor(ChapterColors.accent)
                        .frame(width: 24)

                    Text("Floor Area:")
                        .foregroundColor(ChapterColors.secondaryText)

                    Spacer()

                    Text("\(String(format: "%.1f", roomData.dimensions.area)) sq m")
                        .fontWeight(.semibold)
                        .foregroundColor(ChapterColors.text)
                }

                Divider()

                // Features
                HStack {
                    Image(systemName: "cube.box")
                        .foregroundColor(ChapterColors.accent)
                        .frame(width: 24)

                    Text("Features:")
                        .foregroundColor(ChapterColors.secondaryText)

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(roomData.features.walls) walls, \(roomData.features.doors) doors")
                            .fontWeight(.semibold)
                            .foregroundColor(ChapterColors.text)
                        Text("\(roomData.features.windows) windows, \(roomData.features.openings) openings")
                            .fontWeight(.semibold)
                            .foregroundColor(ChapterColors.text)
                    }
                }
            }
            .padding(24)
            .background(ChapterColors.cardBackground)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(ChapterColors.border, lineWidth: 1)
            )
            .padding(.horizontal)

            Spacer()

            // Continue Button
            Button(action: {
                print("🏠 User tapped 'Let's Style This Room'")
                onContinue()
            }) {
                HStack {
                    Image(systemName: "paintbrush.fill")
                    Text("Let's Style This Room")
                        .fontWeight(.semibold)
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(ChapterColors.accent)
                .cornerRadius(25)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        }
        .background(ChapterColors.background)
        .navigationTitle("Scan Results")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    if #available(iOS 16.0, *) {
        RoomScanView { room in
            print("Scan completed: \(room)")
        }
    } else {
        Text("iOS 16.0+ Required for RoomPlan")
    }
}
