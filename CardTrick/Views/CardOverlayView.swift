import SwiftUI

struct CardOverlayView: View {
    let corners: [CGPoint]
    let phase: TrickPhase
    var debugMode: Bool = false

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            let screenCorners = convertCorners(corners, to: size)

            ZStack {
                // Fake card overlay — only in fakeCard phase
                if phase == .fakeCard {
                    Canvas { context, _ in
                        guard let image = UIImage(named: "fake_card"),
                              let cgImage = image.cgImage else { return }

                        var path = Path()
                        path.move(to: screenCorners[0])
                        path.addLine(to: screenCorners[1])
                        path.addLine(to: screenCorners[2])
                        path.addLine(to: screenCorners[3])
                        path.closeSubpath()

                        context.clip(to: path)

                        let xs = screenCorners.map { $0.x }
                        let ys = screenCorners.map { $0.y }
                        let drawRect = CGRect(
                            x: xs.min()!, y: ys.min()!,
                            width: xs.max()! - xs.min()!,
                            height: ys.max()! - ys.min()!
                        )
                        context.draw(Image(decorative: cgImage, scale: 1.0), in: drawRect)
                    }
                }

                // Debug overlay — shows corners + quad outline
                if debugMode {
                    Canvas { context, _ in
                        // Draw quad outline
                        var path = Path()
                        path.move(to: screenCorners[0])
                        path.addLine(to: screenCorners[1])
                        path.addLine(to: screenCorners[2])
                        path.addLine(to: screenCorners[3])
                        path.closeSubpath()
                        context.stroke(path, with: .color(.green), lineWidth: 2)

                        // Draw corner dots
                        for corner in screenCorners {
                            let dot = Path(ellipseIn: CGRect(x: corner.x - 6, y: corner.y - 6, width: 12, height: 12))
                            context.fill(dot, with: .color(.red))
                        }
                    }
                }
            }
        }
    }

    private func convertCorners(_ corners: [CGPoint], to size: CGSize) -> [CGPoint] {
        return corners.map { point in
            CGPoint(x: point.x * size.width, y: (1 - point.y) * size.height)
        }
    }
}
