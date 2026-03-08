import SwiftUI

struct ConfigView: View {
    @EnvironmentObject var trickConfig: TrickConfig
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            Form {
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

                Section {
                    Toggle("Arm Trick", isOn: $trickConfig.isArmed)
                        .tint(.red)
                } header: {
                    Text("Control")
                } footer: {
                    Text("When armed, each card pass advances the trick: first pass shows fake card, second pass shows real card, then disarms automatically.")
                }

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
        case .idle: return "Idle"
        case .fakeCard: return "Fake Card"
        case .realCard: return "Real Card"
        }
    }

    private var phaseColor: Color {
        switch trickConfig.phase {
        case .idle: return .secondary
        case .fakeCard: return .red
        case .realCard: return .green
        }
    }
}
