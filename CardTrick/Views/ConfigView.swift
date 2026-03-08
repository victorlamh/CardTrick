import SwiftUI
import UserNotifications

struct ConfigView: View {
    @EnvironmentObject var calc: CalculatorState
    @Environment(\.dismiss) var dismiss
    @State private var delayInput: String = ""

    var body: some View {
        NavigationStack {
            Form {
                // Permission status — critical diagnostic
                Section {
                    HStack {
                        Text("Notification Permission")
                        Spacer()
                        if calc.notificationPermissionGranted {
                            Text("Granted ✓")
                                .foregroundColor(.green)
                                .fontWeight(.semibold)
                        } else {
                            Button("Open Settings") {
                                if let url = URL(string: UIApplication.openSettingsURLString) {
                                    UIApplication.shared.open(url)
                                }
                            }
                            .foregroundColor(.red)
                        }
                    }

                    if !calc.lastScheduleError.isEmpty {
                        HStack {
                            Text("Last schedule")
                            Spacer()
                            Text(calc.lastScheduleError)
                                .foregroundColor(calc.lastScheduleError.contains("OK") ? .green : .red)
                                .font(.system(size: 13))
                        }
                    }
                } header: {
                    Text("Diagnostics")
                }

                // Arm
                Section {
                    HStack {
                        Text("Status")
                        Spacer()
                        Text(calc.isArmed ? "ARMED 🔴" : "Disarmed")
                            .foregroundColor(calc.isArmed ? .red : .secondary)
                            .fontWeight(.semibold)
                    }
                    Toggle("Arm Vibration", isOn: $calc.isArmed)
                        .tint(.red)
                } header: {
                    Text("Trick Control")
                } footer: {
                    Text("When armed, pressing = schedules the vibration then disarms automatically.")
                }

                // Delay
                Section {
                    HStack {
                        Text("Delay")
                        Spacer()
                        TextField("10", text: $delayInput)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("sec")
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("Timing")
                }

                // Test button — fire immediately to verify it works
                Section {
                    Button("Test Vibration Now (3 sec)") {
                        calc.isArmed = true
                        // Temporarily set short delay for test
                        let saved = calc.vibrationDelay
                        calc.vibrationDelay = 3
                        calc.tapped("1")
                        calc.tapped("+")
                        calc.tapped("1")
                        calc.tapped("=")
                        calc.vibrationDelay = saved
                    }
                    .foregroundColor(.blue)

                    Button("Cancel Pending Vibration") {
                        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
                        calc.isArmed = false
                        calc.lastScheduleError = ""
                    }
                    .foregroundColor(.orange)
                } header: {
                    Text("Debug")
                } footer: {
                    Text("Use Test to verify vibration works on your device before performing.")
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
                calc.requestNotificationPermission()
            }
        }
    }
}
