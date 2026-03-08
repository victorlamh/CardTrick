import SwiftUI

@main
struct CardTrickApp: App {
    @StateObject private var trickConfig = TrickConfig()

    var body: some Scene {
        WindowGroup {
            CameraView()
                .environmentObject(trickConfig)
                .preferredColorScheme(.dark)
                .statusBarHidden(true)  // hides the clock/battery bar for cleaner camera look
        }
    }
}
