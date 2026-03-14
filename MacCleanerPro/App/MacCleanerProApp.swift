import SwiftUI

@main
struct MacCleanerProApp: App {
    @StateObject private var scannerViewModel = ScannerViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(scannerViewModel)
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
        }
    }
}
