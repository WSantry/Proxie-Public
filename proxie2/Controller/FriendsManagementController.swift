import SwiftUI
import Combine
import FirebaseAuth

class FriendsManagementController: ObservableObject {
    @Published var username = ""
    @Published var friendAddedMessage: String?
    @Published var error: String?
    private let friendRequestModel = FriendRequestModel()

    func sendFriendRequest() {
        guard let currentUserUID = Auth.auth().currentUser?.uid else {
            self.error = "Unable to get current user ID."
            return
        }
        friendRequestModel.fetchUid(forUsername: username) { friendUID in
            if let friendUID = friendUID {
                self.friendRequestModel.sendFriendRequest(toUID: friendUID, fromUID: currentUserUID) { result in
                    DispatchQueue.main.async {
                        switch result {
                        case .success:
                            self.friendAddedMessage = "Friend request sent to \(self.username)"
                        case .failure(let error):
                            self.error = "Error sending request: \(error.localizedDescription)"
                        }
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.error = "User not found."
                }
            }
        }
    }

    func acceptFriendRequest(fromUID: String) {
        guard let currentUserUID = Auth.auth().currentUser?.uid else {
            print("Unable to get current user ID.")
            return
        }
        friendRequestModel.acceptFriendRequest(currentUID: currentUserUID, friendUID: fromUID) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    print("Friend request accepted.")
                case .failure(let error):
                    print("Error accepting request: \(error.localizedDescription)")
                }
            }
        }
    }
}
