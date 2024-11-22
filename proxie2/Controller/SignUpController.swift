import SwiftUI
import FirebaseAuth
import FirebaseFirestore

class SignUpController: ObservableObject {
    @Published var username = ""
    @Published var email = ""
    @Published var password = ""
    @Published var profilePictureMonster = "default_monster_url"
    @Published var error: String?
    private let authModel = AuthModel()
    
    func signUp() {
        authModel.signUp(email: email, password: password) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    print("Sign-up successful for \(self.email)")
                    self.saveUserData()
                case .failure(let error):
                    self.error = error.localizedDescription
                    print("Sign-up failed: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func saveUserData() {
        guard let uid = Auth.auth().currentUser?.uid else {
            self.error = "Unable to retrieve user ID."
            return
        }

        let db = Firestore.firestore()
        
        let userData: [String: Any] = [
            "username": self.username,
            "profilePictureMonster": self.profilePictureMonster,
            "joinDate": Timestamp(),
            "locationData": [
                "currentLocation": NSNull(),
                "lastUpdated": NSNull()
            ],
            "privateData": [
                "email": self.email,
                "friendRequests": [],
                "friends": []
            ]
        ]
        
        db.collection("users").document(uid).setData(userData) { error in
            DispatchQueue.main.async {
                if let error = error {
                    self.error = "Error saving user data: \(error.localizedDescription)"
                    print("Error saving user data: \(error.localizedDescription)")
                } else {
                }
            }
        }
    }
    
    

    
    private func signOutUser() {
        do {
            try Auth.auth().signOut()
            self.username = ""
            self.email = ""
            self.password = ""
            self.profilePictureMonster = ""
            print("User signed out successfully.")
        } catch let signOutError as NSError {
            self.error = "Error signing out: \(signOutError.localizedDescription)"
            print("Error signing out: \(signOutError.localizedDescription)")
        }
    }
}
