import SwiftUI
import AVFoundation
import Vision

// MARK: - Camera Session Manager
class CameraManager: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    @Published var detectedCardCorners: [CGPoint]? = nil

    let session = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let sessionQueue = DispatchQueue(label: "camera.session.queue")
    private let detectionQueue = DispatchQueue(label: "card.detection.queue")

    override init() {
        super.init()
        setupSession()
    }

    private func setupSession() {
        sessionQueue.async {
            self.session.beginConfiguration()
            self.session.sessionPreset = .hd1920x1080

            guard let device = AVCaptureDevice.default(
                .builtInWideAngleCamera,
                for: .video,
                position: .front
            ),
            let input = try? AVCaptureDeviceInput(device: device),
            self.session.canAddInput(input) else { return }

            self.session.addInput(input)

            self.videoOutput.setSampleBufferDelegate(self, queue: self.detectionQueue)
            self.videoOutput.alwaysDiscardsLateVideoFrames = true
            if self.session.canAddOutput(self.videoOutput) {
                self.session.addOutput(self.videoOutput)
            }

            if let connection = self.videoOutput.connection(with: .video) {
                connection.videoRotationAngle = 90
                connection.isVideoMirrored = true
            }

            self.session.commitConfiguration()
            self.session.startRunning()
        }
    }

    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        detectCard(in: pixelBuffer)
    }

    private func detectCard(in pixelBuffer: CVPixelBuffer) {
        let request = VNDetectRectanglesRequest { [weak self] req, _ in
            guard let results = req.results as? [VNRectangleObservation],
                  let best = results.first else {
                DispatchQueue.main.async { self?.detectedCardCorners = nil }
                return
            }
            let corners = [best.topLeft, best.topRight, best.bottomRight, best.bottomLeft]
            DispatchQueue.main.async { self?.detectedCardCorners = corners }
        }

        request.minimumAspectRatio = 0.5
        request.maximumAspectRatio = 0.85
        request.minimumConfidence = 0.85
        request.minimumSize = 0.2
        request.maximumObservations = 1

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        try? handler.perform([request])
    }
}

// MARK: - Camera Preview
struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {}
}

class PreviewView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
    var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
}

// MARK: - Main Camera View
struct CameraView: View {
    @EnvironmentObject var trickConfig: TrickConfig
    @StateObject private var camera = CameraManager()
    @State private var showConfig = false
    @State private var debugMode: Bool = false

    var body: some View {
        ZStack {
            // Live camera feed
            CameraPreview(session: camera.session)
                .ignoresSafeArea()

            // Card overlay
            if let corners = camera.detectedCardCorners {
                CardOverlayView(
                    corners: corners,
                    phase: trickConfig.phase,
                    debugMode: debugMode
                )
                .ignoresSafeArea()
                .onAppear { trickConfig.advance() }
            }

            // Debug HUD — top left
            if debugMode {
                VStack(alignment: .leading, spacing: 6) {
                    debugBadge("Phase: \(phaseLabel)", color: phaseColor)
                    debugBadge("Armed: \(trickConfig.isArmed ? "YES" : "NO")", color: trickConfig.isArmed ? .green : .gray)
                    debugBadge("Card: \(camera.detectedCardCorners != nil ? "DETECTED ✓" : "not found")", color: camera.detectedCardCorners != nil ? .green : .red)
                    Spacer()
                }
                .padding(.top, 60)
                .padding(.leading, 16)
            }

            // Controls
            VStack {
                HStack {
                    // Debug badge (visible when on)
                    if debugMode {
                        Button(action: { debugMode = false }) {
                            Text("DEBUG ON")
                                .font(.system(size: 11, weight: .bold))
                                .padding(.horizontal, 8).padding(.vertical, 4)
                                .background(Color.red)
                                .foregroundColor(.white)
                                .cornerRadius(6)
                        }
                        .padding(.leading, 16)
                    }
                    Spacer()
                    // Secret config tap zone — top right, invisible
                    Button(action: { showConfig = true }) {
                        Color.clear.frame(width: 60, height: 60)
                    }
                }
                Spacer()
                // Long press bottom bar 1 second → toggle debug
                HStack {
                    Spacer()
                    Color.clear
                        .frame(height: 80)
                        .contentShape(Rectangle())
                        .onLongPressGesture(minimumDuration: 1.0) {
                            debugMode.toggle()
                        }
                    Spacer()
                }
            }
        }
        .sheet(isPresented: $showConfig) {
            ConfigView().environmentObject(trickConfig)
        }
    }

    private var phaseLabel: String {
        switch trickConfig.phase {
        case .idle: return "Idle"
        case .fakeCard: return "Fake Card"
        case .realCard: return "Real Card"
        }
    }

    private var phaseColor: Color {
        switch trickConfig.phase {
        case .idle: return .gray
        case .fakeCard: return .red
        case .realCard: return .green
        }
    }

    private func debugBadge(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .semibold, design: .monospaced))
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(color.opacity(0.85))
            .foregroundColor(.white)
            .cornerRadius(6)
    }
}
