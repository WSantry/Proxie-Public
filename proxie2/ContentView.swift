import SwiftUI
import FirebaseAuth

struct ContentView: View {
    @State private var isLoggedIn = false
    @State private var showSignUpView = false

    var body: some View {
        Group {
            if isLoggedIn && !showSignUpView {
                MapView() // Your main app view
            } else if showSignUpView {
                SignUpView(showSignUpView: $showSignUpView)
            } else {
                LoginView(showSignUpView: $showSignUpView)
            }
        }
        .onAppear {
            self.isLoggedIn = Auth.auth().currentUser != nil
            Auth.auth().addStateDidChangeListener { auth, user in
                withAnimation {
                    self.isLoggedIn = user != nil
                }
            }
        }
    }
}
