import SwiftUI

struct CardOverlayView: View {
    let corners: [CGPoint]
    let phase: TrickPhase
    var debugMode: Bool = false

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            let screenCorners = toScreen(corners, size: size)

            ZStack {
                if phase == .fakeCard {
                    WarpedCardView(screenCorners: screenCorners, size: size)
                }

                if debugMode {
                    Canvas { ctx, _ in
                        var p = Path()
                        p.move(to: screenCorners[0])
                        p.addLine(to: screenCorners[1])
                        p.addLine(to: screenCorners[2])
                        p.addLine(to: screenCorners[3])
                        p.closeSubpath()
                        ctx.stroke(p, with: .color(.green), lineWidth: 2)
                        for c in screenCorners {
                            ctx.fill(
                                Path(ellipseIn: CGRect(x: c.x-6, y: c.y-6, width: 12, height: 12)),
                                with: .color(.red)
                            )
                        }
                    }
                }
            }
        }
    }

    private func toScreen(_ pts: [CGPoint], size: CGSize) -> [CGPoint] {
        pts.map { CGPoint(x: $0.x * size.width, y: (1 - $0.y) * size.height) }
    }
}

// MARK: - Perspective warp via CIPerspectiveTransform
struct WarpedCardView: UIViewRepresentable {
    let screenCorners: [CGPoint]  // [topLeft, topRight, bottomRight, bottomLeft]
    let size: CGSize

    func makeUIView(context: Context) -> UIImageView {
        let v = UIImageView()
        v.backgroundColor = .clear
        return v
    }

    func updateUIView(_ uiView: UIImageView, context: Context) {
        guard
            let src = UIImage(named: "fake_card"),
            let ci = CIImage(image: src),
            let filter = CIFilter(name: "CIPerspectiveTransform")
        else { return }

        func flip(_ p: CGPoint) -> CIVector {
            CIVector(x: p.x, y: size.height - p.y)
        }

        filter.setValue(ci,                          forKey: kCIInputImageKey)
        filter.setValue(flip(screenCorners[0]),      forKey: "inputTopLeft")
        filter.setValue(flip(screenCorners[1]),      forKey: "inputTopRight")
        filter.setValue(flip(screenCorners[2]),      forKey: "inputBottomRight")
        filter.setValue(flip(screenCorners[3]),      forKey: "inputBottomLeft")

        guard let out = filter.outputImage else { return }

        let ciCtx = CIContext(options: [.useSoftwareRenderer: false])
        let rect = CGRect(origin: .zero, size: size)
        guard let cg = ciCtx.createCGImage(out, from: rect) else { return }

        uiView.frame = rect
        uiView.image = UIImage(cgImage: cg)
    }
}
