import SwiftUI

@main
struct BorderBeamDemoApp: App {
    var body: some Scene {
        WindowGroup {
            PlaygroundView()
                .frame(minWidth: 720, minHeight: 760)
        }
        .windowResizability(.contentMinSize)
    }
}
