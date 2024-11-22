import SwiftUI
import FirebaseAuth

class LoginController: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var error: String?
    
    private let authModel = AuthModel()
    
    func signIn() {
        authModel.signIn(email: email, password: password) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self.error = nil
                    // No need to set isLoggedIn; ContentView observes authentication state
                case .failure(let error):
                    self.error = error.localizedDescription
                }
            }
        }
    }
}
