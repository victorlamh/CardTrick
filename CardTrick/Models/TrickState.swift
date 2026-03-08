import Foundation

enum TrickPhase {
    case fakeCard   // Pass 1: card detected → show fake card overlay
    case realCard   // Pass 2: card detected → show real feed, no overlay
    case idle       // Default: just show camera, no trick active
}

class TrickConfig: ObservableObject {
    @Published var phase: TrickPhase = .idle
    @Published var isArmed: Bool = false  // toggled from secret config screen

    // Advance through phases on each card detection trigger
    func advance() {
        guard isArmed else { return }
        switch phase {
        case .idle:
            phase = .fakeCard
        case .fakeCard:
            phase = .realCard
        case .realCard:
            phase = .idle
            isArmed = false  // trick is done, disarm automatically
        }
    }

    func reset() {
        phase = .idle
        isArmed = false
    }
}
