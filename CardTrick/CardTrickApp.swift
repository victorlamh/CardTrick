import SwiftUI

@main
struct CardTrickApp: App {
    @StateObject private var calc = CalculatorState()

    var body: some Scene {
        WindowGroup {
            CalculatorView()
                .environmentObject(calc)
                .preferredColorScheme(.dark)
                .onAppear {
                    calc.requestNotificationPermission()
                }
        }
    }
}
