import SwiftUI

struct CardOverlayView: View {
    let corners: [CGPoint]  // 4 normalized points from Vision (0-1 range, bottom-left origin)
    let phase: TrickPhase

    var body: some View {
        GeometryReader { geo in
            let size = geo.size

            // Only draw the fake card overlay during fakeCard phase
            if phase == .fakeCard {
                let screenCorners = convertCorners(corners, to: size)

                // SwiftUI can't do perspective warp natively
                // We use a Canvas to draw the image with a perspective transform
                Canvas { context, canvasSize in
                    guard let image = UIImage(named: "fake_card"),
                          let cgImage = image.cgImage else { return }

                    // Build a perspective transform from unit square → screen corners
                    var path = Path()
                    path.move(to: screenCorners[0])       // topLeft
                    path.addLine(to: screenCorners[1])    // topRight
                    path.addLine(to: screenCorners[2])    // bottomRight
                    path.addLine(to: screenCorners[3])    // bottomLeft
                    path.closeSubpath()

                    // Draw image clipped and transformed into the quad
                    context.clip(to: path)

                    let imgW = CGFloat(cgImage.width)
                    let imgH = CGFloat(cgImage.height)

                    // Compute bounding rect of the quad to position the image
                    let xs = screenCorners.map { $0.x }
                    let ys = screenCorners.map { $0.y }
                    let minX = xs.min()!
                    let minY = ys.min()!
                    let maxX = xs.max()!
                    let maxY = ys.max()!

                    let drawRect = CGRect(
                        x: minX,
                        y: minY,
                        width: maxX - minX,
                        height: maxY - minY
                    )

                    context.draw(
                        Image(decorative: cgImage, scale: 1.0),
                        in: drawRect
                    )
                }
                .ignoresSafeArea()
            }
        }
    }

    // Convert Vision normalized coords to screen points
    // Vision uses bottom-left origin, SwiftUI uses top-left — flip Y axis
    private func convertCorners(_ corners: [CGPoint], to size: CGSize) -> [CGPoint] {
        return corners.map { point in
            CGPoint(
                x: point.x * size.width,
                y: (1 - point.y) * size.height  // flip Y
            )
        }
    }
}
