import SwiftUI
import Combine
class ForgotPasswordController: ObservableObject {
    @Published var email = ""
    @Published var error: String?
    @Published var successMessage: String?
    
    private let authModel = AuthModel()
    
    func sendPasswordReset() {
        authModel.sendPasswordReset(email: email) { result in
            switch result {
            case .success:
                self.error = nil
                self.successMessage = "Password reset email sent successfully."
            case .failure(let error):
                self.error = error.localizedDescription
                self.successMessage = nil
            }
        }
    }
}
