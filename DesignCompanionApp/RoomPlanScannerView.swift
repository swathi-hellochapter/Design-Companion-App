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
            } else {
                print("✅ RoomPlan: Successfully captured room")
                self.scanResult.wrappedValue = processedResult
                NotificationCenter.default.post(name: .roomScanCompleted, object: processedResult)
            }
            self.isPresented.wrappedValue = false
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
            captureView.captureSession.stop()
            print("🏠 ✅ Capture session stopped - processing results...")
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

    var body: some View {
        StyleInputView()
            .onAppear {
                print("🏠 ✅ Navigated to StyleInputView with scanned room data!")
                let roomData = RoomScanData(from: capturedRoom)
                print("🏠 📊 Room description: \(roomData.roomDescription)")
            }
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
