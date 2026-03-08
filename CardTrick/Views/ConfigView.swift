import SwiftUI

struct ConfigView: View {
    @EnvironmentObject var trickConfig: TrickConfig
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            Form {
                // Current status
                Section {
                    HStack {
                        Text("Current Phase")
                        Spacer()
                        Text(phaseLabel)
                            .foregroundColor(phaseColor)
                            .fontWeight(.semibold)
                    }
                } header: {
                    Text("Status")
                }

                // Arm / disarm
                Section {
                    Toggle("Arm Trick", isOn: $trickConfig.isArmed)
                        .tint(.red)
                } header: {
                    Text("Control")
                } footer: {
                    Text("When armed, each time a card enters the frame the trick advances: first pass shows fake card, second pass shows real card, then disarms automatically.")
                }

                // Manual phase override (useful for rehearsal)
                Section {
                    Button("Reset to Idle") {
                        trickConfig.reset()
                    }
                    .foregroundColor(.orange)

                    Button("Force → Fake Card Phase") {
                        trickConfig.phase = .fakeCard
                        trickConfig.isArmed = true
                    }
                    .foregroundColor(.blue)

                    Button("Force → Real Card Phase") {
                        trickConfig.phase = .realCard
                        trickConfig.isArmed = true
                    }
                    .foregroundColor(.blue)
                } header: {
                    Text("Manual Override")
                } footer: {
                    Text("Use these during rehearsal to test each phase independently.")
                }
            }
            .navigationTitle("Trick Config")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private var phaseLabel: String {
        switch trickConfig.phase {
        case .idle:     return "Idle"
        case .fakeCard: return "Fake Card"
        case .realCard: return "Real Card"
        }
    }

    private var phaseColor: Color {
        switch trickConfig.phase {
        case .idle:     return .secondary
        case .fakeCard: return .red
        case .realCard: return .green
        }
    }
}
