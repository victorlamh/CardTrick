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

            // Front camera
            guard let device = AVCaptureDevice.default(
                .builtInWideAngleCamera,
                for: .video,
                position: .front
            ),
            let input = try? AVCaptureDeviceInput(device: device),
            self.session.canAddInput(input) else { return }

            self.session.addInput(input)

            // Frame output
            self.videoOutput.setSampleBufferDelegate(self, queue: self.detectionQueue)
            self.videoOutput.alwaysDiscardsLateVideoFrames = true
            if self.session.canAddOutput(self.videoOutput) {
                self.session.addOutput(self.videoOutput)
            }

            // Lock orientation to portrait
            if let connection = self.videoOutput.connection(with: .video) {
                connection.videoRotationAngle = 90
                connection.isVideoMirrored = true
            }

            self.session.commitConfiguration()
            self.session.startRunning()
        }
    }

    // Called on every frame
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

            // VNRectangleObservation gives normalized coords (0-1), bottom-left origin
            // We get 4 corners
            let corners = [
                best.topLeft,
                best.topRight,
                best.bottomRight,
                best.bottomLeft
            ]
            DispatchQueue.main.async { self?.detectedCardCorners = corners }
        }

        // Tune for playing card aspect ratio (63x88mm → ~0.716)
        request.minimumAspectRatio = 0.5
        request.maximumAspectRatio = 0.85
        request.minimumConfidence = 0.85
        request.minimumSize = 0.2
        request.maximumObservations = 1

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        try? handler.perform([request])
    }
}

// MARK: - SwiftUI Camera Preview
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

    var body: some View {
        ZStack {
            // Live camera feed (fills screen)
            CameraPreview(session: camera.session)
                .ignoresSafeArea()

            // Overlay layer — card replacement drawn here
            if let corners = camera.detectedCardCorners {
                CardOverlayView(
                    corners: corners,
                    phase: trickConfig.phase
                )
                .ignoresSafeArea()
                .onAppear { trickConfig.advance() }
            }

            // Secret config button — top right corner, invisible
            VStack {
                HStack {
                    Spacer()
                    Button(action: { showConfig = true }) {
                        Color.clear.frame(width: 60, height: 60)
                    }
                }
                Spacer()
            }
        }
        .sheet(isPresented: $showConfig) {
            ConfigView().environmentObject(trickConfig)
        }
    }
}
