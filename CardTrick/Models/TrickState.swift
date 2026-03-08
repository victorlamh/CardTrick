import Foundation

enum TrickPhase {
    case fakeCard
    case realCard
    case idle
}

class TrickConfig: ObservableObject {
    @Published var phase: TrickPhase = .idle
    @Published var isArmed: Bool = false

    func advance() {
        guard isArmed else { return }
        switch phase {
        case .idle:
            phase = .fakeCard
        case .fakeCard:
            phase = .realCard
        case .realCard:
            phase = .idle
            isArmed = false
        }
    }

    func reset() {
        phase = .idle
        isArmed = false
    }
}
