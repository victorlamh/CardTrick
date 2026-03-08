import SwiftUI

struct ConfigView: View {
    @EnvironmentObject var calc: CalculatorState
    @Environment(\.dismiss) var dismiss
    @State private var delayInput: String = ""

    var body: some View {
        NavigationStack {
            Form {
                // Status
                Section {
                    HStack {
                        Text("Status")
                        Spacer()
                        Text(calc.isArmed ? "ARMED" : "Disarmed")
                            .foregroundColor(calc.isArmed ? .red : .secondary)
                            .fontWeight(.semibold)
                    }
                } header: {
                    Text("Trick")
                }

                // Arm toggle
                Section {
                    Toggle("Arm Vibration", isOn: $calc.isArmed)
                        .tint(.red)
                } footer: {
                    Text("When armed, pressing = schedules a vibration after the delay below. Disarms automatically after firing.")
                }

                // Delay config
                Section {
                    HStack {
                        Text("Delay")
                        Spacer()
                        TextField("seconds", text: $delayInput)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("sec")
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("Vibration Timing")
                } footer: {
                    Text("How many seconds after = is pressed before the phone vibrates. Default is 10.")
                }

                // Reset
                Section {
                    Button("Disarm & Reset") {
                        calc.isArmed = false
                    }
                    .foregroundColor(.orange)
                } footer: {
                    Text("Cancels any pending vibration.")
                }
            }
            .navigationTitle("Config")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        if let d = Double(delayInput), d > 0 {
                            calc.vibrationDelay = d
                        }
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                delayInput = String(calc.vibrationDelay)
            }
        }
    }
}
