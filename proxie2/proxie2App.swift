import SwiftUI
import FirebaseAppCheck
import Firebase

@main
public struct Proxie2App: App {
    // Ensure Firebase is set up at the start
    public init() {
        FirebaseApp.configure()

        // Initialize App Check with DeviceCheck
              AppCheck.setAppCheckProviderFactory(DeviceCheckProviderFactory())
        
        if CommandLine.arguments.contains("--uitesting") {
            print("Firebase configured for UI testing")
        }
    }
    
    public var body: some Scene {
        WindowGroup {
            ContentView() // Start with ContentView that handles navigation
        }
    }
}
